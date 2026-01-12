import SwiftUI
import Combine

struct AddSongsToPlaylistView: View {
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
                        LazyVStack(spacing: 12) {
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
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(AivoTheme.Primary.orange)
                                .cornerRadius(12)
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
                    .font(.system(size: 20))
                    .foregroundColor(.white)
            }
            
            Text("Add songs")
                .font(.headline)
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
                        .font(.subheadline)
                        .foregroundColor(.white)
                    Image(systemName: "chevron.down")
                        .font(.caption)
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
                .foregroundColor(.gray)
            TextField("Search songs", text: $searchText)
                .foregroundColor(.white)
                .onChange(of: searchText) { _ in
                    filterSongs()
                }
        }
        .padding(10)
        .background(Color.white.opacity(0.1))
        .cornerRadius(10)
        .padding()
    }
    
    private var selectAllButton: some View {
        Button(action: toggleSelectAll) {
            HStack {
                Text("Select all")
                    .foregroundColor(.white)
                Spacer()
                Image(systemName: isAllSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isAllSelected ? AivoTheme.Primary.orange : .gray)
            }
            .padding(.vertical, 8)
        }
    }
    
    private func songRow(for song: SunoData) -> some View {
        Button(action: { toggleSelection(for: song.id) }) {
            HStack(spacing: 12) {
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
                             .foregroundColor(.gray)
                     }
                }
                .frame(width: 48, height: 48)
                .cornerRadius(8)
                .clipped()
                
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(song.title)
                        .font(.body)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    Text(song.modelName) // Using modelName as artist/subtitle equivalent
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Checkbox
                Image(systemName: selectedSongIds.contains(song.id) ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(selectedSongIds.contains(song.id) ? AivoTheme.Primary.orange : .gray)
            }
            .padding(12)
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)
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
        for songId in selectedSongIds {
            if let song = allSongs.first(where: { $0.id == songId }) {
                PlaylistManager.shared.addSongToPlaylist(song, playlist: playlist)
            }
        }
        
        onFinish?()
        dismiss()
    }
}
