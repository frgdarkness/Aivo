import Foundation

// MARK: - Timestamped Lyrics Manager
class TimestampedLyricsManager {
    static let shared = TimestampedLyricsManager()
    
    private let userDefaults = UserDefaults.standard
    private let lyricsMapKey = "TimestampedLyricsMap"
    
    // In-memory cache: [SunoData.id: TimestampedLyricsData]
    private var lyricsCache: [String: TimestampedLyricsData] = [:]
    
    private init() {
        loadFromLocal()
    }
    
    // MARK: - Save Timestamped Lyrics
    func saveTimestampedLyrics(for songId: String, lyrics: TimestampedLyricsData) {
        // Update cache
        lyricsCache[songId] = lyrics
        
        // Save to UserDefaults
        saveToLocal()
        
        Logger.d("💾 [TimestampedLyrics] Saved lyrics for song: \(songId)")
    }
    
    // MARK: - Get Timestamped Lyrics
    func getTimestampedLyrics(for songId: String) -> TimestampedLyricsData? {
        return lyricsCache[songId]
    }
    
    // MARK: - Remove Timestamped Lyrics
    func removeTimestampedLyrics(for songId: String) {
        lyricsCache.removeValue(forKey: songId)
        saveToLocal()
        Logger.d("🗑️ [TimestampedLyrics] Removed lyrics for song: \(songId)")
    }
    
    // MARK: - Clear All
    func clearAll() {
        lyricsCache.removeAll()
        userDefaults.removeObject(forKey: lyricsMapKey)
        Logger.d("🗑️ [TimestampedLyrics] Cleared all lyrics")
    }
    
    // MARK: - Private Methods
    
    private func saveToLocal() {
        do {
            // Encode entire cache as JSON
            let encoder = JSONEncoder()
            let mapData = try encoder.encode(lyricsCache)
            userDefaults.set(mapData, forKey: lyricsMapKey)
            Logger.d("💾 [TimestampedLyrics] Saved \(lyricsCache.count) lyrics to local storage")
        } catch {
            Logger.e("❌ [TimestampedLyrics] Failed to save to local: \(error)")
        }
    }
    
    private func loadFromLocal() {
        guard let mapData = userDefaults.data(forKey: lyricsMapKey) else {
            Logger.d("📱 [TimestampedLyrics] No lyrics found in local storage")
            return
        }
        
        do {
            // Decode entire cache from JSON
            let decoder = JSONDecoder()
            let decodedCache = try decoder.decode([String: TimestampedLyricsData].self, from: mapData)
            lyricsCache = decodedCache
            
            Logger.d("📱 [TimestampedLyrics] Loaded \(lyricsCache.count) lyrics from local storage")
        } catch {
            Logger.e("❌ [TimestampedLyrics] Failed to load from local: \(error)")
            // Clear corrupted data
            userDefaults.removeObject(forKey: lyricsMapKey)
        }
    }
}

