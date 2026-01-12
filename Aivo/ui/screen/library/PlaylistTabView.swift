import SwiftUI

struct PlaylistTabView: View {
    @ObservedObject private var playlistManager = PlaylistManager.shared
    @State private var showingCreatePlaylist = false
    @State private var showingAddSongs = false
    @State private var selectedSmartType: SmartPlaylistType?
    @State private var selectedUserPlaylist: Playlist?
    @State private var justCreatedPlaylist: Playlist?
    
    // Grid Setup
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        ZStack {
                 // Background handled by parent or transparent
                 AivoTheme.Background.primary.ignoresSafeArea()
                 
                 ScrollView {
                     VStack(alignment: .leading, spacing: 24) {
                         // Smart Playlists Grid
                         LazyVGrid(columns: columns, spacing: 16) {
                             smartPlaylistCard(originalType: .favorites,
                                               title: "My favourite",
                                               iconName: "heart.fill",
                                               colors: [Color(hex: "#EE0979"), Color(hex: "#FF6A00")])
                             
                             smartPlaylistCard(originalType: .recentlyAdded,
                                               title: "Last added",
                                               iconName: "plus.circle",
                                               colors: [Color(hex: "#00C9FF"), Color(hex: "#92FE9D")])
                             
                             smartPlaylistCard(originalType: .recentlyPlayed,
                                               title: "Recently played",
                                               iconName: "clock.fill",
                                               colors: [Color(hex: "#4568DC"), Color(hex: "#B06AB3")])
                             
                             smartPlaylistCard(originalType: .topTracks,
                                               title: "Most played",
                                               iconName: "chart.bar.fill",
                                               colors: [Color(hex: "#FF416C"), Color(hex: "#FF4B2B")])
                         }
                         .padding(.horizontal)
                         .padding(.top, 20)
                         
                         // My Playlists Header
                         HStack {
                             Text("My playlists (\(playlistManager.userPlaylists.count))")
                                 .font(.system(size: 20, weight: .bold))
                                 .foregroundColor(.white)
                             Spacer()
                         }
                         .padding(.horizontal)
                         
                         // Create Playlist Row + Playlist List
                         LazyVStack(spacing: 8) {
                             // Create New Playlist Row
                             Button(action: { showingCreatePlaylist = true }) {
                                 HStack(spacing: 16) {
                                     ZStack {
                                         Color.white.opacity(0.1)
                                         Image(systemName: "plus")
                                             .font(.system(size: 24))
                                             .foregroundColor(.white)
                                     }
                                     .frame(width: 56, height: 56)
                                     .cornerRadius(8)
                                     
                                     Text("Create new playlist")
                                         .font(.system(size: 16, weight: .semibold))
                                         .foregroundColor(.white)
                                     
                                     Spacer()
                                 }
                                 .padding(.horizontal)
                                 .padding(.vertical, 8)
                             }
                             
                             // User Playlists
                             ForEach(playlistManager.userPlaylists) { playlist in
                                 UserPlaylistRow(
                                     playlist: playlist,
                                     onTap: { selectedUserPlaylist = playlist },
                                     onPlay: {
                                         let songs = playlistManager.getSongs(for: playlist)
                                         if !songs.isEmpty {
                                             MusicPlayer.shared.loadSong(songs[0], at: 0, in: songs)
                                         }
                                     },
                                     onAddToQueue: {
                                         let songs = playlistManager.getSongs(for: playlist)
                                         songs.forEach { MusicPlayer.shared.addToQueue($0) }
                                     },
                                     onDelete: {
                                         playlistManager.deletePlaylist(playlist)
                                     }
                                 )
                             }
                         }
                     }
                     .padding(.bottom, 100) // Space for player
                 }
             }
             .navigationBarHidden(true)
             .sheet(isPresented: $showingCreatePlaylist) {
                 CreatePlaylistView(onPlaylistCreated: { playlist in
                     self.justCreatedPlaylist = playlist
                     DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                         self.showingAddSongs = true
                     }
                 })
             }
            .sheet(isPresented: $showingAddSongs) {
                if let pl = justCreatedPlaylist {
                    AddSongsToPlaylistView(playlist: pl, onFinish: {
                        playlistManager.objectWillChange.send()
                    })
                }
            }
            .fullScreenCover(item: $selectedSmartType) { type in
                NavigationView {
                    SmartPlaylistDetailView(type: type)
                }
            }
            .fullScreenCover(item: $selectedUserPlaylist) { playlist in
                NavigationView {
                    UserPlaylistDetailView(playlist: playlist)
                }
            }
    }
    
    private func smartPlaylistCard(originalType: SmartPlaylistType, title: String, iconName: String, colors: [Color]) -> some View {
         Button(action: { selectedSmartType = originalType }) {
             ZStack(alignment: .topLeading) { // Changed to .topLeading
                 LinearGradient(gradient: Gradient(colors: colors), startPoint: .topLeading, endPoint: .bottomTrailing)
                 
                 VStack(alignment: .leading, spacing: 4) {
                     Text(title)
                         .font(.system(size: 16, weight: .bold))
                         .foregroundColor(.white)
                         .multilineTextAlignment(.leading)
                     
                     Text("\(PlaylistManager.shared.getSongs(for: originalType).count) songs")
                         .font(.system(size: 12))
                         .foregroundColor(.white.opacity(0.9))
                 }
                 .padding(12)
                 
                 // Icon Large Background
                 GeometryReader { geo in
                     Image(systemName: iconName)
                         .font(.system(size: 80))
                         .foregroundColor(.white.opacity(0.2))
                         .position(x: geo.size.width - 20, y: geo.size.height - 20)
                 }
             }
             .frame(height: 100)
             .cornerRadius(12)
             .overlay(
                // Small Icon at bottom right
                Image(systemName: iconName)
                    .font(.system(size: 24))
                    .foregroundColor(.white.opacity(0.5))
                    .padding(8)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
             )
         }
    }
}

struct UserPlaylistRow: View {
    let playlist: Playlist
    let onTap: () -> Void
    let onPlay: () -> Void
    let onAddToQueue: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Main Clickable Area
            Button(action: onTap) {
                HStack(spacing: 16) {
                    // Cover
                    ZStack {
                        if let data = playlist.coverImageData, let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } else if let colorHex = playlist.coverColor {
                            Color(hex: colorHex)
                                .overlay(
                                    Text(playlist.name.prefix(1).uppercased())
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundColor(.white)
                                )
                        } else {
                            Color.gray
                        }
                    }
                    .frame(width: 56, height: 56)
                    .cornerRadius(8)
                    .clipped()
                    
                    // Info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(playlist.name)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text("\(playlist.songIds.count) songs")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                }
                .contentShape(Rectangle()) // Ensure entire area is tappable
            }
            .buttonStyle(PlainButtonStyle()) // Prevent default button styling affecting layout
            
            // Context Menu Button
            Menu {
                Button(action: onPlay) {
                    Label("Play", systemImage: "play")
                }
                
                Button(action: onAddToQueue) {
                    Label("Add to Queue", systemImage: "text.append")
                }
                
                Button(role: .destructive, action: onDelete) {
                    Label("Delete Playlist", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 20))
                    .foregroundColor(.gray)
                    .frame(width: 40, height: 40)
                    .contentShape(Rectangle())
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

// Helper for Hex Color if not exists
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    PlaylistTabView()
}
