import Foundation
import UIKit

final class LocalStorageManager: ObservableObject {
    static let shared = LocalStorageManager()
    
    private let userDefaults = UserDefaults.standard
    private let profileKey = "LocalUserProfile"
    private let hasRemoteProfileKey = "HasRemoteProfile"
    private let isPremiumUserKey = "IsPremiumUser"
    private let subscriptionPeriodKey = "SubscriptionPeriod"
    private let lastCreditGrantDateKey = "LastPremiumCreditGrantDate"
    
    @Published var localProfile: UserProfile?
    @Published var hasRemoteProfile = false
    @Published var isPremiumUser = false
    @Published var subscriptionPeriod: SubscriptionInfo.SubscriptionPeriod?
    
    private init() {
        loadLocalProfile()
        loadRemoteProfileStatus()
        loadPremiumStatus()
        
        // Ensure localProfile is never null
        if localProfile == nil {
            // Try to get profileID from Keychain first (persists across app reinstalls)
            let profileID: String
            if let keychainProfileID = KeychainManager.shared.getProfileID() {
                // ProfileID exists in Keychain - use it
                profileID = keychainProfileID
                Logger.d("🆔 Loaded profileID from Keychain: \(profileID)")
            } else {
                // No profileID in Keychain - generate new one and save to Keychain
                profileID = generatePersistentProfileID()
                KeychainManager.shared.saveProfileID(profileID)
                Logger.d("🆔 Generated new profileID and saved to Keychain: \(profileID)")
            }
            
            // Also save to UserDefaults for backward compatibility
            UserDefaults.standard.set(profileID, forKey: "FirebaseProfileID")
            
            localProfile = UserProfile(profileID: profileID)
            saveLocalProfile(localProfile!)
        } else {
            // If localProfile exists, ensure its profileID is also in Keychain
            let existingProfileID = localProfile!.profileID
            if KeychainManager.shared.getProfileID() == nil {
                // ProfileID not in Keychain - save it for persistence
                KeychainManager.shared.saveProfileID(existingProfileID)
                Logger.d("🆔 Synced existing profileID to Keychain: \(existingProfileID)")
            }
        }
    }
    
    // MARK: - Local Profile Management
    
    func saveLocalProfile(_ profile: UserProfile) {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .secondsSince1970
            let data = try encoder.encode(profile)
            userDefaults.set(data, forKey: profileKey)
            localProfile = profile
            Logger.d("💾 Local profile saved: \(profile.profileID) - currentCredit = \(profile.currentCredits)")
        } catch {
            Logger.e("❌ Failed to save local profile: \(error)")
        }
    }
    
    func loadLocalProfile() {
        guard let data = userDefaults.data(forKey: profileKey) else {
            Logger.d("📱 No local profile found")
            return
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .secondsSince1970
            let profile = try decoder.decode(UserProfile.self, from: data)
            localProfile = profile
            Logger.d("📱 Local profile loaded: \(profile.profileID)")
        } catch {
            Logger.e("❌ Failed to load local profile: \(error)")
        }
    }
    
    func updateLocalProfile(_ profile: UserProfile) {
        saveLocalProfile(profile)
    }
    
    func clearLocalProfile() {
        userDefaults.removeObject(forKey: profileKey)
        localProfile = nil
        Logger.d("🗑️ Local profile cleared")
    }
    
    // MARK: - Remote Profile Status
    
    func setHasRemoteProfile(_ hasRemote: Bool) {
        userDefaults.set(hasRemote, forKey: hasRemoteProfileKey)
        hasRemoteProfile = hasRemote
        Logger.d("🌐 Remote profile status: \(hasRemote)")
    }
    
    func loadRemoteProfileStatus() {
        hasRemoteProfile = userDefaults.bool(forKey: hasRemoteProfileKey)
        Logger.d("🌐 Remote profile status loaded: \(hasRemoteProfile)")
    }
    
    // MARK: - Premium Status Management
    
    func setIsPremiumUser(_ isPremium: Bool, period: SubscriptionInfo.SubscriptionPeriod? = nil) {
        userDefaults.set(isPremium, forKey: isPremiumUserKey)
        isPremiumUser = isPremium
        
        if let period = period {
            userDefaults.set(period.rawValue, forKey: subscriptionPeriodKey)
            self.subscriptionPeriod = period
        } else if !isPremium {
            userDefaults.removeObject(forKey: subscriptionPeriodKey)
            self.subscriptionPeriod = nil
        }
        
        Logger.d("💎 Premium status updated: \(isPremium), period: \(period?.rawValue ?? "none")")
    }
    
    func loadPremiumStatus() {
        isPremiumUser = userDefaults.bool(forKey: isPremiumUserKey)
        
        if let periodString = userDefaults.string(forKey: subscriptionPeriodKey),
           let period = SubscriptionInfo.SubscriptionPeriod(rawValue: periodString) {
            subscriptionPeriod = period
        } else {
            subscriptionPeriod = nil
        }
        
        Logger.d("💎 Premium status loaded: \(isPremiumUser), period: \(subscriptionPeriod?.rawValue ?? "none")")
    }
    
    func getPremiumStatus() -> (isPremium: Bool, period: SubscriptionInfo.SubscriptionPeriod?) {
        return (isPremiumUser, subscriptionPeriod)
    }
    
    // MARK: - Premium Credit Grant Management
    
    func setLastPremiumCreditGrantDate(_ date: Date) {
        userDefaults.set(date.timeIntervalSince1970, forKey: lastCreditGrantDateKey)
        Logger.d("💎 Last premium credit grant date saved: \(date)")
    }
    
    func getLastPremiumCreditGrantDate() -> Date? {
        let timestamp = userDefaults.double(forKey: lastCreditGrantDateKey)
        guard timestamp > 0 else { return nil }
        return Date(timeIntervalSince1970: timestamp)
    }
    
    func shouldGrantWeeklyCredits() -> Bool {
        guard isPremiumUser else { 
            Logger.d("💎 Should not grant credits: user is not premium")
            return false 
        }
        
        let currentDate = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        guard let lastGrantDate = getLastPremiumCreditGrantDate() else {
            // First time premium user, grant immediately
            Logger.d("💎 Should grant credits: first time premium user (no last grant date)")
            Logger.d("💎 Current date: \(dateFormatter.string(from: currentDate))")
            return true
        }
        
        // Log dates for tracking
        Logger.d("💎 [Credit Grant Check] Last grant date: \(dateFormatter.string(from: lastGrantDate))")
        Logger.d("💎 [Credit Grant Check] Current date: \(dateFormatter.string(from: currentDate))")
        
        // Calculate time difference
        let timeSinceLastGrant = currentDate.timeIntervalSince(lastGrantDate)
        let daysSinceLastGrant = timeSinceLastGrant / 86400.0 // Convert seconds to days
        let hoursSinceLastGrant = timeSinceLastGrant / 3600.0
        
        Logger.d("💎 [Credit Grant Check] Days since last grant: \(String(format: "%.2f", daysSinceLastGrant))")
        Logger.d("💎 [Credit Grant Check] Hours since last grant: \(String(format: "%.2f", hoursSinceLastGrant))")
        
        // Only grant if at least 7 days have passed
        // Also check minimum 1 hour to avoid multiple grants in same session
        guard hoursSinceLastGrant >= 1 else {
            Logger.d("💎 Should not grant credits: only \(String(format: "%.2f", hoursSinceLastGrant)) hours since last grant (minimum 1 hour required)")
            return false
        }
        
        let shouldGrant = daysSinceLastGrant >= 7
        Logger.d("💎 [Credit Grant Check] Should grant credits: \(shouldGrant) (requires 7 days, current: \(String(format: "%.2f", daysSinceLastGrant)) days)")
        
        return shouldGrant
    }
    
    // MARK: - Profile Access (Always Non-Null)
    
    /// Get local profile - always returns non-null profile
    func getLocalProfile() -> UserProfile {
        return localProfile ?? createLocalProfile()
    }
    
    // MARK: - Credit Operations
    
    func addCredits(_ amount: Int) {
        var profile = getLocalProfile()
        profile.addCredits(amount)
        updateLocalProfile(profile)
    }
    
    func consumeCredits(_ amount: Int) -> Bool {
        var profile = getLocalProfile()
        guard profile.currentCredits >= amount else { return false }
        profile.consumeCredits(amount: amount)
        updateLocalProfile(profile)
        return true
    }
    
    func updateCredits(_ credits: Int) {
        var profile = getLocalProfile()
        profile.currentCredits = credits
        updateLocalProfile(profile)
    }
    
    func getCurrentCredits() -> Int {
        return getLocalProfile().currentCredits
    }
    
    // MARK: - Sync Operations
    
    /// Sync profile to remote if needed
    func syncProfileIfNeeded() async {
        await ProfileSyncManager.shared.syncProfileIfNeeded()
    }

    
    // MARK: - Profile Creation
    
    func createLocalProfile() -> UserProfile {
        let profileID = generateLocalProfileID()
        let profile = UserProfile(profileID: profileID)
        saveLocalProfile(profile)
        return profile
    }
    
    private func generateLocalProfileID() -> String {
        let deviceID = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        let timestamp = Int(Date().timeIntervalSince1970)
        let random = Int.random(in: 1000...9999)
        return "local_\(deviceID.prefix(8))_\(timestamp)_\(random)"
    }
    
    // MARK: - Profile ID Management
    
    func getOrCreateProfileID() async throws -> String {
        // Priority 1: Check Keychain first (persists across app reinstalls)
        if let keychainProfileID = KeychainManager.shared.getProfileID() {
            // Sync to UserDefaults for backward compatibility
            UserDefaults.standard.set(keychainProfileID, forKey: "FirebaseProfileID")
            Logger.d("🆔 Retrieved profileID from Keychain: \(keychainProfileID)")
            return keychainProfileID
        }
        
        // Priority 2: Check UserDefaults (for migration from old version)
        if let existing = UserDefaults.standard.string(forKey: "FirebaseProfileID") {
            // Migrate to Keychain
            KeychainManager.shared.saveProfileID(existing)
            Logger.d("🆔 Migrated profileID from UserDefaults to Keychain: \(existing)")
            return existing
        }
        
        // Priority 3: Use existing localProfile if available
        if let existingProfile = localProfile {
            KeychainManager.shared.saveProfileID(existingProfile.profileID)
            UserDefaults.standard.set(existingProfile.profileID, forKey: "FirebaseProfileID")
            Logger.d("🆔 Using existing localProfile ID: \(existingProfile.profileID)")
            return existingProfile.profileID
        }
        
        // Priority 4: Generate new profileID
        let newID = generatePersistentProfileID()
        KeychainManager.shared.saveProfileID(newID)
        UserDefaults.standard.set(newID, forKey: "FirebaseProfileID")
        Logger.d("🆔 Generated new profileID: \(newID)")
        return newID
    }
    
    private func generatePersistentProfileID() -> String {
        let deviceID = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        let ts = Int(Date().timeIntervalSince1970)
        let rnd = Int.random(in: 1000...9999)
        let raw = "\(deviceID)_\(ts)_\(rnd)"
        let hash = raw.data(using: .utf8)?.base64EncodedString() ?? UUID().uuidString
        return "profile_\(hash.prefix(20))"
    }
}
