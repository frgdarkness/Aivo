//
//  SubscriptionManager.swift
//  Aivo
//
//  Created for managing subscription purchases
//

import Foundation
import StoreKit
import Combine

@MainActor
final class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()
    
    // MARK: - Published
    @Published var products: [Product] = []
    @Published var currentSubscription: SubscriptionInfo?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isPremium: Bool = false
    
    // MARK: - Product IDs
    enum ProductIdentifier: String, CaseIterable {
        case premiumWeekly = "aivo.premium.weekly"
        case premiumYearly = "aivo.premium.yearly"
        
        var creditsPerPeriod: Int {
            switch self {
            case .premiumWeekly: return 1000 // 1000 credits per week
            case .premiumYearly: return 1000 // 1000 credits per week (same for yearly)
            }
        }
        
        var period: SubscriptionInfo.SubscriptionPeriod {
            switch self {
            case .premiumWeekly: return .weekly
            case .premiumYearly: return .yearly
            }
        }
        
        var displayName: String {
            switch self {
            case .premiumWeekly: return "Weekly"
            case .premiumYearly: return "Yearly"
            }
        }
    }
    
    private let productIDs = Set(ProductIdentifier.allCases.map { $0.rawValue })
    
    // Listeners
    private var updatesTask: Task<Void, Never>?
    private var statusCheckTask: Task<Void, Never>?
    
    // Track processed transactions (persisted to UserDefaults)
    private func loadProcessedTransactionIDs() -> Set<String> {
        if let data = UserDefaults.standard.data(forKey: "ProcessedSubscriptionTransactionIDs"),
           let ids = try? JSONDecoder().decode([String].self, from: data) {
            return Set(ids)
        }
        return Set<String>()
    }
    
    private func saveProcessedTransactionIDs(_ ids: Set<String>) {
        let array = Array(ids)
        if let data = try? JSONEncoder().encode(array) {
            UserDefaults.standard.set(data, forKey: "ProcessedSubscriptionTransactionIDs")
        }
    }
    
    private var _processedTransactionIDs: Set<String>?
    
    private var processedTransactionIDs: Set<String> {
        get {
            if _processedTransactionIDs == nil {
                _processedTransactionIDs = loadProcessedTransactionIDs()
            }
            return _processedTransactionIDs ?? Set<String>()
        }
        set {
            _processedTransactionIDs = newValue
            saveProcessedTransactionIDs(newValue)
        }
    }
    
    private let profileSyncManager = ProfileSyncManager.shared
    private let localStorage = LocalStorageManager.shared
    
    // MARK: - Init
    private init() {
        Logger.i("SubscriptionManager init")
        Logger.d("SubscriptionManager: Loaded \(processedTransactionIDs.count) processed transaction IDs")
        observeTransactions()
        checkSubscriptionStatus()
        
        // Check and grant bonus credits for subscription on app start
        Task {
            await checkBonusCreditForSubscription()
        }
    }
    
    deinit {
        updatesTask?.cancel()
        statusCheckTask?.cancel()
    }
    
    // MARK: - Public API
    
    /// Fetch subscription products from App Store
    func fetchProducts() {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        Logger.i("fetchSubscriptionProducts: start for ids=\(Array(productIDs))")
        
        Task {
            do {
                let fetched = try await Product.products(for: Array(productIDs))
                self.products = fetched.sorted { lhs, rhs in
                    // Sort by period: weekly first, then yearly
                    let lhsPeriod = ProductIdentifier(rawValue: lhs.id)?.period ?? .weekly
                    let rhsPeriod = ProductIdentifier(rawValue: rhs.id)?.period ?? .weekly
                    return lhsPeriod == .weekly && rhsPeriod == .yearly
                }
                self.isLoading = false
                let productSummaries = self.products.map { "id=\($0.id), price=\($0.displayPrice)" }
                Logger.i("fetchSubscriptionProducts: success count=\(self.products.count) products=[\(productSummaries.joined(separator: "; "))]")
                if self.products.isEmpty {
                    Logger.w("fetchSubscriptionProducts: products list is empty")
                }
            } catch {
                self.isLoading = false
                self.errorMessage = "Failed to fetch products: \(error.localizedDescription)"
                Logger.e("fetchSubscriptionProducts: error=\(error.localizedDescription)")
            }
        }
    }
    
    /// Get product for a specific identifier
    func getProduct(for identifier: ProductIdentifier) -> Product? {
        return products.first { $0.id == identifier.rawValue }
    }
    
    /// Get credits amount for a subscription product
    func getCreditsPerPeriod(for product: Product) -> Int {
        guard let id = ProductIdentifier(rawValue: product.id) else { return 0 }
        return id.creditsPerPeriod
    }
    
    /// Get period for a subscription product
    func getPeriod(for product: Product) -> SubscriptionInfo.SubscriptionPeriod? {
        guard let id = ProductIdentifier(rawValue: product.id) else { return nil }
        return id.period
    }
    
    /// Purchase a subscription
    func purchaseSubscription(_ product: Product) async throws -> Bool {
        errorMessage = nil
        Logger.i("purchaseSubscription: start id=\(product.id) price=\(product.displayPrice)")
        
        // Check if user already has an active subscription
        await checkSubscriptionStatus() // Ensure status is up to date
        
        if isPremium, let currentSub = currentSubscription {
            let periodName = currentSub.period.displayName
            let expiryString: String
            if let expiryDate = currentSub.expiryDate {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                formatter.timeStyle = .none
                expiryString = formatter.string(from: expiryDate)
            } else {
                expiryString = "unknown"
            }
            
            errorMessage = "You already have an active \(periodName) subscription. It expires on \(expiryString)."
            Logger.w("purchaseSubscription: User already has active subscription - period=\(periodName), expires=\(expiryString)")
            NotificationCenter.default.post(
                name: NSNotification.Name("SubscriptionAlreadyActive"),
                object: nil,
                userInfo: ["period": periodName, "expiryDate": expiryString]
            )
            return false
        }
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verificationResult):
                switch verificationResult {
                case .unverified(_, let error):
                    Logger.w("purchaseSubscription: unverified error=\(error.localizedDescription)")
                    self.errorMessage = "Purchase could not be verified."
                    NotificationCenter.default.post(name: NSNotification.Name("SubscriptionPurchaseFailed"), object: nil)
                    return false
                case .verified(let transaction):
                    await handleVerifiedSubscriptionTransaction(transaction)
                    return true
                }
                
            case .userCancelled:
                Logger.w("purchaseSubscription: user cancelled for id=\(product.id)")
                NotificationCenter.default.post(name: NSNotification.Name("SubscriptionPurchaseCancelled"), object: nil)
                return false
                
            case .pending:
                Logger.i("purchaseSubscription: pending for id=\(product.id)")
                NotificationCenter.default.post(name: NSNotification.Name("SubscriptionPurchasePending"), object: nil)
                return false
                
            @unknown default:
                Logger.w("purchaseSubscription: unknown result for id=\(product.id)")
                return false
            }
        } catch {
            self.errorMessage = "Purchase failed: \(error.localizedDescription)"
            Logger.e("purchaseSubscription: error=\(error.localizedDescription) id=\(product.id)")
            NotificationCenter.default.post(name: NSNotification.Name("SubscriptionPurchaseFailed"), object: nil)
            throw error
        }
    }
    
    /// Check current subscription status
    func checkSubscriptionStatus() {
        Logger.i("checkSubscriptionStatus: start")
        
        statusCheckTask?.cancel()
        statusCheckTask = Task {
            do {
                // Check all current entitlements
                var activeSubscription: SubscriptionInfo?
                
                for await result in Transaction.currentEntitlements {
                    switch result {
                    case .verified(let transaction):
                        // Check if this is one of our subscription products
                        if productIDs.contains(transaction.productID) {
                            Logger.d("checkSubscriptionStatus: found subscription transaction id=\(transaction.id) productID=\(transaction.productID)")
                            
                            // Get product to access subscription info
                            let profile = localStorage.getLocalProfile()
                            var product = products.first(where: { $0.id == transaction.productID })
                            if product == nil {
                                product = await fetchProductByID(transaction.productID)
                            }
                            guard let product = product else {
                                Logger.w("checkSubscriptionStatus: product not found for id=\(transaction.productID)")
                                continue
                            }
                            
                            // Get subscription info from product
                            let period = ProductIdentifier(rawValue: transaction.productID)?.period ?? .weekly
                            let creditsPerPeriod = ProductIdentifier(rawValue: transaction.productID)?.creditsPerPeriod ?? 1200
                            
                            // Since transaction is in currentEntitlements, it means subscription is active
                            let subscriptionStatusValue: SubscriptionInfo.SubscriptionStatus = .active
                            
                            // Calculate expiry date based on period
                            // For subscriptions in currentEntitlements, calculate from purchase date
                            let calendar = Calendar.current
                            let expiryDate = calendar.date(byAdding: period == .weekly ? .day : .year, value: period == .weekly ? 7 : 1, to: transaction.purchaseDate)
                            let autoRenews = true // Default for auto-renewable subscriptions
                            
                            let info = SubscriptionInfo(
                                subscriptionID: UUID().uuidString,
                                profileID: profile.profileID,
                                productID: transaction.productID,
                                transactionID: String(transaction.id),
                                creditsPerPeriod: creditsPerPeriod,
                                period: period,
                                price: product.displayPrice,
                                currency: product.priceFormatStyle.currencyCode,
                                status: subscriptionStatusValue,
                                startDate: transaction.purchaseDate,
                                expiryDate: expiryDate,
                                autoRenews: autoRenews
                            )
                            
                            // Keep the most recent active subscription
                            if subscriptionStatusValue == .active {
                                if activeSubscription == nil || (info.expiryDate ?? Date.distantPast) > (activeSubscription?.expiryDate ?? Date.distantPast) {
                                    activeSubscription = info
                                }
                            }
                        }
                    case .unverified(_, let error):
                        Logger.w("checkSubscriptionStatus: unverified transaction error=\(error.localizedDescription)")
                    }
                }
                
                await MainActor.run {
                    self.currentSubscription = activeSubscription
                    self.isPremium = activeSubscription?.isActive ?? false
                    
                    // Update CreditManager premium status
                    if let subscription = activeSubscription, subscription.isActive {
                        // Update premium status but skip initial grant (only grant if weekly period has passed)
                        CreditManager.shared.updatePremiumStatus(true, period: subscription.period, skipInitialGrant: false)
                        
                        // Check and grant bonus credits if needed (separate from purchase flow)
                        Task {
                            await self.checkBonusCreditForSubscription()
                        }
                    } else {
                        CreditManager.shared.updatePremiumStatus(false)
                    }
                    
                    if let subscription = activeSubscription {
                        Logger.i("checkSubscriptionStatus: active subscription found period=\(subscription.period.rawValue) expires=\(subscription.expiryDate?.description ?? "never")")
                    } else {
                        Logger.i("checkSubscriptionStatus: no active subscription found")
                    }
                }
            } catch {
                Logger.e("checkSubscriptionStatus: error=\(error.localizedDescription)")
            }
        }
    }
    
    /// Get current active subscription
    func getCurrentSubscription() -> SubscriptionInfo? {
        return currentSubscription
    }
    
    /// Restore purchases
    func restorePurchases() {
        Logger.i("restorePurchases: start")
        Task {
            do {
                try await AppStore.sync()
                checkSubscriptionStatus() // Re-check after sync
                Logger.i("restorePurchases: success")
            } catch {
                self.errorMessage = "Restore failed: \(error.localizedDescription)"
                Logger.e("restorePurchases: error=\(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Private
    
    private func fetchProductByID(_ productID: String) async -> Product? {
        do {
            let products = try await Product.products(for: [productID])
            return products.first
        } catch {
            Logger.e("fetchProductByID: error=\(error.localizedDescription)")
            return nil
        }
    }
    
    /// Observe transaction updates
    private func observeTransactions() {
        Logger.i("subscriptionObserver: start listening to Transaction.updates")
        updatesTask = Task.detached { [weak self] in
            for await update in Transaction.updates {
                await self?.handleTransactionUpdate(update)
            }
        }
    }
    
    private func handleTransactionUpdate(_ verificationResult: VerificationResult<Transaction>) async {
        switch verificationResult {
        case .unverified(_, let error):
            Logger.w("subscriptionTxUpdate: unverified error=\(error.localizedDescription)")
            
        case .verified(let transaction):
            // Only handle subscription transactions
            // Check if product is in our subscription product IDs
            if productIDs.contains(transaction.productID) {
                Logger.i("subscriptionTxUpdate: verified subscription product_id=\(transaction.productID) transaction_id=\(transaction.id)")
                await handleVerifiedSubscriptionTransaction(transaction)
            }
        }
    }
    
    private func handleVerifiedSubscriptionTransaction(_ transaction: Transaction) async {
        let transactionID = String(transaction.id)
        
        // Check if already processed
        guard !processedTransactionIDs.contains(transactionID) else {
            Logger.w("handleVerifiedSubscriptionTx: transaction already processed id=\(transactionID)")
            // Still need to check status in case of renewal
            await checkSubscriptionStatus()
            return
        }
        
        // Get product
        var product = products.first(where: { $0.id == transaction.productID })
        if product == nil {
            product = await fetchProductByID(transaction.productID)
        }
        guard let product = product else {
            Logger.e("handleVerifiedSubscriptionTx: product not found id=\(transaction.productID)")
            await transaction.finish()
            return
        }
        
        let profile = localStorage.getLocalProfile()
        let period = ProductIdentifier(rawValue: transaction.productID)?.period ?? .weekly
        let creditsPerPeriod = ProductIdentifier(rawValue: transaction.productID)?.creditsPerPeriod ?? 1200
        
        // Check if this is a NEW purchase (user didn't have subscription before)
        let isNewPurchase = await MainActor.run { currentSubscription == nil || !isPremium }
        
        // For new purchases, assume active status
        // The actual status will be checked later via checkSubscriptionStatus()
        let subscriptionStatusValue: SubscriptionInfo.SubscriptionStatus = .active
        
        // Calculate expiry date based on period
        let calendar = Calendar.current
        let expiryDate = calendar.date(byAdding: period == .weekly ? .day : .year, value: period == .weekly ? 7 : 1, to: transaction.purchaseDate)
        let autoRenews = true // Default for auto-renewable subscriptions
        
        // Create SubscriptionInfo
        let info = SubscriptionInfo(
            subscriptionID: UUID().uuidString,
            profileID: profile.profileID,
            productID: transaction.productID,
            transactionID: String(transaction.id),
            creditsPerPeriod: creditsPerPeriod,
            period: period,
            price: product.displayPrice,
            currency: product.priceFormatStyle.currencyCode,
            status: subscriptionStatusValue,
            startDate: transaction.purchaseDate,
            expiryDate: expiryDate,
            autoRenews: autoRenews
        )
        
        Logger.i("handleVerifiedSubscriptionTx: subscription created product_id=\(transaction.productID) period=\(period.rawValue) credits=\(creditsPerPeriod) isNewPurchase=\(isNewPurchase)")
        
        // ONLY grant initial credits for NEW purchases, not renewals or restores
        if subscriptionStatusValue == .active && isNewPurchase {
            await grantInitialPurchaseCredits(amount: creditsPerPeriod)
        } else {
            Logger.i("subscriptionCreditsGranted: SKIPPED (not a new purchase) - isNewPurchase=\(isNewPurchase)")
        }
        
        // Mark as processed AFTER checking if it's new purchase
        var processed = processedTransactionIDs
        processed.insert(transactionID)
        processedTransactionIDs = processed
        
        // Update current subscription and premium status
        await MainActor.run {
            self.currentSubscription = info
            self.isPremium = info.isActive
            
            // Update CreditManager premium status
            // Skip initial grant because we already granted credits above
            if info.isActive {
                CreditManager.shared.updatePremiumStatus(true, period: period, skipInitialGrant: true)
            } else {
                CreditManager.shared.updatePremiumStatus(false)
            }
        }
        
        // Sync with Firebase
        await syncSubscriptionWithFirebase(subscription: info)
        
        // Sync profile
        do {
            try await profileSyncManager.syncProfileToRemote()
        } catch {
            Logger.e("SubscriptionManager: Failed to sync profile: \(error.localizedDescription)")
        }
        
        // Send notification
        NotificationCenter.default.post(name: NSNotification.Name("SubscriptionPurchaseSuccess"), object: nil)
        
        // For subscriptions, we don't finish immediately - let it renew
        // Only finish if it's expired or cancelled
        if subscriptionStatusValue == .expired {
            await transaction.finish()
        } else {
            // Check status periodically for renewals
            checkSubscriptionStatus()
        }
    }
    
    // MARK: - Credit Granting Logic
    
    /// Grant initial credits after successful purchase
    /// This is called ONLY once when user first purchases subscription
    private func grantInitialPurchaseCredits(amount: Int) async {
        Logger.i("grantInitialPurchaseCredits: Granting \(amount) credits for new subscription purchase")
        
        await CreditManager.shared.increaseCredits(by: amount)
        Logger.i("grantInitialPurchaseCredits: + \(amount) -> total=\(CreditManager.shared.credits)")
        
        // Set last grant date to now
        localStorage.setLastPremiumCreditGrantDate(Date())
        Logger.d("grantInitialPurchaseCredits: Last grant date set to \(Date())")
    }
    
    /// Check and grant bonus credits for subscription users
    /// This checks if 7 days have passed since last grant and grants weekly credits
    /// Should be called on app startup and after subscription status checks
    func checkBonusCreditForSubscription() async {
        Logger.i("checkBonusCreditForSubscription: Start checking")
        
        // Only check if user is premium
        guard isPremium, let subscription = currentSubscription else {
            Logger.d("checkBonusCreditForSubscription: User is not premium, skipping")
            return
        }
        
        // Check if should grant weekly credits
        guard localStorage.shouldGrantWeeklyCredits() else {
            if let lastGrantDate = localStorage.getLastPremiumCreditGrantDate() {
                let daysSinceLastGrant = Calendar.current.dateComponents([.day], from: lastGrantDate, to: Date()).day ?? 0
                Logger.d("checkBonusCreditForSubscription: Only \(daysSinceLastGrant) days since last grant, need 7 days")
            } else {
                Logger.d("checkBonusCreditForSubscription: No last grant date found")
            }
            return
        }
        
        // Grant weekly credits
        let creditsPerPeriod = subscription.creditsPerPeriod
        Logger.i("checkBonusCreditForSubscription: Granting \(creditsPerPeriod) weekly credits")
        
        await CreditManager.shared.increaseCredits(by: creditsPerPeriod)
        Logger.i("checkBonusCreditForSubscription: + \(creditsPerPeriod) -> total=\(CreditManager.shared.credits)")
        
        // Update last grant date
        localStorage.setLastPremiumCreditGrantDate(Date())
        Logger.d("checkBonusCreditForSubscription: Last grant date updated to \(Date())")
    }
    
    /// Sync subscription with Firebase Realtime Database
    private func syncSubscriptionWithFirebase(subscription: SubscriptionInfo) async {
        do {
            Logger.i("syncSubscription: start profileID=\(subscription.profileID) product_id=\(subscription.productID) period=\(subscription.period.rawValue)")
            
            // Save subscription to Firebase
            try await FirebaseRealtimeService.shared.saveSubscription(subscription)
            
            Logger.i("syncSubscription: success profileID=\(subscription.profileID) subscriptionID=\(subscription.subscriptionID)")
            
        } catch {
            Logger.e("syncSubscription: error=\(error.localizedDescription)")
        }
    }
}

