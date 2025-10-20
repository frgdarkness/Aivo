//
//  CreditStoreManager.swift
//  DreamHomeAI
//
//  Converted to StoreKit 2 by AI Assistant
//

import Foundation
import StoreKit
import UIKit

@MainActor
final class CreditStoreManager: ObservableObject {
    static let shared = CreditStoreManager()

    // MARK: - Published
    @Published var products: [Product] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Product IDs
    enum ProductIdentifier: String, CaseIterable {
        
        case credits500  = "APP_500_CREDITS_LOCAL"
        case credits1000 = "APP_1000_CREDITS_LOCAL"
        case credits5000 = "APP_5000_CREDITS_LOCAL"
        
//        case credits500  = "DECORA_500_CREDITS_LOCAL"
//        case credits1000 = "DECORA_1000_CREDITS_LOCAL"
//        case credits5000 = "DECORA_5000_CREDITS_LOCAL"

        var credits: Int {
            switch self {
            case .credits500:  return 500
            case .credits1000: return 1000
            case .credits5000: return 5000
            }
        }
    }

    private let productIDs = Set(ProductIdentifier.allCases.map { $0.rawValue })

    // Lắng nghe giao dịch nền
    private var updatesTask: Task<Void, Never>?
    
    // Track processed transactions to avoid duplicates
    private var processedTransactionIDs = Set<String>()

    // MARK: - Init
    private init() {
        Logger.i("CreditStoreManager init")
        observeTransactions()
    }

    deinit {
        updatesTask?.cancel()
    }
    
    /// Clean up old processed transaction IDs to prevent memory leak
    private func cleanupProcessedTransactions() {
        // Keep only last 100 transaction IDs to prevent memory leak
        if processedTransactionIDs.count > 100 {
            let sortedIDs = Array(processedTransactionIDs).sorted()
            let keepCount = 50
            processedTransactionIDs = Set(sortedIDs.suffix(keepCount))
        }
    }

    // MARK: - Public API

    /// Tải danh sách sản phẩm từ App Store
    func fetchProducts() {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        Logger.i("fetchProducts: start for ids=\(Array(productIDs))")

        Task {
            do {
                let fetched = try await Product.products(for: Array(productIDs))
                // Sắp xếp theo giá hiển thị tăng dần (nếu cần)
                self.products = fetched.sorted { lhs, rhs in
                    // displayPrice là String đã định dạng theo locale; để ổn định hơn có thể sort theo giá trị decimal
                    // nhưng StoreKit 2 không expose raw số trực tiếp => dùng id order hoặc để nguyên.
                    lhs.id < rhs.id
                }
                self.isLoading = false
                let productSummaries = self.products.map { "id=\($0.id), price=\($0.displayPrice)" }
                Logger.i("fetchProducts: success count=\(self.products.count) products=[\(productSummaries.joined(separator: "; "))]")
                if self.products.isEmpty {
                    Logger.w("fetchProducts: products list is empty")
                }
            } catch {
                self.isLoading = false
                self.errorMessage = "Failed to fetch products: \(error.localizedDescription)"
                Logger.e("fetchProducts: error=\(error.localizedDescription)")
            }
        }
    }

    /// Mua 1 sản phẩm (tiêu hao – consumable)
    func purchaseProduct(_ product: Product) {
        errorMessage = nil
        Logger.i("purchaseProduct: start id=\(product.id) price=\(product.displayPrice) credits=\(getCredits(for: product))")

        Task {
            do {
                let result = try await product.purchase()

                switch result {
                case .success(let verificationResult):
                    switch verificationResult {
                    case .unverified(_, let error):
                        // Không tin cậy
                        Logger.w("purchaseProduct: unverified error=\(error.localizedDescription)")
                        self.errorMessage = "Purchase could not be verified."
                        NotificationCenter.default.post(name: NSNotification.Name("PurchaseFailed"), object: nil)
                    case .verified(let transaction):
                        await handleVerifiedTransaction(transaction)
                    }

                case .userCancelled:
                    Logger.w("purchaseProduct: user cancelled for id=\(product.id)")
                    NotificationCenter.default.post(name: NSNotification.Name("PurchaseCancelled"), object: nil)

                case .pending:
                    Logger.i("purchaseProduct: pending for id=\(product.id)")
                    NotificationCenter.default.post(name: NSNotification.Name("PurchasePending"), object: nil)

                @unknown default:
                    Logger.w("purchaseProduct: unknown result for id=\(product.id)")
                }
            } catch {
                self.errorMessage = "Purchase failed: \(error.localizedDescription)"
                Logger.e("purchaseProduct: error=\(error.localizedDescription) id=\(product.id)")
            }
        }
    }

    /// Khôi phục giao dịch (chủ yếu hữu ích cho non-consumable/subscription;
    /// với credits tiêu hao thì thường không restore)
    func restorePurchases() {
        Logger.i("restorePurchases: start")
        Task {
            do {
                try await AppStore.sync()
                Logger.i("restorePurchases: success")
            } catch {
                self.errorMessage = "Restore failed: \(error.localizedDescription)"
                Logger.e("restorePurchases: error=\(error.localizedDescription)")
            }
        }
    }

    /// Map product -> số credits
    func getCredits(for product: Product) -> Int {
        guard let id = ProductIdentifier(rawValue: product.id) else { return 0 }
        let credits = id.credits
        // Avoid spamming logs here; this is called often during view recomputations
        return credits
    }

    // MARK: - Private

    /// Lắng nghe mọi giao dịch được cập nhật trong nền (mua từ App Store, Family sharing, v.v.)
    private func observeTransactions() {
        Logger.i("txObserver: start listening to Transaction.updates")
        updatesTask = Task.detached { [weak self] in
            for await update in Transaction.updates {
                await self?.handleTransactionUpdate(update)
            }
        }
    }

    private func handleTransactionUpdate(_ verificationResult: VerificationResult<Transaction>) async {
        switch verificationResult {
        case .unverified(_, let error):
            Logger.w("txUpdate: unverified error=\(error.localizedDescription)")

        case .verified(let transaction):
            Logger.i("txUpdate: verified product_id=\(transaction.productID) \(transaction.id) \(transaction.appTransactionID)")
            await handleVerifiedTransaction(transaction)
        }
    }

    private func handleVerifiedTransaction(_ transaction: Transaction) async {
        // Check if transaction already processed to avoid duplicates
        let transactionID = String(transaction.id)
        Logger.d("handleVerifiedTx: transactionID=\(transactionID) processed=\(processedTransactionIDs)")
        guard !processedTransactionIDs.contains(transactionID) else {
            Logger.w("handleVerifiedTx: transaction already processed id=\(transactionID)")
            await transaction.finish()
            return
        }
        
        // Mark transaction as processed
        processedTransactionIDs.insert(transactionID)
        
        // Clean up old transactions periodically
        cleanupProcessedTransactions()
        
        // Với consumable, bạn cấp credit ngay và finish().
        // productID:
        let productID = transaction.productID
        let credits = ProductIdentifier(rawValue: productID)?.credits ?? 0
        Logger.i("handleVerifiedTx: product_id=\(productID) credits=\(credits) transaction_id=\(transactionID)")

        if credits > 0 {
            // Update local credits
            
            await CreditManager.shared.increaseCredits(by: credits)
            Logger.i("creditsGranted: + \(credits) -> total=\(CreditManager.shared.credits)")
            
            do {
                try await ProfileSyncManager.shared.syncProfileToRemote()
            } catch {
                Logger.e("CreditManager: Failed to handle purchase sync: \(error.localizedDescription)")
            }
            
            // Sync with Firebase Realtime Database
            await syncPurchaseWithFirebase(transaction: transaction, credits: credits)

            Logger.i("purchaseSuccess: product_id=\(productID) total_credits=\(CreditManager.shared.credits)")

            // Thông báo UI
            NotificationCenter.default.post(name: NSNotification.Name("PurchaseSuccess"), object: nil)
        } else {
            Logger.w("handleVerifiedTx: unknown product id=\(productID) → credits=0")
        }

        // Quan trọng: kết thúc giao dịch
        await transaction.finish()
    }
    
    /// Sync purchase with Firebase Realtime Database
    private func syncPurchaseWithFirebase(transaction: Transaction, credits: Int) async {
        do {
            // Get or create user profile
            let profile = LocalStorageManager.shared.getLocalProfile()
            
            // Find the product to get price information
            guard let product = products.first(where: { $0.id == transaction.productID }) else {
                Logger.w("syncPurchase: product not found id=\(transaction.productID)")
                return
            }
            
            Logger.i("syncPurchase: start profileID=\(profile.profileID) product_id=\(product.id) price=\(product.displayPrice) credits=\(credits)")

            // Create purchase record
            let purchase = PurchaseConsumable.fromStoreKitTransaction(
                transaction,
                profileID: profile.profileID,
                product: product,
                creditsAmount: credits
            )
            
            // Save purchase to Firebase
            try await FirebaseRealtimeService.shared.savePurchase(purchase)
            
            // Update profile credits
            //try await FirebaseRealtimeService.shared.updateCreditsAfterPurchase(creditsAmount: credits)
            
            Logger.i("syncPurchase: success profileID=\(profile.profileID) purchaseID=\(purchase.purchaseID) credits=\(credits)")
            
        } catch {
            Logger.e("syncPurchase: error=\(error.localizedDescription)")
        }
    }
}
