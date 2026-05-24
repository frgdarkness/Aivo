import SwiftUI

struct VIPTrialFloatingIndicator: View {
    let onTap: () -> Void
    @State private var countdownText = "59:59"
    @State private var bounceAnim = false
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    private let cyanStart = Color(red: 0.0, green: 0.7, blue: 1.0)
    private let cyanEnd   = Color(red: 0.0, green: 0.95, blue: 1.0)
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                // Crown icon
                Image(systemName: "crown.fill")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(cyanEnd)
                    .scaleEffect(bounceAnim ? 1.12 : 0.95)
                    .frame(width: 26, height: 20)
                    .padding(.bottom, 2)
                
                // Countdown text
                Text(countdownText)
                    .font(.system(size: 15, weight: .bold, design: .monospaced))
                    .foregroundColor(cyanEnd)
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
                                    colors: [cyanStart, cyanEnd],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                    .shadow(color: cyanStart.opacity(0.3), radius: 4)
            )
        }
        .buttonStyle(.plain)
        .onReceive(timer) { _ in
            updateCountdown()
        }
        .onAppear {
            updateCountdown()
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                bounceAnim = true
            }
        }
    }
    
    private func updateCountdown() {
        guard let expiry = UserDefaults.standard.object(forKey: "VIPTrialExpiryDate") as? Date else {
            countdownText = "60:00"
            return
        }
        let diff = expiry.timeIntervalSince(Date())
        guard diff > 0 else {
            countdownText = "00:00"
            return
        }
        let totalSeconds = Int(diff)
        if totalSeconds >= 3600 {
            let hours = totalSeconds / 3600
            let minutes = (totalSeconds % 3600) / 60
            let seconds = totalSeconds % 60
            countdownText = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            let minutes = totalSeconds / 60
            let seconds = totalSeconds % 60
            countdownText = String(format: "%02d:%02d", minutes, seconds)
        }
    }
}

#Preview("VIP Trial Floating Indicator") {
    VIPTrialFloatingIndicator {
        print("VIP indicator tapped")
    }
    .padding()
    .background(Color.gray.opacity(0.2))
}
