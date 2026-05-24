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
    
    /// Internal store for App Store status
    private var isStorePremium: Bool = false
    
    /// Returns true if user has active subscription OR active temporary trial
    var isUserPremium: Bool {
        if isStorePremium { return true }
        if let trialExpiry = UserDefaults.standard.object(forKey: "DailyGiftTrialExpiryDate") as? Date {
            if Date() < trialExpiry { return true }
        }
        return false
    }
    
    var isVIPTrialActive: Bool {
        if let expiry = UserDefaults.standard.object(forKey: "VIPTrialExpiryDate") as? Date {
            return Date() < expiry
        }
        return false
    }
    
    var isAdFree: Bool {
        if isStorePremium { return true }
        if let trialExpiry = UserDefaults.standard.object(forKey: "DailyGiftTrialExpiryDate") as? Date {
            if Date() < trialExpiry { return true }
        }
        return false
    }
    
    func refreshTrialStatus() {
        // Recalculate combined state and notify observers
        self.isPremium = isUserPremium
        objectWillChange.send()
    }
    
    @Published private(set) var products: [Product] = []
    @Published private(set) var currentSubscription: ActiveSubscription?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showPromoCodeSuccess: Bool = false
    
    private var isCheckingBonus = false
    
    // MARK: - Product IDs
    enum ProductID: String, CaseIterable {
        case weekly = "AIVO_PREMIUM_WEEKLY"
        case yearly = "AIVO_PREMIUM_YEARLY"
        case yearlyDiscount = "AIVO_PREMIUM_YEARLY_DISCOUNT"
        
        var sortOrder: Int {
            switch self {
            case .weekly: return 0
            case .yearly: return 1
            case .yearlyDiscount: return 2
            }
        }
        var period: SubscriptionPeriod {
            switch self {
            case .weekly: return .weekly
            case .yearly, .yearlyDiscount: return .yearly
            }
        }
        var creditsPerPeriod: Int {
            switch self {
            case .weekly: return 1000  // 1000 credits/tuần
            case .yearly, .yearlyDiscount: return 1200 // 1200 credits/tuần
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
                    
                    // await checkBonusCreditForSubscription() // already called in refreshStatus
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
            await refreshStatus(forceSync: true, retries: true)
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
    func checkSubscriptionStatus() async {
        await refreshStatus()
    }

    // MARK: - Refresh Status (with sandbox-friendly fallback)
    func refreshStatus(forceSync: Bool = false, retries: Bool = false) async {
        Logger.i("SubscriptionManager: refreshStatus - starting")

        // 1) Chỉ sync nếu thực sự cần (tránh sandbox bắt login liên tục)
        await ensureReceiptIfNeeded(force: forceSync)

        // Process unfinished transactions (for promo codes like AIVO_100_CREDITS)
        for await verification in Transaction.unfinished {
            await handleUpdate(verification)
        }

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

        // 4) Sandbox đôi khi trễ → retry nhẹ 1 lần nếu vẫn nil và entitlements chưa có gì AND retries requested
        if retries && best == nil && !entitlementsHadAny {
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
            isStorePremium = true
            refreshTrialStatus() // Cập nhật isPremium based on store + trial
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
            isStorePremium = false
            refreshTrialStatus() // Cập nhật isPremium
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

    func checkAndGrantVIPTrial() async {
        let isTrialGiftedLocal = UserDefaults.standard.bool(forKey: "VIPTrialGifted")
        let isTrialGiftedKey = KeychainManager.shared.getBool(forKey: "VIPTrialGifted")
        
        guard !isTrialGiftedLocal && !isTrialGiftedKey else {
            return
        }
        
        Logger.i("🎁 checkAndGrantVIPTrial: Granting 1 hour VIP Trial on first open")
        
        // 1. Mark as gifted in both UserDefaults and Keychain
        UserDefaults.standard.set(true, forKey: "VIPTrialGifted")
        KeychainManager.shared.saveBool(true, forKey: "VIPTrialGifted")
        
        // 2. Set expiry date (1 hour from now)
        let expiryDate = Date().addingTimeInterval(3600)
        UserDefaults.standard.set(expiryDate, forKey: "VIPTrialExpiryDate")
        
        // 3. Determine if offer code transaction AIVO_100_CREDITS was already claimed during refreshStatus
        var hasClaimedPromoCode = false
        let allKeys = UserDefaults.standard.dictionaryRepresentation().keys
        for key in allKeys {
            if key.hasPrefix("AIVO_100_CREDITS_CLAIMED_") && UserDefaults.standard.bool(forKey: key) {
                hasClaimedPromoCode = true
                break
            }
        }
        
        if hasClaimedPromoCode {
            // Already claimed 100 credits via handlePromoCode, do NOT gift 60
            Logger.i("🎁 checkAndGrantVIPTrial: User claimed AIVO_100_CREDITS. Direct gift of 60 credits skipped.")
            UserDefaults.standard.set(100, forKey: "VIPTrialGiftCreditsAmount")
        } else {
            // Direct install, gift 60 credits
            Logger.i("🎁 checkAndGrantVIPTrial: User is direct install. Gifting 60 credits.")
            await CreditManager.shared.increaseCredits(by: 60)
            UserDefaults.standard.set(60, forKey: "VIPTrialGiftCreditsAmount")
        }
        
        // Refresh local trial status immediately
        self.refreshTrialStatus()
    }

    func setPremiumDebug(isPremiumEnable: Bool) {
        isPremium = isPremiumEnable
    }
    
    // MARK: - Bonus Credit Logic
    
    /// Cut-off date for new bonus policy (Jan 15, 2026)
    private let bonusPolicyCutoffDate: Date = {
        var components = DateComponents()
        components.year = 2026
        components.month = 1
        components.day = 15
        return Calendar.current.date(from: components) ?? Date()
    }()
    
    private var bonusCreditAmount: Int {
        // Get bonus based on current subscription and cohort
        guard let currentSub = currentSubscription else { return 1000 } // Default to weekly amount
        
        switch currentSub.period {
        case .weekly:
            return 1000
        case .yearly:
            // Check if user is "Grandfathered" (subscribed before Jan 15, 2026)
            // Use local profile startDate as proxy for original purchase if transaction history is partial
            // Ideally, we check the earliest transaction date for the active subscription chain
            let profileStartDate = LocalStorageManager.shared.getLocalProfile().subscriptionStartDate ?? Date()
            
            if profileStartDate < bonusPolicyCutoffDate {
                // Grandfathered: 1200 credits per WEEK
                return 1200
            } else {
                // New Policy: 1200 credits per MONTH
                return 1200
            }
        }
    }
    
    private var bonusIntervalDays: Double {
        guard let currentSub = currentSubscription else { return 7 }
        
        switch currentSub.period {
        case .weekly:
            return 7
        case .yearly:
            let profileStartDate = LocalStorageManager.shared.getLocalProfile().subscriptionStartDate ?? Date()
            if profileStartDate < bonusPolicyCutoffDate {
                // Grandfathered: Weekly bonus
                return 7
            } else {
                // New Policy: Monthly bonus (approx 30 days)
                return 30
            }
        }
    }
    
    func getNextBonusDate() -> Date? {
        guard isPremium else { return nil }
        
        // Return stored next date if available logic supported it, 
        // but currently we calc based on last bonus date + interval
        if let lastBonusDate = KeychainManager.shared.getLastBonusDate() {
            return lastBonusDate.addingTimeInterval(bonusIntervalDays * 24 * 60 * 60)
        }
        
        // If no last bonus date but premium, maybe just started?
        return Date().addingTimeInterval(bonusIntervalDays * 24 * 60 * 60)
    }
    
    func checkBonusCreditForSubscription() async {
        guard isPremium else {
            Logger.d("checkBonusCreditForSubscription: user not premium, skip")
            return
        }
        
        // Prevent concurrent execution (race condition fix)
        guard !isCheckingBonus else { 
            Logger.d("checkBonusCreditForSubscription: Already checking, skipping concurrent call")
            return 
        }
        isCheckingBonus = true
        defer { isCheckingBonus = false }

        let now = Date()
        let bonusAmount = bonusCreditAmount
        let interval = bonusIntervalDays
        
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
            if days >= interval {
                let previousBalance = CreditManager.shared.credits
                await CreditManager.shared.increaseCredits(by: bonusAmount)
                let afterBalance = CreditManager.shared.credits
                
                let historyType: RequestType = (currentSubscription?.period == .yearly) ? .bonusPremiumYearly : .bonusPremiumWeekly
                CreditHistoryManager.shared.addRequest(historyType, cost: bonusAmount)
                
                // ✅ Log bonus to Firestore bonus_history
                let bonusReason = (currentSubscription?.period == .yearly) ? "YearlyPremium" : "WeeklyPremium"
                let profileID = LocalStorageManager.shared.getLocalProfile().profileID
                await FirestoreService.shared.logBonusCredit(profileID: profileID, amount: bonusAmount, reason: bonusReason, previousBalance: previousBalance, afterBalance: afterBalance)
                
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
                Logger.i("checkBonusCreditForSubscription: +\(bonusAmount) credits (\(periodName) bonus), daysSinceLast=\(Int(days)), interval=\(interval)")
            } else {
                Logger.d("checkBonusCreditForSubscription: not yet (\(Int(interval - days)) days left)")
            }
        } else {
            // First time after sub
            let previousBalance = CreditManager.shared.credits
            await CreditManager.shared.increaseCredits(by: bonusAmount)
            let afterBalance = CreditManager.shared.credits
            
            // Log to credit history
            let historyType: RequestType = (currentSubscription?.period == .yearly) ? .bonusPremiumYearly : .bonusPremiumWeekly
            CreditHistoryManager.shared.addRequest(historyType, cost: bonusAmount)
            
            // ✅ Log bonus to Firestore bonus_history
            let bonusReason = (currentSubscription?.period == .yearly) ? "YearlyPremium" : "WeeklyPremium"
            let profileID = LocalStorageManager.shared.getLocalProfile().profileID
            await FirestoreService.shared.logBonusCredit(profileID: profileID, amount: bonusAmount, reason: bonusReason, previousBalance: previousBalance, afterBalance: afterBalance)
            
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
            if transaction.productID == "AIVO_100_CREDITS" {
                Logger.i("handleUpdate: detected AIVO_100_CREDITS promo code claim. txID=\(transaction.id)")
                await handlePromoCode(transaction)
                return
            }
            
            guard productIDs.contains(transaction.productID) else {
                Logger.d("handleUpdate: non-sub product \(transaction.productID) → finish")
                await transaction.finish()
                return
            }
            Logger.i("handleUpdate: verified id=\(transaction.id), product=\(transaction.productID)")
            await handleVerified(transaction)
        }
    }
    
    private func handlePromoCode(_ transaction: Transaction) async {
        let txID = String(transaction.id)
        Logger.i("handlePromoCode: Process start for tx=\(txID)")
        
        if !processedTransactionIDs.insert(txID).inserted {
            Logger.w("handlePromoCode: Transaction already processed in this session. tx=\(txID)")
            await transaction.finish()
            return
        }
        
        let claimedKey = "AIVO_100_CREDITS_CLAIMED_\(txID)"
        if UserDefaults.standard.bool(forKey: claimedKey) {
            Logger.w("handlePromoCode: Transaction already claimed previously in UserDefaults. tx=\(txID)")
            await transaction.finish()
            return
        }
        
        Logger.i("handlePromoCode: Granting 100 credits for tx=\(txID)")
        // Add 100 credits
        let previousBalance = CreditManager.shared.credits
        await CreditManager.shared.increaseCredits(by: 100)
        let afterBalance = CreditManager.shared.credits
        
        Logger.i("handlePromoCode: Balance updated. Previous=\(previousBalance), After=\(afterBalance)")
        
        // Log to history
        CreditHistoryManager.shared.addRequest(.bonusPromoCode, cost: 100) 
        Logger.i("handlePromoCode: Added to CreditHistoryManager (.bonusPromoCode)")
        
        let profileID = LocalStorageManager.shared.getLocalProfile().profileID
        await FirestoreService.shared.logBonusCredit(profileID: profileID, amount: 100, reason: "PromoCode_AIVO_100_CREDITS", previousBalance: previousBalance, afterBalance: afterBalance)
        Logger.i("handlePromoCode: Logged bonus to Firestore for profile=\(profileID)")
        
        UserDefaults.standard.set(true, forKey: claimedKey)
        
        // Broadcast for UI by setting published var
        DispatchQueue.main.async {
            Logger.i("handlePromoCode: Showing PromoCodeSuccessDialog via published state")
            self.showPromoCodeSuccess = true
        }
        
        await transaction.finish()
        Logger.i("handlePromoCode: Finished transaction successfully. tx=\(txID)")
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
        
        
        await refreshStatus(forceSync: false, retries: true)
        
        // Log to Firestore
        await syncSubscriptionWithFirestore(transaction: transaction)
        
        // ✅ Log daily counter to RTDB (daily_new/yyyyMMdd)
        // Only log for initial purchases (not renewals)
        if transaction.id == transaction.originalID {
            Task {
                try? await FirebaseRealtimeService.shared.incrementDailyCounter(packageId: transaction.productID)
            }
        }
        
        await transaction.finish()

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

    /// Sync subscription purchase with Cloud Firestore
    private func syncSubscriptionWithFirestore(transaction: Transaction) async {
        do {
            let profile = LocalStorageManager.shared.getLocalProfile()
            
            // Try to find product info
            let product = products.first(where: { $0.id == transaction.productID })
            
            // Use dummy product if not found to avoid missing log
            let currency = product?.priceFormatStyle.currencyCode ?? "USD"
            let price = product?.displayPrice ?? "Subscription"
            
            // Create a record
            let purchase = PurchaseConsumable(
                purchaseID: UUID().uuidString,
                profileID: profile.profileID,
                productID: transaction.productID,
                transactionID: String(transaction.id),
                creditsAmount: ProductID(rawValue: transaction.productID)?.creditsPerPeriod ?? 0,
                price: price,
                currency: currency,
                status: .completed
            )
            
            // Save to Firestore sub-collection
            try await FirestoreService.shared.logPurchase(profileID: profile.profileID, purchase: purchase)
            
            // Also update the top-level profile in Firestore
            try await FirestoreService.shared.saveProfile(profile)
            
            Logger.i("syncSubscriptionFirestore: success profileID=\(profile.profileID)")
        } catch {
            Logger.e("syncSubscriptionFirestore: error=\(error.localizedDescription)")
        }
    }
    
    func resetNewUserGiftData() {
        Logger.i("🗑️ resetNewUserGiftData: Clearing all new user gift/trial data and extra discount status")
        
        // 1. Reset VIP Trial Keys
        UserDefaults.standard.removeObject(forKey: "VIPTrialGifted")
        UserDefaults.standard.removeObject(forKey: "VIPTrialExpiryDate")
        UserDefaults.standard.removeObject(forKey: "DailyGiftTrialExpiryDate")
        UserDefaults.standard.removeObject(forKey: "VIPTrialGiftDialogShown")
        UserDefaults.standard.removeObject(forKey: "VIPTrialGiftCreditsAmount")
        UserDefaults.standard.removeObject(forKey: "YearlyDiscountExpiryDate")
        UserDefaults.standard.removeObject(forKey: "WelcomeGiftShown")
        UserDefaults.standard.removeObject(forKey: "showFloatingGiftWidget")
        KeychainManager.shared.delete(forKey: "VIPTrialGifted")
        
        // 2. Reset promo keys if any
        let allKeys = UserDefaults.standard.dictionaryRepresentation().keys
        for key in allKeys {
            if key.hasPrefix("AIVO_100_CREDITS_CLAIMED_") {
                UserDefaults.standard.removeObject(forKey: key)
            }
        }
        // 3. Force check status to update UI
        Task {
            await refreshStatus()
        }
    }
    
    func stopVIPTrialAndGift() {
        Logger.i("🛑 stopVIPTrialAndGift: Expiring VIP trial and gift countdown instantly for debug")
        let pastDate = Date().addingTimeInterval(-10)
        UserDefaults.standard.set(pastDate, forKey: "VIPTrialExpiryDate")
        UserDefaults.standard.set(pastDate, forKey: "YearlyDiscountExpiryDate")
        Task {
            await refreshStatus()
        }
    }
    
    func grantVIPTrialAndCredits() {
        let isTrialGiftedLocal = UserDefaults.standard.bool(forKey: "VIPTrialGifted")
        let isTrialGiftedKey = KeychainManager.shared.getBool(forKey: "VIPTrialGifted")
        
        guard !isTrialGiftedLocal && !isTrialGiftedKey else {
            return
        }
        
        Logger.i("🎁 grantVIPTrialAndCredits: Manually granting 1 hour VIP Trial and credits")
        
        // 1. Mark as gifted in both UserDefaults and Keychain
        UserDefaults.standard.set(true, forKey: "VIPTrialGifted")
        KeychainManager.shared.saveBool(true, forKey: "VIPTrialGifted")
        
        // 2. Set expiry date (1 hour from now)
        let expiryDate = Date().addingTimeInterval(3600)
        UserDefaults.standard.set(expiryDate, forKey: "VIPTrialExpiryDate")
        
        // 3. Gift 60 credits
        let giftCredits = 60
        UserDefaults.standard.set(giftCredits, forKey: "VIPTrialGiftCreditsAmount")
        
        // Force check status to update UI
        Task {
            await CreditManager.shared.increaseCredits(by: 60)
            await refreshStatus()
        }
    }
}
