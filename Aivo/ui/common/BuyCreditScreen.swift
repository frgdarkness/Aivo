import SwiftUI
import StoreKit
import Foundation

struct BuyCreditScreen: View {
    let onDismiss: (() -> Void)?
    @State private var currentImageIndex = 0
    @State private var imageUrls: [String] = []
    @State private var animationTimer: Timer?
    @State private var selectedPackageIndex: Int? = nil
    @State private var isPurchasing = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    @ObservedObject private var storeManager = CreditStoreManager.shared

    /// Tỉ lệ chiều cao slide theo chiều cao màn hình
    private let slideHeightRatio: CGFloat = 0.45

    // Credit packages được tạo từ StoreKit products
    private var creditPackages: [CreditPackage] {
        // Nếu đang loading hoặc chưa có products, trả về default packages với giá N/A
        if storeManager.isLoading || storeManager.products.isEmpty {
            return [
                CreditPackage(credits: 500, price: "N/A", isPopular: false, product: nil),
                CreditPackage(credits: 1000, price: "N/A", isPopular: false, product: nil),
                CreditPackage(credits: 5000, price: "N/A", isPopular: true, product: nil)
            ]
        }
        
        // Map products → packages, then sort by credits ascending (500, 1000, 5000)
        let mapped: [CreditPackage] = storeManager.products.map { product in
            CreditPackage(
                credits: storeManager.getCredits(for: product),
                price: product.displayPrice,
                isPopular: false,
                product: product
            )
        }
        .sorted(by: { $0.credits < $1.credits })
        
        // Mark 5000 as popular
        var result = mapped
        if let maxIndex = result.indices.max(by: { result[$0].credits < result[$1].credits }) {
            result[maxIndex] = CreditPackage(
                credits: result[maxIndex].credits,
                price: result[maxIndex].price,
                isPopular: true,
                product: result[maxIndex].product
            )
        }
        return result
    }
    
    init(onDismiss: (() -> Void)? = nil) {
        self.onDismiss = onDismiss
        // Auto select 5000 on open (will set in onAppear when packages are loaded)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            GeometryReader { geo in
                let slideHeight = max(220, geo.size.height * slideHeightRatio)

                VStack(spacing: 0) {
                    // Header với nút X overlay trên image
                    ZStack(alignment: .topTrailing) {
                        // SLIDE ở TRÊN (full width, fill chiều cao đặt ra, không bo góc)
                        imageCarouselView
                            .frame(height: slideHeight)
                            .clipped()
                        
                        // Nút X overlay trên image
                        Button(action: { onDismiss?() }) {
                            Image(systemName: "xmark")
                                .foregroundColor(.white)
                                .font(.title2)
                                .padding(7)
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                        }
                        .padding(.top, 20) // Safe area padding
                        .padding(.trailing, 20)
                    }

                    // Benefits (gộp icon + text, căn giữa)
                    benefitsHeaderView
                        .padding(.top, 8)
                        .padding(.bottom, 6)

                    // Packages (card thấp hơn)
                    if storeManager.isLoading {
                        loadingPackagesView
                            .padding(.bottom, 10)
                    } else {
                        creditPackagesView
                            .padding(.bottom, 10)
                    }

                    // Continue
                    continueButton
                        .padding(.bottom, 20)
                }
                .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
            }
        }
        .onAppear {
            loadImageUrls()
            startImageAnimation()
            
            // Fetch products if not already loaded
            if storeManager.products.isEmpty && !storeManager.isLoading {
                storeManager.fetchProducts()
            }
            
            // Log screen view
            FirebaseLogger.shared.logScreenView(FirebaseLogger.EVENT_SCREEN_BUY_CREDIT)
            // Auto select 5000 when available
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                let pkgs = creditPackages
                if let idx = pkgs.firstIndex(where: { $0.credits == 5000 }) {
                    selectedPackageIndex = idx
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("PurchaseSuccess"))) { _ in
            // Handle successful purchase
            onDismiss?()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("PurchaseCancelled"))) { _ in
            // User cancelled purchase → reset processing state
            isPurchasing = false
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("PurchaseFailed"))) { _ in
            // Purchase failed/unverified → reset processing state and show error if available
            if let error = storeManager.errorMessage {
                errorMessage = error
                showingError = true
            }
            isPurchasing = false
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("PurchasePending"))) { _ in
            // Keep processing spinner for pending
            isPurchasing = true
        }
        .alert("Purchase Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .onDisappear {
            stopImageAnimation()
        }
    }

    // MARK: - Header
    private var headerView: some View {
        HStack {
            Spacer()
            Button(action: { onDismiss?() }) {
                Image(systemName: "xmark")
                    .foregroundColor(.white)
                    .font(.title2)
                    .padding(12) // Tăng vùng tap
                    .background(Color.black.opacity(0.3)) // Thêm background
                    .clipShape(Circle()) // Bo tròn
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    // MARK: - Slide (Carousel)
    private var imageCarouselView: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                ForEach(0..<imageUrls.count, id: \.self) { index in
                    Image(imageUrls[index])
                        .resizable()
                        .aspectRatio(contentMode: .fill) // fill tối đa
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                }
            }
            .offset(x: -CGFloat(currentImageIndex) * geometry.size.width)
            .animation(.easeInOut(duration: 0.8), value: currentImageIndex)
        }
    }

    private var benefitsHeaderView: some View {
        HStack {
            Spacer()
                VStack(alignment: .leading, spacing: 6) {
                    benefitLine(MyLocalizable.unlockAllFeatures.localized)
                    benefitLine(MyLocalizable.processedOnUltraServers.localized)
                    benefitLine(MyLocalizable.boostProcessingSpeed.localized)
                    benefitLine(MyLocalizable.premiumDesignQuality.localized)
                }
            .background(
                GeometryReader { geo in
                    Color.clear
                        .preference(key: WidthPreferenceKey.self, value: geo.size.width)
                }
            )
            .onPreferenceChange(WidthPreferenceKey.self) { width in
                benefitsWidth = width
            }
            .frame(width: benefitsWidth)
            Spacer()
        }
        .padding(.vertical, 12)
        .padding(.trailing, 12)
    }

    // MARK: - Benefit Line
    private func benefitLine(_ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Image(systemName: "checkmark.seal.fill")
                .foregroundColor(.green)
                .font(.system(size: 14, weight: .semibold))
            Text(text)
                .foregroundColor(.white)
                .font(.system(size: 15, weight: .medium))
                .multilineTextAlignment(.leading)
        }
    }

    // MARK: - PreferenceKey để đo chiều rộng cụm
    @State private var benefitsWidth: CGFloat? = nil

    private struct WidthPreferenceKey: PreferenceKey {
        static var defaultValue: CGFloat = 0
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
            value = max(value, nextValue())
        }
    }

    // MARK: - Loading Packages View
    private var loadingPackagesView: some View {
        VStack(spacing: 10) {
            ForEach(0..<3, id: \.self) { index in
                loadingPackageRow(index: index)
            }
        }
        .padding(.horizontal, 20)
    }
    
    private func loadingPackageRow(index: Int) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(LinearGradient(colors: [Color.gray.opacity(0.18), Color.gray.opacity(0.18)],
                                     startPoint: .leading, endPoint: .trailing))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                   Text(MyLocalizable.loading.localized)
                       .font(.system(size: 16, weight: .bold))
                       .foregroundColor(.white.opacity(0.6))
                }
                Spacer()
                Text("N/A")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
        .frame(height: 58)
    }

    // MARK: - Packages (card thấp hơn)
    private var creditPackagesView: some View {
        VStack(spacing: 10) {
            ForEach(Array(creditPackages.enumerated()), id: \.element.credits) { index, package in
                creditPackageRow(package: package, index: index)
            }
        }
        .padding(.horizontal, 20)
    }

    private func creditPackageRow(package: CreditPackage, index: Int) -> some View {
        let isSelected = selectedPackageIndex == index

        return Button(action: { selectedPackageIndex = index }) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        AnyShapeStyle(
                            isSelected
                            ? LinearGradient(colors: [Color.red.opacity(0.35), Color.red.opacity(0.18)],
                                             startPoint: .leading, endPoint: .trailing)
                            : LinearGradient(colors: [Color.gray.opacity(0.18), Color.gray.opacity(0.18)],
                                             startPoint: .leading, endPoint: .trailing)
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.red : Color.gray.opacity(0.3), lineWidth: 1)
                    )

                // Popular badge
                if package.isPopular {
                    VStack {
                        HStack {
                            Spacer()
                       Text(MyLocalizable.bestOffer.localized)
                           .font(.system(size: 10, weight: .bold))
                           .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.red)
                                .cornerRadius(8)
                                .offset(x: -10, y: -4)
                        }
                        Spacer()
                    }
                }

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                   Text("\(package.credits) \(MyLocalizable.credits.localized)")
                       .font(.system(size: 16, weight: .bold))
                       .foregroundColor(.white)

                        if package.isPopular {
                            Text(MyLocalizable.mostPopular.localized)
                                .font(.system(size: 12.5, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    Spacer()
                    Text(package.price)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
            }
        }
        .frame(height: 58) // card thấp hơn
        .buttonStyle(.plain)
    }

    // MARK: - Continue
    private var continueButton: some View {
        Button(action: {
            handlePurchase()
        }) {
            HStack {
                if isPurchasing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                }
                Spacer()
                   Text(isPurchasing ? MyLocalizable.processing.localized : MyLocalizable.continueAction.localized)
                       .font(.system(size: 17, weight: .semibold))
                       .foregroundColor(.white)
                Spacer()
                if !isPurchasing {
                    Image(systemName: "arrow.right")
                        .foregroundColor(.white)
                        .font(.system(size: 17, weight: .semibold))
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(selectedPackageIndex != nil ? Color.red : Color.gray)
            .cornerRadius(12)
        }
        .disabled(selectedPackageIndex == nil || isPurchasing || storeManager.isLoading)
        .padding(.horizontal, 20)
        .padding(.top, 4)
    }
    
    // MARK: - Purchase Handler
    private func handlePurchase() {
        guard let selectedIndex = selectedPackageIndex,
              selectedIndex < creditPackages.count else {
            return
        }
        
        let package = creditPackages[selectedIndex]
        
        // Kiểm tra xem có product hợp lệ không
        guard let product = package.product else {
               errorMessage = MyLocalizable.productNotAvailable.localized
            showingError = true
            return
        }
        
        isPurchasing = true
        
        storeManager.purchaseProduct(product)
        
        // Monitor for errors
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if let error = storeManager.errorMessage {
                errorMessage = error
                showingError = true
                isPurchasing = false
            }
        }
    }

    // MARK: - Data / Timer
    private func loadImageUrls() {
        // Load local pro images from Assets (pro1, pro2, ..., pro14)
        imageUrls = (1...5).map { "pro\($0)" }
    }

    private func startImageAnimation() {
        guard !imageUrls.isEmpty else { return }
        animationTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.8)) {
                currentImageIndex = (currentImageIndex + 1) % imageUrls.count
            }
        }
    }

    private func stopImageAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
    }
}

struct CreditPackage {
    let credits: Int
    let price: String
    let isPopular: Bool
    let product: Product?
}

#Preview {
    BuyCreditScreen {
        Logger.d("Dismissed")
    }
}
