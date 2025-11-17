import SwiftUI
import Kingfisher

// MARK: - Library Tab View
struct LibraryTabView: View {
    @State private var songs: [LibrarySong] = [] // Empty by default to show empty state
    @State private var downloadedSongs: [SunoData] = []
    @State private var showPlayMySongScreen = false
    @State private var selectedSongIndex = 0
    @State private var selectedTab: LibraryTabType = .mySong
    
    enum LibraryTabType: String, CaseIterable {
        case mySong = "My Songs"
        case favorites = "Favorites"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab Selection
            if !downloadedSongs.isEmpty {
                tabSelectionView
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
            }
            
            // Content
            if displayedSongs.isEmpty {
                emptyStateView
            } else {
                downloadedSongsListView
            }
        }
        .onAppear {
            // Log screen view
            AnalyticsLogger.shared.logScreenView(AnalyticsLogger.EVENT.EVENT_SCREEN_LIBRARY)
            
            loadDownloadedSongs()
        }
        .fullScreenCover(isPresented: $showPlayMySongScreen) {
            PlayMySongScreen(
                songs: displayedSongs,
                initialIndex: selectedSongIndex
            )
        }
    }
    
    // MARK: - Computed Properties
    private var displayedSongs: [SunoData] {
        if selectedTab == .favorites {
            return downloadedSongs.filter { FavoriteManager.shared.isFavorite(songId: $0.id) }
        } else {
            return downloadedSongs
        }
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Record Player Card
            VStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 200, height: 120)
                    
                    // Record Player
                    HStack(spacing: 20) {
                        // Vinyl Record
                        ZStack {
                            Circle()
                                .fill(Color.black)
                                .frame(width: 60, height: 60)
                            
                            Circle()
                                .fill(Color.red)
                                .frame(width: 20, height: 20)
                            
                            // Grooves
                            ForEach(0..<3, id: \.self) { index in
                                Circle()
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    .frame(width: 40 + CGFloat(index * 8), height: 40 + CGFloat(index * 8))
                            }
                        }
                        
                        // Tonearm
                        VStack(spacing: 8) {
                            Rectangle()
                                .fill(Color.white)
                                .frame(width: 2, height: 30)
                                .rotationEffect(.degrees(15))
                            
                            // Control Buttons
                            VStack(spacing: 4) {
                                ForEach(0..<4, id: \.self) { _ in
                                    Circle()
                                        .fill(Color.gray)
                                        .frame(width: 8, height: 8)
                                }
                            }
                        }
                    }
                }
                
                // Empty State Text
                VStack(spacing: 8) {
                    Text(selectedTab == .favorites ? "No favorites yet" : "Library is empty")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    HStack(spacing: 4) {
                        Text(selectedTab == .favorites 
                             ? "Add songs to your favorites" 
                             : "Start using it now and discover")
                            .font(.subheadline)
                            .foregroundColor(.white)
                        
                        if selectedTab == .mySong {
                            Text("AIVO AI")
                                .font(.system(size: 16, weight: .black, design: .monospaced))
                                .foregroundColor(AivoTheme.Primary.orange)
                        }
                    }
                }
                
                // Start Creating Button (only show for mySong tab)
                if selectedTab == .mySong {
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
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Tab Selection View
    private var tabSelectionView: some View {
        let expandAnim = Animation.spring(response: 0.35, dampingFraction: 0.9, blendDuration: 0.2)
        
        return HStack(spacing: 0) {
            ForEach(LibraryTabType.allCases, id: \.self) { type in
                Button {
                    withAnimation(expandAnim) {
                        selectedTab = type
                    }
                } label: {
                    Text(type.rawValue)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(selectedTab == type ? .white : .white.opacity(0.7))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedTab == type ? AivoTheme.Primary.orange : .clear)
                        )
                }
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.3))
        )
    }
    
    // MARK: - Songs List View
    private var songsListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(songs, id: \.id) { song in
                    LibrarySongRowView(song: song)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100) // Space for bottom nav
        }
    }
    
    // MARK: - Downloaded Songs List View
    private var downloadedSongsListView: some View {
        ScrollView {
            LazyVStack(spacing: 6) {
                ForEach(Array(displayedSongs.enumerated()), id: \.element.id) { index, song in
                    DownloadedSongRowView(
                        song: song, 
                        index: index,
                        downloadedSongs: displayedSongs,
                        onTap: {
                            selectedSongIndex = index
                            // Load song into MusicPlayer first
                            MusicPlayer.shared.loadSong(song, at: index, in: displayedSongs)
                            showPlayMySongScreen = true
                        }
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100) // Space for bottom nav
        }
    }
    
    // MARK: - Actions
    private func startCreating() {
        print("Starting to create...")
        // This would typically navigate to the home tab or song creation flow
    }
    
    private func loadDownloadedSongs() {
        print("📚 [Library] Loading downloaded songs...")
        
        Task {
            do {
                let sunoDataList = try await SunoDataManager.shared.loadAllSavedSunoData()
                await MainActor.run {
                    self.downloadedSongs = sunoDataList
                    print("📚 [Library] Loaded \(sunoDataList.count) songs into library")
                    for song in sunoDataList {
                        print("📚 [Library] - \(song.title) (\(song.modelName))")
                    }
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

                // BUTTON: sát mép phải card
                Button {
                    onTap()
                } label: {
                    Image(systemName: "play.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(
                            Circle().fill(AivoTheme.Primary.orange)
                        )
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
