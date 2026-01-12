import Foundation
import Combine

class PlaylistManager: ObservableObject {
    static let shared = PlaylistManager()
    
    @Published var playlists: [Playlist] = []
    
    var userPlaylists: [Playlist] {
        playlists
    }
    
    private init() {
        loadPlaylists()
    }
    
    // MARK: - CRUD Operations
    func createPlaylist(name: String, description: String = "", coverImageData: Data? = nil, coverColor: String? = nil, isCustomCover: Bool = false) {
        _ = createPlaylistAndReturn(name: name, description: description, coverImageData: coverImageData, coverColor: coverColor, isCustomCover: isCustomCover)
    }
    
    func createPlaylistAndReturn(name: String, description: String = "", coverImageData: Data? = nil, coverColor: String? = nil, isCustomCover: Bool = false) -> Playlist {
        let newPlaylist = Playlist(
            name: name,
            description: description,
            coverImageData: coverImageData,
            coverColor: coverColor,
            isCustomCover: isCustomCover
        )
        playlists.append(newPlaylist)
        savePlaylists()
        return newPlaylist
    }
    
    func deletePlaylist(_ playlist: Playlist) {
        playlists.removeAll { $0.id == playlist.id }
        savePlaylists()
    }
    
    func addSongToPlaylist(_ songId: String, playlistId: String) {
        if let index = playlists.firstIndex(where: { $0.id == playlistId }) {
            if !playlists[index].songIds.contains(songId) {
                playlists[index].songIds.append(songId)
                playlists[index].updatedAt = Int64(Date().timeIntervalSince1970 * 1000)
                savePlaylists()
            }
        }
    }
    
    func addSongToPlaylist(_ song: SunoData, playlist: Playlist) {
        addSongToPlaylist(song.id, playlistId: playlist.id)
    }
    
    func removeSongFromPlaylist(_ songId: String, playlistId: String) {
        if let index = playlists.firstIndex(where: { $0.id == playlistId }) {
            playlists[index].songIds.removeAll { $0 == songId }
            playlists[index].updatedAt = Int64(Date().timeIntervalSince1970 * 1000)
            savePlaylists()
        }
    }
    
    func reorderSongs(in playlistId: String, from source: IndexSet, to destination: Int) {
        guard let index = playlists.firstIndex(where: { $0.id == playlistId }) else { return }
        
        var songIds = playlists[index].songIds
        songIds.move(fromOffsets: source, toOffset: destination)
        playlists[index].songIds = songIds
        playlists[index].updatedAt = Int64(Date().timeIntervalSince1970 * 1000)
        savePlaylists()
    }
    
    // MARK: - Persistence
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private func getPlaylistsFileURL() -> URL {
        getDocumentsDirectory().appendingPathComponent("playlists.json")
    }
    
    private func savePlaylists() {
        do {
            let data = try JSONEncoder().encode(playlists)
            try data.write(to: getPlaylistsFileURL())
        } catch {
            print("❌ [PlaylistManager] Failed to save playlists: \(error)")
        }
    }
    
    private func loadPlaylists() {
        let url = getPlaylistsFileURL()
        if FileManager.default.fileExists(atPath: url.path) {
            do {
                let data = try Data(contentsOf: url)
                playlists = try JSONDecoder().decode([Playlist].self, from: data)
                print("📚 [PlaylistManager] Loaded \(playlists.count) playlists")
            } catch {
                print("❌ [PlaylistManager] Failed to load playlists: \(error)")
            }
        }
    }
    
    // MARK: - Smart Playlists Logic
    func getSmartPlaylistSongs(type: SmartPlaylistType, allSongs: [SunoData]) -> [SunoData] {
        switch type {
        case .favorites:
            return allSongs.filter { FavoriteManager.shared.isFavorite(songId: $0.id) }
            
        case .recentlyAdded:
            // Sort by createTime descending, take top 30
            return Array(allSongs.sorted { $0.createTime > $1.createTime }.prefix(30))
            
        case .recentlyPlayed:
            // Currently no 'lastPlayed' field in SunoData
            // For now, return random 10 or empty if no tracking
             // TODO: Implement Last Played tracking
             return Array(allSongs.shuffled().prefix(10))
            
        case .topTracks:
            // Currently no 'playCount' field in SunoData
            // For now, return random 10
             // TODO: Implement Play Count tracking
             return Array(allSongs.shuffled().prefix(10))
        }
    }
    
    func getSongs(for type: SmartPlaylistType) -> [SunoData] {
        // Aggregate all songs from SunoDataManager + LocalSongManager
        var allSongs = SunoDataManager.shared.savedSunoDataList
        allSongs.append(contentsOf: LocalSongManager.shared.fetchLocalSongs())
        
        return getSmartPlaylistSongs(type: type, allSongs: allSongs)
    }
}
