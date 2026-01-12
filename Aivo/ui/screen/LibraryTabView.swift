import SwiftUI
import Kingfisher

// MARK: - Library Tab View
struct LibraryTabView: View {
    @State private var tabs: [LibraryTabType] = [.local, .aiSongs, .playlist]
    @State private var selectedTab: LibraryTabType = .local
    
    // Legacy states kept for now to avoid breaking other files if they reference them,
    // but ideally we should only use what's needed for AI Songs.
    // For AI Songs (My Songs), we reuse the logic.
    @State private var downloadedSongs: [SunoData] = []
    @State private var showPlayMySongScreen = false
    @State private var selectedSongIndex = 0
    
    enum LibraryTabType: String, CaseIterable {
        case local = "Local"
        case aiSongs = "AI Songs"
        case playlist = "Playlist"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab Selection
            tabSelectionView
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            
            // Content
            Group {
                switch selectedTab {
                case .local:
                    LocalSongsView()
                case .aiSongs:
                    aiSongsView
                case .playlist:
                    PlaylistTabView()
                }
            }
        }
        .onAppear {
            AnalyticsLogger.shared.logScreenView(AnalyticsLogger.EVENT.EVENT_SCREEN_LIBRARY)
            loadDownloadedSongs()
        }
        .fullScreenCover(isPresented: $showPlayMySongScreen) {
            PlayMySongScreen(
                songs: downloadedSongs,
                initialIndex: selectedSongIndex
            )
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SwitchLibraryCategory"))) { notification in
            if let category = notification.object as? String {
                if category == "AI Generate" || category == "My Songs" {
                    selectedTab = .aiSongs
                    loadDownloadedSongs()
                }
            }
        }
    }
    
    // MARK: - Tab Selection View
    private var tabSelectionView: some View {
        let expandAnim = Animation.spring(response: 0.35, dampingFraction: 0.9, blendDuration: 0.2)
        
        return HStack(spacing: 0) {
            ForEach(tabs, id: \.self) { type in
                Button {
                    withAnimation(expandAnim) {
                        selectedTab = type
                    }
                } label: {
                    Text(type.rawValue)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(selectedTab == type ? .white : .white.opacity(0.7))
                        .frame(maxWidth: .infinity) // Equal width
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedTab == type ? AivoTheme.Primary.orange : .clear)
                        )
                }
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.3))
        )
    }
    
    // MARK: - AI Songs View (Formerly My Songs)
    private var aiSongsView: some View {
        Group {
            if downloadedSongs.isEmpty {
                emptyStateView
            } else {
                downloadedSongsListView
            }
        }
    }
    
    // (Reuse existing emptyStateView but logic inside might need check)
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Record Player Card
            VStack(spacing: 16) {
                // Reuse the Vinyl UI code from before or simplification
               Image(systemName: "music.mic")
                    .font(.system(size: 60))
                    .foregroundColor(.gray)
                
                // Empty State Text
                VStack(spacing: 8) {
                    Text("No AI Songs yet")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    HStack(spacing: 4) {
                        Text("Start creating with")
                            .font(.subheadline)
                            .foregroundColor(.white)
                        
                        Text("AIVO AI")
                            .font(.system(size: 16, weight: .black, design: .monospaced))
                            .foregroundColor(AivoTheme.Primary.orange)
                    }
                }
                
                // Start Creating Button
                Button(action: startCreating) {
                    Text("Start Creating")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(AivoTheme.Primary.orange)
                        .cornerRadius(12)
                        .shadow(color: AivoTheme.Shadow.orange, radius: 10, x: 0, y: 0)
                }
                .padding(.horizontal, 40)
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Downloaded Songs List View
    private var downloadedSongsListView: some View {
        ScrollView {
            LazyVStack(spacing: 6) {
                ForEach(Array(downloadedSongs.enumerated()), id: \.element.id) { index, song in
                    DownloadedSongRowView(
                        song: song,
                        index: index,
                        downloadedSongs: downloadedSongs,
                        onTap: {
                            selectedSongIndex = index
                            MusicPlayer.shared.loadSong(song, at: index, in: downloadedSongs)
                            showPlayMySongScreen = true
                        },
                        onAddToPlaylist: {
                            songToAddToPlaylist = song
                        },
                        onAddToQueue: {
                            MusicPlayer.shared.addToQueue(song)
                        },
                        onDelete: {
                            deleteSong(song)
                        }
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100) // Space for bottom nav
        }
        .sheet(item: $songToAddToPlaylist) { song in
            AddToPlaylistSheet(song: song)
        }
    }
    
    // MARK: - Actions
    @State private var songToAddToPlaylist: SunoData? = nil
    
    private func deleteSong(_ song: SunoData) {
        Task {
            do {
                try await SunoDataManager.shared.deleteSunoData(song)
                loadDownloadedSongs()
            } catch {
                print("❌ Failed to delete song: \(error)")
            }
        }
    }
    
    private func startCreating() {
         // Switch to Home for creation
         NotificationCenter.default.post(name: NSNotification.Name("SwitchMainTab"), object: 0)
    }
    
    private func loadDownloadedSongs() {
        Task {
            do {
                let sunoDataList = try await SunoDataManager.shared.loadAllSavedSunoData()
                await MainActor.run {
                    self.downloadedSongs = sunoDataList
                }
            } catch {
                print("❌ [Library] Error loading downloaded songs: \(error)")
                await MainActor.run {
                    self.downloadedSongs = []
                }
            }
        }
    }
}

// MARK: - Library Song Row View
struct LibrarySongRowView: View {
    let song: LibrarySong
    
    var body: some View {
        HStack(spacing: 12) {
            // Album Art
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(song.albumArtColor)
                    .frame(width: 60, height: 60)
                
                Image(systemName: song.albumArtIcon)
                    .font(.title2)
                    .foregroundColor(.white)
            }
            
            // Song Info
            VStack(alignment: .leading, spacing: 4) {
                Text(song.title)
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(song.artist)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(1)
                
                Text(song.createdDate, style: .date)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Play Button
            Button(action: { playSong(song) }) {
                Image(systemName: "play.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                    )
            }
        }
        .padding(.vertical, 8)
    }
    
    private func playSong(_ song: LibrarySong) {
        print("Playing: \(song.title)")
    }
}

// MARK: - Downloaded Song Row View
    struct DownloadedSongRowView: View {
    let song: SunoData
    let index: Int
    let downloadedSongs: [SunoData]
    let onTap: () -> Void
    let onAddToPlaylist: () -> Void
    let onAddToQueue: () -> Void
    let onDelete: () -> Void
    
    private var isFavorite: Bool {
        FavoriteManager.shared.isFavorite(songId: song.id)
    }
    
    var body: some View {
        // Card nền
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.clear, lineWidth: 2)
                )

            // Nội dung: ảnh (trái sát), info (giữa), nút (phải sát)
            HStack(spacing: 12) {
                let coverSize: CGFloat = 60

                ZStack {
                    // Cover image using Kingfisher for optimized loading
                    KFImage(getImageURL(for: song))
                        .placeholder {
                            Image("demo_cover")
                                .resizable()
                                .scaledToFill()
                        }
                        .setProcessor(DownsamplingImageProcessor(size: CGSize(width: 240, height: 240)))
                        .cacheMemoryOnly()
                        .resizable()
                        .scaledToFill()
                        .frame(width: coverSize, height: coverSize)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .frame(width: coverSize, height: coverSize)
                .padding(.leading, 12)

                // INFO: chiếm toàn bộ phần còn lại
                VStack(alignment: .leading, spacing: 4) {
                    Text(song.title)
                        .font(.headline).fontWeight(.medium)
                        .foregroundColor(.white)
                        .lineLimit(1).truncationMode(.tail)

                    HStack(spacing: 12) {
                        // Duration
                        Label(formatDuration(song.duration), systemImage: "clock.fill")
                            .labelStyle(.titleAndIcon)
                            .font(.caption)
                            .foregroundColor(.gray)
                            .lineLimit(1)
                        
                        // Voice model
                        Text(song.modelName)
                            .font(.caption)
                            .foregroundColor(.gray)
                            .lineLimit(1)
                        
                        // Favorite indicator
                        if isFavorite {
                            Label("", systemImage: "heart.fill")
                                .labelStyle(.titleAndIcon)
                                .font(.caption)
                                .foregroundColor(.red)
                                .lineLimit(1)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .layoutPriority(1)

                // Menu Button
                Menu {
                    Button(action: { onTap() }) {
                        Label("Play", systemImage: "play")
                    }
                    
                    Button(action: { onAddToPlaylist() }) {
                        Label("Add to Playlist", systemImage: "music.note.list")
                    }
                    
                    Button(action: { onAddToQueue() }) {
                        Label("Add to Queue", systemImage: "text.append")
                    }
                    
                    Button(role: .destructive, action: { onDelete() }) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .contentShape(Rectangle())
                }
                .padding(.trailing, 12)
            }
            .frame(height: 76)
            .contentShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(.vertical, 4)
        .onTapGesture {
            onTap()
        }
    }
    
    private func playDownloadedSong(_ song: SunoData) {
        print("🎵 [Library] Playing downloaded song: \(song.title)")
        
        // Find the index of the song in the downloadedSongs array
        guard let index = downloadedSongs.firstIndex(where: { $0.id == song.id }) else {
            print("❌ [Library] Song not found in downloaded songs")
            return
        }
        
        // Use MusicPlayer to play the song
        MusicPlayer.shared.loadSong(song, at: index, in: downloadedSongs)
        print("🎵 [Library] Song loaded into MusicPlayer")
    }
    
    private func formatDuration(_ duration: Double) -> String {
        let m = Int(duration) / 60
        let s = Int(duration) % 60
        return String(format: "%d:%02d", m, s)
    }
}

// MARK: - Supporting Models
struct LibrarySong: Identifiable {
    let id = UUID()
    let title: String
    let artist: String
    let createdDate: Date
    let albumArtIcon: String
    let albumArtColor: Color
}

// MARK: - Helper Functions
func getImageURL(for song: SunoData) -> URL? {
    // Check if local cover exists first
    if let localCoverPath = SunoDataManager.shared.getLocalCoverPath(for: song.id) {
        return localCoverPath
    }
    
    // Fallback to source URL
    return URL(string: song.sourceImageUrl)
}

// MARK: - Preview
struct LibraryTabView_Previews: PreviewProvider {
    static var previews: some View {
        LibraryTabView()
    }
}
