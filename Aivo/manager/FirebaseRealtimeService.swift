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
    private func userSubscriptionsRoot(_ profileID: String) -> String { "\(userRoot(profileID))/subscriptions" }
    private func subscriptionPath(_ profileID: String, _ subscriptionID: String) -> String { "\(userSubscriptionsRoot(profileID))/\(subscriptionID)" }

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
            dbRef.child(path).observeSingleEvent(of: .value, with: { snap in
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
            }, withCancel: { error in
                Logger.e("❌ Firebase error getting profile: \(error.localizedDescription)")
                cont.resume(throwing: error)
            })
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
    

    /// Increment daily counter for a package (thread-safe) - Kept for legacy analytics if needed, or can be removed if moved to Firestore
    func incrementDailyCounter(packageId: String) async throws {
        ensureFirebaseConfigured()
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "ddMMyyyy"
        let dateKey = dateFormatter.string(from: Date())
        
        // Sanitize packageId to be safe for Firebase path (replace . with _)
        let safePackageId = packageId.replacingOccurrences(of: ".", with: "_")
        
        let path = dailyAnalyticsPath(dateKey)
        let counterPath = "\(path)/\(safePackageId)"
        
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            dbRef.child(counterPath).runTransactionBlock({ currentData in
                var value = currentData.value as? Int ?? 0
                value += 1
                currentData.value = value
                return .success(withValue: currentData)
            }) { error, committed, snapshot in
                if let error = error {
                    Logger.e("❌ [Firebase] Increment counter error: \(error.localizedDescription)")
                    cont.resume(throwing: error)
                } else {
                    Logger.d("✅ [Firebase] Incremented \(safePackageId) for \(dateKey): \(snapshot?.value ?? 0)")
                    cont.resume(returning: ())
                }
            }
        }
    }
    // MARK: - Song Generation Logging
    
    private func songLogsRoot(_ date: String) -> String {
        "\(basePath)/songs/\(date)"
    }
    
    private func songLogPath(_ date: String, _ uuid: String) -> String {
        "\(songLogsRoot(date))/\(uuid)"
    }
    
    /// Log generated song data to Firebase (raw JSON string)
    func logGeneratedSong(jsonString: String) async throws {
        ensureFirebaseConfigured()
        
        // Date format: yyyy-MM-dd for folder structure
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateKey = dateFormatter.string(from: Date())
        
        // Use a random UUID for the log entry
        let uuid = UUID().uuidString
        let path = songLogPath(dateKey, uuid)
        
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            dbRef.child(path).setValue(jsonString) { error, _ in
                if let error = error {
                    Logger.e("❌ [Firebase] Log song error: \(error.localizedDescription)")
                    cont.resume(throwing: error)
                } else {
                    Logger.d("✅ [Firebase] Logged generated song to \(path)")
                    cont.resume(returning: ())
                }
            }
        }
    }
    
    // MARK: - User Report Logging
    
    /// Log user feedback/report to Firebase
    /// Path: decoraIOS/userReport/{userID}
    /// Value: "reason1, reason2, Other: details"
    func logUserReport(userId: String, reason: String) async throws {
        ensureFirebaseConfigured()
        
        let path = "\(basePath)/userReport/\(userId)"
        
        // Use push() or child(UUID) if we want multiple reports per user. 
        // User requested: "id-user":"lý do". This implies a direct mapping.
        // However, if a user reports multiple times, direct mapping overwrites. 
        // I will use append/push semantic or just set value as requested.
        // User said: "khi user report thì sẽ hiện mỗi dòng là "id-user":"lý do"". 
        // This likely means key=userId, value=reason.
        
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            dbRef.child(path).setValue(reason) { error, _ in
                if let error = error {
                    Logger.e("❌ [Firebase] Log report error: \(error.localizedDescription)")
                    cont.resume(throwing: error)
                } else {
                    Logger.d("✅ [Firebase] Logged user report to \(path)")
                    cont.resume(returning: ())
                }
            }
        }
    }
}
