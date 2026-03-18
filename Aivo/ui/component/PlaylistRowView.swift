import SwiftUI

struct PlaylistRowView: View {
    let song: SunoData
    let index: Int
    let isCurrent: Bool
    let isPlaying: Bool
    let onTap: () -> Void
    let onTogglePlayPause: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: iPadScaleSmall(12)) {
                // Song info
                VStack(alignment: .leading, spacing: 4) {
                    Text(song.title)
                        .font(.system(size: iPadScale(16), weight: .semibold))
                        .foregroundColor(isCurrent ? AivoTheme.Primary.orange : .white)
                        .lineLimit(1)
                    
                    Text(song.username ?? "Aivo Music")
                        .font(.system(size: iPadScale(14)))
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Play/Pause indicator ONLY for current song
                if isCurrent {
                    Button(action: onTogglePlayPause) {
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: iPadScale(18)))
                            .foregroundColor(AivoTheme.Primary.orange)
                            .frame(width: iPadScale(32), height: iPadScale(32))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // Delete button (X icon)
                Button(action: onDelete) {
                    Image(systemName: "xmark")
                        .font(.system(size: iPadScale(18), weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                        .frame(width: iPadScale(32), height: iPadScale(32))
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.vertical, iPadScaleSmall(12))
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
        .listRowSeparator(.hidden)
        .deleteDisabled(true)
    }
}
