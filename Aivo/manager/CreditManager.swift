import Foundation
import Combine

class CreditManager: ObservableObject {
    static let shared = CreditManager()
    
    @Published var credits: Int
    @Published var isPremiumUser: Bool = false
    
    private let profileSyncManager = ProfileSyncManager.shared
    private let localStorage = LocalStorageManager.shared
    
    private init() {
        // Priority 1: Load credits from Keychain (persists across app reinstalls)
        if let keychainCredits = KeychainManager.shared.getCredits() {
            credits = keychainCredits
            // Sync to local storage for backward compatibility
            localStorage.updateCredits(keychainCredits)
            Logger.d("CreditManager: Loaded credits=\(credits) from Keychain")
        } else {
            // Priority 2: Load from local storage (fallback)
            credits = localStorage.getCurrentCredits()
            // Save to Keychain if we have credits
            if credits > 0 {
                KeychainManager.shared.saveCredits(credits)
                Logger.d("CreditManager: Migrated credits=\(credits) from LocalStorage to Keychain")
            }
        }
        
        // Load premium status
        isPremiumUser = localStorage.isPremiumUser
        
        // Note: Weekly credit checking is now handled by SubscriptionManager.checkBonusCreditForSubscription()
        // This is called on app startup and after subscription status checks
    }
    
    /// Grant weekly credits to premium users
    /// This is called by SubscriptionManager after checking eligibility
    func grantWeeklyPremiumCredits(amount: Int = 1000) async {
        Logger.d("💎 Granting weekly premium credits (\(amount))")
        await increaseCredits(by: amount)
        localStorage.setLastPremiumCreditGrantDate(Date())
        
        // Log event
        AnalyticsLogger.shared.logEventWithBundle("event_premium_weekly_credits_granted", parameters: [
            "credits_granted": amount,
            "total_credits": credits,
            "source": "premium_subscription"
        ])
    }
    
    /// Update premium status
    /// - Parameters:
    ///   - isPremium: Premium status
    ///   - period: Subscription period
    ///   - skipInitialGrant: If true, skip automatic initial credit grant (used when credits already granted elsewhere)
    /// Note: Weekly credit checking is now handled by SubscriptionManager.checkBonusCreditForSubscription()
    func updatePremiumStatus(_ isPremium: Bool, period: SubscriptionInfo.SubscriptionPeriod? = nil, skipInitialGrant: Bool = false) {
        //localStorage.setIsPremiumUser(isPremium, period: period)
        isPremiumUser = isPremium
        
        Logger.d("💎 CreditManager: Premium status updated - isPremium: \(isPremium), period: \(period?.rawValue ?? "none")")
        
        // Note: Weekly credits are now handled separately by SubscriptionManager.checkBonusCreditForSubscription()
        // This method only updates the premium status flag
    }
    
    // Kiểm tra đủ credit cho một request
    func hasEnoughCredits(for count: Int = RemoteConfigManager.shared.creditPerRequest) -> Bool {
        return credits >= count
    }
    
    // Trừ credit sau khi request thành công
    func deductForSuccessfulRequest(count: Int = RemoteConfigManager.shared.creditPerRequest) async {
        guard credits >= count else { return }
        
        // Update local storage first
        let consumeSuccess = localStorage.consumeCredits(count)
        
        // Update UI on main thread
        await MainActor.run {
            self.credits = localStorage.getCurrentCredits()
            // Save to Keychain
            KeychainManager.shared.saveCredits(self.credits)
        }
        
        // Sync to Firebase if remote profile exists
        await profileSyncManager.syncProfileIfNeeded()
    }
    
    // Set số credit trực tiếp (Admin/debug)
    func setCredits(_ value: Int) {
        let newValue = max(0, value)
        
        // Update local storage first
        localStorage.updateCredits(newValue)
        
        // Update UI on main thread
        credits = newValue
        // Save to Keychain
        KeychainManager.shared.saveCredits(newValue)
        Logger.d("CreditManager: Set credits to \(newValue)")

        // Sync to Firebase if remote profile exists
        Task {
            await profileSyncManager.syncProfileIfNeeded()
        }
    }
    
    // Tăng credit (debug/khuyến mãi/in-app purchase)
    func increaseCredits(by amount: Int) async {
        Logger.d("increaseCredits(by \(amount))")
        guard amount > 0 else { return }
        
        // Update local storage first
        localStorage.addCredits(amount)
        
        // Update UI on main thread (only if not already updated)
        await MainActor.run {
            let newCredits = localStorage.getCurrentCredits()
            if self.credits != newCredits {
                self.credits = newCredits
            }
            // Save to Keychain
            KeychainManager.shared.saveCredits(newCredits)
        }
        
        Logger.d("CreditManager: Added \(amount) credits. Total: \(credits)")
        
        // Handle purchase - create remote profile if needed
        await profileSyncManager.syncProfileIfNeeded()
    

        // Log credit increase
        AnalyticsLogger.shared.logEventWithBundle("event_credits_added", parameters: [
            "credits_added": amount,
            "total_credits": credits,
            "source": "in_app_purchase"
        ])
    }
}
