import SwiftUI
import Kingfisher

// MARK: - Explore Tab View New
struct ExploreTabViewNew: View {
    @ObservedObject private var remoteConfig = RemoteConfigManager.shared
    @State private var selectedSongForPlayback: SongPlaybackItem? = nil
    @State private var songStatusMap: [String: SongStatus] = [:]
    
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
        ScrollView {
            VStack(spacing: 24) {
                // Header
                //headerView
                
                // Search Bar
                //searchBarView
                
                // Trending Section
                trendingSection
                
                // Popular Section
                popularSection
                
                // News Section
                newsSection
                
                // Genre Sections
                genreSections
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100) // Space for bottom nav
        }
        .fullScreenCover(item: $selectedSongForPlayback) { item in
            GenerateSunoSongResultScreen(
                sunoDataList: item.songs,
                onClose: {
                    selectedSongForPlayback = nil
                }
            )
        }
        .onAppear {
            loadSongStatus()
        }
    }
    
    // MARK: - Load Song Status
    private func loadSongStatus() {
        var statusMap: [String: SongStatus] = [:]
        for status in remoteConfig.songStatus {
            statusMap[status.id] = status
        }
        songStatusMap = statusMap
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            Text("Explore")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)
            
            Spacer()
            
            // PRO Button
            Button(action: {
                // Handle PRO button tap
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 12))
                    Text("PRO")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                )
            }
            
            // Profile Icon
            Button(action: {
                // Handle profile tap
            }) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
            }
        }
        .padding(.top, 10)
    }
    
    // MARK: - Search Bar
    private var searchBarView: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
                .font(.system(size: 16))
            
            Text("Bài hát, và hơn nữa...")
                .font(.system(size: 16))
                .foregroundColor(.gray)
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
        )
    }
    
    // MARK: - Trending Section
    private var trendingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Trending")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(Array(remoteConfig.trendingList.prefix(10).enumerated()), id: \.element.id) { index, song in
                        TrendingCardView(song: song, rank: index + 1) {
                            selectedSongForPlayback = SongPlaybackItem(song: song)
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
    
    // MARK: - Popular Section
    private var popularSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Popular")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(Array(remoteConfig.hottestList.prefix(10)), id: \.id) { song in
                        PopularCardView(song: song) {
                            selectedSongForPlayback = SongPlaybackItem(song: song)
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
    
    // MARK: - News Section
    private var newsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("News")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
//                Button(action: {
//                    // Handle "Xem tất cả" tap
//                }) {
//                    Text("Xem tất cả")
//                        .font(.system(size: 14, weight: .medium))
//                        .foregroundColor(.white.opacity(0.7))
//                }
            }
            
            // Horizontal scroll with 3 rows, 5 columns per view
            ScrollView(.horizontal, showsIndicators: false) {
                VStack(spacing: 16) {
                    // Split into rows of 5 items each
                    let newsSongs = Array(remoteConfig.newList.prefix(15)) // 3 rows × 5 columns = 15 max
                    
                    ForEach(0..<3) { rowIndex in
                        HStack(spacing: 32) {
                            let startIndex = rowIndex * 5
                            let endIndex = min(startIndex + 5, newsSongs.count)
                            
                            ForEach(startIndex..<endIndex, id: \.self) { index in
                                let song = newsSongs[index]
                                NewsCardView(
                                    song: song,
                                    status: songStatusMap[song.id]
                                ) {
                                    selectedSongForPlayback = SongPlaybackItem(song: song)
                                }
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                }
            }
        }
    }
    
    // MARK: - Genre Sections
    private var genreSections: some View {
        VStack(alignment: .leading, spacing: 24) {
            ForEach(SongGenre.getExplore(), id: \.self) { genre in
                GenreSectionView(
                    genre: genre,
                    songs: filterSongsByGenre(genre),
                    songStatusMap: songStatusMap,
                    onSongTap: { song in
                        selectedSongForPlayback = SongPlaybackItem(song: song)
                    }
                )
            }
        }
    }
    
    // MARK: - Filter Songs by Genre
    private func filterSongsByGenre(_ genre: SongGenre) -> [SunoData] {
        let genreName = genre.rawValue.lowercased()
        var filteredSongs = remoteConfig.allSongsList.filter { song in
            // Check if song tags contain genre name
            song.tags.lowercased().contains(genreName)
        }
        
        // Shuffle the filtered list
        filteredSongs.shuffle()
        
        // Take first 10 items
        return Array(filteredSongs.prefix(10))
    }
}

// MARK: - Genre Section View
struct GenreSectionView: View {
    let genre: SongGenre
    let songs: [SunoData]
    let songStatusMap: [String: SongStatus]
    let onSongTap: (SunoData) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(genre.displayName)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
//                Button(action: {
//                    // Handle "Xem tất cả" tap
//                }) {
//                    Text("Xem tất cả")
//                        .font(.system(size: 14, weight: .medium))
//                        .foregroundColor(.white.opacity(0.7))
//                }
            }
            
            if songs.isEmpty {
                Text("No songs available")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.vertical, 20)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(songs, id: \.id) { song in
                            GenreSongCardView(
                                song: song,
                                status: songStatusMap[song.id],
                                onTap: {
                                    onSongTap(song)
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
    }
}

// MARK: - Genre Song Card View
struct GenreSongCardView: View {
    let song: SunoData
    let status: SongStatus?
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // Cover Image with Listen Count
                ZStack(alignment: .topLeading) {
                    AsyncImage(url: getImageURL(for: song)) { phase in
                        Group {
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
                    }
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    // Listen Count - Top Left Corner
//                    HStack(spacing: 4) {
//                        Image(systemName: "headphones")
//                            .font(.system(size: 10))
//                            .foregroundColor(.white)
//                        Text(formatCount(status?.playCount ?? 0))
//                            .font(.system(size: 11, weight: .medium))
//                            .foregroundColor(.white)
//                    }
//                    .padding(.horizontal, 6)
//                    .padding(.vertical, 4)
//                    .background(
//                        RoundedRectangle(cornerRadius: 6)
//                            .fill(Color.black.opacity(0.5))
//                    )
                    .padding(6)
                }
                
                // Song Title - Max 1 line
                Text(song.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(width: 120, alignment: .leading)
                
                // Model ID (modelName)
                HStack(spacing: 4) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.6))
                    Text(song.modelName)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                .frame(width: 120, alignment: .leading)
            }
            .frame(width: 120)
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

// MARK: - Trending Card View
struct TrendingCardView: View {
    let song: SunoData
    let rank: Int
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Cover Image - Full width/height of item
                AsyncImage(url: getImageURL(for: song)) { phase in
                    Group {
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
                }
                .frame(width: 200, height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Rank Label - Center overlay
                Text("No.\(rank)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(AivoTheme.Primary.orange)
                    .shadow(color: .black.opacity(0.8), radius: 8, x: 0, y: 2)
                    .shadow(color: AivoTheme.Primary.orange.opacity(0.5), radius: 12, x: 0, y: 0)
                
                // Song Title Overlay - Bottom, Full Width, Max 1 Line
                VStack {
                    Spacer()
                    Text(song.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.black.opacity(0.7),
                                    Color.black.opacity(0.5)
                                ]),
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .clipShape(RoundedCorner(radius: 12, corners: [.bottomLeft, .bottomRight]))
                }
            }
            .frame(width: 200, height: 200)
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
}

// MARK: - Popular Card View
struct PopularCardView: View {
    let song: SunoData
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // 2:3 Aspect Ratio Image with Play Icon
                ZStack(alignment: .bottomTrailing) {
                    AsyncImage(url: getImageURL(for: song)) { phase in
                        Group {
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
                    }
                    .frame(width: 120, height: 180) // 2:3 ratio (120 × 180)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    // Play Icon Overlay - Bottom Right Corner
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.white.opacity(0.9))
                        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                        .padding(8)
                }
                
                // Song Title - Max 1 line with truncation
                Text(song.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .multilineTextAlignment(.leading)
                    .frame(width: 120, alignment: .leading)
            }
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
}

// MARK: - News Card View
struct NewsCardView: View {
    let song: SunoData
    let status: SongStatus?
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                // Cover Image with Play Icon (Left)
                ZStack {
                    AsyncImage(url: getImageURL(for: song)) { phase in
                        Group {
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
                    }
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    // Play Icon Overlay
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white.opacity(0.9))
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                }
                
                // Info Section (Middle)
                VStack(alignment: .leading, spacing: 4) {
                    // Row 1: Song Title
                    Text(song.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    
                    // Row 2: Model Name + Play Count
                    HStack(spacing: 8) {
                        Image(systemName: "person.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.6))
                        
                        Text(song.modelName)
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(1)
                        
                        Image(systemName: "headphones")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.6))
                        
                        Text(formatCount(status?.playCount ?? 0))
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    // Row 3: Tags
                    Text(song.tags.isEmpty ? "No tags" : song.tags)
                        .font(.system(size: 10, weight: .regular))
                        .foregroundColor(.white.opacity(0.5))
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                
                //Spacer()
                
                // Like Section (Right)
                VStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text(formatCount(status?.likeCount ?? 0))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .frame(width: 300)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
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
    
    private func getImageURL(for song: SunoData) -> URL? {
        // Check if local cover exists first
        if let localCoverPath = SunoDataManager.shared.getLocalCoverPath(for: song.id) {
            return localCoverPath
        }
        
        // Fallback to source URL or regular image URL
        return URL(string: song.sourceImageUrl.isEmpty ? song.imageUrl : song.sourceImageUrl)
    }
}

// MARK: - Preview
struct ExploreTabViewNew_Previews: PreviewProvider {
    static var previews: some View {
        ExploreTabViewNew()
            .background(AivoSunsetBackground())
    }
}

