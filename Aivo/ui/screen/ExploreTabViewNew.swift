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
        let initialIndex: Int
        
        init(songs: [SunoData], initialIndex: Int) {
            self.id = songs[initialIndex].id
            self.songs = songs
            self.initialIndex = initialIndex
        }
    }
    
    struct ThemeList: Identifiable {
        let id = UUID()
        let title: String
        let songs: [SunoData]
    }
    
    @State private var selectedThemeList: ThemeList?
    @State private var showSubscription = false
    @State private var songsForYou: [SunoData] = []
    
    // Community Sharing
    @State private var communityHottestSongs: [SunoData] = []
    @State private var communityNewestSongs: [SunoData] = []
    @State private var isFetchingCommunity = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                //headerView
                
                // AIVO BILLBOARD Section
                if !remoteConfig.bestAivoSongsList.isEmpty {
                    SongsForYouSection(
                        title: "AIVO BILLBOARD",
                        songs: Array(remoteConfig.bestAivoSongsList.prefix(4)),
                        onPlay: { song in
                            if let index = remoteConfig.bestAivoSongsList.firstIndex(where: { $0.id == song.id }) {
                                selectedSongForPlayback = SongPlaybackItem(songs: remoteConfig.bestAivoSongsList, initialIndex: index)
                            }
                        },
                        onSeeAll: {
                            selectedThemeList = ThemeList(title: "AIVO BILLBOARD", songs: remoteConfig.bestAivoSongsList)
                        }
                    )
                }
                
                // Songs For You Section (Optional, keeping it below if needed, or removing)
                // if !songsForYou.isEmpty { ... }
                
                
                // Community Hottest Section
                if !communityHottestSongs.isEmpty {
                    CommunityHottestSection(
                        songs: communityHottestSongs,
                        onPlay: { song in
                            if let index = communityHottestSongs.firstIndex(where: { $0.id == song.id }) {
                                selectedSongForPlayback = SongPlaybackItem(songs: communityHottestSongs, initialIndex: index)
                            }
                        },
                        onSeeAll: {
                            selectedThemeList = ThemeList(title: "Weekly Top 10", songs: communityHottestSongs)
                        }
                    )
                }
                
                // Limited Offer (Discount Ad)
                if !SubscriptionManager.shared.isPremium {
                    DiscountAdView()
                        .padding(.horizontal, 4) // Adjust padding to match Sona style if needed, Sona used 20 on container
                }
                
                // Search Bar
                //searchBarView
                
                // News Section
                newsSection

                // Trending Section
                trendingSection
                
                // Popular Section
                popularSection
                
                
                
                
                // Genre Sections
                genreSections
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100) // Space for bottom nav
        }

        .fullScreenCover(item: $selectedSongForPlayback) { item in
            PlayOnlineSongScreen(songs: item.songs, initialIndex: item.initialIndex)
        }
        .fullScreenCover(item: $selectedThemeList) { themeList in
            OnlineSongListView(title: themeList.title, songs: themeList.songs)
        }
        .fullScreenCover(isPresented: $showSubscription) {
            SubscriptionScreen()
        }
        .onAppear {
            loadSongStatus()
            fetchCommunitySongs()
        }
    }
    
    // MARK: - Community Songs Fetching
    private func fetchCommunitySongs() {
        guard !isFetchingCommunity else { return }
        
        // Check cache first
        if let cache = LocalStorageManager.shared.getCommunityCache() {
            let expirationTime: TimeInterval = 12 * 60 * 60 // 12 hours
            let cacheAge = Date().timeIntervalSince(cache.lastFetch)
            
            if cacheAge < expirationTime {
                self.communityHottestSongs = cache.hottest
                self.communityNewestSongs = cache.newest
                Logger.d("📦 [Explore] Loaded community songs from cache (Age: \(Int(cacheAge/3600))h)")
                return
            }
            Logger.d("📦 [Explore] Cache expired (Age: \(Int(cacheAge/3600))h), fetching fresh data")
        }
        
        isFetchingCommunity = true
        
        Task {
            do {
                // Fetch 10 hottest and 50 newest songs
                let hottest = try await FirestoreService.shared.fetchHottestSongs(limit: 10)
                let newest = try await FirestoreService.shared.fetchNewSongs(limit: 50)
                
                await MainActor.run {
                    self.communityHottestSongs = hottest
                    self.communityNewestSongs = newest
                    self.isFetchingCommunity = false
                    
                    // Save to cache
                    LocalStorageManager.shared.saveCommunityCache(hottest: hottest, newest: newest)
                    Logger.d("✅ [Explore] Fetched and cached community songs: \(hottest.count) hot, \(newest.count) new")
                }
            } catch {
                await MainActor.run {
                    self.isFetchingCommunity = false
                    Logger.e("❌ [Explore] Error fetching community songs: \(error)")
                }
            }
        }
    }
    
    // MARK: - Load Song Status
    private func loadSongStatus() {
        var statusMap: [String: SongStatus] = [:]
        for status in remoteConfig.songStatus {
            statusMap[status.id] = status
        }
        songStatusMap = statusMap
        
        // Populate Songs For You if empty or strictly if needed
        if songsForYou.isEmpty && !remoteConfig.hottestList.isEmpty {
            songsForYou = remoteConfig.hottestList.shuffled()
        }
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
                showSubscription = true
            }) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(SubscriptionManager.shared.isPremium ? .white : .white.opacity(0.7))
                    .frame(width: 32, height: 32)
                    .background(
                        Group {
                            if SubscriptionManager.shared.isPremium {
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(red: 1.0, green: 0.08, blue: 0.05),
                                        Color(red: 1.0, green: 0.25, blue: 0.05),
                                        Color(red: 1.0, green: 0.45, blue: 0.1)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            } else {
                                Color.gray.opacity(0.3)
                            }
                        }
                    )
                    .clipShape(Circle())
                    .overlay(
                        Circle().stroke(
                            SubscriptionManager.shared.isPremium
                            ? Color(red: 1.0, green: 0.25, blue: 0.05).opacity(0.9)
                            : Color.white.opacity(0.5),
                            lineWidth: 1
                        )
                    )
                    .shadow(color: SubscriptionManager.shared.isPremium ? Color(red: 1.0, green: 0.2, blue: 0.05).opacity(0.45) : .clear,
                            radius: 8, x: 0, y: 3)
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
                            let trendingSongs = Array(remoteConfig.trendingList.prefix(10))
                            selectedSongForPlayback = SongPlaybackItem(songs: trendingSongs, initialIndex: index)
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
            HStack {
                Text("Popular")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: {
                    selectedThemeList = ThemeList(title: "Popular", songs: remoteConfig.hottestList)
                }) {
                    Text("See All")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(Array(remoteConfig.hottestList.prefix(10).enumerated()), id: \.element.id) { index, song in
                        PopularCardView(song: song) {
                            let popularSongs = Array(remoteConfig.hottestList.prefix(10))
                            selectedSongForPlayback = SongPlaybackItem(songs: popularSongs, initialIndex: index)
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
                
                Button(action: {
                    selectedThemeList = ThemeList(title: "News", songs: communityNewestSongs)
                }) {
                    Text("See All")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            // Horizontal scroll with 3 rows
            ScrollView(.horizontal, showsIndicators: false) {
                let rows = [
                    GridItem(.fixed(72), spacing: 16),
                    GridItem(.fixed(72), spacing: 16),
                    GridItem(.fixed(72), spacing: 16)
                ]
                
                let newsSongs = Array(communityNewestSongs.prefix(15))
                
                LazyHGrid(rows: rows, alignment: .top, spacing: 32) {
                    ForEach(Array(newsSongs.enumerated()), id: \.element.id) { index, song in
                        NewsCardView(
                            song: song,
                            status: songStatusMap[song.id]
                        ) {
                            selectedSongForPlayback = SongPlaybackItem(songs: newsSongs, initialIndex: index)
                        }
                        .frame(width: 300) // Fixed width for alignment
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
    
    // MARK: - Genre Sections
    private var genreSections: some View {
        VStack(alignment: .leading, spacing: 24) {
            ForEach(SongGenre.getExplore(), id: \.self) { genre in
                // Filter songs once to maintain consistency
                let filteredSongs = filterSongsByGenre(genre)
                
                GenreSectionView(
                    genre: genre,
                    songs: filteredSongs, // Pass full list
                    songStatusMap: songStatusMap,
                    onSongTap: { _, index in // We ignore the passed array and use filteredSongs logic inside or just pass it through
                         // Play full list starting at index. Even if UI shows 10, playing should probably queue the filtered list?
                         // User said: "show max 10... see all >> full list".
                         // Usually playing from a preview list just plays that context.
                         // But if I want to "get more songs", maybe I should just play the top 10?
                         // User said: "filter không giới hạn số bài... sau khi filter xong thì xáo trộn bài... ở explore thì show max 10... user bấm see all mới xem đc full list".
                         // This implies the Explore view is a "preview" of the filtered list.
                         // If I tap 3rd song, I probably expect to hear that + maybe subsequent ones in that preview?
                         // Let's pass the full filteredSongs list but start at `index`. 
                         // Note: `index` comes from the UI loop which is `prefix(10)`. So index is 0..9.
                         // Only `filteredSongs` are passed to `SongPlaybackItem`.
                         // If `filteredSongs` has 100 items, and I tap index 2, I play from index 2 of 100.
                         // This is great behavior - user finds a song, keeps listening to genre radio.
                         selectedSongForPlayback = SongPlaybackItem(songs: filteredSongs, initialIndex: index)
                    },
                    onSeeAll: { _ in
                        selectedThemeList = ThemeList(title: genre.displayName, songs: filteredSongs)
                    }
                )
            }
        }
    }
    
    // MARK: - Filter Songs by Genre
    private func filterSongsByGenre(_ genre: SongGenre) -> [SunoData] {
        let keywords = genre.searchKeywords
        var filteredSongs = remoteConfig.allSongsList.filter { song in
            let songTags = song.tags.lowercased()
            // Check if ANY keyword is contained in song tags
            return keywords.contains { keyword in
                songTags.contains(keyword)
            }
        }
        
        // Shuffle the filtered list to randomize
        filteredSongs.shuffle()
        
        // Return FULL list (unlimited)
        return filteredSongs
    }
}

// MARK: - Genre Section View
struct GenreSectionView: View {
    let genre: SongGenre
    let songs: [SunoData]
    let songStatusMap: [String: SongStatus]
    let onSongTap: ([SunoData], Int) -> Void
    let onSeeAll: ([SunoData]) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(genre.displayName)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: {
                    onSeeAll(songs)
                }) {
                    Text("See All")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            if songs.isEmpty {
                Text("No songs available")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.vertical, 20)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        // Display only top 10 items
                        ForEach(Array(songs.prefix(10).enumerated()), id: \.element.id) { index, song in
                            GenreSongCardView(
                                song: song,
                                status: songStatusMap[song.id],
                                onTap: {
                                    // Pass full 'songs' list to handler (via closure capture or arg)
                                    // Index matches the full list because we just took prefix.
                                    onSongTap(songs, index)
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
                        
                        Text(song.username ?? "Aivo Music")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(1)
                    }
                    
                    // Row 3: Tags
                    Text(song.tags.isEmpty ? "No tags" : song.tags)
                        .font(.system(size: 10, weight: .regular))
                        .foregroundColor(.white.opacity(0.5))
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                
                //Spacer()
                
                // Play Count Section (Right)
                VStack(spacing: 4) {
                    Image(systemName: "headphones")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text(formatCount(status?.playCount ?? song.playCount ?? 0))
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

// MARK: - Community Sections
struct CommunityHottestSection: View {
    let songs: [SunoData]
    let onPlay: (SunoData) -> Void
    let onSeeAll: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Weekly Top 10")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: onSeeAll) {
                    Text("See All")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AivoTheme.Primary.orange)
                }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(Array(songs.enumerated()), id: \.offset) { index, song in
                        CommunitySongCard(song: song, rank: index + 1) {
                            onPlay(song)
                        }
                    }
                }
                .padding(.horizontal, 2)
            }
        }
    }
}


struct CommunitySongCard: View {
    let song: SunoData
    let rank: Int?
    let onTap: () -> Void
    
    init(song: SunoData, rank: Int? = nil, onTap: @escaping () -> Void) {
        self.song = song
        self.rank = rank
        self.onTap = onTap
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                ZStack(alignment: .bottomTrailing) {
                    AsyncImage(url: URL(string: song.imageUrl)) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Image("demo_cover").resizable().aspectRatio(contentMode: .fill)
                    }
                    .frame(width: 140, height: 140)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    // Rank Label (Bottom-Left)
                    if let rank = rank {
                        Text("#\(rank)")
                            .font(.system(size: 38, weight: .black))
                            .italic()
                            .foregroundColor(AivoTheme.Primary.orange)
                            .shadow(color: .black.opacity(0.8), radius: 4, x: 2, y: 2)
                            .padding(.leading, 8)
                            .padding(.bottom, 0)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                    }
                    
                    // Play Count Badge (Bottom-Right)
                    HStack(spacing: 4) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 10))
                        Text("\(song.playCount ?? 0)")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.6))
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                    .padding(8)
                }
                
                Text(song.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(song.username ?? "Aivo Music")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
                    .lineLimit(1)
            }
            .frame(width: 140)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview
struct ExploreTabViewNew_Previews: PreviewProvider {
    static var previews: some View {
        ExploreTabViewNew()
        // - [x] Integrate `incrementPlayCount` in `MusicPlayer` `[x]`
        // - [x] Update `ExploreTabViewNew` to show community categories `[x]`
        // - [x] Final walkthrough and verification `[x]`
            .background(AivoSunsetBackground())
    }
}

// MARK: - Supporting Views

struct DiscountAdView: View {
    @State private var showSubscription = false
    
    var body: some View {
        HStack {
            Image(systemName: "tag.fill") // Placeholder
                .resizable()
                .frame(width: 40, height: 40)
                .foregroundColor(AivoTheme.Primary.orange)
                .padding(8)
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text("Limited Offer")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Text("Unleash your creativity and build your music world with AI")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Button(action: {
                showSubscription = true
            }) {
                Text("80% OFF")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.yellow) // Specific ad color
                    .cornerRadius(16)
            }
        }
        .padding(12)
        .background(Color(hex: "#1C1C1E"))
        .cornerRadius(12)
        .onTapGesture {
            showSubscription = true
        }
        .fullScreenCover(isPresented: $showSubscription) {
            SubscriptionScreen()
        }
    }
}

struct SongsForYouSection: View {
    let title: String
    let songs: [SunoData]
    let onPlay: (SunoData) -> Void
    let onSeeAll: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: title.contains("Community") ? "globe" : "person.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(AivoTheme.Primary.orange)
                Text(title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Button(action: onSeeAll) {
                    Text("See All")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                }
            }
            .padding(.top, 16)
            
            VStack(spacing: 12) {
                ForEach(songs) { song in
                    SongForYouRow(song: song, onPlay: onPlay)
                }
            }
            .padding(.bottom, 16)
        }
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

struct SongForYouRow: View {
    let song: SunoData
    let onPlay: (SunoData) -> Void
    @State private var showMenu = false
    
    var body: some View {
        HStack(spacing: 12) {
            KFImage(URL(string: song.imageUrl.isEmpty ? song.sourceImageUrl : song.imageUrl))
                .placeholder {
                    Color.gray.opacity(0.3)
                }
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 48, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 4))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(song.title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(song.username ?? "Aivo Music")
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Button(action: {
                showMenu = true
            }) {
                Image(systemName: "ellipsis")
                    .rotationEffect(.degrees(90))
                    .foregroundColor(.gray)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onPlay(song)
        }
        .confirmationDialog("", isPresented: $showMenu, titleVisibility: .hidden) {
            Button("Play Now") {
                onPlay(song)
            }
            Button("Add to queue") {
                MusicPlayer.shared.addToQueue(song)
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}

