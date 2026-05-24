import SwiftUI

struct WelcomeGiftDialog: View {
    let onOpenGift: () -> Void
    
    @State private var bounceIcon = false
    @State private var glowAnimation = false
    
    private let giftGoldStart = Color(red: 1.0, green: 0.55, blue: 0.1)
    private let giftGoldEnd   = Color(red: 0.95, green: 0.3, blue: 0.15)
    
    var body: some View {
        VStack(spacing: 20) {
            // Gift icon with glow
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.4), .clear],
                            center: .center,
                            startRadius: 20,
                            endRadius: 70
                        )
                    )
                    .frame(width: 140, height: 140)
                    .scaleEffect(glowAnimation ? 1.2 : 0.9)
                
                Image("icon_gift_yes")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .scaleEffect(bounceIcon ? 1.08 : 0.95)
                    .shadow(color: giftGoldStart.opacity(0.5), radius: 12, y: 5)
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    bounceIcon = true
                    glowAnimation = true
                }
            }
            
            Text("🎉 Welcome Gift!")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text("You have a special gift waiting!\nTap to unwrap your exclusive offer.")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
            
            // Open Gift Button
            Button(action: onOpenGift) {
                HStack(spacing: 12) {
                    Image(systemName: "gift.fill")
                        .font(.system(size: 18, weight: .bold))
                    Text("Open Gift")
                        .font(.system(size: 18, weight: .bold))
                }
                .foregroundColor(.white)
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
            .padding(.horizontal, 8)
        }
        .padding(28)
        .padding(.top, 12)
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
                                colors: [Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.5), Color(red: 1.0, green: 0.49, blue: 0.2).opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .shadow(color: Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.15), radius: 20, x: 0, y: 10)
        )
        .padding(.horizontal, 28)
        .transition(.scale(scale: 0.5).combined(with: .opacity))
    }
}
