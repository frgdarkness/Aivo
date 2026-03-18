const { onSchedule } = require('firebase-functions/v2/scheduler');
const { onRequest } = require('firebase-functions/v2/https');
const { setGlobalOptions } = require('firebase-functions/v2');
const admin = require('firebase-admin');

admin.initializeApp();
const db = admin.firestore();

// Set global options to use us-central1 region
setGlobalOptions({ region: 'us-central1' });

/**
 * Helper to get current week tag (YYYY-wWW)
 * matching the logic in iOS/DateUtils.swift
 */
function getWeekTag(date = new Date()) {
    const d = new Date(Date.UTC(date.getFullYear(), date.getMonth(), date.getDate()));
    const dayNum = d.getUTCDay() || 7;
    d.setUTCDate(d.getUTCDate() + 4 - dayNum);
    const yearStart = new Date(Date.UTC(d.getUTCFullYear(), 0, 1));
    const weekNo = Math.ceil((((d - yearStart) / 86400000) + 1) / 7);
    return `${d.getUTCFullYear()}-w${weekNo.toString().padStart(2, '0')}`;
}

/**
 * Main logic to calculate and save the leaderboard for a specific week tag
 */
async function calculateLeaderboard(weekTag) {
    console.log(`🚀 Calculating leaderboard for: ${weekTag}`);

    // Query Top 10 songs for the given weekTag
    const songsSnapshot = await db.collection('shared_songs')
        .where('isPublic', '==', true)
        .where('weekTag', '==', weekTag)
        .orderBy('playCount', 'desc')
        .limit(10)
        .get();

    if (songsSnapshot.empty) {
        console.log(`⚠️ No songs found for ${weekTag}`);
        return { success: false, message: 'No songs found', week: weekTag };
    }

    const songs = songsSnapshot.docs.map(doc => {
        const data = doc.data();
        data.id = doc.id; // Ensure ID is included
        return data;
    });
    
    const year = weekTag.split('-w')[0];
    const week = weekTag.split('-w')[1];

    const leaderboardData = {
        title: `${year} week ${week}`,
        songs: songs,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        calculatedAt: new Date().toISOString()
    };

    // Save to leaderboards collection
    await db.collection('leaderboards').doc(weekTag).set(leaderboardData);
    
    console.log(`✅ Leaderboard saved for ${weekTag} with ${songs.length} songs.`);
    return { success: true, week: weekTag, songsCount: songs.length };
}

/**
 * 1. Automated Scheduler: Run every Monday at 00:00 UTC (Gen 2)
 */
exports.weeklyLeaderboardSchedulerV2 = onSchedule('0 0 * * 1', async (event) => {
    // Calculate for the previous week (just finished)
    const lastWeekDate = new Date();
    lastWeekDate.setDate(lastWeekDate.getDate() - 1); // Sunday
    const weekTag = getWeekTag(lastWeekDate);
    
    return await calculateLeaderboard(weekTag);
});

/**
 * 2. Test/Force Trigger: Call via HTTP with ?week=YYYY-wWW (Gen 2)
 */
exports.weeklyLeaderboardForceV2 = onRequest({ invoker: "public" }, async (req, res) => {
    try {
        const weekParam = req.query.week;
        if (!weekParam) {
            return res.status(400).send('Missing "week" parameter (e.g. ?week=2026-w11)');
        }

        const result = await calculateLeaderboard(weekParam);
        return res.status(200).json(result);
    } catch (error) {
        console.error('❌ Error force calculating board:', error);
        return res.status(500).send(error.toString());
    }
});

// ============================================================
// PLAY COUNT SYNC: RTDB → Firestore
// ============================================================

const rtdb = admin.database();
const RTDB_PLAY_COUNTS_PATH = 'decoraIOS/play_counts';
const FIRESTORE_SONGS_COLLECTION = 'shared_songs';

/**
 * Core logic: Read play_counts from RTDB, batch update Firestore,
 * then use transactions to safely subtract synced counts (avoiding race conditions)
 */
async function syncPlayCounts() {
    console.log('🚀 [PlayCount Sync] Starting RTDB → Firestore sync...');

    // 1. Read all play counts from RTDB (snapshot at this moment)
    const snapshot = await rtdb.ref(RTDB_PLAY_COUNTS_PATH).once('value');
    const playCounts = snapshot.val();

    if (!playCounts || Object.keys(playCounts).length === 0) {
        console.log('✅ [PlayCount Sync] No pending play counts to sync.');
        return { success: true, message: 'No pending play counts', synced: 0 };
    }

    const songIDs = Object.keys(playCounts);
    console.log(`📊 [PlayCount Sync] Found ${songIDs.length} songs to sync`);

    // 2. Batch update Firestore (max 500 per batch)
    let totalSynced = 0;
    let batchCount = 0;
    const BATCH_SIZE = 450; // Leave some margin under 500 limit

    for (let i = 0; i < songIDs.length; i += BATCH_SIZE) {
        const batchSongIDs = songIDs.slice(i, i + BATCH_SIZE);
        const batch = db.batch();

        for (const songID of batchSongIDs) {
            const count = playCounts[songID];
            if (typeof count === 'number' && count > 0) {
                const songRef = db.collection(FIRESTORE_SONGS_COLLECTION).doc(songID);
                batch.update(songRef, {
                    playCount: admin.firestore.FieldValue.increment(count)
                });
                totalSynced++;
            }
        }

        try {
            await batch.commit();
            batchCount++;
            console.log(`✅ [PlayCount Sync] Batch ${batchCount} committed (${batchSongIDs.length} songs)`);
        } catch (error) {
            // Some songs might not exist in Firestore (private/intro songs)
            // Retry individually for this batch
            console.warn(`⚠️ [PlayCount Sync] Batch ${batchCount + 1} failed, retrying individually...`);
            for (const songID of batchSongIDs) {
                const count = playCounts[songID];
                if (typeof count === 'number' && count > 0) {
                    try {
                        await db.collection(FIRESTORE_SONGS_COLLECTION).doc(songID).update({
                            playCount: admin.firestore.FieldValue.increment(count)
                        });
                    } catch (innerError) {
                        // Song doesn't exist in Firestore - skip silently
                        console.log(`⏭️ [PlayCount Sync] Skipping ${songID} (not in Firestore)`);
                    }
                }
            }
            batchCount++;
        }
    }

    // 3. Safely subtract synced counts using RTDB transactions (avoids race conditions)
    //    If new writes came in between read (step 1) and now, the difference is preserved
    let cleanedCount = 0;
    const cleanupPromises = songIDs.map(songID => {
        const syncedCount = playCounts[songID];
        if (typeof syncedCount !== 'number' || syncedCount <= 0) return Promise.resolve();

        const songRef = rtdb.ref(`${RTDB_PLAY_COUNTS_PATH}/${songID}`);
        return songRef.transaction(currentValue => {
            if (currentValue === null) {
                // Already deleted by another process
                return null;
            }
            const remaining = currentValue - syncedCount;
            if (remaining <= 0) {
                // All counts synced, delete this key
                cleanedCount++;
                return null; // returning null deletes the node
            }
            // New writes came in during sync — keep the difference
            console.log(`📝 [PlayCount Sync] ${songID}: keeping ${remaining} new plays (was ${currentValue}, synced ${syncedCount})`);
            return remaining;
        });
    });

    await Promise.all(cleanupPromises);
    console.log(`🗑️ [PlayCount Sync] Cleaned ${cleanedCount}/${songIDs.length} entries from RTDB`);

    const result = {
        success: true,
        message: `Synced ${totalSynced} songs in ${batchCount} batches, cleaned ${cleanedCount} RTDB entries`,
        synced: totalSynced,
        batches: batchCount,
        cleaned: cleanedCount
    };
    console.log(`✅ [PlayCount Sync] Complete:`, result);
    return result;
}

/**
 * 3. Scheduled: Sync RTDB play counts to Firestore every 6 hours
 */
exports.syncPlayCountFromRTDB = onSchedule('0 */6 * * *', async (event) => {
    return await syncPlayCounts();
});

/**
 * 4. Force Trigger: Sync RTDB play counts immediately (for testing)
 *    Usage: https://<region>-<project>.cloudfunctions.net/syncPlayCountFromRTDBForce
 */
exports.syncPlayCountFromRTDBForce = onRequest({ invoker: "public" }, async (req, res) => {
    try {
        const result = await syncPlayCounts();
        return res.status(200).json(result);
    } catch (error) {
        console.error('❌ [PlayCount Sync] Force sync error:', error);
        return res.status(500).send(error.toString());
    }
});

// ============================================================
// COMMUNITY FEED SYNC: Firestore → RTDB
// Reduces client Firestore reads from 60 → 0 per fetch
// ============================================================

const RTDB_COMMUNITY_FEED_PATH = 'decoraIOS/community_feed';

/**
 * Core logic: Query hottest + newest from Firestore,
 * then write combined feed to RTDB for client reads
 */
async function syncCommunityFeed() {
    console.log('🚀 [CommunityFeed] Starting Firestore → RTDB sync...');

    const currentWeek = getWeekTag();
    console.log(`📅 [CommunityFeed] Current week: ${currentWeek}`);

    // 1. Fetch hottest songs of this week (by playCount)
    const hottestSnap = await db.collection(FIRESTORE_SONGS_COLLECTION)
        .where('isPublic', '==', true)
        .where('weekTag', '==', currentWeek)
        .orderBy('playCount', 'desc')
        .limit(10)
        .get();

    const hottest = hottestSnap.docs.map(doc => {
        const data = doc.data();
        // Convert Firestore Timestamps to epoch seconds
        for (const key of Object.keys(data)) {
            if (data[key] && typeof data[key] === 'object' && data[key]._seconds !== undefined) {
                data[key] = data[key]._seconds;
            }
        }
        return data;
    });
    console.log(`🔥 [CommunityFeed] Hottest: ${hottest.length} songs`);

    // 2. Fetch newest songs (by createTime)
    const newestSnap = await db.collection(FIRESTORE_SONGS_COLLECTION)
        .where('isPublic', '==', true)
        .orderBy('createTime', 'desc')
        .limit(50)
        .get();

    const newest = newestSnap.docs.map(doc => {
        const data = doc.data();
        // Convert Firestore Timestamps to epoch seconds
        for (const key of Object.keys(data)) {
            if (data[key] && typeof data[key] === 'object' && data[key]._seconds !== undefined) {
                data[key] = data[key]._seconds;
            }
        }
        return data;
    });
    console.log(`🆕 [CommunityFeed] Newest: ${newest.length} songs`);

    // 3. Write to RTDB (replaces entire node)
    await rtdb.ref(RTDB_COMMUNITY_FEED_PATH).set({
        lastUpdated: Math.floor(Date.now() / 1000),
        weekTag: currentWeek,
        hottest: hottest,
        newest: newest
    });

    const result = {
        success: true,
        message: `Community feed synced: ${hottest.length} hot, ${newest.length} new`,
        hottest: hottest.length,
        newest: newest.length,
        weekTag: currentWeek
    };
    console.log('✅ [CommunityFeed] Complete:', result);
    return result;
}

/**
 * 5. Scheduled: Sync community feed every 30 minutes
 */
exports.syncCommunityFeedToRTDB = onSchedule('*/30 * * * *', async (event) => {
    return await syncCommunityFeed();
});

/**
 * 6. Force Trigger: Sync community feed immediately (for testing)
 *    Usage: https://<region>-<project>.cloudfunctions.net/syncCommunityFeedToRTDBForce
 */
exports.syncCommunityFeedToRTDBForce = onRequest({ invoker: "public" }, async (req, res) => {
    try {
        const result = await syncCommunityFeed();
        return res.status(200).json(result);
    } catch (error) {
        console.error('❌ [CommunityFeed] Force sync error:', error);
        return res.status(500).send(error.toString());
    }
});
