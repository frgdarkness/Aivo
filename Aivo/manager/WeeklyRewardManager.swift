import Foundation
import Combine

/// Manages weekly billboard reward checking and granting
class WeeklyRewardManager: ObservableObject {
    static let shared = WeeklyRewardManager()
    
    // Published state for UI binding (HomeView listens to these)
    @Published var pendingReward: WeeklyRewardInfo? = nil
    
    private let weeklyRewardCheckedKey = "AIVO_WeeklyRewardChecked"
    
    struct WeeklyRewardInfo {
        let rank: Int
        let song: SunoData
        let rewardAmount: Int
        let weekTag: String
    }
    
    private init() {}
    
    // MARK: - Reward Amount by Rank
    static func rewardForRank(_ rank: Int) -> Int {
        switch rank {
        case 1: return 1000
        case 2: return 500
        case 3: return 300
        case 4...10: return 200
        default: return 0
        }
    }
    
    // MARK: - Main Entry Point
    /// Called on app startup to check and claim weekly reward
    func checkAndClaimWeeklyReward() async {
        let previousWeekTag = getPreviousWeekTag()
        Logger.d("🏆 [WeeklyReward] Checking reward for week: \(previousWeekTag)")
        
        // 1. Check if already checked this week locally
        let checkedTag = UserDefaults.standard.string(forKey: weeklyRewardCheckedKey)
        if checkedTag == previousWeekTag {
            Logger.d("🏆 [WeeklyReward] Already checked \(previousWeekTag), skipping")
            return
        }
        
        // 2. Also check server-side weeklyRewardTag to prevent double-claiming
        let profile = LocalStorageManager.shared.getLocalProfile()
        if profile.weeklyRewardTag == previousWeekTag {
            Logger.d("🏆 [WeeklyReward] Already claimed reward for \(previousWeekTag) (server tag), marking local checked")
            UserDefaults.standard.set(previousWeekTag, forKey: weeklyRewardCheckedKey)
            return
        }
        
        // 3. Fetch the leaderboard for previous week
        do {
            guard let boardData = try await FirestoreService.shared.fetchWeeklyBoard(weekTag: previousWeekTag) else {
                Logger.d("🏆 [WeeklyReward] No leaderboard for \(previousWeekTag) yet, will try again later")
                return // Don't mark checked — leaderboard not generated yet
            }
            
            // 4. Parse songs from the board
            guard let songsArray = boardData["songs"] as? [[String: Any]] else {
                Logger.d("🏆 [WeeklyReward] No songs data in leaderboard \(previousWeekTag)")
                UserDefaults.standard.set(previousWeekTag, forKey: weeklyRewardCheckedKey)
                return
            }
            
            // 5. Find user's songs by profileID
            let userProfileID = profile.profileID
            var bestRank: Int? = nil
            var bestSongData: [String: Any]? = nil
            
            for (index, songData) in songsArray.enumerated() {
                if let songProfileID = songData["profileID"] as? String,
                   songProfileID == userProfileID {
                    let rank = index + 1 // 0-indexed → 1-indexed rank
                    if bestRank == nil || rank < bestRank! {
                        bestRank = rank
                        bestSongData = songData
                    }
                }
            }
            
            // 6. Mark as checked (leaderboard exists, regardless of whether user is in it)
            UserDefaults.standard.set(previousWeekTag, forKey: weeklyRewardCheckedKey)
            
            // 7. If user found in top 10, grant reward
            if let rank = bestRank, let songData = bestSongData, rank <= 10 {
                let rewardAmount = WeeklyRewardManager.rewardForRank(rank)
                
                Logger.i("🏆 [WeeklyReward] User found at rank #\(rank) in \(previousWeekTag)! Granting \(rewardAmount) credits")
                
                // Parse song for UI display
                let song = parseSongFromDict(songData)
                
                // Grant credits
                let previousBalance = CreditManager.shared.credits
                await CreditManager.shared.increaseCredits(by: rewardAmount)
                let afterBalance = CreditManager.shared.credits
                
                // Log to credit history
                CreditHistoryManager.shared.addRequest(.weeklyReward, cost: rewardAmount)
                
                // ✅ Log bonus to Firestore bonus_history
                await FirestoreService.shared.logBonusCredit(profileID: userProfileID, amount: rewardAmount, reason: "WeeklyBillboard", previousBalance: previousBalance, afterBalance: afterBalance)
                
                // Update weeklyRewardTag on profile and sync
                LocalStorageManager.shared.updateWeeklyRewardTag(previousWeekTag)
                await ProfileSyncManager.shared.syncProfileIfNeeded()
                
                // Log analytics
                AnalyticsLogger.shared.logEventWithBundle("event_weekly_reward_claimed", parameters: [
                    "week_tag": previousWeekTag,
                    "rank": rank,
                    "reward_credits": rewardAmount,
                    "song_id": song.id
                ])
                
                // Set pending reward for UI
                let rewardInfo = WeeklyRewardInfo(rank: rank, song: song, rewardAmount: rewardAmount, weekTag: previousWeekTag)
                await MainActor.run {
                    self.pendingReward = rewardInfo
                }
            } else {
                Logger.d("🏆 [WeeklyReward] User not found in top 10 for \(previousWeekTag)")
            }
            
        } catch {
            Logger.e("🏆 [WeeklyReward] Error checking reward: \(error)")
        }
    }
    
    /// Dismiss the reward dialog
    func dismissReward() {
        pendingReward = nil
    }
    
    // MARK: - Week Tag Helpers
    
    /// Calculate the previous week's tag (ISO 8601 week number)
    func getPreviousWeekTag() -> String {
        let calendar = Calendar(identifier: .iso8601)
        let now = Date()
        // Go back 7 days to get to last week
        guard let lastWeek = calendar.date(byAdding: .day, value: -7, to: now) else {
            return ""
        }
        let year = calendar.component(.yearForWeekOfYear, from: lastWeek)
        let week = calendar.component(.weekOfYear, from: lastWeek)
        return "\(year)-w\(String(format: "%02d", week))"
    }
    
    /// Get current week tag
    func getCurrentWeekTag() -> String {
        let calendar = Calendar(identifier: .iso8601)
        let now = Date()
        let year = calendar.component(.yearForWeekOfYear, from: now)
        let week = calendar.component(.weekOfYear, from: now)
        return "\(year)-w\(String(format: "%02d", week))"
    }
    
    // MARK: - Song Parsing
    private func parseSongFromDict(_ dict: [String: Any]) -> SunoData {
        // Parse essential fields for display
        let jsonData = try? JSONSerialization.data(withJSONObject: dict)
        if let data = jsonData, let song = try? JSONDecoder().decode(SunoData.self, from: data) {
            return song
        }
        // Fallback: create a minimal SunoData
        return SunoData(
            id: dict["id"] as? String ?? "",
            audioUrl: dict["audioUrl"] as? String ?? "",
            sourceAudioUrl: dict["sourceAudioUrl"] as? String ?? "",
            streamAudioUrl: dict["streamAudioUrl"] as? String ?? "",
            sourceStreamAudioUrl: dict["sourceStreamAudioUrl"] as? String ?? "",
            imageUrl: dict["imageUrl"] as? String ?? "",
            sourceImageUrl: dict["sourceImageUrl"] as? String ?? "",
            prompt: dict["prompt"] as? String ?? "",
            modelName: dict["modelName"] as? String ?? "",
            title: dict["title"] as? String ?? "Unknown",
            tags: dict["tags"] as? String ?? "",
            createTime: dict["createTime"] as? Int64 ?? 0,
            duration: dict["duration"] as? Double ?? 0
        )
    }
}
