import SwiftUI
import StoreKit

struct YearlyDiscountDialog: View {
    @Binding var isPresented: Bool
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @State private var isPurchasing = false
    @State private var errorMessage: String? = nil
    
    @State private var showCloseAlert = false
    @State private var remainingSeconds: Int = 3600
    @State private var bounceIcon = false
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    // Theme colors matching ThemeProject and Aivo
    private let giftGoldStart = Color(red: 1.0, green: 0.55, blue: 0.1)
    private let giftGoldEnd   = Color(red: 0.95, green: 0.3, blue: 0.15)
    
    var body: some View {
        ZStack {
            // Screen-level dark backdrop (only active when close alert is shown)
            if showCloseAlert {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showCloseAlert = false
                        }
                    }
                    .transition(.opacity)
            }
            
            // Main Card Container
            VStack(spacing: 0) {
                // Top Close Button
                HStack {
                    Spacer()
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showCloseAlert = true
                        }
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white.opacity(0.5))
                            .padding(6)
                            .background(Circle().fill(Color.white.opacity(0.1)))
                    }
                    .disabled(isPurchasing)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                
                // Title
                Text("🎉 Exclusive Offer")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.top, 2)
                
                // Gift Icon with Glow
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [giftGoldStart.opacity(0.35), .clear],
                                center: .center,
                                startRadius: 20,
                                endRadius: 70
                            )
                        )
                        .frame(width: 130, height: 130)
                    
                    Image("icon_gift_yes")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 76, height: 76)
                        .scaleEffect(bounceIcon ? 1.08 : 0.95)
                        .shadow(color: giftGoldStart.opacity(0.5), radius: 10, y: 4)
                }
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                        bounceIcon = true
                    }
                }
                .padding(.top, 4)
                
                // Special Offer: 45% OFF
                Text("Special Offer: 45% OFF")
                    .font(.system(size: 26, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [giftGoldStart, giftGoldEnd],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .padding(.top, 2)
                
                // Plan name
                Text("Premium Yearly Plan")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.top, 6)
                
                Text("Unlock permanent access to VIP features,\nadvanced AI models & daily credits")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.65))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.top, 4)
                
                // Price Display with Strikethrough
                VStack(spacing: 4) {
                    Text("$89.99")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                        .strikethrough(true, color: giftGoldEnd)
                    
                    HStack(alignment: .bottom, spacing: 4) {
                        Text("$49.99")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundColor(giftGoldStart)
                        Text("/year")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                            .padding(.bottom, 6)
                    }
                }
                .padding(.top, 10)
                
                // Countdown Timer Pill
                HStack(spacing: 8) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 12))
                        .foregroundColor(remainingSeconds <= 60 ? .red : giftGoldStart)
                    Text("Expires in \(formatCountdown(remainingSeconds))")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(remainingSeconds <= 60 ? .red : giftGoldStart)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill((remainingSeconds <= 60 ? Color.red : giftGoldStart).opacity(0.12))
                )
                .padding(.top, 8)
                
                if let error = errorMessage {
                    Text(error)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                }
                
                // Purchase Button
                Button(action: handlePurchase) {
                    ZStack {
                        if isPurchasing {
                            HStack(spacing: 8) {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                Text("Processing...")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        } else {
                            HStack(spacing: 12) {
                                Image(systemName: "gift.fill")
                                    .font(.system(size: 16, weight: .bold))
                                Text("Claim Your Gift")
                                    .font(.system(size: 17, weight: .bold))
                            }
                            .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        LinearGradient(
                            colors: [giftGoldStart, giftGoldEnd],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
                    .shadow(color: giftGoldStart.opacity(0.4), radius: 10, y: 4)
                }
                .disabled(isPurchasing)
                .padding(.horizontal, 20)
                .padding(.top, 14)
                
                Text("Auto renewal · Cancel anytime")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.35))
                    .padding(.top, 8)
                    .padding(.bottom, 18)
            }
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#1C1C2E"), Color(hex: "#2A1F3D")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [giftGoldStart.opacity(0.4), giftGoldEnd.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                    .shadow(color: giftGoldStart.opacity(0.1), radius: 20, x: 0, y: 10)
            )
            .padding(.horizontal, 28)
            .transition(.scale(scale: 0.6).combined(with: .opacity))
            .disabled(showCloseAlert)
            
            // Close confirmation overlay (shows inside YearlyDiscountDialog view bounds)
            if showCloseAlert {
                ZStack {
                    VStack(spacing: 14) {
                        Text("⏳")
                            .font(.system(size: 36))
                        
                        Text("This offer is for new users only\nand expires soon!")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .lineSpacing(3)
                        
                        Text("You'll lose this deal if you leave.")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(giftGoldEnd)
                        
                        HStack(spacing: 16) {
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    showCloseAlert = false
                                }
                            }) {
                                Text("Cancel")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 44)
                                    .background(Color.white.opacity(0.12))
                                    .clipShape(Capsule())
                            }
                            
                            Button(action: {
                                withAnimation {
                                    showCloseAlert = false
                                    isPresented = false
                                }
                            }) {
                                Text("Close")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 44)
                                    .background(
                                        LinearGradient(
                                            colors: [giftGoldStart, giftGoldEnd],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .clipShape(Capsule())
                            }
                        }
                        .padding(.top, 8)
                    }
                    .padding(22)
                    .background(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "#1C1C2E"), Color(hex: "#2A1F3D")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 22, style: .continuous)
                                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, 16)
                }
                .zIndex(10)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            updateRemaining()
        }
        .onReceive(timer) { _ in
            updateRemaining()
        }
    }
    
    private func updateRemaining() {
        guard let expiry = UserDefaults.standard.object(forKey: "YearlyDiscountExpiryDate") as? Date else {
            remainingSeconds = 3600
            return
        }
        let diff = expiry.timeIntervalSince(Date())
        remainingSeconds = max(0, Int(diff))
    }
    
    private func formatCountdown(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
    
    private func handlePurchase() {
        guard !isPurchasing else { return }
        
        guard let product = subscriptionManager.getProduct(for: .yearlyDiscount) else {
            errorMessage = "Discount plan not found. Please try again later."
            return
        }
        
        isPurchasing = true
        errorMessage = nil
        
        Task {
            do {
                let success = try await subscriptionManager.purchaseSubscription(product)
                await MainActor.run {
                    isPurchasing = false
                    if success {
                        withAnimation {
                            isPresented = false
                        }
                    } else if let errorMsg = subscriptionManager.errorMessage {
                        errorMessage = errorMsg
                    }
                }
            } catch {
                await MainActor.run {
                    isPurchasing = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}
