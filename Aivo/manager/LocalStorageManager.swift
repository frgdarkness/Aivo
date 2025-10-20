import Foundation
import UIKit

final class LocalStorageManager: ObservableObject {
    static let shared = LocalStorageManager()
    
    private let userDefaults = UserDefaults.standard
    private let profileKey = "LocalUserProfile"
    private let hasRemoteProfileKey = "HasRemoteProfile"
    
    @Published var localProfile: UserProfile?
    @Published var hasRemoteProfile = false
    
    private init() {
        loadLocalProfile()
        loadRemoteProfileStatus()
        
        // Ensure localProfile is never null
        if localProfile == nil {
            let profileID = generatePersistentProfileID()
            localProfile = UserProfile(profileID: profileID)
            saveLocalProfile(localProfile!)
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
        if let existing = UserDefaults.standard.string(forKey: "FirebaseProfileID") {
            return existing
        }
        if let kc = KeychainManager.shared.getProfileID() {
            UserDefaults.standard.set(kc, forKey: "FirebaseProfileID")
            return kc
        }
        let newID = generatePersistentProfileID()
        UserDefaults.standard.set(newID, forKey: "FirebaseProfileID")
        KeychainManager.shared.saveProfileID(newID)
        Logger.d("🆔 Generated profileID: \(newID)")
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
