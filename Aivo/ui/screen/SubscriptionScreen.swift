import SwiftUI
import StoreKit

struct SubscriptionScreen: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @ObservedObject private var creditManager = CreditManager.shared
    @State private var selectedPlan: Plan = .yearly
    @State private var isPurchasing = false
    @State private var showPurchaseError = false
    @State private var purchaseErrorMessage = ""
    @State private var showAlreadySubscribedAlert = false
    @State private var alreadySubscribedMessage = ""

    enum Plan { case yearly, weekly }

    var body: some View {
        ZStack {
            customBackgroundView

            VStack(spacing: 0) {
                header
                Spacer(minLength: 20)
                
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
            subscriptionManager.fetchProducts()
            subscriptionManager.checkSubscriptionStatus()
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
                        .frame(width: geometry.size.width, height: geometry.size.height * 0.55, alignment: .center)
                        .clipped()

                    Spacer()
                }

                // Nửa dưới: Đen theo theme
                VStack {
                    Spacer()
                    AivoTheme.Primary.blackOrangeDark
                        .opacity(0.9)
                        .frame(height: geometry.size.height * 0.45)
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
                        AivoTheme.Primary.orange.opacity(0.08)
                    ]),
                    startPoint: .center,
                    endPoint: .bottom
                )
            }
            .ignoresSafeArea()
            .drawingGroup()
        }
    }

    private var header: some View {
        HStack {
            Spacer()
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.15))
                    .clipShape(Circle())
            }
        }
        .padding(.top, 50)
    }

    // MARK: - Active Subscription View
    private func activeSubscriptionView(subscription: SubscriptionInfo) -> some View {
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
                if let expiryDate = subscription.expiryDate {
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
        HStack { Text("Upgrade to Premium")
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
//                HStack(spacing: 8) {
//                    Text("Your credit:")
//                        .font(.system(size: 16, weight: .medium))
//                        .foregroundColor(.white)
//                        .padding(.leading, 12)
//                        //.padding(.top, 8)
//                    Spacer()
//                }
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
            //.padding(.top, 20)
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
            featureRow("1000 credits per week")
            featureRow("Access to All Features")
            featureRow("Ad-Free experience")
            featureRow("Premium quality AI Song")
            featureRow("Unlimited downloads")
        }
        .padding(.top, 18)
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
            if let yearlyProduct = subscriptionManager.getProduct(for: .premiumYearly) {
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
            if let weeklyProduct = subscriptionManager.getProduct(for: .premiumWeekly) {
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
                    subtitle: "1200 credits per week",
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
//                    Text(subtitle)
//                        .foregroundColor(.white.opacity(0.7))
//                        .font(.system(size: 13, weight: .regular))
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
                Text(isPurchasing ? "Processing..." : "Continue For Payment")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .background(
                Capsule()
                    .fill(isPurchasing ? AivoTheme.Primary.orange.opacity(0.6) : AivoTheme.Primary.orange)
            )
        }
        .disabled(isPurchasing || subscriptionManager.isLoading)
        .padding(.top, 18)
    }
    
    private func handlePurchase() {
        guard !isPurchasing else { return }
        
        let productID: SubscriptionManager.ProductIdentifier = selectedPlan == .yearly ? .premiumYearly : .premiumWeekly
        
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
                Text("|")
                Button("Restore") {
                    handleRestore()
                }
            }
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(.white.opacity(0.7))
            .padding(.top, 10)
        }
    }
    
    private func handleRestore() {
        Logger.i("📱 [SubscriptionScreen] Restoring purchases")
        subscriptionManager.restorePurchases()
    }
}

struct SubscriptionScreen_Previews: PreviewProvider {
    static var previews: some View {
        SubscriptionScreen()
    }
}
