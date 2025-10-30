import Foundation

// MARK: - Intro Song Data Models
struct IntroSongJSON: Codable {
    let mood: String
    let data: [GenreData]
}

struct GenreData: Codable {
    let genre: String
    let data: [ThemeData]
}

struct ThemeData: Codable {
    let theme: String
    let songs: [SunoData]
}

// MARK: - Intro Song Service
class IntroSongService {
    static let shared = IntroSongService()
    
    private init() {}
    
    private var cachedSongs: [IntroSongJSON]?
    
    // MARK: - Load Songs from JSON
    func loadSongsFromJSON() throws -> [IntroSongJSON] {
        if let cached = cachedSongs {
            return cached
        }
        
        guard let url = Bundle.main.url(forResource: "sample_ai_song", withExtension: "json") else {
            throw IntroSongError.fileNotFound
        }
        
        let data = try Data(contentsOf: url)
        let songs = try JSONDecoder().decode([IntroSongJSON].self, from: data)
        
        cachedSongs = songs
        return songs
    }
    
    // MARK: - Query Songs by Mood, Genre, Theme
    func querySongs(mood: SongMood, genre: SongGenre, theme: SongTheme) throws -> [SunoData] {
        let songsData = try loadSongsFromJSON()
        
        let moodString = moodToJSONString(mood)
        let genreString = genreToJSONString(genre)
        let themeString = themeToJSONString(theme)
        
        // Find matching mood
        guard let moodData = songsData.first(where: { $0.mood.lowercased() == moodString.lowercased() }) else {
            Logger.w("⚠️ [IntroSong] No songs found for mood: \(moodString)")
            return []
        }
        
        // Find matching genre
        guard let genreData = moodData.data.first(where: { $0.genre.lowercased() == genreString.lowercased() }) else {
            Logger.w("⚠️ [IntroSong] No songs found for genre: \(genreString)")
            return []
        }
        
        // Find matching theme
        guard let themeData = genreData.data.first(where: { $0.theme.lowercased() == themeString.lowercased() }) else {
            Logger.w("⚠️ [IntroSong] No songs found for theme: \(themeString)")
            return []
        }
        
        Logger.d("✅ [IntroSong] Found \(themeData.songs.count) songs for \(moodString)/\(genreString)/\(themeString)")
        return themeData.songs
    }
    
    // MARK: - Get Random Song
    func getRandomSong(mood: SongMood, genre: SongGenre, theme: SongTheme) -> SunoData? {
        do {
            let songs = try querySongs(mood: mood, genre: genre, theme: theme)
            return songs.randomElement()
        } catch {
            Logger.e("❌ [IntroSong] Error querying songs: \(error)")
            return nil
        }
    }
    
    // MARK: - Helper: Convert Enums to JSON Strings
    private func moodToJSONString(_ mood: SongMood) -> String {
        // Direct lowercase mapping (Happy -> happy)
        return mood.rawValue.lowercased()
    }
    
    private func genreToJSONString(_ genre: SongGenre) -> String {
        // Map genres to JSON format
        let genreMap: [SongGenre: String] = [
            .rap: "rap",
            .pop: "pop",
            .pop_ballad: "pop ballad",
            .rock: "rock",
            .kpop: "kpop",
            .electronic: "electronic",
            .edm: "edm",
            .hiphop: "hiphop"
        ]
        
        // Check direct mapping first
        if let mapped = genreMap[genre] {
            return mapped
        }
        
        // Fallback: lowercase rawValue and handle special cases
        let raw = genre.rawValue.lowercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "&", with: "")
        
        // Handle common variations
        if raw.contains("edm") || raw == "electronic" {
            return "edm"
        }
        if raw.contains("pop") && raw.contains("ballad") {
            return "pop ballad"
        }
        if raw.contains("hip") || raw.contains("rap") {
            return "rap"
        }
        
        return raw
    }
    
    private func themeToJSONString(_ theme: SongTheme) -> String {
        // Map themes to JSON format (remove "My " prefix and lowercase)
        let themeMap: [SongTheme: String] = [
            .myPet: "pet",
            .myLove: "love",
            .myFutureSelf: "future",
            .myFamily: "family",
            .myDreams: "dream",
            .myCity: "city",
            .myWork: "work",
            .myHobbies: "hobby",
            .myMemories: "memory",
            .myGoals: "goal",
            .love: "love",
            .party: "party",
            .friendship: "friendship",
            .dream: "dream"
        ]
        
        // Check direct mapping first
        if let mapped = themeMap[theme] {
            return mapped
        }
        
        // Fallback: lowercase and remove "My " prefix
        var raw = theme.rawValue.lowercased()
        if raw.hasPrefix("my ") {
            raw = String(raw.dropFirst(3))
        }
        return raw
    }
}

// MARK: - Errors
enum IntroSongError: Error {
    case fileNotFound
    case decodingError
    case noSongsFound
}

