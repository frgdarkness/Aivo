//
//  SubscriptionManager.swift
//  Aivo
//
//  Created for managing subscription purchases
//

import Foundation
import StoreKit
import Combine
import FBSDKCoreKit

@MainActor
final class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()
    
    // MARK: - Published states
    @Published private(set) var isPremium: Bool = false
    @Published private(set) var products: [Product] = []
    @Published private(set) var currentSubscription: ActiveSubscription?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Product IDs
    enum ProductID: String, CaseIterable {
//        case weekly = "AIVO_PREMIUM_WEEKLY"
//        case yearly = "AIVO_PREMIUM_YEARLY"
        
        case weekly = "aivo.premium.weekly"
        case yearly = "aivo.premium.yearly"

        var sortOrder: Int {
            switch self {
            case .weekly: return 0
            case .yearly: return 1
            }
        }
        var period: SubscriptionPeriod {
            switch self {
            case .weekly: return .weekly
            case .yearly: return .yearly
            }
        }
        var creditsPerPeriod: Int {
            switch self {
            case .weekly: return 1000  // 1000 credits/tuần
            case .yearly: return 1200 // 1200 credits/tuần
            }
        }
    }

    enum SubscriptionPeriod {
        case weekly
        case yearly
        
        var displayName: String {
            switch self {
            case .weekly: return "Weekly"
            case .yearly: return "Yearly"
            }
        }
    }

    struct ActiveSubscription {
        let productID: String
        let willAutoRenew: Bool
        let expiresDate: Date?
        var displayName: String?
        var displayPrice: String?

        var period: SubscriptionPeriod {
            ProductID(rawValue: productID)?.period ?? .weekly
        }
        var isActive: Bool {
            guard let exp = expiresDate else { return true }
            return exp > Date()
        }
    }

    // MARK: - Private
    private let productIDs = Set(ProductID.allCases.map(\.rawValue))
    private var updatesTask: Task<Void, Never>?
    private var processedTransactionIDs = Set<String>()

    private var bonusCreditAmount: Int {
        // Get bonus based on current subscription period
        guard let currentSub = currentSubscription else { return 1000 } // Default to weekly
        switch currentSub.period {
        case .weekly: return 1000
        case .yearly: return 1200
        }
    }
    private let bonusIntervalDays: Double = 7
    
    // MARK: - Init
    private init() {
        Logger.i("SubscriptionManager: Initializing")
        observeTransactionUpdates()
        Task { await refreshStatus() } // không force sync để tránh loop login sandbox
    }

    deinit { updatesTask?.cancel() }
    
    // MARK: - Public API
    
    /// Fetch product list từ App Store
    func fetchProducts() async {
        guard !isLoading else {
            Logger.d("SubscriptionManager: fetchProducts already running")
            return
        }
        isLoading = true
        errorMessage = nil
        Logger.i("SubscriptionManager: fetchProducts - starting for productIDs=\(Array(productIDs))")
        
            do {
                let fetched = try await Product.products(for: Array(productIDs))
            products = fetched.sorted {
                (ProductID(rawValue: $0.id)?.sortOrder ?? 999) < (ProductID(rawValue: $1.id)?.sortOrder ?? 999)
            }
            isLoading = false
            Logger.i("SubscriptionManager: fetchProducts - success, count=\(products.count)")
            Logger.d("SubscriptionManager: Products: " + products.map { "id=\($0.id), price=\($0.displayPrice)" }.joined(separator: "; "))
        } catch {
            isLoading = false
            errorMessage = "Failed to fetch products: \(error.localizedDescription)"
            Logger.e("SubscriptionManager: fetchProducts - error=\(error.localizedDescription)")
        }
    }

    func product(for id: ProductID) -> Product? {
        products.first { $0.id == id.rawValue }
    }

    /// Mua theo enum ProductID
    func purchase(productID: ProductID) async {
        Logger.i("SubscriptionManager: purchase - start id=\(productID.rawValue)")
        var prod = product(for: productID)
        if prod == nil {
            do { prod = try await Product.products(for: [productID.rawValue]).first }
            catch { Logger.e("purchase: fetch product fail \(error.localizedDescription)") }
        }
        guard let product = prod else {
            errorMessage = "Product not found."
            Logger.e("purchase: product missing \(productID.rawValue)")
            return
        }
        await purchase(product: product)
    }

    /// Mua với Product
    func purchase(product: Product) async {
        Logger.i("SubscriptionManager: purchase - start product=\(product.id), price=\(product.displayPrice)")
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let tx):
                    Logger.i("purchase: verified tx id=\(tx.id)")
                    
                    // Get price and currency directly from Product (accurate)
                    let price = product.price // Decimal
                    let currency = product.priceFormatStyle.currencyCode ?? "USD"
                    let amount = NSDecimalNumber(decimal: price).doubleValue
                    let period = ProductID(rawValue: product.id)?.period == .weekly ? "weekly" : "yearly"
                    
                    // ✅ Log purchase to Facebook App Events for conversion tracking
                    FacebookEventLogger.shared.logSubscriptionPurchase(
                        amount: amount,
                        currency: currency,
                        productID: product.id,
                        period: period
                    )
                    
                    // ✅ Log subscription purchase to Firebase and AppsFlyer
                    AnalyticsLogger.shared.logEventWithBundle("event_buy_subscription", parameters: [
                        "product_id": product.id,
                        "price": amount,
                        "currency": currency,
                        "period": period,
                        "timestamp": Date().timeIntervalSince1970
                    ])
                    
                    // ✅ Also log to AppsFlyer as revenue event (for attribution)
                    // Pass Product directly for accurate price and currency
                    AppsFlyerLogger.shared.logSubscribe(product: product)
                    
                    await handleVerified(tx)
                    await checkBonusCreditForSubscription()
                case .unverified(_, let err):
                    errorMessage = "Purchase unverified: \(err.localizedDescription)"
                    Logger.w("purchase: unverified \(err.localizedDescription)")
                    NotificationCenter.default.post(name: NSNotification.Name("SubscriptionPurchaseFailed"), object: nil)
                }
            case .pending:
                Logger.i("purchase: pending")
                NotificationCenter.default.post(name: NSNotification.Name("SubscriptionPurchasePending"), object: nil)
            case .userCancelled:
                Logger.w("purchase: user cancelled")
                NotificationCenter.default.post(name: NSNotification.Name("SubscriptionPurchaseCancelled"), object: nil)
            @unknown default:
                Logger.w("purchase: unknown result")
            }
        } catch {
            errorMessage = "Purchase failed: \(error.localizedDescription)"
            Logger.e("purchase: error \(error.localizedDescription)")
            NotificationCenter.default.post(name: NSNotification.Name("SubscriptionPurchaseFailed"), object: nil)
        }
    }

    /// Legacy wrapper
    func purchaseSubscription(_ product: Product) async throws -> Bool {
        await purchase(product: product)
        return errorMessage == nil
    }

    /// Khôi phục mua
    func restorePurchases() async {
        Logger.i("restorePurchases: start")
        do {
            try await AppStore.sync()
            await refreshStatus(forceSync: false)
            Logger.i("restorePurchases: success")
            
            // ✅ Log restore subscription to Firebase and AppsFlyer
            if isPremium {
                AnalyticsLogger.shared.logEventWithBundle("event_restore_subscription", parameters: [
                    "product_id": currentSubscription?.productID ?? "unknown",
                    "period": currentSubscription?.period.displayName ?? "unknown",
                    "timestamp": Date().timeIntervalSince1970
                ])
            }
        } catch {
            errorMessage = "Restore failed: \(error.localizedDescription)"
            Logger.e("restorePurchases: error \(error.localizedDescription)")
        }
    }

    /// Check subscription (wrapper)
    func checkSubscriptionStatus() {
        Task { await refreshStatus() }
    }

    // MARK: - Refresh Status (with sandbox-friendly fallback)
    func refreshStatus(forceSync: Bool = false) async {
        Logger.i("SubscriptionManager: refreshStatus - starting")

        // 1) Chỉ sync nếu thực sự cần (tránh sandbox bắt login liên tục)
        await ensureReceiptIfNeeded(force: forceSync)

        // 2) Thử đọc entitlements trước (nhanh nhất)
        var best: ActiveSubscription?
        var entitlementsHadAny = false

        for await res in Transaction.currentEntitlements {
            switch res {
            case .verified(let tx):
                guard productIDs.contains(tx.productID) else { continue }
                entitlementsHadAny = true
                Logger.d("refreshStatus: entitlements tx id=\(tx.id), product=\(tx.productID)")
                let candidate = ActiveSubscription(
                    productID: tx.productID,
                    willAutoRenew: (tx.revocationDate == nil),
                    expiresDate: tx.expirationDate,          // iOS 15+: auto-renewable có expirationDate
                    displayName: nil,
                    displayPrice: nil
                )
                best = chooseMoreRecent(current: best, candidate: candidate)
            case .unverified(_, let err):
                Logger.w("refreshStatus: entitlements unverified \(err.localizedDescription)")
            }
        }

        // 3) Nếu entitlements rỗng → fallback latest(for:)
        if best == nil {
            Logger.d("refreshStatus: entitlements empty → fallback latest(for:)")
            for id in productIDs {
                if let tx = await latestActiveTransaction(for: id) {
                    let candidate = ActiveSubscription(
                        productID: tx.productID,
                        willAutoRenew: (tx.revocationDate == nil),
                        expiresDate: tx.expirationDate,
                        displayName: nil,
                        displayPrice: nil
                    )
                    best = chooseMoreRecent(current: best, candidate: candidate)
                }
            }
        }

        // 4) Sandbox đôi khi trễ → retry nhẹ 1 lần nếu vẫn nil và entitlements chưa có gì
        if best == nil && !entitlementsHadAny {
            try? await Task.sleep(nanoseconds: 600_000_000) // 0.6s
            Logger.d("refreshStatus: retry after short delay")
            for id in productIDs {
                if let tx = await latestActiveTransaction(for: id) {
                    let candidate = ActiveSubscription(
                        productID: tx.productID,
                        willAutoRenew: (tx.revocationDate == nil),
                        expiresDate: tx.expirationDate,
                        displayName: nil,
                        displayPrice: nil
                    )
                    best = chooseMoreRecent(current: best, candidate: candidate)
                }
            }
        }

        // 5) Cập nhật state + nạp thông tin hiển thị
        if var sub = best {
            if let prod = try? await Product.products(for: [sub.productID]).first {
                sub.displayName = prod.displayName
                sub.displayPrice = prod.displayPrice
            }
            currentSubscription = sub
            isPremium = true
            Logger.i("refreshStatus: ACTIVE product=\(sub.productID), expires=\(sub.expiresDate?.description ?? "nil")")

            // Cập nhật CreditManager
            let infoPeriod: SubscriptionInfo.SubscriptionPeriod? = (sub.period == .weekly) ? .weekly : .yearly
            CreditManager.shared.updatePremiumStatus(true, period: infoPeriod, skipInitialGrant: true)
            
            // Update subscription fields in UserProfile
            // Determine start date: use current time if profile doesn't have it yet
            let profile = LocalStorageManager.shared.getLocalProfile()
            let startDate = profile.subscriptionStartDate ?? Date()
            let expiredDate = sub.expiresDate
            
            LocalStorageManager.shared.updateSubscriptionFields(
                plan: infoPeriod,
                startDate: startDate,
                expiredDate: expiredDate
            )
            
            // Sync profile to remote if needed
            if LocalStorageManager.shared.hasRemoteProfile {
                Task {
                    await ProfileSyncManager.shared.syncProfileIfNeeded()
                }
            }
        } else {
            currentSubscription = nil
            isPremium = false
            Logger.i("refreshStatus: NO ACTIVE SUBSCRIPTION")
            CreditManager.shared.updatePremiumStatus(false)
            
            // Clear subscription fields when no active subscription
            LocalStorageManager.shared.updateSubscriptionFields(
                plan: nil,
                startDate: nil,
                expiredDate: nil
            )
            
            // Sync profile to remote if needed
            if LocalStorageManager.shared.hasRemoteProfile {
                Task {
                    await ProfileSyncManager.shared.syncProfileIfNeeded()
                }
            }
        }

        // 6) Bonus credit nếu premium
        await checkBonusCreditForSubscription()
    }

    func setPremiumDebug(isPremiumEnable: Bool) {
        isPremium = isPremiumEnable
    }
    
    // MARK: - Bonus Credit (weekly: 1000, yearly: 1200)
    func checkBonusCreditForSubscription() async {
        guard isPremium else {
            Logger.d("checkBonusCreditForSubscription: user not premium, skip")
            return
        }

        let now = Date()
        
        // Get bonus amount based on current subscription period
        let bonusAmount = bonusCreditAmount
        
        // Priority 1: Load from Keychain (persists across app reinstalls)
        var lastBonusDate: Date? = KeychainManager.shared.getLastBonusDate()
        
        // Priority 2: Fallback to UserDefaults (migration from old version)
        if lastBonusDate == nil {
            if let userDefaultsDate = UserDefaults.standard.object(forKey: "AIVO_LastBonusCreditDate") as? Date {
                lastBonusDate = userDefaultsDate
                // Migrate to Keychain
                KeychainManager.shared.saveLastBonusDate(userDefaultsDate)
                Logger.d("checkBonusCreditForSubscription: Migrated lastBonusDate from UserDefaults to Keychain")
            }
        }

        if let last = lastBonusDate {
            let days = now.timeIntervalSince(last) / (60 * 60 * 24)
            if days >= bonusIntervalDays {
                await CreditManager.shared.increaseCredits(by: bonusAmount)
                KeychainManager.shared.saveLastBonusDate(now)
                // Also save to UserDefaults for backward compatibility
                UserDefaults.standard.set(now, forKey: "AIVO_LastBonusCreditDate")
                
                // Update lastBonusTime in UserProfile
                LocalStorageManager.shared.updateLastBonusTime(now)
                
                // Sync profile to remote if needed
                if LocalStorageManager.shared.hasRemoteProfile {
                    Task {
                        await ProfileSyncManager.shared.syncProfileIfNeeded()
                    }
                }
                
                let periodName = currentSubscription?.period.displayName ?? "unknown"
                Logger.i("checkBonusCreditForSubscription: +\(bonusAmount) credits (\(periodName) bonus), daysSinceLast=\(Int(days))")
            } else {
                Logger.d("checkBonusCreditForSubscription: not yet (\(Int(bonusIntervalDays - days)) days left)")
            }
        } else {
            // lần đầu sau khi sub
            await CreditManager.shared.increaseCredits(by: bonusAmount)
            KeychainManager.shared.saveLastBonusDate(now)
            // Also save to UserDefaults for backward compatibility
            UserDefaults.standard.set(now, forKey: "AIVO_LastBonusCreditDate")
            
            // Update lastBonusTime in UserProfile
            LocalStorageManager.shared.updateLastBonusTime(now)
            
            // Sync profile to remote if needed
            if LocalStorageManager.shared.hasRemoteProfile {
                Task {
                    await ProfileSyncManager.shared.syncProfileIfNeeded()
                }
            }
            
            let periodName = currentSubscription?.period.displayName ?? "unknown"
            Logger.i("checkBonusCreditForSubscription: first-time +\(bonusAmount) credits (\(periodName) bonus)")
        }
    }

    // MARK: - Transaction observation
    private func observeTransactionUpdates() {
        Logger.i("SubscriptionManager: observeTransactionUpdates - starting")
        updatesTask = Task.detached { [weak self] in
            guard let self else { return }
            Logger.d("observeTransactionUpdates: task started")
            for await update in Transaction.updates {
                await self.handleUpdate(update)
            }
        }
    }
    
    private func handleUpdate(_ verification: VerificationResult<Transaction>) async {
        switch verification {
        case .unverified(_, let error):
            Logger.w("handleUpdate: unverified \(error.localizedDescription)")
        case .verified(let transaction):
            guard productIDs.contains(transaction.productID) else {
                Logger.d("handleUpdate: non-sub product \(transaction.productID) → finish")
                await transaction.finish()
                return
            }
            Logger.i("handleUpdate: verified id=\(transaction.id), product=\(transaction.productID)")
            await handleVerified(transaction)
        }
    }

    private func handleVerified(_ transaction: Transaction) async {
        let txID = String(transaction.id)
        let status = await String(describing: transaction.subscriptionStatus)
        Logger.d("handleVerified: id=\(txID) - product=\(transaction.productID) - status=\(status) - appTransactionID=\(transaction.appTransactionID) - expiredDate=\(transaction.expirationDate ?? Date())")
        if !processedTransactionIDs.insert(txID).inserted {
            Logger.w("handleVerified: already processed id=\(txID) → finish & refresh")
            await transaction.finish()
            await refreshStatus()
            return
        }
        
        // Không spam sync, chỉ finish & refresh
        Logger.d("handleVerified: new tx id=\(txID) → refresh")
        
        // Update subscription fields with transaction info before refresh
        // This ensures startDate is set from actual purchase date
        let profile = LocalStorageManager.shared.getLocalProfile()
        if profile.subscriptionPlan == nil {
            // First time subscription - set startDate from transaction
            let period: SubscriptionInfo.SubscriptionPeriod? = {
                guard let productID = ProductID(rawValue: transaction.productID) else { return nil }
                return productID.period == .weekly ? .weekly : .yearly
            }()
            
            LocalStorageManager.shared.updateSubscriptionFields(
                plan: period,
                startDate: transaction.purchaseDate,
                expiredDate: transaction.expirationDate
            )
            Logger.d("handleVerified: Set initial subscription startDate from transaction: \(transaction.purchaseDate)")
        }
        
        await refreshStatus()
        await transaction.finish()

        // Sync profile to RemoteFirebase khi user subscribe (tương tự CreditStoreManager)
        // Chỉ sync khi user subscribe, không sync mặc định
        do {
            try await ProfileSyncManager.shared.createRemoteProfileAndSync()
            Logger.i("handleVerified: Profile synced to RemoteFirebase after subscription")
        } catch {
            Logger.e("handleVerified: Failed to sync profile to RemoteFirebase: \(error.localizedDescription)")
            // Nếu đã có remote profile, thử sync lại
            do {
                await ProfileSyncManager.shared.syncProfileIfNeeded()
                Logger.d("handleVerified: Profile sync attempted via syncProfileIfNeeded")
            } catch {
                Logger.e("handleVerified: Failed to sync profile: \(error.localizedDescription)")
            }
        }

        NotificationCenter.default.post(name: NSNotification.Name("SubscriptionPurchaseSuccess"), object: nil)
    }

    // MARK: - Helpers

    /// Chỉ gọi AppStore.sync() khi thật sự cần (chưa có receipt) hoặc force
    private func ensureReceiptIfNeeded(force: Bool = false) async {
        let hasReceipt: Bool = {
            guard let url = Bundle.main.appStoreReceiptURL else { return false }
            return FileManager.default.fileExists(atPath: url.path)
        }()
        if force || !hasReceipt {
            do {
                //try await AppStore.sync()
                Logger.d("ensureReceiptIfNeeded: AppStore.sync() done (force=\(force))")
            } catch {
                Logger.w("ensureReceiptIfNeeded: sync failed \(error.localizedDescription)")
            }
        } else {
            Logger.d("ensureReceiptIfNeeded: receipt exists → skip sync")
        }
    }

    /// Fallback: lấy transaction mới nhất của 1 product và tự kiểm tra còn hiệu lực
    private func latestActiveTransaction(for productID: String) async -> Transaction? {
        do {
            if let result = try await Transaction.latest(for: productID) {
                switch result {
                case .verified(let tx):
                    if let rev = tx.revocationDate, rev <= Date() { return nil }
                    if let exp = tx.expirationDate { return exp > Date() ? tx : nil }
                    return tx
                case .unverified(_, let err):
                    Logger.w("latestActiveTransaction: unverified \(productID) \(err.localizedDescription)")
                    return nil
                }
            }
        } catch {
            Logger.w("latestActiveTransaction: error \(productID) \(error.localizedDescription)")
        }
        return nil
    }

    private func chooseMoreRecent(current: ActiveSubscription?, candidate: ActiveSubscription) -> ActiveSubscription {
        guard let cur = current else { return candidate }
        let curExp = cur.expiresDate ?? .distantPast
        let candExp = candidate.expiresDate ?? .distantPast
        return candExp > curExp ? candidate : cur
    }

    // MARK: - Legacy helpers
    func getProduct(for identifier: ProductID) -> Product? { product(for: identifier) }
    func getCreditsPerPeriod(for product: Product) -> Int {
        ProductID(rawValue: product.id)?.creditsPerPeriod ?? 1000
    }
    func getPeriod(for product: Product) -> SubscriptionPeriod? {
        ProductID(rawValue: product.id)?.period
    }
    func getCurrentSubscription() -> ActiveSubscription? { currentSubscription }
}
