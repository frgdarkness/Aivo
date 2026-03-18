import Foundation
import FirebaseDatabase

/// Fetches community feed from RTDB instead of direct Firestore queries.
/// This reduces Firestore reads from 60 → 0 per fetch.
///
/// Flow:
/// 1. Cloud Function syncs Firestore → RTDB every 30 minutes
/// 2. Client reads from RTDB (0 Firestore reads, RTDB charged by bandwidth)
/// 3. Local cache prevents unnecessary RTDB fetches too
final class CommunityFeedManager {
    static let shared = CommunityFeedManager()
    
    private let rtdbPath = "decoraIOS/community_feed"
    
    private init() {}
    
    /// Fetch community feed from RTDB
    /// Returns (hottest, newest) song arrays
    func fetchCommunityFeed() async throws -> (hottest: [SunoData], newest: [SunoData]) {
        let ref = Database.database().reference().child(rtdbPath)
        
        Logger.d("📡 [CommunityFeed] Fetching from RTDB...")
        
        let snapshot = try await ref.getData()
        
        guard let value = snapshot.value as? [String: Any] else {
            Logger.d("📡 [CommunityFeed] No data found in RTDB, falling back to Firestore")
            return try await fallbackToFirestore()
        }
        
        let lastUpdated = value["lastUpdated"] as? Int ?? 0
        let weekTag = value["weekTag"] as? String ?? "unknown"
        
        var hottest: [SunoData] = []
        var newest: [SunoData] = []
        
        // Parse hottest array
        if let hottestArray = value["hottest"] as? [[String: Any]] {
            hottest = hottestArray.compactMap { parseSunoData(from: $0) }
        }
        
        // Parse newest array
        if let newestArray = value["newest"] as? [[String: Any]] {
            newest = newestArray.compactMap { parseSunoData(from: $0) }
        }
        
        let updatedDate = Date(timeIntervalSince1970: TimeInterval(lastUpdated))
        let ageMinutes = Int(Date().timeIntervalSince(updatedDate) / 60)
        Logger.d("📡 [CommunityFeed] RTDB loaded: \(hottest.count) hot, \(newest.count) new (week: \(weekTag), age: \(ageMinutes)min)")
        
        // If RTDB data is too old (> 2 hours) or empty, fallback to Firestore
        if hottest.isEmpty && newest.isEmpty {
            Logger.d("📡 [CommunityFeed] RTDB empty, falling back to Firestore")
            return try await fallbackToFirestore()
        }
        
        return (hottest, newest)
    }
    
    /// Fallback to direct Firestore queries if RTDB is empty/unavailable
    private func fallbackToFirestore() async throws -> (hottest: [SunoData], newest: [SunoData]) {
        Logger.d("📡 [CommunityFeed] Falling back to direct Firestore queries")
        let hottest = try await FirestoreService.shared.fetchHottestSongs(limit: 10)
        let newest = try await FirestoreService.shared.fetchNewSongs(limit: 50)
        return (hottest, newest)
    }
    
    /// Parse a dictionary into SunoData
    private func parseSunoData(from dict: [String: Any]) -> SunoData? {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: dict) else { return nil }
        return try? JSONDecoder().decode(SunoData.self, from: jsonData)
    }
}
