import SwiftUI
import Kingfisher

// MARK: - Explore Tab View
struct ExploreTabView: View {
    @State private var selectedCategory: ExploreCategory = .popular
    @State private var popularSongs: [SunoData] = []
    @State private var newSongs: [SunoData] = []
    @State private var songStatusMap: [String: SongStatus] = [:]
    @State private var isLoading = true
    @State private var selectedSongForPlayback: SongPlaybackItem? = nil
    
    // Wrapper to hold song data for fullScreenCover(item:)
    struct SongPlaybackItem: Identifiable {
        let id: String
        let songs: [SunoData]
        
        init(song: SunoData) {
            self.id = song.id
            self.songs = [song]
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
            }
        }
        .fullScreenCover(item: $selectedSongForPlayback) { item in
            GenerateSunoSongResultScreen(
                sunoDataList: item.songs,
                onClose: {
                    selectedSongForPlayback = nil
                }
            )
        }
    }
    
    // MARK: - Category Tabs
    private var categoryTabs: some View {
        HStack(spacing: 0) {
            ForEach(ExploreCategory.allCases, id: \.self) { category in
                Button(action: { selectedCategory = category }) {
                    Text(category.rawValue)
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(selectedCategory == category ? .black : .white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedCategory == category ? AivoTheme.Primary.orange : Color.clear)
                        )
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 20)
    }
    
    // MARK: - Song List View
    private var songListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                let songs = selectedCategory == .popular ? popularSongs : newSongs
                
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
                    ForEach(songs, id: \.id) { song in
                        SongRowView(
                            song: song,
                            status: songStatusMap[song.id],
                            onTap: {
                                Logger.d("🎵 [ExploreTab] User tapped song: \(song.title)")
                                Logger.d("🎵 [ExploreTab] Song ID: \(song.id)")
                                
                                // Create playback item and set it - this will trigger fullScreenCover(item:)
                                let playbackItem = SongPlaybackItem(song: song)
                                Logger.d("✅ [ExploreTab] Creating SongPlaybackItem with song: \(song.title)")
                                
                                // Set the item - fullScreenCover(item:) will automatically trigger when item changes from nil to non-nil
                                selectedSongForPlayback = playbackItem
                                Logger.d("✅ [ExploreTab] selectedSongForPlayback set, opening GenerateSunoSongResultScreen")
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
                
                await MainActor.run {
                    self.popularSongs = popular
                    self.newSongs = new
                    self.isLoading = false
                }
                
                Logger.i("✅ [ExploreTab] Loaded \(popular.count) popular songs and \(new.count) new songs")
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
