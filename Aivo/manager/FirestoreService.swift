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
    private let usernamesCollection = "usernames" // Collection for unique usernames
    
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
    
    // MARK: - Username Uniqueness
    
    /// Checks if a username is available (case-insensitive check using lowercase IDs)
    func checkUsernameAvailability(username: String) async throws -> Bool {
        ensureFirebaseConfigured()
        let normalizedName = username.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if normalizedName.isEmpty { return false }
        
        let docRef = db.collection(usernamesCollection).document(normalizedName)
        let snapshot = try await docRef.getDocument()
        return !snapshot.exists
    }
    
    /// Atomically updates a username (claims new, releases old)
    func updateUsername(profileID: String, newUsername: String, oldUsername: String?) async throws {
        ensureFirebaseConfigured()
        let normalizedNew = newUsername.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedOld = oldUsername?.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // If name hasn't changed, do nothing
        if normalizedNew == normalizedOld { return }
        
        Logger.d("🔥 Firestore: Updating username from '\(oldUsername ?? "nil")' to '\(newUsername)'")
        
        try await db.runTransaction({ (transaction, errorPointer) -> Any? in
            let newDocRef = self.db.collection(self.usernamesCollection).document(normalizedNew)
            
            // 1. Check if new name is taken
            let newDoc: DocumentSnapshot
            do {
                newDoc = try transaction.getDocument(newDocRef)
            } catch let error as NSError {
                errorPointer?.pointee = error
                return nil
            }
            
            if newDoc.exists {
                let error = NSError(domain: "FirestoreService", code: 409, userInfo: [NSLocalizedDescriptionKey: "Username is already taken"])
                errorPointer?.pointee = error
                return nil
            }
            
            // 2. Claim new username
            transaction.setData(["profileID": profileID], forDocument: newDocRef)
            
            // 3. Update user profile
            let userDocRef = self.db.collection(self.usersCollection).document(profileID)
            transaction.updateData(["userName": newUsername], forDocument: userDocRef)
            
            // 4. Release old username
            if let old = normalizedOld, !old.isEmpty {
                let oldDocRef = self.db.collection(self.usernamesCollection).document(old)
                transaction.deleteDocument(oldDocRef)
            }
            
            return nil
        })
        
        Logger.d("✅ Firestore: Username updated successfully")
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
