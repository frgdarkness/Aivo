import SwiftUI
import Kingfisher

// MARK: - Explore Tab View
struct ExploreTabView: View {
    @State private var selectedCategory: ExploreCategory = .popular
    @State private var popularSongs: [SunoData] = []
    @State private var newSongs: [SunoData] = []
    @State private var allSongs: [SunoData] = []
    @State private var displayedSongs: [SunoData] = []
    @State private var songStatusMap: [String: SongStatus] = [:]
    @State private var isLoading = true
    @State private var selectedSongForPlayback: SongPlaybackItem? = nil
    
    // Wrapper to hold song data for fullScreenCover(item:)
    struct SongPlaybackItem: Identifiable {
        let id: String
        let songs: [SunoData]
        let initialIndex: Int
        
        init(songs: [SunoData], initialIndex: Int) {
            self.id = songs[initialIndex].id
            self.songs = songs
            self.initialIndex = initialIndex
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Category Tabs
            categoryTabs
            
            // Song List
            if isLoading {
                VStack {
                    Spacer()
                    ProgressView()
                        .tint(AivoTheme.Primary.orange)
                        .scaleEffect(1.2)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                songListView
            }
        }
        .onAppear {
            if popularSongs.isEmpty && newSongs.isEmpty {
                loadData()
            } else {
                // Shuffle again when re-entering if not popular
                if selectedCategory != .popular {
                    updateDisplayedSongs()
                }
            }
        }
        .onChange(of: selectedCategory) { _ in
            updateDisplayedSongs()
        }
        .fullScreenCover(item: $selectedSongForPlayback) { item in
            PlayOnlineSongScreen(songs: item.songs, initialIndex: item.initialIndex)
        }
    }
    
    // MARK: - Logic
    
    private func updateDisplayedSongs() {
        switch selectedCategory {
        case .popular:
            // Keep popular sorting (by play/like)
            displayedSongs = popularSongs
            
        case .new:
            // Randomize New songs, take 20
            displayedSongs = Array(newSongs.shuffled().prefix(20))
            
        case .pop, .edm, .rock, .jazz, .hipHop, .classical, .country, .rnb, .kpop:
            // Filter by genre tag
            let genreKeyword = getGenreKeyword(for: selectedCategory)
            let filtered = allSongs.filter { song in
                song.tags.localizedCaseInsensitiveContains(genreKeyword)
            }
            // Randomize filtered list, take 20
            displayedSongs = Array(filtered.shuffled().prefix(20))
        }
    }
    
    private func getGenreKeyword(for category: ExploreCategory) -> String {
        switch category {
        case .pop: return "pop"
        case .edm: return "edm"
        case .rock: return "rock"
        case .jazz: return "jazz"
        case .hipHop: return "hip hop"
        case .classical: return "classical"
        case .country: return "country"
        case .rnb: return "r&b"
        case .kpop: return "k-pop"
        default: return ""
        }
    }
    
    // MARK: - Category Tabs
    private var categoryTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(ExploreCategory.allCases, id: \.self) { category in
                    Button(action: { selectedCategory = category }) {
                        Text(category.rawValue)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(selectedCategory == category ? .white : .gray)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(selectedCategory == category ? AivoTheme.Primary.orange : Color.gray.opacity(0.1))
                            )
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
    }
    
    // MARK: - Song List View
    private var songListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                // Use displayedSongs state
                let songs = displayedSongs
                
                if songs.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "music.note.list")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        
                        Text("No songs available")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 100)
                } else {
                    ForEach(Array(songs.enumerated()), id: \.element.id) { index, song in
                        SongRowView(
                            song: song,
                            status: songStatusMap[song.id],
                            onTap: {
                                Logger.d("🎵 [ExploreTab] User tapped song: \(song.title) at index \(index)")
                                
                                // Create playback item with full song list and index
                                let playbackItem = SongPlaybackItem(songs: songs, initialIndex: index)
                                Logger.d("✅ [ExploreTab] Opening PlayOnlineSongScreen with \(songs.count) songs")
                                
                                // Set the item - fullScreenCover(item:) will automatically trigger
                                selectedSongForPlayback = playbackItem
                            }
                        )
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100) // Space for bottom nav
        }
    }
    
    // MARK: - Load Data
    private func loadData() {
        isLoading = true
        
        Task {
            do {
                Logger.d("📥 [ExploreTab] Starting to load data...")
                
                // Load song status first
                let statusMap = try loadSongStatus()
                Logger.d("📊 [ExploreTab] Loaded \(statusMap.count) song statuses")
                await MainActor.run {
                    self.songStatusMap = statusMap
                }
                
                // Load popular songs
                let popular = try loadSongs(from: "hottest_songs")
                Logger.d("🔥 [ExploreTab] Loaded \(popular.count) popular songs")
                
                // Load new songs
                let new = try loadSongs(from: "new_songs")
                Logger.d("🆕 [ExploreTab] Loaded \(new.count) new songs")
                
                // Load ALL songs for genre filtering
                let all = try loadSongs(from: "all_songs")
                Logger.d("📚 [ExploreTab] Loaded \(all.count) total songs")
                
                await MainActor.run {
                    self.popularSongs = popular
                    self.newSongs = new
                    self.allSongs = all
                    
                    // Initialize displayed songs
                    self.updateDisplayedSongs()
                    
                    self.isLoading = false
                }
                
                Logger.i("✅ [ExploreTab] Data load complete")
            } catch {
                Logger.e("❌ [ExploreTab] Error loading data: \(error)")
                Logger.e("❌ [ExploreTab] Error details: \(error.localizedDescription)")
                await MainActor.run {
                    self.isLoading = false
                    // Set empty arrays on error so UI can show empty state
                    if self.popularSongs.isEmpty {
                        self.popularSongs = []
                    }
                    if self.newSongs.isEmpty {
                        self.newSongs = []
                    }
                }
            }
        }
    }
    
    private func loadSongs(from filename: String) throws -> [SunoData] {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "json") else {
            throw ExploreDataError.fileNotFound(filename)
        }
        
        let data = try Data(contentsOf: url)
        let songs = try JSONDecoder().decode([SunoData].self, from: data)
        
        return songs
    }
    
    private func loadSongStatus() throws -> [String: SongStatus] {
        guard let url = Bundle.main.url(forResource: "song_status", withExtension: "json") else {
            throw ExploreDataError.fileNotFound("song_status")
        }
        
        let data = try Data(contentsOf: url)
        let statusList = try JSONDecoder().decode([SongStatus].self, from: data)
        
        var statusMap: [String: SongStatus] = [:]
        for status in statusList {
            statusMap[status.id] = status
        }
        
        return statusMap
    }
}

// MARK: - Song Row View
struct SongRowView: View {
    let song: SunoData
    let status: SongStatus?
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Album Art
                ZStack {
                    AsyncImage(url: getImageURL(for: song)) { phase in
                        switch phase {
                        case .empty:
                            Image("demo_cover")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure:
                            Image("demo_cover")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        @unknown default:
                            Image("demo_cover")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        }
                    }
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                // Song Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(song.title)
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    HStack(spacing: 16) {
                        HStack(spacing: 4) {
                            Image(systemName: "play.fill")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            Text(formatCount(status?.playCount ?? 0))
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        HStack(spacing: 4) {
                            Image(systemName: "heart.fill")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            Text(formatCount(status?.likeCount ?? 0))
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                Spacer()
                
                // Play Button
                Image(systemName: "play.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                    )
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
    
    private func getImageURL(for song: SunoData) -> URL? {
        // Check if local cover exists first
        if let localCoverPath = SunoDataManager.shared.getLocalCoverPath(for: song.id) {
            return localCoverPath
        }
        
        // Fallback to source URL or regular image URL
        return URL(string: song.sourceImageUrl.isEmpty ? song.imageUrl : song.sourceImageUrl)
    }
    
    private func formatCount(_ count: Int) -> String {
        if count >= 1000000 {
            return String(format: "%.1fM", Double(count) / 1000000.0)
        } else if count >= 1000 {
            return String(format: "%.1fK", Double(count) / 1000.0)
        } else {
            return "\(count)"
        }
    }
}

// MARK: - Supporting Models
enum ExploreCategory: String, CaseIterable {
    case popular = "Popular"
    case new = "New"
    case pop = "Pop"
    case edm = "EDM"
    case rock = "Rock"
    case jazz = "Jazz"
    case hipHop = "Hip Hop"
    case classical = "Classical"
    case country = "Country"
    case rnb = "R&B"
    case kpop = "K-Pop"
}

// MARK: - Song Status Model
struct SongStatus: Codable {
    let id: String
    let playCount: Int
    let likeCount: Int
}

// MARK: - Errors
enum ExploreDataError: Error {
    case fileNotFound(String)
    
    var localizedDescription: String {
        switch self {
        case .fileNotFound(let filename):
            return "Could not find \(filename).json in bundle"
        }
    }
}

// MARK: - Preview
struct ExploreTabView_Previews: PreviewProvider {
    static var previews: some View {
        ExploreTabView()
    }
}
