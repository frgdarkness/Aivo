//
//  BuyCreditDialog.swift
//  Aivo
//
//  Created by AI Assistant
//

import SwiftUI
import StoreKit
import UIKit

// MARK: - Buy Credit Dialog Modifier
struct BuyCreditDialogModifier: ViewModifier {
    @Binding var isPresented: Bool
    @ObservedObject private var storeManager = CreditStoreManager.shared
    @ObservedObject private var creditManager = CreditManager.shared
    
    @State private var selectedPackageIndex: Int? = nil
    @State private var isPurchasing = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if isPresented {
                // Nền mờ tối
                Rectangle()
                    .fill(Color.black.opacity(0.75))
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture { 
                        withAnimation(.spring()) { isPresented = false } 
                    }
                
                // Dialog Card
                BuyCreditDialogCard(
                    onClose: { 
                        withAnimation(.spring()) { isPresented = false } 
                    },
                    selectedPackageIndex: $selectedPackageIndex,
                    isPurchasing: $isPurchasing,
                    onPurchase: handlePurchase,
                    storeManager: storeManager,
                    creditManager: creditManager
                )
                .padding(.horizontal, 24)
                .transition(.scale.combined(with: .opacity))
                .zIndex(1)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.88, blendDuration: 0.2), value: isPresented)
        .onChange(of: isPresented) { newValue in
            if newValue {
                // Fetch products when dialog opens
                if storeManager.products.isEmpty && !storeManager.isLoading {
                    storeManager.fetchProducts()
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("PurchaseSuccess"))) { _ in
            // Handle successful purchase
            isPurchasing = false
            withAnimation(.spring()) { 
                isPresented = false 
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("PurchaseCancelled"))) { _ in
            // User cancelled purchase
            isPurchasing = false
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("PurchaseFailed"))) { _ in
            // Purchase failed
            if let error = storeManager.errorMessage {
                errorMessage = error
                showingError = true
            }
            isPurchasing = false
        }
        .alert("Purchase Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func autoSelect5000Package() {
        let creditPackages = getCreditPackages()
        // Find index of 5000 credits package
        if let index = creditPackages.firstIndex(where: { $0.credits == 5000 }) {
            selectedPackageIndex = index
        }
    }
    
    private func handlePurchase() {
        guard let selectedIndex = selectedPackageIndex else { return }
        
        let creditPackages = getCreditPackages()
        guard selectedIndex < creditPackages.count else { return }
        
        let package = creditPackages[selectedIndex]
        
        guard let product = package.product else {
            errorMessage = "Product not available. Please try again later."
            showingError = true
            return
        }
        
        isPurchasing = true
        storeManager.purchaseProduct(product)
        
        // Log Firebase event
        FirebaseLogger.shared.logEventWithBundle("event_buy_credit", parameters: [
            "credits": package.credits,
            "price": package.price,
            "timestamp": Date().timeIntervalSince1970
        ])
    }
    
    private func getCreditPackages() -> [BuyCreditDialogPackage] {
        if storeManager.isLoading || storeManager.products.isEmpty {
            return [
                BuyCreditDialogPackage(credits: 500, price: "Loading...", originalPrice: nil, isPopular: false, product: nil),
                BuyCreditDialogPackage(credits: 1000, price: "Loading...", originalPrice: nil, isPopular: false, product: nil),
                BuyCreditDialogPackage(credits: 5000, price: "Loading...", originalPrice: nil, isPopular: true, product: nil)
            ]
        }
        
        let mapped: [BuyCreditDialogPackage] = storeManager.products.map { product in
            BuyCreditDialogPackage(
                credits: storeManager.getCredits(for: product),
                price: product.displayPrice,
                originalPrice: nil,
                isPopular: false,
                product: product
            )
        }
        .sorted(by: { $0.credits < $1.credits })
        
        // Mark 5000 as popular and calculate original price
        var result = mapped
        if let maxIndex = result.indices.max(by: { result[$0].credits < result[$1].credits }) {
            // Find 500 credits product to calculate original price
            let credits500Product = result.first { $0.credits == 500 }
            let originalPrice = calculateOriginalPriceFor5000(from: credits500Product, formatLike: result[maxIndex].product)
            
            result[maxIndex] = BuyCreditDialogPackage(
                credits: result[maxIndex].credits,
                price: result[maxIndex].price,
                originalPrice: originalPrice,
                isPopular: true,
                product: result[maxIndex].product
            )
        }
        return result
    }
    
    // Calculate original price for 5000 credits (500 credits × 10)
    private func calculateOriginalPriceFor5000(from credits500Product: BuyCreditDialogPackage?, formatLike product: Product?) -> String? {
        guard let credits500 = credits500Product,
              let product500 = credits500.product,
              let product5000 = product else {
            return nil
        }
        
        // Calculate original price = 500 credits price × 10
        let price500 = product500.price
        let multiplier = NSDecimalNumber(value: 10)
        let originalAmount = NSDecimalNumber(decimal: price500).multiplying(by: multiplier)
        
        // Format using product5000's format style
        let formatted = originalAmount.decimalValue.formatted(product5000.priceFormatStyle)
        return formatted
    }
}

extension View {
    /// Buy credit dialog modifier
    func buyCreditDialog(isPresented: Binding<Bool>) -> some View {
        self.modifier(BuyCreditDialogModifier(isPresented: isPresented))
    }
}

// MARK: - Dialog Card
private struct BuyCreditDialogCard: View {
    let onClose: () -> Void
    @Binding var selectedPackageIndex: Int?
    @Binding var isPurchasing: Bool
    let onPurchase: () -> Void
    @ObservedObject var storeManager: CreditStoreManager
    @ObservedObject var creditManager: CreditManager
    @ObservedObject private var remoteConfig = RemoteConfigManager.shared
    
    private func autoSelect5000Package() {
        let packages = creditPackages
        // Find index of 5000 credits package
        if let index = packages.firstIndex(where: { $0.credits == 5000 }) {
            selectedPackageIndex = index
        }
    }
    
    private var creditPackages: [BuyCreditDialogPackage] {
        if storeManager.isLoading || storeManager.products.isEmpty {
            return [
                BuyCreditDialogPackage(credits: 500, price: "Loading...", originalPrice: nil, isPopular: false, product: nil),
                BuyCreditDialogPackage(credits: 1000, price: "Loading...", originalPrice: nil, isPopular: false, product: nil),
                BuyCreditDialogPackage(credits: 5000, price: "Loading...", originalPrice: nil, isPopular: true, product: nil)
            ]
        }
        
        let mapped: [BuyCreditDialogPackage] = storeManager.products.map { product in
            BuyCreditDialogPackage(
                credits: storeManager.getCredits(for: product),
                price: product.displayPrice,
                originalPrice: nil,
                isPopular: false,
                product: product
            )
        }
        .sorted(by: { $0.credits < $1.credits })
        
        // Mark 5000 as popular and calculate original price
        var result = mapped
        if let maxIndex = result.indices.max(by: { result[$0].credits < result[$1].credits }) {
            // Find 500 credits product to calculate original price
            let credits500Product = result.first { $0.credits == 500 }
            let originalPrice = calculateOriginalPriceFor5000(from: credits500Product, formatLike: result[maxIndex].product)
            
            result[maxIndex] = BuyCreditDialogPackage(
                credits: result[maxIndex].credits,
                price: result[maxIndex].price,
                originalPrice: originalPrice,
                isPopular: true,
                product: result[maxIndex].product
            )
        }
        return result
    }
    
    // Calculate original price for 5000 credits (500 credits × 10)
    private func calculateOriginalPriceFor5000(from credits500Product: BuyCreditDialogPackage?, formatLike product: Product?) -> String? {
        guard let credits500 = credits500Product,
              let product500 = credits500.product,
              let product5000 = product else {
            return nil
        }
        
        // Calculate original price = 500 credits price × 10
        let price500 = product500.price
        let multiplier = NSDecimalNumber(value: 10)
        let originalAmount = NSDecimalNumber(decimal: price500).multiplying(by: multiplier)
        
        // Format using product5000's format style
        let formatted = originalAmount.decimalValue.formatted(product5000.priceFormatStyle)
        return formatted
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Main content
            VStack(spacing: 20) {
                // Header
                HStack {
                    Text("Buy Credits")
                        .font(.system(size: 26, weight: .heavy))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.4), radius: 4, x: 0, y: 2)
                    
                    Image("icon_coin")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                    Spacer()
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white.opacity(0.7))
                            .frame(width: 32, height: 32)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 8)
                
                // Credit Packages
                if storeManager.isLoading {
                    VStack(spacing: 14) {
                        ForEach(0..<3, id: \.self) { _ in
                            loadingPackageRow
                        }
                    }
                } else {
                    VStack(spacing: 14) {
                        ForEach(Array(creditPackages.enumerated()), id: \.element.credits) { index, package in
                            creditPackageRow(package: package, index: index)
                        }
                    }
                }
                
                // Purchase Button
                Button(action: onPurchase) {
                    HStack {
                        if isPurchasing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        }
                        Text(isPurchasing ? "Processing..." : "Purchase")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        selectedPackageIndex != nil && !storeManager.isLoading
                            ? LinearGradient(
                                colors: [AivoTheme.Primary.orange, AivoTheme.Primary.orange.opacity(0.85)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            : LinearGradient(
                                colors: [Color.gray.opacity(0.5), Color.gray.opacity(0.5)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(selectedPackageIndex == nil || isPurchasing || storeManager.isLoading)
                .buttonStyle(.plain)
            }
            
            // Footer - Terms of Use and Privacy Policy
            footer
                .padding(.top, 16)
        }
        .padding(20)
        .background(
            ZStack {
                // Full đen background
                Color.black
                
                // Ánh cam đậm dần ở phía dưới
                VStack {
                    Spacer()
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: Color.clear, location: 0.0),
                            .init(color: AivoTheme.Primary.orange.opacity(0.15), location: 0.5),
                            .init(color: AivoTheme.Primary.orange.opacity(0.35), location: 1.0)
                        ]),
                        startPoint: .center,
                        endPoint: .bottom
                    )
                    .frame(height: 200)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.85, blue: 0.4), // Vàng (goldenSun)
                            Color(red: 1.0, green: 0.75, blue: 0.2)  // Vàng cam
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        )
        .shadow(color: .black.opacity(0.6), radius: 30, x: 0, y: 15)
        .shadow(color: AivoTheme.Primary.orange.opacity(0.2), radius: 40, x: 0, y: 20)
        .onAppear {
            // Auto select 5000 credits package when dialog appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                autoSelect5000Package()
            }
        }
        .onChange(of: storeManager.products) { _ in
            // Auto select 5000 credits package when products are loaded
            if !storeManager.products.isEmpty && !storeManager.isLoading {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    autoSelect5000Package()
                }
            }
        }
    }
    
    // MARK: - Footer
    private var footer: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                Button(action: {
                    openTermsUrl()
                }) {
                    Text("Terms of use")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .underline()
                }
                
                Text("|")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
                
                Button(action: {
                    openPrivacyPolicyUrl()
                }) {
                    Text("Privacy Policy")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .underline()
                }
            }
            .padding(.bottom, 4)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Open URL Methods
    private func openTermsUrl() {
        if let url = URL(string: remoteConfig.termsUrl) {
            UIApplication.shared.open(url)
            Logger.d("📱 [BuyCreditDialog] Opening Terms URL: \(remoteConfig.termsUrl)")
        } else {
            Logger.e("❌ [BuyCreditDialog] Invalid Terms URL: \(remoteConfig.termsUrl)")
        }
    }
    
    private func openPrivacyPolicyUrl() {
        if let url = URL(string: remoteConfig.privacyPolicyUrl) {
            UIApplication.shared.open(url)
            Logger.d("📱 [BuyCreditDialog] Opening Privacy Policy URL: \(remoteConfig.privacyPolicyUrl)")
        } else {
            Logger.e("❌ [BuyCreditDialog] Invalid Privacy Policy URL: \(remoteConfig.privacyPolicyUrl)")
        }
    }
    
    private var loadingPackageRow: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.white.opacity(0.06))
            .frame(height: 64)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
            .overlay(
                HStack {
                    // Radio placeholder
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                        .frame(width: 22, height: 22)
                        .padding(.leading, 18)
                    
                    Text("Loading...")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                    Spacer()
                    Text("N/A")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.trailing, 16)
                }
            )
    }
    
    private func creditPackageRow(package: BuyCreditDialogPackage, index: Int) -> some View {
        let isSelected = selectedPackageIndex == index
        
        return ZStack(alignment: .topTrailing) {
            Button(action: {
                selectedPackageIndex = index
            }) {
                HStack {
                    // Radio button
                    ZStack {
                        Circle()
                            .stroke(AivoTheme.Primary.orange, lineWidth: 2)
                            .frame(width: 22, height: 22)
                        if isSelected {
                            Circle()
                                .fill(AivoTheme.Primary.orange)
                                .frame(width: 14, height: 14)
                        }
                    }
                    .padding(.leading, 18)
                    
                    // Credit amount with icon (no "Credits" text)
                    HStack(spacing: 6) {
                        Text("\(package.credits)")
                            .foregroundColor(.white)
                            .font(.system(size: 18, weight: .semibold))
                    }
                    
                    Spacer()
                    
                    // Price section with original price for 5000 credits
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        if let originalPrice = package.originalPrice {
                            // Original price with strikethrough
                            Text(originalPrice)
                                .foregroundColor(.white.opacity(0.5))
                                .font(.system(size: 16, weight: .regular))
                                .strikethrough()
                        }
                        
                        // Current price
                        Text(package.price)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        AivoTheme.Secondary.goldenSun,
                                        AivoTheme.Primary.orange
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .font(.system(size: package.originalPrice != nil ? 22 : 18, weight: .bold))
                            .shadow(color: AivoTheme.Primary.orange.opacity(0.5), radius: 2, x: 0, y: 1)
                    }
                    .padding(.trailing, 16)
                }
                .frame(height: 64)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.06))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(isSelected ? AivoTheme.Primary.orange : Color.white.opacity(0.15), lineWidth: 2)
                        )
                )
            }
            .buttonStyle(.plain)
            
            // Popular badge (BEST tag)
            if package.isPopular {
                tagView("BEST")
                    .padding(.trailing, 12)
                    .padding(.top, -8)
            }
        }
    }
    
    private func tagView(_ text: String) -> some View {
        let gradient = LinearGradient(
            colors: [
                Color(red: 1.0, green: 0.1, blue: 0.1),
                Color(red: 1.0, green: 0.25, blue: 0.0)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
        return Text(text)
            .font(.system(size: 12, weight: .heavy))
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                Capsule().fill(gradient)
            )
            .overlay(
                Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: AivoTheme.Shadow.black.opacity(0.4), radius: 6, x: 0, y: 3)
    }
}

// MARK: - Credit Package Model
fileprivate struct BuyCreditDialogPackage {
    let credits: Int
    let price: String
    let originalPrice: String?
    let isPopular: Bool
    let product: Product?
}

// MARK: - Preview
struct BuyCreditDialog_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            // Background
            AivoTheme.Background.primary
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                Text("Tap to show dialog")
                    .foregroundColor(.white)
                    .padding()
                Spacer()
            }
            .buyCreditDialog(isPresented: .constant(true))
        }
    }
}

