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
            HStack(spacing: 12) {
                // Song info
                VStack(alignment: .leading, spacing: 4) {
                    Text(song.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(isCurrent ? AivoTheme.Primary.orange : .white)
                        .lineLimit(1)
                    
                    Text(song.username ?? "Aivo Music")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Play/Pause indicator ONLY for current song
                if isCurrent {
                    Button(action: onTogglePlayPause) {
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 18))
                            .foregroundColor(AivoTheme.Primary.orange)
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // Delete button (X icon)
                Button(action: onDelete) {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
        .listRowSeparator(.hidden)
        .deleteDisabled(true)
    }
}
