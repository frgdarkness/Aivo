import SwiftUI
import Kingfisher

struct SmartPlaylistDetailView: View {
    let type: SmartPlaylistType
    @State private var songs: [SunoData] = []
    @State private var isLoading = true
    
    // Player
    @State private var showPlayMySongScreen = false
    @State private var selectedSongIndex = 0
    
    @Environment(\.dismiss) var dismiss // Added dismiss
    
    var body: some View {
        ZStack {
            AivoTheme.Background.primary.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                ZStack(alignment: .top) { // Align top center
                    LinearGradient(colors: type.gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                        .frame(height: 250)
                        
                    // Back Button
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
                    }
                    .zIndex(2)
                    
                    VStack {
                        // Title centered in header
                        Text(type.rawValue)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                    }
                    .frame(height: 250)
                    .frame(maxWidth: .infinity)
                }
                .frame(height: 250)
                .ignoresSafeArea(edges: .top)
                .zIndex(1)
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
                    .padding(.trailing, 20)
                    .offset(y: -28),
                    alignment: .bottomTrailing
                )
                
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
                            Spacer()
                            Text("No songs found")
                                .foregroundColor(.gray)
                            Spacer()
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
                                            
                                            // Cover
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
                                            
                                            // No Duration, just empty spacer push
                                        }
                                        .padding(.vertical, 4)
                                    }
                                    .listRowBackground(Color.clear)
                                }
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
        .fullScreenCover(isPresented: $showPlayMySongScreen) {
            PlayMySongScreen(
                songs: songs,
                initialIndex: selectedSongIndex
            )
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                 if !songs.isEmpty {
                     Button(action: { playSong(index: 0) }) {
                         Image(systemName: "play.circle.fill")
                             .font(.title)
                             .foregroundColor(.white)
                     }
                 }
            }
        }
        .navigationBarHidden(true)
    }
    
    private func loadSongs() {
        Task {
            // Fetch all songs first (simplified for MVP, ideally PlaylistManager should cache or query directly)
            // Assuming SunoDataManager has a way to get all songs, or we pass them.
            // But SmartPlaylist needs access to ALL songs.
            // Let's rely on SunoDataManager to load all saved data
            
            let allSongs = try? await SunoDataManager.shared.loadAllSavedSunoData()
            // Also include local songs? "Local" songs are separate.
            // Smart playlists usually aggregate everything. Let's merge if possible.
            let localSongs = LocalSongManager.shared.fetchLocalSongs()
            
            let combined = (allSongs ?? []) + localSongs
            
            let smartSongs = PlaylistManager.shared.getSmartPlaylistSongs(type: type, allSongs: combined)
            
            await MainActor.run {
                self.songs = smartSongs
                self.isLoading = false
            }
        }
    }
    
    private func playSong(index: Int) {
        selectedSongIndex = index
        MusicPlayer.shared.loadSong(songs[index], at: index, in: songs)
        showPlayMySongScreen = true
    }
    
    private func formatDuration(_ duration: Double) -> String {
        let m = Int(duration) / 60
        let s = Int(duration) % 60
        return String(format: "%d:%02d", m, s)
    }
}
