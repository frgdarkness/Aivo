import Foundation
import FirebaseCore
import FirebaseDatabase

final class ProfileSyncManager: ObservableObject {
    static let shared = ProfileSyncManager()
    
    private let firebaseService = FirebaseRealtimeService.shared
    private let localStorage = LocalStorageManager.shared
    
    @Published var isSyncing = false
    @Published var syncError: String?
    
    private init() {}
    
    // MARK: - Profile Sync Logic
    
    /// Sync profile to Firebase if remote profile exists
    func syncProfileIfNeeded() async {
        guard localStorage.hasRemoteProfile else {
            Logger.d("🌐 No remote profile - skipping sync")
            return
        }
        
        await MainActor.run { self.isSyncing = true }
        
        do {
            // Use FirebaseRealtimeService helper method
            let profile = localStorage.getLocalProfile()
            await firebaseService.syncProfileIfNeeded(profile)
            
            await MainActor.run { 
                self.isSyncing = false
                self.syncError = nil
            }
        } catch {
            Logger.e("❌ Failed to sync profile: \(error)")
            await MainActor.run { 
                self.isSyncing = false
                self.syncError = error.localizedDescription
            }
        }
    }
    
    /// Create remote profile and sync local data
    /// Only creates remote profile if it doesn't exist, otherwise syncs existing profile
    func createRemoteProfileAndSync() async throws {
        let localProfile = localStorage.getLocalProfile()
        let profileID = localProfile.profileID
        
        await MainActor.run { self.isSyncing = true }
        
        do {
            // Check if profile already exists on remote
            let exists = try await firebaseService.checkProfileExistsOnServer(profileID: profileID)
            
            if exists {
                // Profile already exists - sync instead of creating
                Logger.d("🌐 Remote profile already exists for ID: \(profileID) - syncing...")
                try await firebaseService.updateProfile(localProfile)
                localStorage.setHasRemoteProfile(true)
                Logger.d("✅ Remote profile synced successfully")
            } else {
                // Profile doesn't exist - create new one
                Logger.d("🌐 Creating new remote profile for ID: \(profileID)")
                try await firebaseService.createProfile(localProfile)
                localStorage.setHasRemoteProfile(true)
                Logger.d("✅ Remote profile created and synced")
            }
            
            await MainActor.run { 
                self.isSyncing = false
                self.syncError = nil
            }
        } catch {
            Logger.e("❌ Failed to create/sync remote profile: \(error)")
            await MainActor.run { 
                self.isSyncing = false
                self.syncError = error.localizedDescription
            }
            throw error
        }
    }
    
    /// Load profile on app startup với logic chính xác
    func loadProfileOnStartup() async -> UserProfile {
        do {
            // Get profile ID
            let profileID = try await localStorage.getOrCreateProfileID()
            Logger.d("loading profile: \(profileID)")
            // Check if profile exists on server
            let hasRemoteProfile = try await firebaseService.hasProfileOnServer(profileID: profileID)
            
            if hasRemoteProfile {
                // Load from server
                let profile = try await firebaseService.getProfileFromServer(profileID: profileID)
                localStorage.saveLocalProfile(profile)
                localStorage.setHasRemoteProfile(true)
                Logger.d("✅ Profile loaded from Firebase on startup")
                return profile
            } else {
                // No remote profile - use existing local profile
                let localProfile = localStorage.getLocalProfile()
                Logger.d("📱 Using existing local profile on startup")
                return localProfile
            }
        } catch {
            // Error case - fallback to local
            Logger.e("❌ Error loading profile on startup: \(error)")
            
            let localProfile = localStorage.getLocalProfile()
            Logger.d("📱 Using local profile as fallback")
            return localProfile
        }
    }
    
    //
    func syncProfileToRemote() async throws {
        Logger.d("Syncing profile to remote")
        if !localStorage.hasRemoteProfile {
            // Create remote profile on first purchase
            Logger.d("Creating remote profile on first purchase")
            try await createRemoteProfileAndSync()
        } else {
            // Just sync existing profile
            Logger.d("Syncing existing remote profile")
            await syncProfileIfNeeded()
        }
    }
}

// MARK: - Error Types

enum ProfileSyncError: Error, LocalizedError {
    case noLocalProfile
    case syncFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .noLocalProfile:
            return "No local profile found"
        case .syncFailed(let message):
            return "Sync failed: \(message)"
        }
    }
}
