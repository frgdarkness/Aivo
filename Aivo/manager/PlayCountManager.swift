import Foundation
import FirebaseDatabase

/// Manages play count tracking via RTDB instead of direct Firestore writes.
/// 
/// Flow:
/// 1. When a song starts playing, call `startTracking(songID:)`
/// 2. After `PLAY_COUNT_MIN_TIME` seconds (from RemoteConfig), the play is counted
/// 3. Play count is written to RTDB: `play_counts/{songID}` += 1
/// 4. Cloud Function syncs RTDB → Firestore every 6 hours
final class PlayCountManager {
    static let shared = PlayCountManager()
    
    private let basePath = "decoraIOS"
    
    private var dbRef: DatabaseReference {
        Database.database().reference()
    }
    
    // Track current song playback
    private var currentTrackingSongID: String?
    private var currentTrackingSongName: String?
    private var trackingTimer: Timer?
    private var trackingStartTime: Date?
    
    // Prevent double-counting for the same song in the same play session
    private var countedSongIDs: Set<String> = []
    
    private init() {
        Logger.d("📊 [PlayCountManager] Initialized")
    }
    
    // MARK: - Public API
    
    /// Start tracking a song play. After minimum time threshold, count will be recorded.
    /// Call this when a song starts playing.
    func startTracking(songID: String, songName: String = "") {
        // Prevent tracking local files (don't clutter global DB)
        if songID.hasPrefix("local_") {
            Logger.d("📊 [PlayCountManager] Skipping tracking for local song: \(songName)")
            return
        }
        
        // Stop previous tracking
        stopTracking()
        
        // Reset counted set if it's a different song
        // (allow re-counting if user plays the same song again later)
        
        currentTrackingSongID = songID
        currentTrackingSongName = songName
        trackingStartTime = Date()
        
        // Get minimum play time from RemoteConfig
        let minTime = RemoteConfigManager.shared.timeToRecordPlayCount
        
        Logger.d("📊 [PlayCountManager] Start tracking: \(songName) - \(songID), minTime: \(minTime)s")
        
        // Schedule timer to count after minimum time
        trackingTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(minTime), repeats: false) { [weak self] _ in
            self?.recordPlayCount(songID: songID, songName: songName)
        }
    }
    
    /// Stop tracking current song (call when song is stopped/skipped before threshold)
    func stopTracking() {
        trackingTimer?.invalidate()
        trackingTimer = nil
        
        if let songID = currentTrackingSongID, let startTime = trackingStartTime {
            let elapsed = Date().timeIntervalSince(startTime)
            Logger.d("📊 [PlayCountManager] Stopped tracking \(currentTrackingSongName ?? "") - \(songID) after \(String(format: "%.1f", elapsed))s")
        }
        
        currentTrackingSongID = nil
        currentTrackingSongName = nil
        trackingStartTime = nil
    }
    
    /// Call when song naturally finishes playing (always counts if not already counted)
    func songDidFinishPlaying(songID: String) {
        // If song finished naturally, it means user listened to the whole thing
        // Record if not already recorded by timer
        if !countedSongIDs.contains(songID) {
            recordPlayCount(songID: songID, songName: currentTrackingSongName ?? "")
        }
    }
    
    /// Clear counted songs set (call when app enters background or new session)
    func resetSession() {
        countedSongIDs.removeAll()
        Logger.d("📊 [PlayCountManager] Session reset")
    }
    
    // MARK: - Private
    
    private func recordPlayCount(songID: String, songName: String) {
        // Prevent double counting in same play session
        guard !countedSongIDs.contains(songID) else {
            Logger.d("📊 [PlayCountManager] Already counted \(songName) - \(songID) in this session, skipping")
            return
        }
        
        countedSongIDs.insert(songID)
        
        // Calculate increment value (1 or random 1..RANDOM_PLAY_COUNT_VALUE)
        let remoteConfig = RemoteConfigManager.shared
        let incrementValue: Int
        if remoteConfig.enableRandomPlayCount {
            incrementValue = Int.random(in: 1...remoteConfig.randomPlayCountValue)
            Logger.d("📊 [PlayCountManager] Random increment enabled: +\(incrementValue)")
        } else {
            incrementValue = 1
        }
        
        // Write to RTDB using atomic increment
        let path = "\(basePath)/play_counts/\(songID)"
        Logger.d("### write playCount RTDB: \(songName) - \(songID) (increment: \(incrementValue))")
        dbRef.child(path).setValue(ServerValue.increment(incrementValue as NSNumber)) { error, _ in
            if let error = error {
                Logger.e("❌ [PlayCountManager] RTDB write FAILED: \(songName) - \(songID) | Error: \(error.localizedDescription)")
            } else {
                Logger.d("✅ [PlayCountManager] RTDB write SUCCESS: \(songName) - \(songID)")
            }
        }
    }
}
