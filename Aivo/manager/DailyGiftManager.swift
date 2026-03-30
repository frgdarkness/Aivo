import Foundation
import Combine

@MainActor
class DailyGiftManager: ObservableObject {
    static let shared = DailyGiftManager()
    
    @Published var currentStreak: Int = 0
    @Published var lastClaimDate: Date?
    @Published var isPremiumTrialActive: Bool = false
    @Published var trialExpiryDate: Date?
    
    // Credit mission states
    @Published var dailyShareClaimed: Bool = false
    @Published var lastShareClaimDate: Date?
    
    private let streakKey = "DailyGiftStreakCount"
    private let lastClaimDateKey = "DailyGiftLastClaimDate"
    private let trialExpiryKey = "DailyGiftTrialExpiryDate"
    private let shareClaimedKey = "DailyGiftShareClaimed"
    private let lastShareDateKey = "DailyGiftLastShareDate"
    
    // Reward structure: (credits, trialHours)
    struct DayReward {
        let credits: Int
        let trialHours: Int // 0 = no trial
        
        var description: String {
            if trialHours >= 24 {
                return "Claim \(credits) credits and \(trialHours/24) day premium free"
            } else if trialHours > 0 {
                return "Claim \(credits) credits and \(trialHours)h premium free"
            } else {
                return "Claim \(credits) credits free"
            }
        }
        
        var shortLabel: String {
            if trialHours >= 24 {
                return "+\(credits) & \(trialHours/24)d VIP"
            } else if trialHours > 0 {
                return "+\(credits) & \(trialHours)h VIP"
            } else {
                return "+\(credits)"
            }
        }
    }
    
    let dayRewards: [DayReward] = [
        DayReward(credits: 5,  trialHours: 0),   // Day 1
        DayReward(credits: 5,  trialHours: 0),   // Day 2
        DayReward(credits: 10, trialHours: 0),   // Day 3
        DayReward(credits: 10, trialHours: 1),   // Day 4: 1h premium
        DayReward(credits: 15, trialHours: 0),   // Day 5
        DayReward(credits: 15, trialHours: 0),   // Day 6
        DayReward(credits: 20, trialHours: 24),  // Day 7: 1 day premium
    ]
    
    /// The day number waiting to be claimed (1-7), or 0 if streak complete
    var todayDayNumber: Int {
        if canClaimToday() {
            let next = currentStreak + 1
            return next > 7 ? 1 : next
        } else {
            return currentStreak
        }
    }
    
    private init() {
        loadState()
        checkTrialExpiry()
        updateStreakIfNeeded()
    }
    
    private func loadState() {
        currentStreak = UserDefaults.standard.integer(forKey: streakKey)
        if let timestamp = UserDefaults.standard.object(forKey: lastClaimDateKey) as? Date {
            lastClaimDate = timestamp
        }
        if let trialTs = UserDefaults.standard.object(forKey: trialExpiryKey) as? Date {
            trialExpiryDate = trialTs
        }
        // Share mission
        dailyShareClaimed = UserDefaults.standard.bool(forKey: shareClaimedKey)
        if let shareDate = UserDefaults.standard.object(forKey: lastShareDateKey) as? Date {
            lastShareClaimDate = shareDate
            // Reset if not today
            if !Calendar.current.isDateInToday(shareDate) {
                dailyShareClaimed = false
                UserDefaults.standard.set(false, forKey: shareClaimedKey)
            }
        }
    }
    
    func updateStreakIfNeeded() {
        guard let last = lastClaimDate else { return }
        
        let calendar = Calendar.current
        if calendar.isDateInToday(last) { return }
        
        let now = Date()
        let diff = calendar.dateComponents([.day], from: calendar.startOfDay(for: last), to: calendar.startOfDay(for: now))
        
        if let days = diff.day, days > 1 {
            Logger.d("🎁 [DailyGift] Streak reset! Days missed: \(days)")
            currentStreak = 0
            saveStreak()
        }
    }
    
    func canClaimToday() -> Bool {
        guard let last = lastClaimDate else { return true }
        return !Calendar.current.isDateInToday(last)
    }
    
    func claim() {
        guard canClaimToday() else { return }
        
        if currentStreak >= 7 {
            currentStreak = 1
        } else {
            currentStreak += 1
        }
        
        lastClaimDate = Date()
        saveStreak()
        saveLastClaimDate()
        
        let reward = dayRewards[currentStreak - 1]
        
        // Give credits
        Task {
            await CreditManager.shared.increaseCredits(by: reward.credits)
        }
        
        // Day 4: 1h Premium, Day 7: 24h Premium
        if reward.trialHours > 0 {
            activateTrialPremium(hours: reward.trialHours)
        }
        
        DailyGiftNotificationManager.shared.cancelRemindersForToday()
        
        Logger.d("🎁 [DailyGift] Claimed Day \(currentStreak)! Reward: \(reward.credits) credits, trial: \(reward.trialHours)h")
    }
    
    // MARK: - Share Mission
    func claimShareReward() {
        guard !dailyShareClaimed else { return }
        dailyShareClaimed = true
        lastShareClaimDate = Date()
        UserDefaults.standard.set(true, forKey: shareClaimedKey)
        UserDefaults.standard.set(Date(), forKey: lastShareDateKey)
        
        Task {
            await CreditManager.shared.increaseCredits(by: 20)
        }
        Logger.d("🎁 [DailyGift] Share mission claimed! +20 credits")
    }
    
    // MARK: - Trial Premium
    private func activateTrialPremium(hours: Int) {
        let expiry = Date().addingTimeInterval(TimeInterval(hours * 3600))
        trialExpiryDate = expiry
        saveTrialExpiry()
        isPremiumTrialActive = true
        SubscriptionManager.shared.refreshTrialStatus()
        Logger.d("🎁 [DailyGift] 💎 Trial Premium activated for \(hours)h until \(expiry)")
    }
    
    func checkTrialExpiry() {
        if let expiry = trialExpiryDate {
            if Date() > expiry {
                Logger.d("🎁 [DailyGift] 💎 Trial Premium expired.")
                trialExpiryDate = nil
                isPremiumTrialActive = false
                saveTrialExpiry()
                SubscriptionManager.shared.refreshTrialStatus()
            } else {
                isPremiumTrialActive = true
            }
        }
    }
    
    var isUserEffectivelyPremium: Bool {
        return SubscriptionManager.shared.isPremium || isPremiumTrialActive
    }
    
    // MARK: - Debug Helpers
    func debugSetStreak(_ day: Int) {
        currentStreak = min(max(day, 0), 7)
        // Set lastClaimDate to today so it looks like we just claimed
        lastClaimDate = Date()
        saveStreak()
        saveLastClaimDate()
        objectWillChange.send()
        Logger.d("🎁 [DEBUG] Streak set to Day \(currentStreak)")
    }
    
    func debugResetToday() {
        // Reset lastClaimDate to yesterday so canClaimToday() returns true
        lastClaimDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())
        saveLastClaimDate()
        objectWillChange.send()
        Logger.d("🎁 [DEBUG] Daily gift reset for today")
    }
    
    func debugResetCreditMissions() {
        // Reset video
        UserDefaultsManager.shared.dailyVideoCreditUsedCount = 0
        UserDefaultsManager.shared.lastVideoCreditDate = nil
        // Reset rate
        UserDefaultsManager.shared.hasRatedForCredit = false
        // Reset share
        dailyShareClaimed = false
        lastShareClaimDate = nil
        UserDefaults.standard.set(false, forKey: shareClaimedKey)
        UserDefaults.standard.removeObject(forKey: lastShareDateKey)
        
        objectWillChange.send()
        UserDefaultsManager.shared.objectWillChange.send()
        Logger.d("🎁 [DEBUG] Credit missions reset")
    }
    
    func debugClearTrial() {
        trialExpiryDate = nil
        isPremiumTrialActive = false
        saveTrialExpiry()
        SubscriptionManager.shared.refreshTrialStatus()
        objectWillChange.send()
        Logger.d("🎁 [DEBUG] Premium Trial cleared")
    }
    
    // MARK: - Persistence
    private func saveStreak() {
        UserDefaults.standard.set(currentStreak, forKey: streakKey)
    }
    
    private func saveLastClaimDate() {
        UserDefaults.standard.set(lastClaimDate, forKey: lastClaimDateKey)
    }
    
    private func saveTrialExpiry() {
        UserDefaults.standard.set(trialExpiryDate, forKey: trialExpiryKey)
    }
}
