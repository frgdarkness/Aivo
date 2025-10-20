import Foundation
import Combine

class CreditManager: ObservableObject {
    static let shared = CreditManager()
    
    @Published var credits: Int
    
    private let profileSyncManager = ProfileSyncManager.shared
    private let localStorage = LocalStorageManager.shared
    
    private init() {
        // Load credits from local storage
        credits = localStorage.getCurrentCredits()
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
        }
        
        Logger.d("CreditManager: Added \(amount) credits. Total: \(credits)")
        
        // Handle purchase - create remote profile if needed
        await profileSyncManager.syncProfileIfNeeded()
    

        // Log credit increase
        FirebaseLogger.shared.logEventWithBundle("event_credits_added", parameters: [
            "credits_added": amount,
            "total_credits": credits,
            "source": "in_app_purchase"
        ])
    }
}
