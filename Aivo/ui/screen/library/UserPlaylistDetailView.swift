import SwiftUI
import Kingfisher

struct UserPlaylistDetailView: View {
    @State var playlist: Playlist
    @State private var songs: [SunoData] = []
    @State private var isLoading = true
    
    // Player
    @State private var showPlayMySongScreen = false
    @State private var selectedSongIndex = 0
    
    // Actions
    @State private var showEditSheet = false
    @State private var showDeleteAlert = false
    @Environment(\.dismiss) var dismiss
    @State private var showAddSongs = false // New state
    
    var body: some View {
        ZStack {
            AivoTheme.Background.primary.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                    .frame(height: 250)
                    .zIndex(1) // Ensure header is above list content for button overlap
                
                // Content
                if isLoading {
                    Spacer()
                    ProgressView()
                        .tint(.white)
                    Spacer()
                } else {
                    VStack(spacing: 0) {
                        // Song Count Header
                        Text("\(songs.count) Songs")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding(.bottom, 12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)
                        
                        if songs.isEmpty {
                            VStack {
                                Spacer()
                                Text("Playlist is empty")
                                    .font(.title3)
                                    .foregroundColor(.gray)
                                Text("Add songs from Player or Library")
                                    .font(.subheadline)
                                    .foregroundColor(.gray.opacity(0.7))
                                Spacer()
                            }
                        } else {
                            List {
                                ForEach(Array(songs.enumerated()), id: \.element.id) { index, song in
                                    Button(action: {
                                        playSong(index: index)
                                    }) {
                                        HStack(spacing: 12) {
                                            Text("\(index + 1)")
                                                .font(.subheadline)
                                                .foregroundColor(.gray)
                                                .frame(width: 25)
                                            
                                            // Cover Image
                                            let coverSize: CGFloat = 40
                                            ZStack {
                                                if let coverPath = song.coverImageLocalPath,
                                                   let image = UIImage(contentsOfFile: coverPath) {
                                                    Image(uiImage: image)
                                                        .resizable()
                                                        .aspectRatio(contentMode: .fill)
                                                } else if let url = URL(string: song.imageUrl), !song.imageUrl.isEmpty {
                                                     KFImage(url)
                                                        .placeholder {
                                                            Image("cover_default_resize")
                                                                .resizable()
                                                        }
                                                        .resizable()
                                                        .aspectRatio(contentMode: .fill)
                                                } else {
                                                    Image("cover_default_resize")
                                                        .resizable()
                                                        .aspectRatio(contentMode: .fill)
                                                }
                                            }
                                            .frame(width: coverSize, height: coverSize)
                                            .cornerRadius(6)
                                            .clipped()
                                            
                                            VStack(alignment: .leading) {
                                                Text(song.title)
                                                    .font(.headline)
                                                    .foregroundColor(.white)
                                                    .lineLimit(1)
                                                Text(song.modelName)
                                                    .font(.caption)
                                                    .foregroundColor(.gray)
                                            }
                                            
                                            Spacer()
                                            
                                            // Menu Button
                                            Menu {
                                                Button(action: {
                                                    playSong(index: index)
                                                }) {
                                                    Label("Play", systemImage: "play")
                                                }
                                                
                                                Button(role: .destructive, action: {
                                                    removeSong(song)
                                                }) {
                                                    Label("Remove from Playlist", systemImage: "trash")
                                                }
                                            } label: {
                                                Image(systemName: "ellipsis")
                                                    .font(.system(size: 20))
                                                    .foregroundColor(.gray)
                                                    .frame(width: 40, height: 40)
                                                    .contentShape(Rectangle())
                                            }
                                        }
                                        .padding(.vertical, 4)
                                    }
                                    .listRowBackground(Color.clear)
                                    .swipeActions {
                                        Button(role: .destructive) {
                                            removeSong(song)
                                        } label: {
                                            Label("Remove", systemImage: "trash")
                                        }
                                    }
                                }
                                .onMove(perform: moveSong)
                            }
                            .listStyle(.plain)
                        }
                    }.offset(y: -42)
                }
            }
        }
        .onAppear {
            loadSongs()
        }
        .sheet(isPresented: $showAddSongs) {
             AddSongsToPlaylistView(playlist: playlist, onFinish: {
                 // Reload songs
                 Task {
                     // small delay to allow data save
                     try? await Task.sleep(nanoseconds: 500_000_000)
                     loadSongs()
                 }
             })
        }
        .fullScreenCover(isPresented: $showPlayMySongScreen) {
            PlayMySongScreen(
                songs: songs,
                initialIndex: selectedSongIndex
            )
        }
        .confirmationDialog("Delete Playlist?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                deletePlaylist()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This action cannot be undone.")
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { showDeleteAlert = true }) {
                        Label("Delete Playlist", systemImage: "trash")
                    }
                    // Edit option can be added similarly
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(.white)
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    private var headerView: some View {
        ZStack(alignment: .top) { // Align top center
            if let data = playlist.coverImageData, let uiImage = UIImage(data: data) {
                 Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 250)
                    .clipped()
                    .overlay(Color.black.opacity(0.4))
            } else if let hex = playlist.coverColor {
                Rectangle()
                    .fill(Color(hex: hex))
                    .frame(height: 250)
                    .overlay(Color.black.opacity(0.2))
            } else {
                Rectangle()
                    .fill(Color.gray)
                    .frame(height: 250)
            }
            
            // Back Button (Keep leading)
            HStack {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)
                        .padding()
                        .padding(.top, 40)
                }
                Spacer()
                
                // Add Songs Button
                Button(action: {
                    showAddSongs = true
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)
                        .padding()
                        .padding(.top, 40)
                }
            }
            .zIndex(2)
            
            // Centered Title Content
            VStack(spacing: 4) {
                if playlist.coverImageData == nil && playlist.coverColor == nil {
                    Image(systemName: "music.note.list")
                        .font(.system(size: 60))
                        .foregroundColor(.white)
                        .padding(.bottom, 8)
                }
                
                Text(playlist.name)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                if !playlist.description.isEmpty {
                    Text(playlist.description)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
            }
            .frame(height: 250) // Occupy full header height to center vertically
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 40) // Avoid buttons
        }
        .ignoresSafeArea(edges: .top)
            .overlay(
                // Play Button at bottom right boundary
                Button(action: {
                    if !songs.isEmpty {
                       playSong(index: 0)
                    }
                }) {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 64))
                        .foregroundColor(AivoTheme.Primary.orange)
                        .background(Color.white.mask(Circle()))
                }
                .padding(.trailing, 20) // Right aligned
                .offset(y: -28), // Half height to straddle boundary
                alignment: .bottomTrailing
            )
    }
    
    private func loadSongs() {
        Task {
            // Load actual SunoData objects from IDs
            let allSongs = try? await SunoDataManager.shared.loadAllSavedSunoData()
            let localSongs = LocalSongManager.shared.fetchLocalSongs()
            let combined = (allSongs ?? []) + localSongs
            
            let filtered = combined.filter { playlist.songIds.contains($0.id) }
            
            // Maintain order of playlist.songIds
            var orderedSongs: [SunoData] = []
            for id in playlist.songIds {
                if let song = filtered.first(where: { $0.id == id }) {
                    orderedSongs.append(song)
                }
            }
            
            await MainActor.run {
                self.songs = orderedSongs
                self.isLoading = false
            }
        }
    }
    
    private func playSong(index: Int) {
        selectedSongIndex = index
        MusicPlayer.shared.loadSong(songs[index], at: index, in: songs)
        showPlayMySongScreen = true
    }
    
    private func removeSong(_ song: SunoData) {
        PlaylistManager.shared.removeSongFromPlaylist(song.id, playlistId: playlist.id)
        if let idx = songs.firstIndex(where: { $0.id == song.id }) {
            songs.remove(at: idx)
        }
        // Update local playlist State object to reflect count changes instantly
        if var updated = PlaylistManager.shared.playlists.first(where: { $0.id == playlist.id }) {
            self.playlist = updated
        }
    }
    
    private func moveSong(from source: IndexSet, to destination: Int) {
        // Update local state first for smooth UI
        songs.move(fromOffsets: source, toOffset: destination)
        
        // Persist change
        PlaylistManager.shared.reorderSongs(in: playlist.id, from: source, to: destination)
        
        // Update local playlist object
        if var updated = PlaylistManager.shared.playlists.first(where: { $0.id == playlist.id }) {
            self.playlist = updated
        }
    }
    
    private func deletePlaylist() {
        PlaylistManager.shared.deletePlaylist(playlist)
        dismiss()
    }
    
    private func formatDuration(_ duration: Double) -> String {
        let m = Int(duration) / 60
        let s = Int(duration) % 60
        return String(format: "%d:%02d", m, s)
    }
}

#Preview {
    UserPlaylistDetailView(playlist: Playlist(name: "Test Playlist", description: "This is a test"))
}
