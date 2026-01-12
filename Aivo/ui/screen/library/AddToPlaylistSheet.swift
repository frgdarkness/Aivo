import SwiftUI

struct AddToPlaylistSheet: View {
    let song: SunoData
    @Environment(\.dismiss) var dismiss
    @StateObject private var playlistManager = PlaylistManager.shared
    @State private var showCreatePlaylist = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AivoTheme.Background.primary.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Spacer()
                        Text("Add to Playlist")
                            .font(.headline)
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding()
                    .overlay(
                        Button("Cancel") { dismiss() }
                            .foregroundColor(.white)
                            .padding(.leading)
                        , alignment: .leading
                    )
                    
                    ScrollView {
                        VStack(spacing: 8) {
                            // New Playlist Option
                            Button(action: { showCreatePlaylist = true }) {
                                HStack(spacing: 16) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.white.opacity(0.1))
                                            .frame(width: 56, height: 56)
                                        Image(systemName: "plus")
                                            .font(.title2)
                                            .foregroundColor(.white)
                                    }
                                    
                                    Text("New Playlist")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                            }
                            
                            Divider().background(Color.white.opacity(0.1))
                                .padding(.leading, 80)
                            
                            // User Playlists
                            ForEach(playlistManager.playlists) { playlist in
                                Button(action: {
                                    addToPlaylist(playlist)
                                }) {
                                    HStack(spacing: 16) {
                                        // Cover
                                        playlistCover(for: playlist)
                                        
                                        VStack(alignment: .leading) {
                                            Text(playlist.name)
                                                .font(.headline)
                                                .foregroundColor(.white)
                                            Text("\(playlist.songIds.count) songs")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                        
                                        Spacer()
                                        
                                        if playlist.songIds.contains(song.id) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(AivoTheme.Primary.orange)
                                        }
                                    }
                                    .padding(.horizontal)
                                    .padding(.vertical, 8)
                                }
                                
                                Divider().background(Color.white.opacity(0.1))
                                    .padding(.leading, 80)
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showCreatePlaylist) {
                CreatePlaylistView(onPlaylistCreated: { newPlaylist in
                    addToPlaylist(newPlaylist)
                })
            }
        }
    }
    
    private func addToPlaylist(_ playlist: Playlist) {
        // If already exists, maybe remove? Or just do nothing and dismiss
        if playlist.songIds.contains(song.id) {
            // Optional: Toggle removal? For now, just dismiss as "Done"
            dismiss()
        } else {
            PlaylistManager.shared.addSongToPlaylist(song.id, playlistId: playlist.id)
            // Show toast or feedback?
            dismiss()
        }
    }
    
    @ViewBuilder
    private func playlistCover(for playlist: Playlist) -> some View {
        if let data = playlist.coverImageData, let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 56, height: 56)
                .cornerRadius(8)
                .clipped()
        } else if let hex = playlist.coverColor {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(hex: hex))
                .frame(width: 56, height: 56)
                .overlay(
                    Text(String(playlist.name.prefix(1)).uppercased())
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                )
        } else {
             RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 56, height: 56)
                .overlay(
                    Image(systemName: "music.note.list")
                        .foregroundColor(.white)
                )
        }
    }
}
