import SwiftUI

// MARK: - Playing Banner View
struct PlayingBannerView: View {
    @StateObject private var musicPlayer = MusicPlayer.shared
    @State private var showFullPlayer = false
    
    var body: some View {
        if let currentSong = musicPlayer.currentSong {
            HStack(spacing: 12) {
                // Album Art
                AsyncImage(url: URL(string: currentSong.imageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image("demo_cover")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                }
                .frame(width: 40, height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                
                // Song Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(currentSong.title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text(currentSong.modelName)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Control Buttons
                HStack(spacing: 8) {
                    // Play/Pause Button
                    Button(action: {
                        musicPlayer.togglePlayPause()
                    }) {
                        Image(systemName: musicPlayer.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Circle())
                    }
                    
                    // Close Button
                    Button(action: {
                        musicPlayer.stop()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Circle())
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.black.opacity(0.9))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(AivoTheme.Primary.orange.opacity(0.6), lineWidth: 1)
                    )
            )
            .onTapGesture {
                showFullPlayer = true
            }
            .fullScreenCover(isPresented: $showFullPlayer) {
                PlayMySongScreen(
                    songs: musicPlayer.songs,
                    initialIndex: musicPlayer.currentIndex
                )
            }
        }
    }
}

// MARK: - Preview
struct PlayingBannerView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black
            VStack {
                Spacer()
                PlayingBannerView()
            }
        }
    }
}
