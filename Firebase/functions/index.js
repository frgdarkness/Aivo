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
