import SwiftUI

struct VIPTrialInfoDialog: View {
    @Binding var isPresented: Bool
    @State private var timeRemainingString = ""
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    // Light blue gradient colors for VIP Trial
    private let vipBlueStart = Color(red: 0.12, green: 0.53, blue: 0.90)
    private let vipBlueEnd   = Color(red: 0.23, green: 0.87, blue: 0.96)
    
    var body: some View {
        VStack(spacing: 24) {
            // Crown Icon with Blue Radial Gradient Glow
            ZStack {
                Circle()
                    .fill(RadialGradient(
                        gradient: Gradient(colors: [vipBlueStart.opacity(0.4), .clear]),
                        center: .center,
                        startRadius: 0,
                        endRadius: 60
                    ))
                    .frame(width: 110, height: 110)
                
                Image(systemName: "crown.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [vipBlueStart, vipBlueEnd],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: vipBlueStart.opacity(0.5), radius: 10, x: 0, y: 5)
            }
            .padding(.top, 10)
            
            // Info text
            VStack(spacing: 10) {
                Text("VIP Trial Active")
                    .font(.system(size: 22, weight: .black))
                    .foregroundColor(.white)
                
                Text("Time Remaining")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white.opacity(0.5))
                
                Text(timeRemainingString)
                    .font(.system(size: 32, weight: .black, design: .monospaced))
                    .foregroundColor(vipBlueEnd)
                    .padding(.vertical, 4)
                    .onReceive(timer) { _ in
                        updateTimeRemaining()
                    }
                    .onAppear {
                        updateTimeRemaining()
                    }
            }
            
            // Features list
            VStack(spacing: 12) {
                benefitRow(icon: "music.note", title: "Unlock AI Song Generation")
                benefitRow(icon: "mic.fill", title: "Unlock AI Song Cover")
                benefitRow(icon: "doc.text.fill", title: "Unlock AI Lyrics Generation")
                benefitRow(icon: "bolt.fill", title: "Fast Server Generation Speed")
            }
            .padding(.vertical, 8)
            
            // Buttons
            VStack(spacing: 12) {
                // Buy Premium Button
                Button(action: {
                    isPresented = false
                    NotificationCenter.default.post(name: NSNotification.Name("ShowSubscriptionScreen"), object: nil)
                }) {
                    HStack {
                        Image(systemName: "crown.fill")
                        Text("Upgrade to Ad-Free Premium")
                            .fontWeight(.bold)
                    }
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        LinearGradient(
                            colors: [Color.orange, Color.red],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(26)
                    .shadow(color: Color.orange.opacity(0.4), radius: 10, y: 4)
                }
                
                // OK / Dismiss Button
                Button(action: {
                    withAnimation {
                        isPresented = false
                    }
                }) {
                    Text("Got it")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white.opacity(0.6))
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(22)
                }
            }
        }
        .padding(24)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(hex: "#121214"))
                
                RoundedRectangle(cornerRadius: 24)
                    .stroke(
                        LinearGradient(
                            colors: [vipBlueStart, vipBlueEnd.opacity(0.3), vipBlueStart],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: vipBlueStart.opacity(0.2), radius: 15)
        .shadow(color: .black.opacity(0.55), radius: 35)
        .padding(.horizontal, 32)
    }
    
    private func benefitRow(icon: String, title: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(vipBlueEnd)
                .frame(width: 28, height: 28)
                .background(vipBlueEnd.opacity(0.12))
                .clipShape(Circle())
            
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.85))
            
            Spacer()
        }
        .padding(.horizontal, 12)
    }
    
    private func updateTimeRemaining() {
        guard let expiry = UserDefaults.standard.object(forKey: "VIPTrialExpiryDate") as? Date else {
            timeRemainingString = "00:00"
            return
        }
        let diff = expiry.timeIntervalSince(Date())
        guard diff > 0 else {
            timeRemainingString = "00:00"
            return
        }
        let hours = Int(diff) / 3600
        let minutes = (Int(diff) % 3600) / 60
        let seconds = Int(diff) % 60
        
        if hours > 0 {
            timeRemainingString = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            timeRemainingString = String(format: "%02d:%02d", minutes, seconds)
        }
    }
}
