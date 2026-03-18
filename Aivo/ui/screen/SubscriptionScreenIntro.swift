import SwiftUI
import StoreKit
import UIKit

struct SubscriptionScreenIntro: View {
    let onDismiss: (() -> Void)?
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @ObservedObject private var creditManager = CreditManager.shared
    @ObservedObject private var remoteConfig = RemoteConfigManager.shared
    @StateObject private var musicPlayer = MusicPlayer.shared
    @State private var selectedPlan: Plan = .yearly
    @State private var isPurchasing = false
    @State private var showPurchaseError = false
    @State private var showAlreadySubscribedAlert = false
    @State private var alreadySubscribedMessage = ""
    @State private var purchaseErrorMessage = ""
    @State private var buttonScale: CGFloat = 1.0
    @State private var glowIntensity: Double = 0.5
    @State private var rotationAngle: Double = 0
    @State private var isDownloadingSong = false
    @State private var subscriptionSong: SunoData?
    @State private var isScrubbing = false
    @State private var scrubTime: TimeInterval = 0
    @State private var isRestoring = false
    @State private var showRestoreSuccess = false
    @State private var showRestoreError = false
    @State private var restoreErrorMessage = ""
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
                        // Cover với play/pause button ở giữa
                        coverWithPlayButton
                            .padding(.top, DeviceScale.isIPad ? 30 : 2)
                            .padding(.bottom, iPadScaleSmall(20))
                        
                        if subscriptionManager.isPremium, let currentSub = subscriptionManager.currentSubscription {
                            // Active subscription view
                            activeSubscriptionView(subscription: currentSub)
                        } else {
                            // Purchase view
                            purchaseView
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                // Footer - Always visible at bottom (sticky)
                footer
                    .padding(.horizontal, iPadScaleSmall(20))
                    .padding(.bottom, iPadScaleSmall(24))
                    .background(
                        // Subtle background để footer nổi bật hơn
                        LinearGradient(
                            colors: [
                                Color.clear,
                                AivoTheme.Primary.blackOrangeDark.opacity(0.95)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
        }
        .ignoresSafeArea()
        .background(AivoTheme.Background.primary.ignoresSafeArea())
        .buyCreditDialog(isPresented: $showBuyCreditDialog)
        .onAppear {
            // Log screen view
            AnalyticsLogger.shared.logScreenView(AnalyticsLogger.EVENT.EVENT_SCREEN_SUBSCRIPTION_INTRO)
            
            Task {
                await subscriptionManager.fetchProducts()
                await subscriptionManager.refreshStatus()
                
                // Load random subscription song if not playing
                await loadRandomSubscriptionSong()
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
        .alert("Restore Successful", isPresented: $showRestoreSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Your purchases have been restored successfully.")
        }
        .alert("Restore Failed", isPresented: $showRestoreError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(restoreErrorMessage.isEmpty ? "Failed to restore purchases. Please try again." : restoreErrorMessage)
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
        .onChange(of: musicPlayer.isPlaying) { isPlaying in
            // Use explicit animation control to prevent conflicts
            if isPlaying {
                // Start rotation animation smoothly
                withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                    rotationAngle = 360
                }
            } else {
                // Stop rotation smoothly
                withAnimation(.easeInOut(duration: 0.3)) {
                    rotationAngle = 0
                }
            }
        }
        .onChange(of: musicPlayer.currentTime) { _ in
            // Update progress khi currentTime thay đổi (trừ khi đang scrub)
            if !isScrubbing && musicPlayer.duration > 0 {
                // Progress tự động update qua binding
            }
        }
    }

    // MARK: - Background không blur
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

    // MARK: - Cover với Play/Pause Button và Circular Seekbar
    private var coverWithPlayButton: some View {
        let circleSize: CGFloat = DeviceScale.isIPad ? 360 : 200
        let coverSize: CGFloat = DeviceScale.isIPad ? 348 : 190
        let playBtnSize: CGFloat = DeviceScale.isIPad ? 100 : 70
        let playIconSize: CGFloat = DeviceScale.isIPad ? 48 : 32
        
        return ZStack {
            if !isDownloadingSong {
                let progress = musicPlayer.duration > 0 ? (isScrubbing ? scrubTime : musicPlayer.currentTime) / musicPlayer.duration : 0
                
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: DeviceScale.isIPad ? 6 : 4)
                        .frame(width: circleSize, height: circleSize)
                    
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    AivoTheme.Primary.orange,
                                    AivoTheme.Secondary.goldenSun
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: DeviceScale.isIPad ? 6 : 4, lineCap: .round)
                        )
                        .frame(width: circleSize, height: circleSize)
                        .rotationEffect(.degrees(-90))
                    
                    Image("cover_default_resize")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: coverSize, height: coverSize)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
                        .rotation3DEffect(
                            .degrees(rotationAngle),
                            axis: (x: 0, y: 0, z: 1),
                            perspective: 2.0
                        )
                        .drawingGroup()
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            handleCircularSeek(value: value)
                        }
                        .onEnded { value in
                            handleCircularSeekEnd()
                        }
                )
            } else {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .frame(width: coverSize, height: coverSize)
            }
            
            if !isDownloadingSong {
                Button(action: { musicPlayer.togglePlayPause() }) {
                    Image(systemName: musicPlayer.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: playIconSize))
                        .foregroundColor(.white)
                        .frame(width: playBtnSize, height: playBtnSize)
                        .clipShape(Circle())
                        .shadow(color: AivoTheme.Shadow.orange, radius: 10, x: 0, y: 5)
                }
            }
        }
    }
    
    // MARK: - Circular Seekbar Handlers
    private func handleCircularSeek(value: DragGesture.Value) {
        guard musicPlayer.duration > 0 else { return }
        
        let center = CGPoint(x: 110, y: 110) // Center của circle 220x220
        let location = value.location
        
        // Tính khoảng cách từ center đến touch point
        let dx = location.x - center.x
        let dy = location.y - center.y
        let distance = sqrt(dx * dx + dy * dy)
        
        // Kiểm tra xem touch có nằm trong vùng ring (giữa button và progress bar) không
        // Button radius: 35 (70/2), Progress bar radius: 110 (220/2)
        // Chỉ cho phép seek khi touch nằm trong vùng ring (35 < distance < 110)
        let buttonRadius: CGFloat = 35
        let outerRadius: CGFloat = 110
        
        guard distance > buttonRadius && distance <= outerRadius else {
            // Touch nằm trong button hoặc ngoài progress bar - không seek
            return
        }
        
        // Tính góc (atan2 trả về -π đến π, bắt đầu từ phía bên phải)
        var angle = atan2(dy, dx) * 180 / .pi
        
        // Chuyển đổi từ -180...180 sang 0...360 (bắt đầu từ trên cùng = -90 độ)
        angle = angle + 90 // Rotate để bắt đầu từ trên
        if angle < 0 {
            angle += 360
        }
        
        // Chuyển đổi góc (0-360) thành progress (0-1)
        let progress = angle / 360.0
        
        // Tính thời gian tương ứng
        let newTime = progress * musicPlayer.duration
        
        // Update scrub time
        isScrubbing = true
        scrubTime = max(0, min(musicPlayer.duration, newTime))
    }
    
    private func handleCircularSeekEnd() {
        guard isScrubbing else { return }
        
        // Seek đến vị trí đã chọn
        musicPlayer.seek(to: scrubTime)
        isScrubbing = false
    }

    private var header: some View {
        HStack {
            Button(action: {
                onDismiss?()
                dismiss()
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white.opacity(0.3))
                    .frame(width: 42, height: 42)
                    .clipShape(Circle())
            }
            
            Spacer()
            
            Button(action: handleRestore) {
                if isRestoring {
                    HStack(spacing: 6) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(width: 20, height: 20)
                        Text("Restore")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white.opacity(0.55))
                            .lineLimit(1)
                    }
                    
                } else {
                    Text("Restore")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white.opacity(0.55))
                        .lineLimit(1)
                }
            }
            .disabled(isRestoring)
            .padding(.horizontal, 6)
            .padding(.vertical, 8)
        }
        .padding(.top, 50)
    }

    // MARK: - Active Subscription View
    private func activeSubscriptionView(subscription: SubscriptionManager.ActiveSubscription) -> some View {
        VStack(spacing: 0) {
            // Title showing subscription plan
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("\(subscription.period.displayName) Premium")
                        .font(.system(size: 28, weight: .heavy))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.4), radius: 6, x: 0, y: 2)
                    Spacer()
                }
                
                // Expiry date
                if let expiryDate = subscription.expiresDate {
                    HStack {
                        Text("Expires on \(formatDate(expiryDate))")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white.opacity(0.75))
                        Spacer()
                    }
                }
                
                // Next Bonus Date
                if let nextBonus = subscriptionManager.getNextBonusDate() {
                    HStack {
                        Text("Next bonus date: \(formatDate(nextBonus))")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(AivoTheme.Secondary.goldenSun)
                        Spacer()
                    }
                    .padding(.top, 2)
                }
            }
            .padding(.top, 8)
            
            // Keep features list
            features
            
            // Credit display (similar to CreditDialogModifier)
            creditInfoView
                .padding(.top, 18)
                .padding(.bottom, 12)
            
            // Add minimum spacing to ensure footer is visible
            Spacer(minLength: 20)
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
            // Add minimum spacing to ensure footer is visible
            Spacer(minLength: 20)
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
            VStack(spacing: 16) {
                // Coin icon + Credits count
                VStack(spacing: 12) {
                    Image("icon_coin_512")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .shadow(radius: 8, y: 4)
                    
                    HStack(spacing: 8) {
                        Text("\(creditManager.credits)")
                            .font(.system(size: 42, weight: .bold))
                            .foregroundColor(.white)
                        Text("Credits")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 28)
            .padding(.top, 28)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
            )
            
            // Add button ở góc trên phải
            Button(action: {
                showBuyCreditDialog = true
            }) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(AivoTheme.Primary.orange)
                    .background(
                        Circle()
                            .fill(Color.white)
                            .frame(width: 28, height: 28)
                    )
                    .shadow(color: AivoTheme.Primary.orange.opacity(0.4), radius: 4, x: 0, y: 2)
            }
            .padding(.top, 12)
            .padding(.trailing, 12)
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
        
        return VStack(alignment: .leading, spacing: iPadScaleSmall(4)) {
            featureRowWithHighlightedCredits(creditsAmount: creditsAmount, period: perString)
            featureRow("Access to All Features")
            featureRow("Ad-Free experience")
            featureRow("Premium quality AI Song")
            featureRow("Unlimited export Song")
        }
        .padding(.top, iPadScaleSmall(14))
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
                        .padding(.top, iPadScaleSmall(6))
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
        VStack(spacing: DeviceScale.isIPad ? 20 : 14) {
            // Yearly plan
            if let yearlyProduct = subscriptionManager.getProduct(for: .yearly),
               let weeklyProduct = subscriptionManager.getProduct(for: .weekly) {
                // Tính giá gốc từ weekly × 53 và format giống yearly price
                let originalPrice = calculateOriginalYearlyPrice(from: weeklyProduct, formatLike: yearlyProduct)
                
                // Calculate equivalent weekly price for Yearly plan
                let yearlyPriceVal = yearlyProduct.price
                let weeklyPriceVal = yearlyPriceVal / 52
                let equivalentWeeklyPrice = weeklyPriceVal.formatted(yearlyProduct.priceFormatStyle)
                
                planCard(
                    title: "Yearly",
                    subtitle: "\(subscriptionManager.getCreditsPerPeriod(for: yearlyProduct)) credits per week",
                    price: yearlyProduct.displayPrice,
                    originalPrice: originalPrice,
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
                    subtitle: "1200 credits per week",
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
                    // If not selected: Show Regular Price
                    // If selected: Logic inside planCard uses introPrice/regularPrice
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
        .padding(.top, iPadScaleSmall(20))
    }

    private func planCard(title: String, subtitle: String, price: String, originalPrice: String?, introPrice: String?, regularPrice: String?, per: String, equivalentWeeklyPrice: String?, isSelected: Bool, tagText: String?, onTap: @escaping () -> Void) -> some View {
        ZStack(alignment: .topTrailing) {
            Button(action: onTap) {
                HStack {
                    // Radio
                    ZStack {
                        Circle().stroke(AivoTheme.Primary.orange, lineWidth: 2)
                            .frame(width: iPadScale(26), height: iPadScale(26))
                        if isSelected {
                            Circle().fill(AivoTheme.Primary.orange)
                                .frame(width: iPadScale(14), height: iPadScale(14))
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
                                .font(.system(size: iPadScale(18), weight: .bold))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [AivoTheme.Secondary.goldenSun, AivoTheme.Primary.orange],
                                        startPoint: .leading, endPoint: .trailing
                                    )
                                )
                            
                            Text("Then \(regular) / week")
                                .foregroundColor(.white.opacity(0.7))
                                .font(.system(size: iPadScale(14), weight: .regular))
                        }
                        .padding(.trailing, 16)
                    } else {
                        // Standard Layout (Unselected or No Intro)
                        VStack(alignment: .trailing, spacing: 2) {
                            HStack(alignment: .firstTextBaseline, spacing: 6) {
                                if let original = originalPrice {
                                    // Giá gốc có strikethrough
                                    Text(original)
                                        .foregroundColor(.white.opacity(0.5))
                                        .font(.system(size: iPadScale(16), weight: .regular))
                                        .strikethrough()
                                }
                                
                                // Giá real nổi bật
                                Text(price)
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
                                    .font(.system(size: iPadScale(originalPrice != nil ? 22 : 18), weight: .bold))
                                    .shadow(color: AivoTheme.Primary.orange.opacity(0.5), radius: 2, x: 0, y: 1)
                                
                                Text(per)
                                    .foregroundColor(.white.opacity(0.7))
                                    .font(.system(size: iPadScale(14), weight: .regular))
                            }
                            
                            if let equivalent = equivalentWeeklyPrice {
                                Text("\(equivalent) / week")
                                    .foregroundColor(AivoTheme.Secondary.goldenSun)
                                    .font(.system(size: iPadScale(13), weight: .semibold))
                            }
                        }
                        .padding(.trailing, 16)
                    }
                }
                .frame(height: iPadScale(equivalentWeeklyPrice != nil ? 76 : 64))
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
            .font(.system(size: iPadScale(12), weight: .heavy))
            .foregroundColor(.white)
            .padding(.horizontal, iPadScaleSmall(10))
            .padding(.vertical, iPadScaleSmall(4))
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
                    .font(.system(size: iPadScale(17), weight: .semibold))
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
        .padding(.top, 8)
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
        Logger.i("📱 [SubscriptionScreenIntro] Starting purchase for product: \(product.id)")
        
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
                .font(.system(size: iPadScale(15), weight: .bold))
                .foregroundColor(AivoTheme.Primary.orange)
            Text("Auto Renewal. Cancel anytime.")
                .foregroundColor(.white.opacity(0.85))
                .font(.system(size: iPadScale(15), weight: .medium))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 14)
        .padding(.bottom, 6)
    }

    private var footer: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                Button(action: {
                    openTermsUrl()
                }) {
                    Text("Terms of use")
                        .font(.system(size: iPadScale(12), weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .underline()
                }
                
                Text("|")
                    .font(.system(size: iPadScale(12), weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
                
                Button(action: {
                    openPrivacyPolicyUrl()
                }) {
                    Text("Privacy Policy")
                        .font(.system(size: iPadScale(12), weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .underline()
                }
            }
            .padding(.top, 10)
            .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Open URL Methods
    private func openTermsUrl() {
        if let url = URL(string: remoteConfig.termsUrl) {
            UIApplication.shared.open(url)
            Logger.d("📱 [SubscriptionScreenIntro] Opening Terms URL: \(remoteConfig.termsUrl)")
        } else {
            Logger.e("❌ [SubscriptionScreenIntro] Invalid Terms URL: \(remoteConfig.termsUrl)")
        }
    }
    
    private func openPrivacyPolicyUrl() {
        if let url = URL(string: remoteConfig.privacyPolicyUrl) {
            UIApplication.shared.open(url)
            Logger.d("📱 [SubscriptionScreenIntro] Opening Privacy Policy URL: \(remoteConfig.privacyPolicyUrl)")
        } else {
            Logger.e("❌ [SubscriptionScreenIntro] Invalid Privacy Policy URL: \(remoteConfig.privacyPolicyUrl)")
        }
    }
    
    private func handleRestore() {
        guard !isRestoring else { return }
        
        Logger.i("📱 [SubscriptionScreenIntro] Restoring purchases")
        isRestoring = true
        
        Task {
            await subscriptionManager.restorePurchases()
            
            await MainActor.run {
                isRestoring = false
                
                // Check if restore was successful
                if subscriptionManager.isPremium {
                    showRestoreSuccess = true
                    // Refresh status to update UI
                    Task {
                        await subscriptionManager.refreshStatus()
                    }
                } else if let errorMsg = subscriptionManager.errorMessage, !errorMsg.isEmpty {
                    restoreErrorMessage = errorMsg
                    showRestoreError = true
                } else {
                    // No subscription found after restore
                    restoreErrorMessage = "No active subscription found to restore."
                    showRestoreError = true
                }
            }
        }
    }
    
    // MARK: - Load Random Subscription Song
    private func loadRandomSubscriptionSong() async {
        // Chỉ load nếu không có bài hát nào đang phát
        guard musicPlayer.currentSong == nil else {
            Logger.d("🎵 [SubscriptionScreenIntro] Song already playing, skip loading")
            return
        }
        
        Logger.d("🎵 [SubscriptionScreenIntro] Loading random subscription song...")
        
        // Use bestAivoSongsList from RemoteConfig, fallback to JSON
        var songs = remoteConfig.bestAivoSongsList
        if songs.isEmpty {
            Logger.d("🎵 [SubscriptionScreenIntro] bestAivoSongsList empty, falling back to JSON")
            if let jsonSongs = loadSubscriptionSongsFromJSON() {
                songs = jsonSongs
            }
        }
        
        guard !songs.isEmpty else {
            Logger.e("❌ [SubscriptionScreenIntro] No songs found")
            return
        }
        
        // Chọn random song
        let randomSong = songs.randomElement()!
        Logger.d("🎵 [SubscriptionScreenIntro] Selected random song: \(randomSong.title)")
        
        await MainActor.run {
            subscriptionSong = randomSong
        }
        
        // Kiểm tra xem đã có ở local chưa
        let localFilePath = getLocalFilePath(for: randomSong)
        
        if FileManager.default.fileExists(atPath: localFilePath.path) {
            Logger.d("✅ [SubscriptionScreenIntro] Song already downloaded, loading from local")
            // Load từ local
            await MainActor.run {
                musicPlayer.loadSong(randomSong, at: 0, in: [randomSong])
                isDownloadingSong = false
            }
        } else {
            Logger.d("📥 [SubscriptionScreenIntro] Song not in local, downloading...")
            // Download về local
            await downloadSubscriptionSong(randomSong)
        }
    }
    
    // MARK: - Load Songs from JSON
    private func loadSubscriptionSongsFromJSON() -> [SunoData]? {
        guard let url = Bundle.main.url(forResource: "subscription_songs", withExtension: "json") else {
            Logger.e("❌ [SubscriptionScreenIntro] subscription_songs.json not found")
            return nil
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let songs = try decoder.decode([SunoData].self, from: data)
            Logger.d("✅ [SubscriptionScreenIntro] Loaded \(songs.count) songs from JSON")
            return songs
        } catch {
            Logger.e("❌ [SubscriptionScreenIntro] Error parsing JSON: \(error)")
            return nil
        }
    }
    
    // MARK: - Download Subscription Song
    private func downloadSubscriptionSong(_ song: SunoData) async {
        await MainActor.run {
            isDownloadingSong = true
        }
        
        guard let audioUrl = URL(string: song.audioUrl) else {
            Logger.e("❌ [SubscriptionScreenIntro] Invalid audio URL: \(song.audioUrl)")
            await MainActor.run {
                isDownloadingSong = false
            }
            return
        }
        
        let ext = audioUrl.pathExtension.isEmpty ? "mp3" : audioUrl.pathExtension.lowercased()
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let sunoDataDirectory = documentsPath.appendingPathComponent("SunoData")
        
        // Create directory if it doesn't exist
        try? FileManager.default.createDirectory(at: sunoDataDirectory, withIntermediateDirectories: true)
        
        let fileName = "\(song.id)_audio.\(ext)"
        let localURL = sunoDataDirectory.appendingPathComponent(fileName)
        
        Logger.d("📥 [SubscriptionScreenIntro] Downloading to: \(localURL.path)")
        
        let downloader = ProgressiveDownloader(
            destinationURL: localURL,
            onProgress: { progress in
                // Progress tracking (optional)
            },
            onComplete: { fileURL in
                Logger.d("✅ [SubscriptionScreenIntro] Download completed for song: \(song.title)")
                
                // Validate file size
                let fileManager = FileManager.default
                do {
                    let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
                    if let fileSize = attributes[.size] as? Int64 {
                        Logger.d("📊 [SubscriptionScreenIntro] Downloaded file size: \(fileSize) bytes")
                        
                        if fileSize < 100 * 1024 {
                            Logger.e("❌ [SubscriptionScreenIntro] Downloaded file too small (\(fileSize) bytes)")
                            Task { @MainActor in
                                self.isDownloadingSong = false
                            }
                            return
                        }
                        
                        Logger.d("✅ [SubscriptionScreenIntro] File size validation passed")
                    }
                } catch {
                    Logger.e("❌ [SubscriptionScreenIntro] Error getting file attributes: \(error)")
                }
                
                // Download xong, load vào MusicPlayer
                Task { @MainActor in
                    self.isDownloadingSong = false
                    self.musicPlayer.loadSong(song, at: 0, in: [song])
                    Logger.i("🎵 [SubscriptionScreenIntro] Song loaded and ready to play")
                }
            },
            onError: { error in
                Logger.e("❌ [SubscriptionScreenIntro] Download error: \(error)")
                Task { @MainActor in
                    self.isDownloadingSong = false
                }
            }
        )
        
        downloader.start(url: audioUrl)
    }
    
    // MARK: - Get Local File Path (same as MusicPlayer)
    private func getLocalFilePath(for song: SunoData) -> URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = documents.appendingPathComponent("SunoData")
        let names = [
            "\(song.id)_audio.mp3", "\(song.id)_audio.wav", "\(song.id)_audio.m4a",
            "\(song.id).mp3", "\(song.id).wav", "\(song.id).m4a"
        ]
        for name in names {
            let p = dir.appendingPathComponent(name)
            if FileManager.default.fileExists(atPath: p.path) { return p }
        }
        return dir.appendingPathComponent("\(song.id)_audio.mp3")
    }
    
    // MARK: - Calculate Original Yearly Price
    private func calculateOriginalYearlyPrice(from weeklyProduct: Product, formatLike yearlyProduct: Product) -> String {
        // Lấy giá weekly và tính × 53
        let weeklyPrice = weeklyProduct.price
        
        // Tính giá gốc = weekly × 53
        // Sử dụng NSDecimalNumber để tính toán chính xác
        let weeklyDecimal = NSDecimalNumber(decimal: weeklyPrice)
        let multiplier = NSDecimalNumber(value: 53)
        let originalAmount = weeklyDecimal.multiplying(by: multiplier)
        
        // Format giống với yearly price format
        // Sử dụng priceFormatStyle từ yearlyProduct để format giống nhau
        let formatted = originalAmount.decimalValue.formatted(yearlyProduct.priceFormatStyle)
        return formatted
    }
}

struct SubscriptionScreenIntro_Previews: PreviewProvider {
    static var previews: some View {
        SubscriptionScreenIntro()
    }
}

