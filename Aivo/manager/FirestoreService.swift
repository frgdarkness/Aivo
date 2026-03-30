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
    private let leaderboardsCollection = "leaderboards" // Collection for weekly leaderboards
    
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
            
            // 3. Update user profile (setData with merge:true handles non-premium users without docs)
            let userDocRef = self.db.collection(self.usersCollection).document(profileID)
            transaction.setData(["userName": newUsername], forDocument: userDocRef, merge: true)
            
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
            }
        }
    }
    
    /// Fetch hottest songs of the week
    func fetchHottestSongs(weekTag: String? = nil, limit: Int = 10) async throws -> [SunoData] {
        ensureFirebaseConfigured()
        let targetWeek = weekTag ?? DateUtils.getCurrentWeekTag()
        Logger.d("🔥 Firestore: Fetching hottest songs for \(targetWeek)")
        
        // 1. Try to fetch songs for the current week specifically
        let query = db.collection(songsCollection)
            .whereField("isPublic", isEqualTo: true)
            .whereField("weekTag", isEqualTo: targetWeek)
            .order(by: "playCount", descending: true)
            .limit(to: limit)
            
        let snapshot = try await query.getDocuments()
        var results = snapshot.documents.compactMap { try? mapToSunoData(data: $0.data()) }
        
        // 2. If no songs found for the requested week (and it is the current week), 
        // fallback to the latest available ranking from the leaderboards collection.
        if results.isEmpty && weekTag == nil {
            Logger.d("🔥 Firestore: No hottest songs for current week, falling back to leaderboard history")
            if let history = try? await fetchWeeklyBoardHistory(),
               let latest = history.first,
               let board = try? mapToWeeklyBoard(data: latest) {
                results = board.songs
                Logger.d("🔥 Firestore: Loaded \(results.count) songs from latest board: \(board.id)")
            }
        }
        
        Logger.d("🔥 Firestore: Hottest results: \(results.count) songs")
        return results
    }
    
    /// Map a dictionary to a WeeklyBoard object
    func mapToWeeklyBoard(data: [String: Any]) throws -> WeeklyBoard {
        let jsonData = try JSONSerialization.data(withJSONObject: data)
        return try JSONDecoder().decode(WeeklyBoard.self, from: jsonData)
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
    
    // MARK: - Weekly Leaderboards
    
    /// Fetch history of weekly boards
    func fetchWeeklyBoardHistory() async throws -> [[String: Any]] {
        ensureFirebaseConfigured()
        Logger.d("🔥 Firestore: Fetching weekly board history")
        
        let query = db.collection(leaderboardsCollection)
            .order(by: "timestamp", descending: true)
            .limit(to: 12) // Only fetch 12 most recent weeks
        
        let snapshot = try await query.getDocuments()
        return snapshot.documents.map { doc in
            var data = doc.data()
            data["id"] = doc.documentID
            // Recursively convert Timestamps to Double (TimeInterval)
            return convertTimestamps(data)
        }
    }
    
    /// Fetch a specific weekly board by week tag
    func fetchWeeklyBoard(weekTag: String) async throws -> [String: Any]? {
        ensureFirebaseConfigured()
        Logger.d("🔥 Firestore: Fetching weekly board for \(weekTag)")
        
        let doc = try await db.collection(leaderboardsCollection).document(weekTag).getDocument()
        guard doc.exists, var data = doc.data() else {
            Logger.d("🔥 Firestore: No leaderboard found for \(weekTag)")
            return nil
        }
        data["id"] = doc.documentID
        return convertTimestamps(data)
    }
    
    /// Fetch the latest available weekly board songs
    func fetchLatestWeeklyBoard() async throws -> [SunoData] {
        Logger.d("🔥 Firestore: Fetching latest weekly board songs")
        let history = try await fetchWeeklyBoardHistory()
        guard let latest = history.first else { return [] }
        let board = try mapToWeeklyBoard(data: latest)
        return board.songs
    }
    
    /// Recursively convert Firestore Timestamps to Int64 for JSON compatibility
    private func convertTimestamps(_ data: [String: Any]) -> [String: Any] {
        var result = data
        for (key, value) in result {
            if let timestamp = value as? Timestamp {
                result[key] = Int64(timestamp.dateValue().timeIntervalSince1970)
            } else if let dict = value as? [String: Any] {
                result[key] = convertTimestamps(dict)
            } else if let array = value as? [[String: Any]] {
                result[key] = array.map { convertTimestamps($0) }
            }
        }
        return result
    }
    
    
    private let bonusHistoryCollection = "bonus_history"
    
    // MARK: - Purchase & Bonus History
    
    /// Log a bonus credit grant to the user's bonus_history sub-collection
    func logBonusCredit(profileID: String, amount: Int, reason: String, previousBalance: Int? = nil, afterBalance: Int? = nil) async {
        ensureFirebaseConfigured()
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyMMdd"
        let dateString = dateFormatter.string(from: Date())
        
        // Format check: if reason is "Buy", use yyMMdd__BuyXXXXCredit
        // Otherwise use yyMMdd__xxxxCredit__reason
        let docID: String
        if reason == "Buy" {
            docID = "\(dateString)__Buy\(amount)Credit"
        } else {
            docID = "\(dateString)__\(amount)Credit__\(reason)"
        }
        Logger.d("🔥 Firestore: Logging bonus credit \(docID) for user \(profileID)")
        
        let bonusRef = db.collection(usersCollection)
            .document(profileID)
            .collection(bonusHistoryCollection)
            .document(docID)
            
        var data: [String: Any] = [
            "amount": Int64(amount),
            "reason": reason,
            "timestamp": FieldValue.serverTimestamp(),
            "date": dateString
        ]
        
        if let previous = previousBalance {
            data["previousBalance"] = Int64(previous)
        }
        if let after = afterBalance {
            data["afterBalance"] = Int64(after)
        }
        
        do {
            try await bonusRef.setData(data)
            Logger.d("✅ Firestore: Bonus credit logged successfully at \(bonusRef.path)")
        } catch {
            Logger.e("❌ Firestore: Failed to log bonus credit: \(error)")
        }
    }
    
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
