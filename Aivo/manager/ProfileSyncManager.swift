import Foundation
import FirebaseCore
import FirebaseDatabase

final class ProfileSyncManager: ObservableObject {
    static let shared = ProfileSyncManager()
    
    private let firebaseService = FirebaseRealtimeService.shared
    private let firestoreService = FirestoreService.shared
    private let localStorage = LocalStorageManager.shared
    
    @Published var isSyncing = false
    @Published var syncError: String?
    
    private init() {}
    
    // MARK: - Profile Sync Logic
    
    /// Sync profile to Firestore if remote profile exists
    func syncProfileIfNeeded() async {
        guard localStorage.hasRemoteProfile else {
            Logger.d("🌐 No remote profile - skipping sync")
            return
        }
        
        await MainActor.run { self.isSyncing = true }
        
        do {
            let profile = localStorage.getLocalProfile()
            try await firestoreService.saveProfile(profile)
            
            await MainActor.run { 
                self.isSyncing = false
                self.syncError = nil
            }
        } catch {
            Logger.e("❌ Failed to sync profile to Firestore: \(error)")
            await MainActor.run { 
                self.isSyncing = false
                self.syncError = error.localizedDescription
            }
        }
    }
    
    /// Create remote profile and sync local data to Firestore
    func createRemoteProfileAndSync() async throws {
        let localProfile = localStorage.getLocalProfile()
        let profileID = localProfile.profileID
        
        await MainActor.run { self.isSyncing = true }
        
        do {
            // Check if profile already exists on Firestore
            let exists = try await firestoreService.fetchProfile(profileID: profileID) != nil
            
            if exists {
                Logger.d("🌐 Firestore profile already exists for ID: \(profileID) - updating...")
            } else {
                Logger.d("🌐 Creating new Firestore profile for ID: \(profileID)")
            }
            
            try await firestoreService.saveProfile(localProfile)
            localStorage.setHasRemoteProfile(true)
            Logger.d("✅ Firestore profile synced successfully")
            
            await MainActor.run { 
                self.isSyncing = false
                self.syncError = nil
            }
        } catch {
            Logger.e("❌ Failed to create/sync Firestore profile: \(error)")
            await MainActor.run { 
                self.isSyncing = false
                self.syncError = error.localizedDescription
            }
            throw error
        }
    }
    
    /// Load profile on app startup with logic for Firestore and migration
    func loadProfileOnStartup() async -> UserProfile {
        do {
            // Get profile ID
            let profileID = try await localStorage.getOrCreateProfileID()
            Logger.d("🌐 Loading profile via Firestore: \(profileID)")
            
            // 1. Try Firestore first
            if let firestoreProfile = try await firestoreService.fetchProfile(profileID: profileID) {
                localStorage.saveLocalProfile(firestoreProfile)
                localStorage.setHasRemoteProfile(true)
                Logger.d("✅ Profile loaded from Firestore on startup")
                return firestoreProfile
            }
            
            // 2. If not in Firestore, check Realtime Database (Migration Case)
            Logger.d("🔄 Profile not in Firestore, checking RTDB for migration...")
            let hasRTDBProfile = try await firebaseService.hasProfileOnServer(profileID: profileID)
            
            if hasRTDBProfile {
                let rtdbProfile = try await firebaseService.getProfileFromServer(profileID: profileID)
                
                // Lazy Migration: Save profile to Firestore
                Logger.d("🚀 Migrating profile from RTDB to Firestore...")
                try await firestoreService.saveProfile(rtdbProfile)
                
                // Migrate Purchase History
                Task {
                    do {
                        let purchases = try await firebaseService.getAllPurchases(profileID: profileID)
                        Logger.d("📦 Found \(purchases.count) purchases to migrate")
                        for purchase in purchases {
                            try? await firestoreService.logPurchase(profileID: profileID, purchase: purchase)
                        }
                        Logger.d("✅ Purchase history migration completed")
                    } catch {
                        Logger.e("❌ Failed to migrate purchase history: \(error)")
                    }
                }
                
                localStorage.saveLocalProfile(rtdbProfile)
                localStorage.setHasRemoteProfile(true)
                Logger.d("✅ Profile migrated and loaded from RTDB -> Firestore")
                return rtdbProfile
            } else {
                // 3. No remote profile found - use existing local profile
                let localProfile = localStorage.getLocalProfile()
                Logger.d("📱 Using existing local profile on startup (no remote found)")
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
            // Create remote profile
            Logger.d("🚀 Creating new profile on Firestore")
            let localProfile = localStorage.getLocalProfile()
            try await firestoreService.saveProfile(localProfile)
            localStorage.setHasRemoteProfile(true)
        } else {
            // Just sync existing profile to Firestore
            Logger.d("🔄 Syncing existing profile to Firestore")
            let localProfile = localStorage.getLocalProfile()
            try await firestoreService.saveProfile(localProfile)
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
