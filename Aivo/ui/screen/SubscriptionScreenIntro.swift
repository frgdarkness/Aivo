import SwiftUI
import StoreKit

struct SubscriptionScreenIntro: View {
    let onDismiss: (() -> Void)?
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @ObservedObject private var creditManager = CreditManager.shared
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

    init(onDismiss: (() -> Void)? = nil) {
        self.onDismiss = onDismiss
    }

    enum Plan { case yearly, weekly }

    var body: some View {
        ZStack {
            customBackgroundView

            VStack(spacing: 0) {
                header
                Spacer(minLength: 20)
                
                // Cover với play/pause button ở giữa
                coverWithPlayButton
                    .padding(.top, 20)
                    .padding(.bottom, 30)
                
                if subscriptionManager.isPremium, let currentSub = subscriptionManager.currentSubscription {
                    // Active subscription view
                    activeSubscriptionView(subscription: currentSub)
                } else {
                    // Purchase view
                    purchaseView
                }
                
                footer
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .ignoresSafeArea()
        .background(AivoTheme.Background.primary.ignoresSafeArea())
        .onAppear {
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

    // MARK: - Cover với Play/Pause Button ở giữa
    private var coverWithPlayButton: some View {
        ZStack {
            if !isDownloadingSong {
                // Cover tròn với rotation animation (chỉ hiện khi không download)
                Group {
                    if let song = subscriptionSong, let imageUrl = URL(string: song.imageUrl) {
                        AsyncImage(url: imageUrl) { phase in
                            Group {
                                switch phase {
                                case .empty:
                                    Image("demo_cover")
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                case .failure(_):
                                    Image("demo_cover")
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                @unknown default:
                                    Image("demo_cover")
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                }
                            }
                        }
                    } else {
                        Image("demo_cover")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    }
                }
                .frame(width: 200, height: 200)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.9), radius: 20, x: 0, y: 10)
                // Use rotation3DEffect for better GPU performance
                .rotation3DEffect(
                    .degrees(rotationAngle),
                    axis: (x: 0, y: 0, z: 1),
                    perspective: 2.0
                )
                .drawingGroup()
            } else {
                // Hiện loading indicator khi đang download
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .frame(width: 200, height: 200)
            }
            
            // Play/Pause button ở giữa cover (chỉ hiện khi không download)
            if !isDownloadingSong {
                Button(action: { musicPlayer.togglePlayPause() }) {
                    Image(systemName: musicPlayer.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.white)
                        .frame(width: 70, height: 70)
                        //.background(AivoTheme.Primary.orange)
                        .clipShape(Circle())
                        .shadow(color: AivoTheme.Shadow.orange, radius: 10, x: 0, y: 5)
                }
            }
        }
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
            }
            .padding(.top, 8)
            
            // Keep features list
            features
            
            // Credit display (similar to CreditDialogModifier)
            creditInfoView
                .padding(.top, 18)
                .padding(.bottom, 12)
            
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
                .font(.system(size: 28, weight: .heavy))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.4), radius: 6, x: 0, y: 2)
            Spacer()
        }
        .padding(.top, 8)
    }
    
    // MARK: - Credit Info View (from CreditDialogModifier)
    private var creditInfoView: some View {
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
    }
    
    // Helper function to format date
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    private var features: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Dynamic credits based on selected plan
            let creditsAmount = selectedPlan == .yearly ? 1200 : 1000
            featureRowWithHighlightedCredits(creditsAmount: creditsAmount)
            featureRow("Access to All Features")
            featureRow("Ad-Free experience")
            featureRow("Premium quality AI Song")
        }
        .padding(.top, 20)
    }

    private func featureRowWithHighlightedCredits(creditsAmount: Int) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(AivoTheme.Primary.orange.opacity(0.15))
                    .frame(width: 28, height: 28)
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(AivoTheme.Primary.orange)
                    .font(.system(size: 20))
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
                    .font(.system(size: 28, weight: .bold))
                    .shadow(color: AivoTheme.Primary.orange.opacity(0.5), radius: 4, x: 0, y: 2)
                VStack {
                    Text("credits per week")
                        .foregroundColor(.white.opacity(0.85))
                        .font(.system(size: 17, weight: .medium))
                        .padding(.top, 6)
                }
                
            }
            
            Spacer()
        }
    }

    private func featureRow(_ text: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(AivoTheme.Primary.orange.opacity(0.15))
                    .frame(width: 28, height: 28)
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(AivoTheme.Primary.orange)
                    .font(.system(size: 20))
            }
            Text(text)
                .foregroundColor(.white.opacity(0.85))
                .font(.system(size: 17, weight: .medium))
            Spacer()
        }
    }

    private var planCards: some View {
        VStack(spacing: 14) {
            // Yearly plan
            if let yearlyProduct = subscriptionManager.getProduct(for: .yearly) {
                planCard(
                    title: "Yearly",
                    subtitle: "\(subscriptionManager.getCreditsPerPeriod(for: yearlyProduct)) credits per week",
                    price: yearlyProduct.displayPrice,
                    per: "/Year",
                    isSelected: selectedPlan == .yearly,
                    showTag: true
                ) { selectedPlan = .yearly }
            } else {
                // Fallback loading state
                planCard(
                    title: "Yearly",
                    subtitle: "1200 credits per week",
                    price: "Loading...",
                    per: "/Year",
                    isSelected: selectedPlan == .yearly,
                    showTag: true
                ) { selectedPlan = .yearly }
                    .opacity(0.6)
            }

            // Weekly plan
            if let weeklyProduct = subscriptionManager.getProduct(for: .weekly) {
                planCard(
                    title: "Weekly",
                    subtitle: "\(subscriptionManager.getCreditsPerPeriod(for: weeklyProduct)) credits per week",
                    price: weeklyProduct.displayPrice,
                    per: "/Week",
                    isSelected: selectedPlan == .weekly,
                    showTag: false
                ) { selectedPlan = .weekly }
            } else {
                // Fallback loading state
                planCard(
                    title: "Weekly",
                    subtitle: "1000 credits per week",
                    price: "Loading...",
                    per: "/Week",
                    isSelected: selectedPlan == .weekly,
                    showTag: false
                ) { selectedPlan = .weekly }
                    .opacity(0.6)
            }
        }
        .padding(.top, 28)
    }

    private func planCard(title: String, subtitle: String, price: String, per: String, isSelected: Bool, showTag: Bool, onTap: @escaping () -> Void) -> some View {
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
                    .padding(.leading, 18)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .foregroundColor(.white)
                        .font(.system(size: 18, weight: .semibold))
                }
                    Spacer()
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(price)
                        .foregroundColor(.white)
                        .font(.system(size: 18, weight: .bold))
                    Text(per)
                        .foregroundColor(.white.opacity(0.7))
                        .font(.system(size: 14, weight: .regular))
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

            if showTag {
                tagView("Save 75%")
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
            .frame(height: 58)
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
        .padding(.top, 18)
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
            }
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(.white.opacity(0.7))
            .padding(.top, 10)
        }
    }
    
    private func handleRestore() {
        Logger.i("📱 [SubscriptionScreenIntro] Restoring purchases")
        Task {
            await subscriptionManager.restorePurchases()
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
        
        // Load songs from JSON
        guard let songs = loadSubscriptionSongsFromJSON() else {
            Logger.e("❌ [SubscriptionScreenIntro] Failed to load subscription songs from JSON")
            return
        }
        
        guard !songs.isEmpty else {
            Logger.e("❌ [SubscriptionScreenIntro] No songs found in JSON")
            return
        }
        
        songs.forEach { Logger.d("🎵 [SubscriptionScreenIntro] Found song: \($0.title)") }
        
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
}

struct SubscriptionScreenIntro_Previews: PreviewProvider {
    static var previews: some View {
        SubscriptionScreenIntro()
    }
}

