import Foundation

struct UserProfile: Codable {
    let profileID: String
    let createdAt: Date
    var currentCredits: Int
    var totalCredits: Int
    var lastUpdated: Date
    var userName: String
    var avatarImageName: String
    
    init(profileID: String, currentCredits: Int = 0, totalCredits: Int = 0, userName: String = "Your name", avatarImageName: String = "demo_cover") {
        self.profileID = profileID
        self.createdAt = Date()
        self.currentCredits = currentCredits
        self.totalCredits = totalCredits
        self.lastUpdated = Date()
        self.userName = userName
        self.avatarImageName = avatarImageName
    }
    
    enum CodingKeys: String, CodingKey {
        case profileID
        case createdAt
        case currentCredits
        case totalCredits
        case lastUpdated
        case userName
        case avatarImageName
    }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        profileID = try c.decode(String.self, forKey: .profileID)
        currentCredits = try c.decode(Int.self, forKey: .currentCredits)
        totalCredits = try c.decode(Int.self, forKey: .totalCredits)
        let createdTS = try c.decode(Double.self, forKey: .createdAt)
        createdAt = Date(timeIntervalSince1970: createdTS)
        let updatedTS = try c.decode(Double.self, forKey: .lastUpdated)
        lastUpdated = Date(timeIntervalSince1970: updatedTS)
        userName = try c.decodeIfPresent(String.self, forKey: .userName) ?? "Your name"
        avatarImageName = try c.decodeIfPresent(String.self, forKey: .avatarImageName) ?? "demo_cover"
    }
    
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(profileID, forKey: .profileID)
        try c.encode(currentCredits, forKey: .currentCredits)
        try c.encode(totalCredits, forKey: .totalCredits)
        try c.encode(createdAt.timeIntervalSince1970, forKey: .createdAt)
        try c.encode(lastUpdated.timeIntervalSince1970, forKey: .lastUpdated)
        try c.encode(userName, forKey: .userName)
        try c.encode(avatarImageName, forKey: .avatarImageName)
    }
    
    mutating func addCredits(_ amount: Int) {
        currentCredits += amount
        totalCredits += amount
        lastUpdated = Date()
    }
    
    mutating func setCredits(_ newBalance: Int) {
        let delta = max(0, newBalance - currentCredits)
        currentCredits = newBalance
        totalCredits += delta
        lastUpdated = Date()
    }
    
    mutating func consumeCredits(amount: Int) {
        currentCredits = max(0, currentCredits - amount)
        lastUpdated = Date()
    }
    
    mutating func updateUserName(_ newName: String) {
        self.userName = newName
        self.lastUpdated = Date()
    }
    
    mutating func updateAvatarImageName(_ newAvatarName: String) {
        self.avatarImageName = newAvatarName
        self.lastUpdated = Date()
    }
}
