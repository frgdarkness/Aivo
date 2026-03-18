import SwiftUI
import StoreKit

struct SubscriptionScreen: View {
    let onDismiss: (() -> Void)?
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @ObservedObject private var creditManager = CreditManager.shared
    @State private var selectedPlan: Plan = .yearly
    @State private var isPurchasing = false
    @State private var showPurchaseError = false
    @State private var showAlreadySubscribedAlert = false
    @State private var alreadySubscribedMessage = ""
    @State private var purchaseErrorMessage = ""
    @State private var buttonScale: CGFloat = 1.0
    @State private var glowIntensity: Double = 0.5
    @State private var showBuyCreditDialog = false

    init(onDismiss: (() -> Void)? = nil) {
        self.onDismiss = onDismiss
    }

    enum Plan { case yearly, weekly }

    var body: some View {
        ZStack {
            customBackgroundView

            VStack(spacing: 0) {
                header
                Spacer(minLength: 6)
                
                // Scrollable content area
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Cover tròn hiển thị tĩnh
                        coverImage
                            .padding(.top, 2)
                            .padding(.bottom, 20)
                        
                        if subscriptionManager.isPremium, let currentSub = subscriptionManager.currentSubscription {
                            // Active subscription view
                            activeSubscriptionView(subscription: currentSub)
                        } else {
                            // Purchase view
                            purchaseView
                        }
                    }
                    .padding(.horizontal, iPadScaleSmall(20))
                }
                
                // Footer
                footer
                    .padding(.horizontal, iPadScaleSmall(20))
                    .padding(.bottom, iPadScaleSmall(24))
            }
        }
        .ignoresSafeArea()
        .background(AivoTheme.Background.primary.ignoresSafeArea())
        .buyCreditDialog(isPresented: $showBuyCreditDialog)
        .onAppear {
            // Log screen view
            AnalyticsLogger.shared.logScreenView(AnalyticsLogger.EVENT.EVENT_SCREEN_SUBSCRIPTION)
            
            Task {
                await subscriptionManager.fetchProducts()
                await subscriptionManager.refreshStatus()
            }
        }
        .alert("Purchase Error", isPresented: $showPurchaseError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(purchaseErrorMessage)
        }
        .alert("Already Subscribed", isPresented: $showAlreadySubscribedAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alreadySubscribedMessage)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SubscriptionPurchaseSuccess"))) { _ in
            // Handle successful purchase
            isPurchasing = false
            // Mark subscription prompt as shown since user now has subscription
            UserDefaultsManager.shared.markSubscriptionPromptShown()
            onDismiss?()
            dismiss()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SubscriptionPurchaseFailed"))) { _ in
            // Handle failed purchase
            isPurchasing = false
            if let errorMsg = subscriptionManager.errorMessage, !errorMsg.isEmpty {
                purchaseErrorMessage = errorMsg
                showPurchaseError = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SubscriptionAlreadyActive"))) { notification in
            // Handle already subscribed case
            isPurchasing = false
            if let userInfo = notification.userInfo,
               let period = userInfo["period"] as? String,
               let expiryDate = userInfo["expiryDate"] as? String {
                alreadySubscribedMessage = "You already have an active \(period) subscription.\nIt expires on \(expiryDate)."
            } else {
                alreadySubscribedMessage = "You already have an active subscription. Please check your subscription status."
            }
            showAlreadySubscribedAlert = true
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SubscriptionPurchaseCancelled"))) { _ in
            // Handle cancelled purchase
            isPurchasing = false
        }
    }

    // MARK: - Background giống PlayMySongScreen (nửa trên ảnh, dưới đen, overlay gradient)
    private var customBackgroundView: some View {
        GeometryReader { geometry in
            ZStack {
                // Nửa trên: Ảnh cover (không blur)
                VStack {
                    Image("demo_cover")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.height * 0.6)
                        .clipped()

                    Spacer()
                }

                // Nửa dưới: Đen theo theme
                VStack {
                    Spacer()
                    AivoTheme.Primary.blackOrangeDark
                        .opacity(0.9)
                        .frame(height: geometry.size.height * 0.4)
                }

                // Overlay đen dần từ đỉnh đến cuối (nhấn cam nhẹ)
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color.black.opacity(0.05), location: 0.0),
                        .init(color: Color.black.opacity(1.0), location: 0.5),
                        .init(color: Color.black.opacity(1.0), location: 1.0)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )

                // Orange glow very subtle at bottom area
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.clear,
                        AivoTheme.Primary.orange.opacity(0.18)
                    ]),
                    startPoint: .center,
                    endPoint: .bottom
                )
            }
            .ignoresSafeArea()
            .drawingGroup()
        }
    }

    // MARK: - Cover Image
    private var coverImage: some View {
        let circleSize: CGFloat = iPadScaleLarge(200)
        let coverSize: CGFloat = iPadScaleLarge(190)
        return ZStack {
            // Background circle (mờ)
            Circle()
                .stroke(Color.white.opacity(0.2), lineWidth: 4)
                .frame(width: circleSize, height: circleSize)
            
            // Progress circle (màu cam) - full circle for visual
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            AivoTheme.Primary.orange,
                            AivoTheme.Secondary.goldenSun
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .frame(width: circleSize, height: circleSize)
                .rotationEffect(.degrees(-90))
            
            // Cover tròn
            Image("cover_default_resize")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: coverSize, height: coverSize)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
        }
    }

    private var header: some View {
        HStack {
            
            Button(action: {
                onDismiss?()
                dismiss()
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: iPadScale(20), weight: .bold))
                    .foregroundColor(.white.opacity(0.3))
                    .frame(width: iPadScale(42), height: iPadScale(42))
                    .clipShape(Circle())
            }
            Spacer()
        }
        .padding(.top, iPadScaleSmall(50))
    }

    // MARK: - Active Subscription View
    private func activeSubscriptionView(subscription: SubscriptionManager.ActiveSubscription) -> some View {
        VStack(spacing: 0) {
            // Title showing subscription plan
            VStack(alignment: .leading, spacing: iPadScaleSmall(8)) {
                HStack {
                    Text("\(subscription.period.displayName) Premium")
                        .font(.system(size: iPadScale(28), weight: .heavy))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.4), radius: 6, x: 0, y: 2)
                    Spacer()
                }
                
                // Expiry date
                if let expiryDate = subscription.expiresDate {
                    HStack {
                        Text("Expires on \(formatDate(expiryDate))")
                            .font(.system(size: iPadScale(15), weight: .medium))
                            .foregroundColor(.white.opacity(0.75))
                        Spacer()
                    }
                }
                
                // Next Bonus Date
                if let nextBonus = subscriptionManager.getNextBonusDate() {
                    HStack {
                        Text("Next bonus date: \(formatDate(nextBonus))")
                            .font(.system(size: iPadScale(15), weight: .medium))
                            .foregroundColor(AivoTheme.Secondary.goldenSun)
                        Spacer()
                    }
                    .padding(.top, 2)
                }
            }
            .padding(.top, iPadScaleSmall(8))
            
            // Keep features list
            features
            
            // Credit display (similar to CreditDialogModifier)
            creditInfoView
                .padding(.top, iPadScaleSmall(18))
                .padding(.bottom, iPadScaleSmall(12))
            
            //Spacer()
        }
    }
    
    // MARK: - Purchase View
    private var purchaseView: some View {
        VStack(spacing: 0) {
            title
            features
            planCards
            autoRenewalView
            ctaButton
        }
    }
    
    private var title: some View {
        
        HStack {
            Spacer()
            Text("Upgrade to Premium")
                .font(.system(size: iPadScale(28), weight: .heavy))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.4), radius: 6, x: 0, y: 2)
            Spacer()
        }
        .padding(.top, iPadScaleSmall(8))
    }
    
    // MARK: - Credit Info View (from CreditDialogModifier)
    private var creditInfoView: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: iPadScaleSmall(16)) {
                // Coin icon + Credits count
                VStack(spacing: iPadScaleSmall(12)) {
                    Image("icon_coin_512")
                        .resizable()
                        .scaledToFit()
                        .frame(width: iPadScale(80), height: iPadScale(80))
                        .shadow(radius: 8, y: 4)
                    
                    HStack(spacing: 8) {
                        Text("\(creditManager.credits)")
                            .font(.system(size: iPadScale(42), weight: .bold))
                            .foregroundColor(.white)
                        Text("Credits")
                            .font(.system(size: iPadScale(20), weight: .semibold))
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, iPadScaleSmall(28))
            .padding(.top, iPadScaleSmall(28))
            .background(
                RoundedRectangle(cornerRadius: iPadScale(20))
                    .fill(Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: iPadScale(20))
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
            )
            
            // Add button ở góc trên phải
            Button(action: {
                showBuyCreditDialog = true
            }) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: iPadScale(24), weight: .semibold))
                    .foregroundColor(AivoTheme.Primary.orange)
                    .background(
                        Circle()
                            .fill(Color.white)
                            .frame(width: iPadScale(28), height: iPadScale(28))
                    )
                    .shadow(color: AivoTheme.Primary.orange.opacity(0.4), radius: 4, x: 0, y: 2)
            }
            .padding(.top, iPadScaleSmall(12))
            .padding(.trailing, iPadScaleSmall(12))
        }
    }
    
    // Helper function to format date
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    private var features: some View {
        // Dynamic credits based on selected plan or current subscription
        let creditsAmount: Int
        let perString: String
        
        if subscriptionManager.isPremium, let sub = subscriptionManager.currentSubscription {
            // Active sub: show actual terms
            if sub.period == .yearly {
                // Check cohort for active user
                let startDate = LocalStorageManager.shared.getLocalProfile().subscriptionStartDate ?? Date()
                let components = DateComponents(year: 2026, month: 1, day: 15)
                let cutoff = Calendar.current.date(from: components) ?? Date()
                if startDate < cutoff {
                    creditsAmount = 1200
                    perString = "week"
                } else {
                    creditsAmount = 1200
                    perString = "month"
                }
            } else {
                creditsAmount = 1000
                perString = "week"
            }
        } else {
            // Not premium: Show what they WILL get if they select a plan
            if selectedPlan == .yearly {
                creditsAmount = 1200
                perString = "month" // New users get monthly
            } else {
                creditsAmount = 1000
                perString = "week"
            }
        }
        
        return VStack(alignment: .leading, spacing: iPadScaleSmall(16)) {
            featureRowWithHighlightedCredits(creditsAmount: creditsAmount, period: perString)
            featureRow("Access to All Features")
            featureRow("Ad-Free experience")
            featureRow("Premium quality AI Song")
            //featureRow("Unlimited downloads")
        }
        .padding(.top, iPadScaleSmall(20))
    }

    private func featureRowWithHighlightedCredits(creditsAmount: Int, period: String) -> some View {
        HStack(spacing: iPadScaleSmall(12)) {
            ZStack {
                Circle().fill(AivoTheme.Primary.orange.opacity(0.15))
                    .frame(width: iPadScale(28), height: iPadScale(28))
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(AivoTheme.Primary.orange)
                    .font(.system(size: iPadScale(20)))
            }
            
            // Credits amount with highlight
            HStack(spacing: 4) {
                Text("\(creditsAmount)")
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                AivoTheme.Secondary.goldenSun,
                                Color(red: 1.0, green: 0.85, blue: 0.4)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .font(.system(size: iPadScale(28), weight: .bold))
                    .shadow(color: AivoTheme.Primary.orange.opacity(0.5), radius: 4, x: 0, y: 2)
                VStack {
                    Text("credits per \(period)")
                        .foregroundColor(.white.opacity(0.85))
                        .font(.system(size: iPadScale(17), weight: .medium))
                        .padding(.top, 6)
                }
                
            }
            
            Spacer()
        }
    }

    private func featureRow(_ text: String) -> some View {
        HStack(spacing: iPadScaleSmall(12)) {
            ZStack {
                Circle().fill(AivoTheme.Primary.orange.opacity(0.15))
                    .frame(width: iPadScale(28), height: iPadScale(28))
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(AivoTheme.Primary.orange)
                    .font(.system(size: iPadScale(20)))
            }
            Text(text)
                .foregroundColor(.white.opacity(0.85))
                .font(.system(size: iPadScale(17), weight: .medium))
            Spacer()
        }
    }

    private var planCards: some View {
        VStack(spacing: 14) {
            // Yearly plan
            if let yearlyProduct = subscriptionManager.getProduct(for: .yearly) {
                // Calculate equivalent weekly price
                let weeklyPrice = yearlyProduct.price / 52
                let equivalentWeeklyPrice = weeklyPrice.formatted(yearlyProduct.priceFormatStyle)
                
                planCard(
                    title: "Yearly",
                    subtitle: "1200 credits per month", // New policy for fresh purchase
                    price: yearlyProduct.displayPrice,
                    originalPrice: nil,
                    introPrice: nil,
                    regularPrice: nil,
                    per: "/Year",
                    equivalentWeeklyPrice: equivalentWeeklyPrice,
                    isSelected: selectedPlan == .yearly,
                    tagText: "Save 75%"
                ) { selectedPlan = .yearly }
            } else {
                // Fallback loading state
                planCard(
                    title: "Yearly",
                    subtitle: "1200 credits per month",
                    price: "Loading...",
                    originalPrice: nil,
                    introPrice: nil,
                    regularPrice: nil,
                    per: "/Year",
                    equivalentWeeklyPrice: nil,
                    isSelected: selectedPlan == .yearly,
                    tagText: "Save 75%"
                ) { selectedPlan = .yearly }
                    .opacity(0.6)
            }

            // Weekly plan
            if let weeklyProduct = subscriptionManager.getProduct(for: .weekly) {
                if let introOffer = weeklyProduct.subscription?.introductoryOffer {
                    // Has Intro Offer
                    // If not selected: Show Regular Price.
                    // If selected: Logic inside planCard will use introPrice/regularPrice.
                    planCard(
                        title: "Weekly",
                        subtitle: "\(subscriptionManager.getCreditsPerPeriod(for: weeklyProduct)) credits per week",
                        price: weeklyProduct.displayPrice, // Default to regular
                        originalPrice: nil, 
                        introPrice: introOffer.displayPrice,
                        regularPrice: weeklyProduct.displayPrice,
                        per: "/Week",
                        equivalentWeeklyPrice: nil,
                        isSelected: selectedPlan == .weekly,
                        tagText: nil
                    ) { selectedPlan = .weekly }
                } else {
                    // Regular
                    planCard(
                        title: "Weekly",
                        subtitle: "\(subscriptionManager.getCreditsPerPeriod(for: weeklyProduct)) credits per week",
                        price: weeklyProduct.displayPrice,
                        originalPrice: nil,
                        introPrice: nil,
                        regularPrice: nil,
                        per: "/Week",
                        equivalentWeeklyPrice: nil,
                        isSelected: selectedPlan == .weekly,
                        tagText: nil
                    ) { selectedPlan = .weekly }
                }
            } else {
                // Fallback loading state
                planCard(
                    title: "Weekly",
                    subtitle: "1000 credits per week",
                    price: "Loading...",
                    originalPrice: nil,
                    introPrice: nil,
                    regularPrice: nil,
                    per: "/Week",
                    equivalentWeeklyPrice: nil,
                    isSelected: selectedPlan == .weekly,
                    tagText: nil
                ) { selectedPlan = .weekly }
                    .opacity(0.6)
            }
        }
        .padding(.top, iPadScaleSmall(28))
    }

    private func planCard(title: String, subtitle: String, price: String, originalPrice: String?, introPrice: String?, regularPrice: String?, per: String, equivalentWeeklyPrice: String?, isSelected: Bool, tagText: String?, onTap: @escaping () -> Void) -> some View {
        ZStack(alignment: .topTrailing) {
            Button(action: onTap) {
                HStack {
                    // Radio
                    ZStack {
                        Circle().stroke(AivoTheme.Primary.orange, lineWidth: 2)
                            .frame(width: 26, height: 26)
                        if isSelected {
                            Circle().fill(AivoTheme.Primary.orange)
                                .frame(width: 14, height: 14)
                        }
                    }
                    .padding(.leading, iPadScaleSmall(18))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .foregroundColor(.white)
                            .font(.system(size: iPadScale(18), weight: .semibold))
                    }
                    Spacer()
                    
                    // Price Section
                    if isSelected, let intro = introPrice, let regular = regularPrice {
                        // Selected with Intro Offer -> 2 lines
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("First week \(intro)")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [AivoTheme.Secondary.goldenSun, AivoTheme.Primary.orange],
                                        startPoint: .leading, endPoint: .trailing
                                    )
                                )
                            
                            Text("Then \(regular) / week")
                                .foregroundColor(.white.opacity(0.7))
                                .font(.system(size: 14, weight: .regular))
                        }
                        .padding(.trailing, 16)
                    } else {
                        // Standard Layout (Unselected or No Intro)
                        VStack(alignment: .trailing, spacing: 2) {
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                if let original = originalPrice {
                                    Text(original)
                                        .foregroundColor(.white.opacity(0.5))
                                        .font(.system(size: 15, weight: .regular))
                                        .strikethrough()
                                }
                                
                                Text(price)
                                    .foregroundColor(.white)
                                    .font(.system(size: originalPrice != nil ? 20 : 18, weight: .bold))
                                
                                Text(per)
                                    .foregroundColor(.white.opacity(0.7))
                                    .font(.system(size: 14, weight: .regular))
                            }
                            
                            if let equivalent = equivalentWeeklyPrice {
                                Text("\(equivalent) / week")
                                    .foregroundColor(AivoTheme.Secondary.goldenSun)
                                    .font(.system(size: 13, weight: .semibold))
                            }
                        }
                        .padding(.trailing, 16)
                    }
                }
                .frame(height: equivalentWeeklyPrice != nil ? iPadScale(76) : iPadScale(64))
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

            if let tag = tagText {
                tagView(tag)
                    .padding(.trailing, 12)
                    .padding(.top, -8)
            }
        }
    }

    private func tagView(_ text: String) -> some View {
        let gradient = LinearGradient(
                colors: [
                    Color(red: 1.0, green: 0.1, blue: 0.1),   // 🔴 Đỏ tươi (#FF1A1A)
                    Color(red: 1.0, green: 0.25, blue: 0.0)   // 🟠 Đỏ-cam nhạt (#FF4000)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        return Text(text)
            .font(.system(size: 13, weight: .heavy))
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

    private var ctaButton: some View {
        Button(action: handlePurchase) {
            HStack {
                if isPurchasing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .padding(.trailing, 8)
                }
                Text(isPurchasing ? "Processing..." : "Continue")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: iPadScale(58))
            .background(
                ZStack {
                    // Base gradient
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    AivoTheme.Primary.orange,
                                    AivoTheme.Primary.orange.opacity(0.85)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    // Glowing border effect
                    Capsule()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    AivoTheme.Primary.orange,
                                    AivoTheme.Primary.orange.opacity(0.8),
                                    AivoTheme.Primary.orange.opacity(0.6)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2.5
                        )
                        .opacity(glowIntensity)
                    
                    // Outer glow shadow
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    AivoTheme.Primary.orange.opacity(0.4),
                                    AivoTheme.Primary.orange.opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .blur(radius: 8)
                        .opacity(glowIntensity * 0.8)
                        .padding(-4)
                }
            )
            .scaleEffect(buttonScale)
            .shadow(
                color: AivoTheme.Primary.orange.opacity(glowIntensity * 0.8),
                radius: 12,
                x: 0,
                y: 4
            )
            .shadow(
                color: AivoTheme.Primary.orange.opacity(glowIntensity * 0.4),
                radius: 20,
                x: 0,
                y: 8
            )
        }
        .disabled(isPurchasing || subscriptionManager.isLoading)
        .padding(.top, iPadScaleSmall(18))
        .onAppear {
            startPulseAnimation()
        }
        .onDisappear {
            stopPulseAnimation()
        }
    }
    
    // MARK: - Pulse Animation
    private func startPulseAnimation() {
        // Synchronized pulse: scale and glow together with same timing
        let animationDuration = 1.6 // Unified duration for both effects
        
        withAnimation(
            .easeInOut(duration: animationDuration)
            .repeatForever(autoreverses: true)
        ) {
            // Scale up = glow bright (synchronized)
            buttonScale = 1.03
            glowIntensity = 0.9
        }
    }
    
    private func stopPulseAnimation() {
        withAnimation(.easeInOut(duration: 0.3)) {
            buttonScale = 1.0
            glowIntensity = 0.5
        }
    }
    
    private func handlePurchase() {
        guard !isPurchasing else { return }
        
        let productID: SubscriptionManager.ProductID = selectedPlan == .yearly ? .yearly : .weekly
        
        guard let product = subscriptionManager.getProduct(for: productID) else {
            purchaseErrorMessage = "Product not available. Please try again later."
            showPurchaseError = true
            return
        }
        
        isPurchasing = true
        Logger.i("📱 [SubscriptionScreen] Starting purchase for product: \(product.id)")
        
        Task {
            do {
                let success = try await subscriptionManager.purchaseSubscription(product)
                await MainActor.run {
                    isPurchasing = false
                    if !success {
                        // If purchase was cancelled or failed, error will be handled via notification
                        // But if it returned false due to already subscribed, show alert
                        if let errorMsg = subscriptionManager.errorMessage,
                           errorMsg.contains("already have an active") {
                            alreadySubscribedMessage = errorMsg
                            showAlreadySubscribedAlert = true
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    isPurchasing = false
                    purchaseErrorMessage = "Purchase failed: \(error.localizedDescription)"
                    showPurchaseError = true
                }
            }
        }
    }

    // MARK: - Auto Renewal
    private var autoRenewalView: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(AivoTheme.Primary.orange)
            Text("Auto Renewal. Cancel anytime.")
                .foregroundColor(.white.opacity(0.85))
                .font(.system(size: 15, weight: .medium))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 10)
        .padding(.bottom, 6)
    }

    private var footer: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                Button("Terms of use") {
                    // Open terms
                }
                Text("|")
                Button("Privacy Policy") {
                    // Open privacy
                }
//                Text("|")
//                Button("Restore") {
//                    handleRestore()
//                }
            }
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(.white.opacity(0.7))
            .padding(.top, 10)
        }
    }
    
    private func handleRestore() {
        Logger.i("📱 [SubscriptionScreen] Restoring purchases")
        Task {
            await subscriptionManager.restorePurchases()
        }
    }
}

struct SubscriptionScreen_Previews: PreviewProvider {
    static var previews: some View {
        SubscriptionScreen()
    }
}
