import SwiftUI

struct BillboardIntroDialog: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.8)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }
            
            // Dialog Content
            VStack(spacing: 0) {
                // Header with Title and Close Button
                HStack {
                    Text("New Feature!")
                        .font(.system(size: iPadScale(20), weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark")
                            .font(.system(size: iPadScale(16), weight: .bold))
                            .foregroundColor(.white.opacity(0.6))
                            .frame(width: iPadScale(32), height: iPadScale(32))
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
                .padding(.bottom, iPadScaleSmall(16))
                
                // Crown Icon with Glow
                ZStack {
                    Circle()
                        .fill(RadialGradient(
                            gradient: Gradient(colors: [AivoTheme.Primary.orange.opacity(0.6), .clear]),
                            center: .center,
                            startRadius: 0,
                            endRadius: iPadScale(60)
                        ))
                        .frame(width: iPadScale(120), height: iPadScale(120))
                    
                    Image("icon_trophy_2")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: iPadScale(80), height: iPadScale(80))
                        .shadow(color: .orange.opacity(0.5), radius: 10, x: 0, y: 5)
                }
                .padding(.bottom, iPadScaleSmall(12))
                
                Text("Weekly Billboard Event")
                    .font(.system(size: iPadScale(22), weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, iPadScaleSmall(8))
                
                Text("The Weekly Billboard is officially live, celebrating the most listened-to tracks. Create your unique masterpiece and share it with the community to join the race now!")
                    .font(.system(size: iPadScale(15)))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, iPadScaleSmall(20))
                
                // Rewards Table
                VStack(spacing: 0) {
                    HStack {
                        Image(systemName: "trophy.fill")
                            .foregroundColor(.yellow)
                        Text("Top 10 Rewards")
                            .font(.system(size: iPadScale(16), weight: .bold))
                            .foregroundColor(.yellow)
                    }
                    .padding(.bottom, iPadScaleSmall(16))
                    
                    rewardRow(rank: "#1", credit: "1000", isTop: true)
                    Divider().background(Color.white.opacity(0.1)).padding(.vertical, iPadScaleSmall(8))
                    rewardRow(rank: "#2", credit: "500")
                    Divider().background(Color.white.opacity(0.1)).padding(.vertical, iPadScaleSmall(8))
                    rewardRow(rank: "#3", credit: "300")
                    Divider().background(Color.white.opacity(0.1)).padding(.vertical, iPadScaleSmall(8))
                    rewardRow(rank: "#4-10", credit: "200")
                }
                .padding(.horizontal, iPadScaleSmall(20))
                .padding(.vertical, iPadScaleSmall(16))
                .background(
                    RoundedRectangle(cornerRadius: iPadScale(24))
                        .fill(Color.black.opacity(0.4))
                        .overlay(
                            RoundedRectangle(cornerRadius: iPadScale(24))
                                .stroke(LinearGradient(colors: [.orange.opacity(0.5), .clear, .orange.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
                        )
                )
                .padding(.horizontal, iPadScaleSmall(8))
                .padding(.bottom, iPadScaleSmall(24))
                
                // Action Buttons
                VStack(spacing: 0) {
                    Button(action: {
                        isPresented = false
                        // Switch to Generate Song tab (index 1: explore=0, home=1, cover=2, library=3)
                        NotificationCenter.default.post(name: NSNotification.Name("SwitchMainTab"), object: 1)
                    }) {
                        Text("Create a Track Now")
                            .font(.system(size: iPadScale(18), weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, iPadScaleSmall(14))
                            .background(
                                LinearGradient(
                                    colors: [AivoTheme.Primary.orange, AivoTheme.Primary.orangeDark],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .cornerRadius(iPadScale(30))
                            .shadow(color: AivoTheme.Primary.orange.opacity(0.4), radius: 10, x: 0, y: 5)
                    }
                }
            }
            .padding(iPadScaleSmall(20))
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: iPadScale(32))
                        .fill(AivoTheme.Primary.blackOrangeDark)
                    
                    RoundedRectangle(cornerRadius: iPadScale(32))
                        .stroke(LinearGradient(colors: [.orange.opacity(0.6), .clear, .orange.opacity(0.4)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 2)
                }
            )
            .padding(.horizontal, DeviceScale.isIPad ? 100 : 20)
            .shadow(color: .black.opacity(0.5), radius: 40)
        }
    }
    
    private func rewardRow(rank: String, credit: String, isTop: Bool = false) -> some View {
        HStack {
            Text(rank)
                .font(.system(size: iPadScale(20), weight: .black))
                .foregroundColor(isTop ? .yellow : .white)
            
            if isTop {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                    .font(.system(size: iPadScale(12)))
            }
            
            Spacer()
            
            HStack(spacing: 4) {
                Image("icon_coin")
                    .resizable()
                    .frame(width: iPadScale(20), height: iPadScale(20))
                Text(credit)
                    .font(.system(size: iPadScale(18), weight: .bold))
                    .foregroundColor(.white)
            }
        }
    }
}

#Preview {
    BillboardIntroDialog(isPresented: .constant(true))
}
