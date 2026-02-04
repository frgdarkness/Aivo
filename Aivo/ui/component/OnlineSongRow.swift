import SwiftUI
import Kingfisher

struct OnlineSongRow: View {
    let song: SunoData
    let isPlaying: Bool
    let onPlayPause: (() -> Void)?
    
    var body: some View {
        HStack(spacing: 12) {
            // Cover Image
            KFImage(URL(string: song.imageUrl.isEmpty ? song.sourceImageUrl : song.imageUrl))
                .placeholder {
                    ZStack {
                        Color.gray.opacity(0.2)
                        ProgressView()
                            .tint(.white)
                    }
                }
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 50, height: 50)
                .cornerRadius(8)
                .clipped()
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(song.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(song.modelName)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Play/Pause button for currently playing song
            if isPlaying {
                Button(action: {
                    onPlayPause?()
                }) {
                    Image(systemName: "pause.fill")
                        .font(.system(size: 16))
                        .foregroundColor(AivoTheme.Primary.orange)
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(PlainButtonStyle()) // Changed to PlainButtonStyle for simplicity/availability
            }
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }
}
