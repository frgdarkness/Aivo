import Foundation
import FirebaseCore
import FirebaseAnalytics
import FirebaseDatabase
import UIKit

final class FirebaseRealtimeService: ObservableObject {
    static let shared = FirebaseRealtimeService()

    // Gốc dữ liệu
    private let basePath = "decoraIOS"

    // ✅ Không khởi tạo Database sớm
    private var dbRef: DatabaseReference {
        Database.database().reference()
    }

    @Published var currentProfile: UserProfile?
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Listeners
    private var profileHandle: DatabaseHandle?
    private var profileRef: DatabaseReference?

    private init() {
        Logger.d("🔥 FirebaseRealtimeService initialized (safe)")
    }

    // MARK: - Path helpers
    private func userRoot(_ profileID: String) -> String { "\(basePath)/users/\(profileID)" }
    private func userProfilePath(_ profileID: String) -> String { "\(userRoot(profileID))/profile" }
    private func userPurchasesRoot(_ profileID: String) -> String { "\(userRoot(profileID))/purchases" }
    private func purchasePath(_ profileID: String, _ purchaseID: String) -> String { "\(userPurchasesRoot(profileID))/\(purchaseID)" }

    // MARK: - Ensure Firebase Configured
    private func ensureFirebaseConfigured() {
        if FirebaseApp.app() == nil {
            Logger.d("⚠️ Firebase not configured — configuring now...")
            FirebaseApp.configure()
        }
    }


    // MARK: - Public API

    /// Lấy profile từ server (không tạo mới)
    func getProfileFromServer(profileID: String) async throws -> UserProfile {
        ensureFirebaseConfigured()
        
        let profile = try await getProfile(profileID: profileID)
        await MainActor.run { self.currentProfile = profile }
        return profile
    }
    
    /// Check if profile exists on server
    func hasProfileOnServer(profileID: String) async throws -> Bool {
        return try await checkProfileExistsOnServer(profileID: profileID)
    }
    

    /// Đọc profile thực từ DB
    func getProfile(profileID: String) async throws -> UserProfile {
        ensureFirebaseConfigured()

        let path = userProfilePath(profileID)
        return try await withCheckedThrowingContinuation { (cont: CheckedContinuation<UserProfile, Error>) in
            dbRef.child(path).observeSingleEvent(of: .value) { snap in
                guard let value = snap.value else {
                    cont.resume(throwing: FirebaseError.profileNotFound)
                    return
                }
                Logger.d("getProfile from RealtimeDatabase -> value = \(value)")
                // ✅ Kiểm tra kiểu dữ liệu từ Firebase
                guard let dict = value as? [String: Any] else {
                    cont.resume(throwing: FirebaseError.invalidData)
                    return
                }

                do {
                    let data = try JSONSerialization.data(withJSONObject: dict, options: [])
                    let profile = try JSONDecoder().decode(UserProfile.self, from: data)
                    cont.resume(returning: profile)
                } catch {
                    cont.resume(throwing: FirebaseError.invalidData)
                }
            }
        }
    }

    /// Tạo profile
    func createProfile(_ profile: UserProfile) async throws {
        ensureFirebaseConfigured()

        let path = userProfilePath(profile.profileID)
        let enc = JSONEncoder(); enc.dateEncodingStrategy = .secondsSince1970
        let data = try enc.encode(profile)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            dbRef.child(path).setValue(json) { err, _ in
                if let err = err { cont.resume(throwing: err) }
                else {
                    Logger.d("✅ Profile created on RealtimeDatabase: \(profile.profileID)")
                    cont.resume(returning: ())
                }
            }
        }
    }
    

    /// Update profile with server check
    func updateProfileWithCheck(_ profile: UserProfile) async throws {
        ensureFirebaseConfigured()
        
        let exists = try await checkProfileExistsOnServer(profileID: profile.profileID)
        
        if exists {
            // Update existing profile
            try await updateProfile(profile)
        } else {
            // Create new profile
            try await createProfile(profile)
        }
    }

    /// Cập nhật profile
    func updateProfile(_ profile: UserProfile) async throws {
        ensureFirebaseConfigured()

        var updated = profile
        updated.lastUpdated = Date()
        let path = userProfilePath(profile.profileID)
        let enc = JSONEncoder()
        enc.dateEncodingStrategy = .secondsSince1970
        let data = try enc.encode(updated)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            // 📍 Bước 1: Kiểm tra xem profile có tồn tại trên Firebase chưa
            dbRef.child(path).observeSingleEvent(of: .value) { snapshot in
                if snapshot.exists() {
                    // ✅ Nếu tồn tại -> update
                    self.dbRef.child(path).updateChildValues(json) { err, _ in
                        if let err = err {
                            cont.resume(throwing: err)
                        } else {
                            Task { @MainActor in self.currentProfile = updated }
                            Logger.d("✅ Profile updated: \(profile.profileID)")
                            cont.resume(returning: ())
                        }
                    }
                } else {
                    // 🆕 Nếu chưa tồn tại -> tạo mới
                    self.dbRef.child(path).setValue(json) { err, _ in
                        if let err = err {
                            cont.resume(throwing: err)
                        } else {
                            Task { @MainActor in self.currentProfile = updated }
                            Logger.d("✅ Profile created (auto from update): \(profile.profileID)")
                            cont.resume(returning: ())
                        }
                    }
                }
            }
        }
    }

    /// Lưu purchase
    func savePurchase(_ purchase: PurchaseConsumable) async throws {
        ensureFirebaseConfigured()

        let path = purchasePath(purchase.profileID, purchase.purchaseID)
        let enc = JSONEncoder(); enc.dateEncodingStrategy = .secondsSince1970
        let data = try enc.encode(purchase)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            dbRef.child(path).setValue(json) { err, _ in
                if let err = err { cont.resume(throwing: err) }
                else {
                    Logger.d("✅ Purchase saved: \(purchase.purchaseID)")
                    cont.resume(returning: ())
                }
            }
        }
    }
    
    func checkProfileExistsOnServer(profileID: String) async throws -> Bool {
        ensureFirebaseConfigured()

        let path = userProfilePath(profileID)

        return try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Bool, Error>) in
            dbRef.child(path).observeSingleEvent(of: .value) { snapshot in
                if snapshot.exists() {
                    Logger.d("✅ Profile exists: \(profileID)")
                    cont.resume(returning: true)
                } else {
                    Logger.d("❌ Profile does not exist: \(profileID)")
                    cont.resume(returning: false)
                }
            }
        }
    }

    /// Lấy tất cả purchase của profile
    func getPurchases(profileID: String) async throws -> [PurchaseConsumable] {
        ensureFirebaseConfigured()

        let root = userPurchasesRoot(profileID)
        return try await withCheckedThrowingContinuation { cont in
            dbRef.child(root).observeSingleEvent(of: .value) { snap in
                guard let map = snap.value as? [String: Any] else {
                    cont.resume(returning: []); return
                }
                do {
                    let data = try JSONSerialization.data(withJSONObject: map)
                    let dict = try JSONDecoder().decode([String: PurchaseConsumable].self, from: data)
                    cont.resume(returning: Array(dict.values))
                } catch {
                    cont.resume(throwing: FirebaseError.invalidData)
                }
            }
        }
    }

    /// Lấy 1 purchase cụ thể
    func getPurchase(profileID: String, purchaseID: String) async throws -> PurchaseConsumable {
        ensureFirebaseConfigured()

        let path = purchasePath(profileID, purchaseID)
        return try await withCheckedThrowingContinuation { cont in
            dbRef.child(path).observeSingleEvent(of: .value) { snap in
                guard let value = snap.value else {
                    cont.resume(throwing: FirebaseError.purchaseNotFound); return
                }
                do {
                    let data = try JSONSerialization.data(withJSONObject: value)
                    let purchase = try JSONDecoder().decode(PurchaseConsumable.self, from: data)
                    cont.resume(returning: purchase)
                } catch {
                    cont.resume(throwing: FirebaseError.invalidData)
                }
            }
        }
    }


    // MARK: - Realtime listeners

    func startListeningToProfile(profileID: String) {
        ensureFirebaseConfigured()

        stopListening()
        let path = userProfilePath(profileID)
        let ref = dbRef.child(path)
        profileRef = ref
        profileHandle = ref.observe(.value) { [weak self] snap in
            guard let self = self, let value = snap.value else { return }
            do {
                let data = try JSONSerialization.data(withJSONObject: value)
                let profile = try JSONDecoder().decode(UserProfile.self, from: data)
                Task { @MainActor in self.currentProfile = profile }
            } catch {
                Logger.e("❌ Failed to decode profile listen: \(error)")
            }
        }
        Logger.d("🔊 Listening profile \(profileID)")
    }

    func stopListening() {
        if let ref = profileRef, let handle = profileHandle {
            ref.removeObserver(withHandle: handle)
        }
        profileRef = nil
        profileHandle = nil
        Logger.d("🔇 Stop listening")
    }
    
    // MARK: - Local-First Helper Methods
    
    /// Sync profile to server if remote profile exists
    func syncProfileIfNeeded(_ profile: UserProfile) async {
        let localStorage = LocalStorageManager.shared
        
//        guard localStorage.hasRemoteProfile else {
//            Logger.d("🌐 No remote profile - skipping sync")
//            return
//        }
        
        do {
            let exists = try await checkProfileExistsOnServer(profileID: profile.profileID)
            
            if exists {
                try await updateProfile(profile)
                Logger.d("✅ Profile synced to Firebase")
            } else {
                try await createProfile(profile)
                Logger.d("✅ Profile created on Firebase")
            }
        } catch {
            Logger.e("❌ Failed to sync profile: \(error)")
        }
    }
}
