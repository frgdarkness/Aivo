import SwiftUI

struct VIPTrialGiftDialog: View {
    @Binding var isPresented: Bool
    @State private var showCloseAlert = false
    @State private var bounceIcon = false
    
    // Read the credit amount we saved when granting the trial
    private var creditAmount: Int {
        let saved = UserDefaults.standard.integer(forKey: "VIPTrialGiftCreditsAmount")
        return saved > 0 ? saved : 60
    }
    
    // Light blue gradient colors for VIP Trial
    private let vipBlueStart = Color(red: 0.12, green: 0.53, blue: 0.90)
    private let vipBlueEnd   = Color(red: 0.23, green: 0.87, blue: 0.96)
    
    var body: some View {
        ZStack {
            // Content Card
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
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                
                // Header Icon with Blue Glow
                ZStack {
                    Circle()
                        .fill(RadialGradient(
                            gradient: Gradient(colors: [vipBlueStart.opacity(0.4), .clear]),
                            center: .center,
                            startRadius: 0,
                            endRadius: 65
                        ))
                        .frame(width: 120, height: 120)
                    
                    Image("icon_gift_yes")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .scaleEffect(bounceIcon ? 1.08 : 0.95)
                        .shadow(color: vipBlueStart.opacity(0.5), radius: 12, x: 0, y: 5)
                }
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                        bounceIcon = true
                    }
                }
                
                // Content Titles
                VStack(spacing: 12) {
                    Text("Welcome Gift!")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("We've credited your account with free credits and a premium test drive!")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 10)
                    
                    // Rewards display container
                    VStack(spacing: 16) {
                        // VIP Trial Pill
                        HStack(spacing: 12) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("1 Hour VIP Trial")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                Text("Full access to premium features (with ads)")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .frame(height: 60)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    LinearGradient(
                                        colors: [vipBlueStart, vipBlueEnd],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                        
                        // Credit Pill
                        HStack(spacing: 12) {
                            Image("icon_coin")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 32, height: 32)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("+\(creditAmount) Credits")
                                    .font(.system(size: 18, weight: .black))
                                    .foregroundColor(.white)
                                Text("Generate lyrics, songs and covers")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .frame(height: 60)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.08))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        )
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 20)
                
                // Start Button
                Button(action: {
                    withAnimation {
                        isPresented = false
                    }
                }) {
                    Text("Start VIP Trial")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            LinearGradient(
                                colors: [vipBlueStart, vipBlueEnd],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                        .shadow(color: vipBlueStart.opacity(0.4), radius: 10, y: 4)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
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
                                    colors: [vipBlueStart, vipBlueEnd.opacity(0.3), vipBlueStart],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                    .shadow(color: vipBlueStart.opacity(0.1), radius: 20, x: 0, y: 10)
            )
            .padding(.horizontal, 28)
            
            // Close confirmation overlay
            if showCloseAlert {
                ZStack {
                    Color.black.opacity(0.7)
                        .cornerRadius(28)
                    
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
                            .foregroundColor(.red)
                        
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
                                            colors: [vipBlueStart, vipBlueEnd],
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
    }
}
