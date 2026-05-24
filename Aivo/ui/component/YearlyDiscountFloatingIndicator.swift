import SwiftUI

struct YearlyDiscountFloatingIndicator: View {
    let onTap: () -> Void
    @State private var countdownText = "59:59"
    @State private var bounceAnim = false
    @State private var isVisible = true
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    private let giftGoldStart = Color(red: 1.0, green: 0.55, blue: 0.1)
    private let giftGoldEnd   = Color(red: 0.95, green: 0.3, blue: 0.15)
    
    var body: some View {
        if isVisible {
            Button(action: onTap) {
                HStack(spacing: 4) {
                    // Gift icon
                    Text("🎁")
                        .font(.system(size: 17))
                        .scaleEffect(bounceAnim ? 1.12 : 0.95)
                        .frame(width: 26, height: 20)
                    
                    // Countdown text
                    Text(countdownText)
                        .font(.system(size: 15, weight: .bold, design: .monospaced))
                        .foregroundColor(giftGoldStart)
                }
                .padding(.horizontal, 10)
                .frame(height: 42)
                .background(
                    Capsule()
                        .fill(Color.black.opacity(0.85))
                        .overlay(
                            Capsule()
                                .stroke(
                                    LinearGradient(
                                        colors: [giftGoldStart, giftGoldEnd],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        )
                        .shadow(color: giftGoldStart.opacity(0.3), radius: 4)
                )
            }
            .buttonStyle(.plain)
            .onReceive(timer) { _ in
                updateCountdown()
            }
            .onAppear {
                initializeExpiryIfNeeded()
                updateCountdown()
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    bounceAnim = true
                }
            }
        }
    }
    
    private func initializeExpiryIfNeeded() {
        if UserDefaults.standard.object(forKey: "YearlyDiscountExpiryDate") == nil {
            let expiry = Date().addingTimeInterval(3600) // 60 minutes
            UserDefaults.standard.set(expiry, forKey: "YearlyDiscountExpiryDate")
        }
    }
    
    private func updateCountdown() {
        guard let expiry = UserDefaults.standard.object(forKey: "YearlyDiscountExpiryDate") as? Date else {
            countdownText = "60:00"
            return
        }
        let diff = expiry.timeIntervalSince(Date())
        if diff <= 0 {
            countdownText = "00:00"
            isVisible = false
            return
        }
        let minutes = Int(diff) / 60
        let seconds = Int(diff) % 60
        countdownText = String(format: "%d:%02d", minutes, seconds)
    }
}

#Preview("VIP Trial Floating Indicator") {
    YearlyDiscountFloatingIndicator {
        print("VIP indicator tapped")
    }
    .padding()
    .background(Color.gray.opacity(0.2))
}
