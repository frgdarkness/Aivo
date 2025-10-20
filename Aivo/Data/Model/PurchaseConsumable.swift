import Foundation
import StoreKit

struct PurchaseConsumable: Codable {
    let purchaseID: String
    let profileID: String
    let productID: String
    let transactionID: String
    let creditsAmount: Int
    let price: String
    let currency: String
    let purchasedAt: Date
    let status: PurchaseStatus
    let receiptData: String?
    let platform: String
    let appVersion: String
    let deviceInfo: String?
    
    enum PurchaseStatus: String, Codable, CaseIterable {
        case pending = "pending"
        case completed = "completed"
        case failed = "failed"
        case refunded = "refunded"
        case cancelled = "cancelled"
    }
    
    init(
        purchaseID: String,
        profileID: String,
        productID: String,
        transactionID: String,
        creditsAmount: Int,
        price: String,
        currency: String,
        status: PurchaseStatus = .pending,
        receiptData: String? = nil,
        deviceInfo: String? = nil
    ) {
        self.purchaseID = purchaseID
        self.profileID = profileID
        self.productID = productID
        self.transactionID = transactionID
        self.creditsAmount = creditsAmount
        self.price = price
        self.currency = currency
        self.purchasedAt = Date()
        self.status = status
        self.receiptData = receiptData
        self.platform = "iOS"
        self.appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        self.deviceInfo = deviceInfo
    }
    
    enum CodingKeys: String, CodingKey {
        case purchaseID
        case profileID
        case productID
        case transactionID
        case creditsAmount
        case price
        case currency
        case purchasedAt
        case status
        case receiptData
        case platform
        case appVersion
        case deviceInfo
    }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        purchaseID = try c.decode(String.self, forKey: .purchaseID)
        profileID = try c.decode(String.self, forKey: .profileID)
        productID = try c.decode(String.self, forKey: .productID)
        transactionID = try c.decode(String.self, forKey: .transactionID)
        creditsAmount = try c.decode(Int.self, forKey: .creditsAmount)
        price = try c.decode(String.self, forKey: .price)
        currency = try c.decode(String.self, forKey: .currency)
        status = try c.decode(PurchaseStatus.self, forKey: .status)
        receiptData = try c.decodeIfPresent(String.self, forKey: .receiptData)
        platform = try c.decode(String.self, forKey: .platform)
        appVersion = try c.decode(String.self, forKey: .appVersion)
        deviceInfo = try c.decodeIfPresent(String.self, forKey: .deviceInfo)
        let ts = try c.decode(Double.self, forKey: .purchasedAt)
        purchasedAt = Date(timeIntervalSince1970: ts)
    }
    
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(purchaseID, forKey: .purchaseID)
        try c.encode(profileID, forKey: .profileID)
        try c.encode(productID, forKey: .productID)
        try c.encode(transactionID, forKey: .transactionID)
        try c.encode(creditsAmount, forKey: .creditsAmount)
        try c.encode(price, forKey: .price)
        try c.encode(currency, forKey: .currency)
        try c.encode(purchasedAt.timeIntervalSince1970, forKey: .purchasedAt)
        try c.encode(status, forKey: .status)
        try c.encodeIfPresent(receiptData, forKey: .receiptData)
        try c.encode(platform, forKey: .platform)
        try c.encode(appVersion, forKey: .appVersion)
        try c.encodeIfPresent(deviceInfo, forKey: .deviceInfo)
    }
    
    var isCompleted: Bool { status == .completed }
    var isRefunded: Bool { status == .refunded }
    var displayPrice: String { "\(price) \(currency)" }
    
    var formattedPurchaseDate: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: purchasedAt)
    }
}

extension PurchaseConsumable {
    static func fromStoreKitTransaction(
        _ transaction: StoreKit.Transaction,
        profileID: String,
        product: StoreKit.Product,
        creditsAmount: Int,
        receiptData: String? = nil
    ) -> PurchaseConsumable {
        let deviceInfo = "\(UIDevice.current.model) - iOS \(UIDevice.current.systemVersion)"
        return PurchaseConsumable(
            purchaseID: UUID().uuidString,
            profileID: profileID,
            productID: product.id,
            transactionID: String(transaction.id),
            creditsAmount: creditsAmount,
            price: product.displayPrice,
            currency: product.priceFormatStyle.currencyCode ?? "USD",
            status: .completed,
            receiptData: receiptData,
            deviceInfo: deviceInfo
        )
    }
}
