import SwiftUI
import Combine

struct AddSongsToPlaylistView: View {
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    let playlist: Playlist
    var onFinish: (() -> Void)?
    @Environment(\.dismiss) var dismiss
    
    @State private var allSongs: [SunoData] = []
    @State private var displayedSongs: [SunoData] = []
    @State private var selectedSongIds: Set<String> = []
    @State private var searchText = ""
    @State private var filter: SongFilter = .allSongs
    
    // Dependencies
    private let playlistManager = PlaylistManager.shared
    
    enum SongFilter: String, CaseIterable {
        case allSongs = "All songs"
        case favorites = "My favorites"
        case lastAdded = "Last added"
        case recentlyPlayed = "Recently played"
        case mostPlayed = "Most played"
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AivoTheme.Background.primary.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    headerView
                    searchBar
                    
                    ScrollView {
                        LazyVStack(spacing: iPadScaleSmall(12)) {
                            selectAllButton
                            
                            ForEach(displayedSongs) { song in
                                songRow(for: song)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 80) // Space for bottom button
                    }
                }
                
                // Bottom Button
                VStack {
                    Spacer()
                    if !selectedSongIds.isEmpty {
                        Button(action: addSelectedSongs) {
                            Text("Add \(selectedSongIds.count) songs")
                                .font(.system(size: iPadScale(17), weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: iPadScale(50))
                                .background(AivoTheme.Primary.orange)
                                .cornerRadius(iPadScale(12))
                        }
                        .padding()
                        .background(AivoTheme.Background.primary.opacity(0.9))
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            loadSongs()
        }
    }
    
    // MARK: - Subviews
    
    private var headerView: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "arrow.left")
                    .font(.system(size: iPadScale(20)))
                    .foregroundColor(.white)
            }
            
            Text("Add songs")
                .font(.system(size: iPadScale(17), weight: .semibold))
                .foregroundColor(.white)
                .padding(.leading, 8)
            
            Spacer()
            
            Menu {
                ForEach(SongFilter.allCases, id: \.self) { option in
                    Button(action: {
                        filter = option
                        filterSongs()
                    }) {
                        if filter == option {
                            Label(option.rawValue, systemImage: "checkmark")
                        } else {
                            Text(option.rawValue)
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(filter.rawValue)
                        .font(.system(size: iPadScale(15)))
                        .foregroundColor(.white)
                    Image(systemName: "chevron.down")
                        .font(.system(size: iPadScale(12)))
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(AivoTheme.Background.secondary)
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .font(.system(size: iPadScale(16)))
                .foregroundColor(.gray)
            TextField("Search songs", text: $searchText)
                .font(.system(size: iPadScale(16)))
                .foregroundColor(.white)
                .onChange(of: searchText) { _ in
                    filterSongs()
                }
        }
        .padding(iPadScaleSmall(10))
        .background(Color.white.opacity(0.1))
        .cornerRadius(iPadScale(10))
        .padding()
    }
    
    private var selectAllButton: some View {
        Button(action: toggleSelectAll) {
            HStack {
                Text("Select all")
                    .font(.system(size: iPadScale(16)))
                    .foregroundColor(.white)
                Spacer()
                Image(systemName: isAllSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: iPadScale(22)))
                    .foregroundColor(isAllSelected ? AivoTheme.Primary.orange : .gray)
            }
            .padding(.vertical, iPadScaleSmall(8))
        }
    }
    
    private func songRow(for song: SunoData) -> some View {
        let coverSize: CGFloat = iPadScale(48)
        
        return Button(action: { toggleSelection(for: song.id) }) {
            HStack(spacing: iPadScaleSmall(12)) {
                // Artwork
                ZStack {
                     if let localPath = song.coverImageLocalPath,
                        let image = UIImage(contentsOfFile: localPath) {
                         Image(uiImage: image)
                             .resizable()
                             .aspectRatio(contentMode: .fill)
                     } else if let url = URL(string: song.imageUrl) {
                         AsyncImage(url: url) { phase in
                             if let image = phase.image {
                                 image.resizable().aspectRatio(contentMode: .fill)
                             } else {
                                 Color.gray.opacity(0.3)
                             }
                         }
                     } else {
                         Image(systemName: "music.note")
                             .font(.system(size: iPadScale(20)))
                             .foregroundColor(.gray)
                     }
                }
                .frame(width: coverSize, height: coverSize)
                .cornerRadius(iPadScale(8))
                .clipped()
                
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(song.title)
                        .font(.system(size: iPadScale(16)))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    Text((song.username?.isEmpty == false ? song.username! : song.modelName))
                        .font(.system(size: iPadScale(13)))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Checkbox
                Image(systemName: selectedSongIds.contains(song.id) ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: iPadScale(22)))
                    .foregroundColor(selectedSongIds.contains(song.id) ? AivoTheme.Primary.orange : .gray)
            }
            .padding(iPadScaleSmall(12))
            .background(Color.white.opacity(0.05))
            .cornerRadius(iPadScale(12))
        }
    }
    
    // MARK: - Logic
    
    var isAllSelected: Bool {
        return !displayedSongs.isEmpty && selectedSongIds.count == displayedSongs.count
    }
    
    private func toggleSelectAll() {
        if isAllSelected {
            selectedSongIds.removeAll()
        } else {
            selectedSongIds = Set(displayedSongs.map { $0.id })
        }
    }
    
    private func toggleSelection(for id: String) {
        if selectedSongIds.contains(id) {
            selectedSongIds.remove(id)
        } else {
            selectedSongIds.insert(id)
        }
    }
    
    private func loadSongs() {
        // Aggregate songs from both managers
        let aiSongs = SunoDataManager.shared.savedSunoDataList
        let localSongs = LocalSongManager.shared.fetchLocalSongs()
        
        self.allSongs = aiSongs + localSongs
        filterSongs()
    }
    
    private func filterSongs() {
        var result = allSongs
        
        // 1. Apply Category Filter
        switch filter {
        case .allSongs:
            break
        case .favorites:
            // Assuming PlaylistManager has logic for favorites, or we check if in Favorites playlist
            // Ideally, we'd query PlaylistManager.shared.getSongs(for: .favorites) but that returns [SunoData]
            // Let's use that directly if selected
            result = PlaylistManager.shared.getSongs(for: .favorites)
        case .lastAdded:
            // Sort by creation/import date if available.
            // For now, assuming newer items are at font or back. Let's just reverse allSongs as a proxy or keep standard.
            // A real implementation would check createdAt/etc.
            result = result.reversed()
        case .recentlyPlayed:
             result = PlaylistManager.shared.getSongs(for: .recentlyPlayed)
        case .mostPlayed:
             result = PlaylistManager.shared.getSongs(for: .topTracks) // 'topTracks' ~ 'mostPlayed'
        }
        
        // 2. Apply Search
        if !searchText.isEmpty {
            result = result.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        }
        
        self.displayedSongs = result
    }
    
    private func addSelectedSongs() {
        // Non-premium users must watch a reward ad before adding songs
        if !subscriptionManager.isPremium {
            Logger.d("📢 [AddSongs] Non-premium user, showing reward ad before adding songs...")
            AdManager.shared.showRewardAd { success in
                guard success else {
                    Logger.d("📢 [AddSongs] User skipped reward ad, blocking add songs")
                    return
                }
                Logger.d("📢 [AddSongs] Reward ad completed, proceeding with add songs")
                performAddSongs()
            }
        } else {
            performAddSongs()
        }
    }
    
    private func performAddSongs() {
        for songId in selectedSongIds {
            if let song = allSongs.first(where: { $0.id == songId }) {
                PlaylistManager.shared.addSongToPlaylist(song, playlist: playlist)
            }
        }
        
        onFinish?()
        dismiss()
    }
}
