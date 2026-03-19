import SwiftUI
import AVFoundation

// MARK: - Shape: Only top corners rounded
struct TopRoundedRectangle: Shape {
    var radius: CGFloat = 16

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let r = min(min(radius, rect.width / 2), rect.height / 2)

        // Bắt đầu từ góc dưới trái
        p.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        // Lên cạnh trái đến chỗ bo góc
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY + r))
        // Bo góc trên trái
        p.addQuadCurve(to: CGPoint(x: rect.minX + r, y: rect.minY),
                       control: CGPoint(x: rect.minX, y: rect.minY))
        // Cạnh trên
        p.addLine(to: CGPoint(x: rect.maxX - r, y: rect.minY))
        // Bo góc trên phải
        p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY + r),
                       control: CGPoint(x: rect.maxX, y: rect.minY))
        // Xuống cạnh phải về đáy
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        // Đóng path (cạnh dưới phẳng)
        p.closeSubpath()
        return p
    }
}

// MARK: - Playing Banner View
struct PlayingBannerView: View {
    @StateObject private var musicPlayer = MusicPlayer.shared
    @StateObject private var onlinePlayer = OnlineStreamPlayer.shared
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @State private var showFullPlayer = false

    private let cornerRadius: CGFloat = 16
    
    // Determine which player is active
    private var isOnlinePlaying: Bool {
        // Prioritize online player if it's playing or has a song and offline player is stopped
        return onlinePlayer.currentSong != nil && (onlinePlayer.isPlaying || musicPlayer.currentSong == nil || !musicPlayer.isPlaying)
    }
    
    private var activeSong: SunoData? {
        if isOnlinePlaying {
            return onlinePlayer.currentSong
        } else {
            return musicPlayer.currentSong
        }
    }

    var body: some View {
        if let currentSong = activeSong {
            let shape = TopRoundedRectangle(radius: cornerRadius)

            HStack(spacing: iPadScaleSmall(12)) {
                // Album Art - Check local cover first (for imported songs), then remote URL
                Group {
                    if let localCoverURL = SunoDataManager.shared.getLocalCoverPath(for: currentSong.id),
                       let uiImage = UIImage(contentsOfFile: localCoverURL.path) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else if !currentSong.imageUrl.isEmpty, let url = URL(string: currentSong.imageUrl) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Image("demo_cover")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        }
                    } else {
                        Image("demo_cover")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    }
                }
                .frame(width: iPadScale(40), height: iPadScale(40))
                .clipShape(RoundedRectangle(cornerRadius: 8))

                // Song Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(currentSong.title)
                        .font(.system(size: iPadScale(16), weight: .medium))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    Text(currentSong.username ?? "Aivo Music")
                        .font(.system(size: iPadScale(14)))
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Control Buttons
                HStack(spacing: iPadScaleSmall(8)) {
                    // Play/Pause Button
                    Button(action: {
                        if isOnlinePlaying {
                            onlinePlayer.togglePlayPause()
                        } else {
                            musicPlayer.togglePlayPause()
                        }
                    }) {
                        Image(systemName: (isOnlinePlaying ? onlinePlayer.isPlaying : musicPlayer.isPlaying) ? "pause.fill" : "play.fill")
                            .font(.system(size: iPadScale(20)))
                            .foregroundColor(.white)
                            .frame(width: iPadScale(36), height: iPadScale(36))
                            .background(Color.white.opacity(0.2))
                            .clipShape(Circle())
                    }

                    // Close Button
                    Button(action: {
                        if isOnlinePlaying {
                            onlinePlayer.stop()
                        } else {
                            musicPlayer.stop()
                        }
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: iPadScale(16), weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: iPadScale(36), height: iPadScale(36))
                            .background(Color.white.opacity(0.2))
                            .clipShape(Circle())
                    }
                }
            }
            .padding(.horizontal, iPadScaleSmall(12))
            .padding(.vertical, iPadScaleSmall(8))
            .background(
                Group {
                    if subscriptionManager.isPremium {
                        TopRoundedRectangle(radius: cornerRadius)
                            .fill(AivoTheme.Primary.blackOrange.opacity(0.9))
                    } else {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(AivoTheme.Primary.blackOrange.opacity(0.9))
                    }
                }
            )
            .overlay(
                Group {
                    if subscriptionManager.isPremium {
                        TopRoundedRectangle(radius: cornerRadius)
                            .stroke(AivoTheme.Primary.orange.opacity(0.8), lineWidth: 1)
                    } else {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(AivoTheme.Primary.orange.opacity(0.8), lineWidth: 1)
                    }
                }
            )
            .padding(.horizontal, subscriptionManager.isPremium ? 0 : 12)
            .padding(.bottom, subscriptionManager.isPremium ? 0 : 12)
            .onTapGesture { showFullPlayer = true }
            .fullScreenCover(isPresented: $showFullPlayer) {
                if isOnlinePlaying {
                    PlayOnlineSongScreen(
                        songs: onlinePlayer.songs,
                        initialIndex: onlinePlayer.currentIndex
                    )
                } else {
                    PlayMySongScreen(
                        songs: musicPlayer.songs,
                        initialIndex: musicPlayer.currentIndex
                    )
                }
            }
        }
    }
}

// MARK: - Preview
struct PlayingBannerView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack {
                Spacer()
                PlayingBannerView()
            }
        }
        .preferredColorScheme(.dark)
    }
}
