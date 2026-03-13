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
    private let songsCollection = "shared_songs"   // Collection for community shared songs
    
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
    
    // MARK: - Community Song Sharing
    
    /// Save a song to Firestore (either private or shared)
    func saveSongToFirestore(_ song: SunoData, isPublic: Bool = false) async throws {
        ensureFirebaseConfigured()
        Logger.d("🔥 Firestore: Saving song \(song.id) to Firestore (isPublic: \(isPublic))")
        
        var songToSave = song
        
        // Ensure profileID is set if possible
        if songToSave.profileID == nil {
            if let profileID = currentProfile?.profileID {
                songToSave.profileID = profileID
            } else {
                songToSave.profileID = try? await LocalStorageManager.shared.getOrCreateProfileID()
            }
        }
        
        // Ensure weekTag is set
        if songToSave.weekTag == nil {
            songToSave.weekTag = DateUtils.getCurrentWeekTag()
        }
        
        // Set public status if explicitly provided or keep existing
        if isPublic {
            songToSave.isPublic = true
        } else if songToSave.isPublic == nil {
            songToSave.isPublic = false
        }
        
        // Initialize other fields if missing
        if songToSave.playCount == nil { songToSave.playCount = 0 }
        if songToSave.likeCount == nil { songToSave.likeCount = 0 }
        
        let songRef = db.collection(songsCollection).document(songToSave.id)
        let data = try mapFromSunoData(songToSave)
        
        try await songRef.setData(data, merge: true)
        Logger.d("✅ Firestore: Song saved successfully")
    }
    
    /// Share a song to the community
    func shareSongToCommunity(_ song: SunoData) async throws {
        try await saveSongToFirestore(song, isPublic: true)
    }
    
    /// Increment play count for a song
    func incrementPlayCount(songID: String) {
        ensureFirebaseConfigured()
        let songRef = db.collection(songsCollection).document(songID)
        songRef.updateData([
            "playCount": FieldValue.increment(Int64(1))
        ]) { error in
            if let error = error as NSError?, error.domain == FirestoreErrorDomain, error.code == 5 {
                // Silently ignore - song is not in Firestore (likely private/intro song)
                return
            }
            if let error = error {
                Logger.e("❌ Firestore: Failed to increment playCount for \(songID): \(error)")
            } else {
                Logger.d("✅ Firestore: playCount incremented for \(songID)")
            }
        }
    }
    
    /// Fetch hottest songs of the week
    func fetchHottestSongs(weekTag: String? = nil, limit: Int = 10) async throws -> [SunoData] {
        ensureFirebaseConfigured()
        let targetWeek = weekTag ?? DateUtils.getCurrentWeekTag()
        Logger.d("🔥 Firestore: Fetching hottest songs for \(targetWeek)")
        
        let query = db.collection(songsCollection)
            .whereField("isPublic", isEqualTo: true)
            .whereField("weekTag", isEqualTo: targetWeek)
            .order(by: "playCount", descending: true)
            .limit(to: limit)
            
        let snapshot = try await query.getDocuments()
        Logger.d("🔥 Firestore: Hottest query returned \(snapshot.documents.count) docs")
        
        // Debug check
        let allDocsS = try? await db.collection(songsCollection).limit(to: 5).getDocuments()
        if let docs = allDocsS?.documents {
            Logger.d("🔥 Firestore: Found \(docs.count) sample docs in total")
            for doc in docs {
                let d = doc.data()
                Logger.d("📝 Sample Song \(doc.documentID): isPublic=\(d["isPublic"] ?? "nil"), weekTag=\(d["weekTag"] ?? "nil")")
            }
        }

        return snapshot.documents.compactMap { try? mapToSunoData(data: $0.data()) }
    }
    
    /// Fetch newest shared songs
    func fetchNewSongs(limit: Int = 10) async throws -> [SunoData] {
        ensureFirebaseConfigured()
        Logger.d("🔥 Firestore: Fetching newest community songs")
        
        let query = db.collection(songsCollection)
            .whereField("isPublic", isEqualTo: true)
            .order(by: "createTime", descending: true)
            .limit(to: limit)
            
        let snapshot = try await query.getDocuments()
        Logger.d("🔥 Firestore: Newest query returned \(snapshot.documents.count) docs")
        return snapshot.documents.compactMap { try? mapToSunoData(data: $0.data()) }
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
    
    // SunoData Mapping
    private func mapToSunoData(data: [String: Any]) throws -> SunoData {
        let jsonData = try JSONSerialization.data(withJSONObject: data)
        return try JSONDecoder().decode(SunoData.self, from: jsonData)
    }
    
    private func mapFromSunoData(_ song: SunoData) throws -> [String: Any] {
        let data = try JSONEncoder().encode(song)
        return try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
    }
}
