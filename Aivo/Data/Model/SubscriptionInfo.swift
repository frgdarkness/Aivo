import Foundation
import StoreKit
import UIKit

struct SubscriptionInfo: Codable {
    let subscriptionID: String
    let profileID: String
    let productID: String
    let transactionID: String
    let creditsPerPeriod: Int
    let period: SubscriptionPeriod
    let price: String
    let currency: String
    let status: SubscriptionStatus
    let startDate: Date
    let expiryDate: Date?
    let autoRenews: Bool
    let receiptData: String?
    let platform: String
    let appVersion: String
    let deviceInfo: String?
    
    enum SubscriptionPeriod: String, Codable, CaseIterable {
        case weekly = "weekly"
        case yearly = "yearly"
        
        var displayName: String {
            switch self {
            case .weekly: return "Weekly"
            case .yearly: return "Yearly"
            }
        }
    }
    
    enum SubscriptionStatus: String, Codable, CaseIterable {
        case active = "active"
        case expired = "expired"
        case cancelled = "cancelled"
        case pending = "pending"
        case inGracePeriod = "in_grace_period"
        case inBillingRetryPeriod = "in_billing_retry_period"
    }
    
    init(
        subscriptionID: String,
        profileID: String,
        productID: String,
        transactionID: String,
        creditsPerPeriod: Int,
        period: SubscriptionPeriod,
        price: String,
        currency: String,
        status: SubscriptionStatus = .pending,
        startDate: Date = Date(),
        expiryDate: Date? = nil,
        autoRenews: Bool = true,
        receiptData: String? = nil,
        deviceInfo: String? = nil
    ) {
        self.subscriptionID = subscriptionID
        self.profileID = profileID
        self.productID = productID
        self.transactionID = transactionID
        self.creditsPerPeriod = creditsPerPeriod
        self.period = period
        self.price = price
        self.currency = currency
        self.status = status
        self.startDate = startDate
        self.expiryDate = expiryDate
        self.autoRenews = autoRenews
        self.receiptData = receiptData
        self.platform = "iOS"
        self.appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        self.deviceInfo = deviceInfo
    }
    
    enum CodingKeys: String, CodingKey {
        case subscriptionID
        case profileID
        case productID
        case transactionID
        case creditsPerPeriod
        case period
        case price
        case currency
        case status
        case startDate
        case expiryDate
        case autoRenews
        case receiptData
        case platform
        case appVersion
        case deviceInfo
    }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        subscriptionID = try c.decode(String.self, forKey: .subscriptionID)
        profileID = try c.decode(String.self, forKey: .profileID)
        productID = try c.decode(String.self, forKey: .productID)
        transactionID = try c.decode(String.self, forKey: .transactionID)
        creditsPerPeriod = try c.decode(Int.self, forKey: .creditsPerPeriod)
        period = try c.decode(SubscriptionPeriod.self, forKey: .period)
        price = try c.decode(String.self, forKey: .price)
        currency = try c.decode(String.self, forKey: .currency)
        status = try c.decode(SubscriptionStatus.self, forKey: .status)
        autoRenews = try c.decode(Bool.self, forKey: .autoRenews)
        receiptData = try c.decodeIfPresent(String.self, forKey: .receiptData)
        platform = try c.decode(String.self, forKey: .platform)
        appVersion = try c.decode(String.self, forKey: .appVersion)
        deviceInfo = try c.decodeIfPresent(String.self, forKey: .deviceInfo)
        
        let startTS = try c.decode(Double.self, forKey: .startDate)
        startDate = Date(timeIntervalSince1970: startTS)
        
        if let expiryTS = try? c.decode(Double.self, forKey: .expiryDate) {
            expiryDate = Date(timeIntervalSince1970: expiryTS)
        } else {
            expiryDate = nil
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(subscriptionID, forKey: .subscriptionID)
        try c.encode(profileID, forKey: .profileID)
        try c.encode(productID, forKey: .productID)
        try c.encode(transactionID, forKey: .transactionID)
        try c.encode(creditsPerPeriod, forKey: .creditsPerPeriod)
        try c.encode(period, forKey: .period)
        try c.encode(price, forKey: .price)
        try c.encode(currency, forKey: .currency)
        try c.encode(status, forKey: .status)
        try c.encode(startDate.timeIntervalSince1970, forKey: .startDate)
        try c.encodeIfPresent(expiryDate?.timeIntervalSince1970, forKey: .expiryDate)
        try c.encode(autoRenews, forKey: .autoRenews)
        try c.encodeIfPresent(receiptData, forKey: .receiptData)
        try c.encode(platform, forKey: .platform)
        try c.encode(appVersion, forKey: .appVersion)
        try c.encodeIfPresent(deviceInfo, forKey: .deviceInfo)
    }
    
    var isActive: Bool { status == .active }
    var isExpired: Bool {
        guard let expiry = expiryDate else { return false }
        return expiry < Date()
    }
    var displayPrice: String { "\(price) \(currency)" }
    
    var formattedStartDate: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: startDate)
    }
}

extension SubscriptionInfo {
    static func fromStoreKitTransaction(
        _ transaction: StoreKit.Transaction,
        profileID: String,
        product: StoreKit.Product,
        period: SubscriptionPeriod,
        creditsPerPeriod: Int,
        receiptData: String? = nil
    ) -> SubscriptionInfo {
        let deviceInfo = "\(UIDevice.current.model) - iOS \(UIDevice.current.systemVersion)"
        
        // Calculate expiry date based on period (fallback calculation)
        let calendar = Calendar.current
        let expiryDate = calendar.date(byAdding: period == .weekly ? .day : .year, value: period == .weekly ? 7 : 1, to: transaction.purchaseDate)
        
        // Default status is pending - will be updated from subscription status
        let status: SubscriptionStatus = .pending
        
        return SubscriptionInfo(
            subscriptionID: UUID().uuidString,
            profileID: profileID,
            productID: product.id,
            transactionID: String(transaction.id),
            creditsPerPeriod: creditsPerPeriod,
            period: period,
            price: product.displayPrice,
            currency: product.priceFormatStyle.currencyCode,
            status: status,
            startDate: transaction.purchaseDate,
            expiryDate: expiryDate,
            autoRenews: true, // Default for subscriptions
            receiptData: receiptData,
            deviceInfo: deviceInfo
        )
    }
}

