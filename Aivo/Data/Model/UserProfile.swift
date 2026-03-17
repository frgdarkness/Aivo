import Foundation

struct UserProfile: Codable {
    let profileID: String
    var currentCredits: Int
    var totalCredits: Int
    var userName: String
    var avatarUrl: String
    var subscriptionPlan: SubscriptionInfo.SubscriptionPeriod?
    var subscriptionStartDate: Date?
    var subscriptionExpiredDate: Date?
    var lastBonusTime: Date?
    var weeklyRewardTag: String?
    
    init(
        profileID: String,
        currentCredits: Int = 0,
        totalCredits: Int = 0,
        userName: String = "Your name",
        avatarUrl: String = "",
        subscriptionPlan: SubscriptionInfo.SubscriptionPeriod? = nil,
        subscriptionStartDate: Date? = nil,
        subscriptionExpiredDate: Date? = nil,
        lastBonusTime: Date? = nil,
        weeklyRewardTag: String? = nil
    ) {
        self.profileID = profileID
        self.currentCredits = currentCredits
        self.totalCredits = totalCredits
        self.userName = userName
        self.avatarUrl = avatarUrl
        self.subscriptionPlan = subscriptionPlan
        self.subscriptionStartDate = subscriptionStartDate
        self.subscriptionExpiredDate = subscriptionExpiredDate
        self.lastBonusTime = lastBonusTime
        self.weeklyRewardTag = weeklyRewardTag
    }
    
    enum CodingKeys: String, CodingKey {
        case profileID
        case currentCredits
        case totalCredits
        case userName
        case avatarUrl
        case subscriptionPlan
        case subscriptionStartDate
        case subscriptionExpiredDate
        case lastBonusTime
        case weeklyRewardTag
        case avatarImageName // For backward compatibility with RTDB/Old Local Storage
        case lastUpdated // For backward compatibility
        case createdAt // For backward compatibility
    }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        profileID = try c.decode(String.self, forKey: .profileID)
        currentCredits = try c.decode(Int.self, forKey: .currentCredits)
        totalCredits = try c.decode(Int.self, forKey: .totalCredits)
        userName = try c.decodeIfPresent(String.self, forKey: .userName) ?? "Your name"
        
        // Handle avatar naming change
        if let url = try? c.decodeIfPresent(String.self, forKey: .avatarUrl) {
            avatarUrl = url
        } else if let oldName = try? c.decodeIfPresent(String.self, forKey: .avatarImageName) {
            avatarUrl = oldName
        } else {
            avatarUrl = ""
        }
        
        // Decode subscription fields (optional for backward compatibility)
        if let planString = try? c.decodeIfPresent(String.self, forKey: .subscriptionPlan),
           let plan = SubscriptionInfo.SubscriptionPeriod(rawValue: planString) {
            subscriptionPlan = plan
        } else {
            subscriptionPlan = nil
        }
        
        if let startTS = try? c.decodeIfPresent(Double.self, forKey: .subscriptionStartDate) {
            subscriptionStartDate = Date(timeIntervalSince1970: startTS)
        } else {
            subscriptionStartDate = nil
        }
        
        if let expiredTS = try? c.decodeIfPresent(Double.self, forKey: .subscriptionExpiredDate) {
            subscriptionExpiredDate = Date(timeIntervalSince1970: expiredTS)
        } else {
            subscriptionExpiredDate = nil
        }
        
        if let bonusTS = try? c.decodeIfPresent(Double.self, forKey: .lastBonusTime) {
            lastBonusTime = Date(timeIntervalSince1970: bonusTS)
        } else {
            lastBonusTime = nil
        }
        
        weeklyRewardTag = try? c.decodeIfPresent(String.self, forKey: .weeklyRewardTag)
    }
    
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(profileID, forKey: .profileID)
        try c.encode(currentCredits, forKey: .currentCredits)
        try c.encode(totalCredits, forKey: .totalCredits)
        try c.encode(userName, forKey: .userName)
        try c.encode(avatarUrl, forKey: .avatarUrl)
        try c.encodeIfPresent(subscriptionPlan?.rawValue, forKey: .subscriptionPlan)
        try c.encodeIfPresent(subscriptionStartDate?.timeIntervalSince1970, forKey: .subscriptionStartDate)
        try c.encodeIfPresent(subscriptionExpiredDate?.timeIntervalSince1970, forKey: .subscriptionExpiredDate)
        try c.encodeIfPresent(lastBonusTime?.timeIntervalSince1970, forKey: .lastBonusTime)
        try c.encodeIfPresent(weeklyRewardTag, forKey: .weeklyRewardTag)
    }
    
    mutating func addCredits(_ amount: Int) {
        currentCredits += amount
        totalCredits += amount
    }
    
    mutating func setCredits(_ newBalance: Int) {
        let delta = max(0, newBalance - currentCredits)
        currentCredits = newBalance
        totalCredits += delta
    }
    
    mutating func consumeCredits(amount: Int) {
        currentCredits = max(0, currentCredits - amount)
    }
    
    mutating func updateUserName(_ newName: String) {
        self.userName = newName
    }
    
    mutating func updateAvatarUrl(_ newAvatarUrl: String) {
        self.avatarUrl = newAvatarUrl
    }
}
