import Foundation

// MARK: - Favorite Manager
class FavoriteManager {
    static let shared = FavoriteManager()
    
    private init() {}
    
    private let key = "favorite_song_ids"
    
    // MARK: - Get Favorite IDs
    private func getFavoriteIds() -> Set<String> {
        guard let data = UserDefaults.standard.array(forKey: key) as? [String] else {
            return Set<String>()
        }
        return Set(data)
    }
    
    // MARK: - Save Favorite IDs
    private func saveFavoriteIds(_ ids: Set<String>) {
        UserDefaults.standard.set(Array(ids), forKey: key)
    }
    
    // MARK: - Check if favorite
    func isFavorite(songId: String) -> Bool {
        return getFavoriteIds().contains(songId)
    }
    
    // MARK: - Toggle favorite
    func toggleFavorite(songId: String) -> Bool {
        var favorites = getFavoriteIds()
        
        if favorites.contains(songId) {
            favorites.remove(songId)
            saveFavoriteIds(favorites)
            return false
        } else {
            favorites.insert(songId)
            saveFavoriteIds(favorites)
            return true
        }
    }
    
    // MARK: - Add favorite
    func addFavorite(songId: String) {
        var favorites = getFavoriteIds()
        favorites.insert(songId)
        saveFavoriteIds(favorites)
    }
    
    // MARK: - Remove favorite
    func removeFavorite(songId: String) {
        var favorites = getFavoriteIds()
        favorites.remove(songId)
        saveFavoriteIds(favorites)
    }
    
    // MARK: - Get all favorites
    func getAllFavorites() -> Set<String> {
        return getFavoriteIds()
    }
    
    // MARK: - Clear all favorites
    func clearAllFavorites() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
