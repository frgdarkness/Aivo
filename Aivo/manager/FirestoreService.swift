import Foundation
import FirebaseCore
import FirebaseFirestore
import FirebaseAnalytics

final class FirestoreService: ObservableObject {
    static let shared = FirestoreService()
    
    private var db: Firestore {
        return Firestore.firestore()
    }
    private let usersCollection = "users"
    private let purchasesCollection = "purchases"
    
    @Published var currentProfile: UserProfile?
    
    private init() {                                                    
        Logger.d("🔥 FirestoreService initialized")
    }
    
    // MARK: - Ensure Firebase Configured
    private func ensureFirebaseConfigured() {
        if FirebaseApp.app() == nil {
            Logger.d("⚠️ Firebase not configured — configuring now...")
            FirebaseApp.configure()
        }
    }
    
    // MARK: - Profile Management
    
    /// Fetch profile from Firestore
    func fetchProfile(profileID: String) async throws -> UserProfile? {
        ensureFirebaseConfigured()
        
        let docRef = db.collection(usersCollection).document(profileID)
        let snapshot = try await docRef.getDocument()
        
        guard snapshot.exists, let data = snapshot.data() else {
            return nil
        }
        
        return try mapToUserProfile(data: data)
    }
    
    /// Save or update profile in Firestore
    func saveProfile(_ profile: UserProfile) async throws {
        ensureFirebaseConfigured()
        Logger.d("🔥 Firestore: Saving profile \(profile.profileID)")
        
        let docRef = db.collection(usersCollection).document(profile.profileID)
        let data = try mapFromUserProfile(profile)
        
        try await docRef.setData(data, merge: true)
        Logger.d("✅ Firestore: Profile saved successfully")
        
        await MainActor.run {
            self.currentProfile = profile
        }
    }
    
    // MARK: - Purchase History
    
    /// Log a purchase to the user's sub-collection
    func logPurchase(profileID: String, purchase: PurchaseConsumable) async throws {
        ensureFirebaseConfigured()
        Logger.d("🔥 Firestore: Logging purchase \(purchase.purchaseID) for user \(profileID)")
        
        let purchaseRef = db.collection(usersCollection)
            .document(profileID)
            .collection(purchasesCollection)
            .document(purchase.purchaseID)
        
        let enc = JSONEncoder()
        enc.dateEncodingStrategy = .secondsSince1970
        let data = try enc.encode(purchase)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        
        try await purchaseRef.setData(json)
        Logger.d("✅ Firestore: Purchase logged successfully at \(purchaseRef.path)")
    }
    
    // MARK: - Helpers (Mapping)
    
    private func mapToUserProfile(data: [String: Any]) throws -> UserProfile {
        let jsonData = try JSONSerialization.data(withJSONObject: data)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        return try decoder.decode(UserProfile.self, from: jsonData)
    }
    
    private func mapFromUserProfile(_ profile: UserProfile) throws -> [String: Any] {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        let data = try encoder.encode(profile)
        return try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
    }
}
