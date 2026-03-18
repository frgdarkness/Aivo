import SwiftUI

struct BillboardCongratsDialog: View {
    @Binding var isPresented: Bool
    let rank: Int
    let song: SunoData?
    let rewardAmount: Int
    
    private var rankLabel: String {
        switch rank {
        case 1: return "1ST PLACE"
        case 2: return "2ND PLACE"
        case 3: return "3RD PLACE"
        default: return "\(rank)TH PLACE"
        }
    }
    
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
                // Crown Icon with Glow (same style as Intro)
                ZStack {
                    Circle()
                        .fill(RadialGradient(
                            gradient: Gradient(colors: [AivoTheme.Primary.orange.opacity(0.6), .clear]),
                            center: .center,
                            startRadius: 0,
                            endRadius: iPadScale(60)
                        ))
                        .frame(width: iPadScale(120), height: iPadScale(120))
                    
                    Image("icon_trophy")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: iPadScale(80), height: iPadScale(80))
                        .shadow(color: .orange.opacity(0.5), radius: 10, x: 0, y: 5)
                }
                .padding(.bottom, iPadScaleSmall(12))
                
                // Title
                HStack(spacing: 8) {
                    Text("🎉")
                    Text("CONGRATULATIONS!")
                        .font(.system(size: iPadScale(22), weight: .black))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.yellow, .white, .yellow],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
                .shadow(color: .orange.opacity(0.4), radius: 6)
                .padding(.bottom, iPadScaleSmall(6))
                
                Text("You made the Weekly Billboard")
                    .font(.system(size: iPadScale(15)))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.bottom, iPadScaleSmall(20))
                
                // Song Card with Rank
                if let song = song {
                    HStack(spacing: iPadScaleSmall(16)) {
                        // Song Cover
                        AsyncImage(url: URL(string: song.imageUrl)) { image in
                            image.resizable().aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Image("demo_cover").resizable().aspectRatio(contentMode: .fill)
                        }
                        .frame(width: iPadScale(80), height: iPadScale(80))
                        .clipShape(RoundedRectangle(cornerRadius: iPadScale(12)))
                        .overlay(
                            RoundedRectangle(cornerRadius: iPadScale(12))
                                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                        )
                        
                        // Song Info
                        VStack(alignment: .leading, spacing: iPadScaleSmall(4)) {
                            Text("#\(rank)")
                                .font(.system(size: iPadScale(36), weight: .black))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.yellow, .orange],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .shadow(color: .orange.opacity(0.6), radius: 6)
                            
                            Text(song.title)
                                .font(.system(size: iPadScale(16), weight: .bold))
                                .foregroundColor(.white)
                                .lineLimit(1)
                            
                            Text("by \(song.username ?? "Aivo Music")")
                                .font(.system(size: iPadScale(13)))
                                .foregroundColor(.white.opacity(0.6))
                                .lineLimit(1)
                        }
                        
                        Spacer()
                    }
                    .padding(iPadScaleSmall(16))
                    .background(
                        RoundedRectangle(cornerRadius: iPadScale(20))
                            .fill(Color.black.opacity(0.4))
                            .overlay(
                                RoundedRectangle(cornerRadius: iPadScale(20))
                                    .stroke(LinearGradient(colors: [.orange.opacity(0.5), .clear, .orange.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, iPadScaleSmall(4))
                    .padding(.bottom, iPadScaleSmall(20))
                }
                
                // Divider
                Rectangle()
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 1)
                    .padding(.horizontal, iPadScaleSmall(10))
                    .padding(.bottom, iPadScaleSmall(16))
                
                // Earned Credits
                Text("You earned")
                    .font(.system(size: iPadScale(15)))
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.bottom, iPadScaleSmall(6))
                
                HStack(spacing: 8) {
                    Image("icon_coin")
                        .resizable()
                        .frame(width: iPadScale(32), height: iPadScale(32))
                    
                    Text("\(rewardAmount)")
                        .font(.system(size: iPadScale(36), weight: .black))
                        .foregroundColor(.white)
                    
                    Text("Credits")
                        .font(.system(size: iPadScale(20), weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.bottom, iPadScaleSmall(24))
                
                // Buttons
                VStack(spacing: iPadScaleSmall(12)) {
                    Button(action: { isPresented = false }) {
                        Text("Claim Reward")
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
                    }.padding(.bottom, iPadScaleSmall(12))
                    
//                    Button(action: { /* Share action */ }) {
//                        HStack(spacing: 6) {
//                            Image(systemName: "square.and.arrow.up")
//                                .font(.system(size: iPadScale(14)))
//                            Text("Share Achievement")
//                                .font(.system(size: iPadScale(15), weight: .medium))
//                        }
//                        .foregroundColor(.white.opacity(0.7))
//                    }
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
    
    private func compactRewardRow(rank: String, credit: String) -> some View {
        HStack {
            Spacer()
            Text(rank)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 50)
            
            Image("icon_coin")
                .resizable()
                .frame(width: 16, height: 16)
            
            Text(credit)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 40, alignment: .leading)
            Spacer()
        }
        .padding(.vertical, 3)
    }
}

#Preview {
    BillboardCongratsDialog(isPresented: .constant(true), rank: 1, song: SunoData.mock, rewardAmount: 1000)
}
