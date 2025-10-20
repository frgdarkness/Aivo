import Foundation

// MARK: - Song Creation Enums

enum SongMood: String, CaseIterable {
    case chill = "Chill"
    case happy = "Happy"
    case motivational = "Motivational"
    case sad = "Sad"
    case energetic = "Energetic"
    case romantic = "Romantic"
    case calm = "Calm"
    case aggressive = "Aggressive"
    
    var displayName: String {
        return self.rawValue
    }
    
    var description: String {
        switch self {
        case .chill:
            return "Relaxed and laid-back vibes"
        case .happy:
            return "Upbeat and joyful energy"
        case .motivational:
            return "Inspiring and empowering"
        case .sad:
            return "Melancholic and emotional"
        case .energetic:
            return "High-energy and dynamic"
        case .romantic:
            return "Love and passion"
        case .calm:
            return "Peaceful and serene"
        case .aggressive:
            return "Intense and powerful"
        }
    }
    
    static func getHottest() -> [SongMood] {
        return [.chill, .happy, .motivational, .energetic]
    }
}

enum SongGenre: String, CaseIterable {
    case rap = "Rap"
    case pop = "Pop"
    case rock = "Rock"
    case kpop = "K-Pop"
    case electronic = "Electronic"
    case country = "Country"
    case rnb = "R&B"
    case jazz = "Jazz"
    case classical = "Classical"
    case hiphop = "Hip-Hop"
    
    var displayName: String {
        return self.rawValue
    }
    
    var description: String {
        switch self {
        case .rap:
            return "Rhythmic spoken lyrics"
        case .pop:
            return "Popular mainstream music"
        case .rock:
            return "Guitar-driven rock music"
        case .kpop:
            return "Korean pop music"
        case .electronic:
            return "Electronic and synthesized sounds"
        case .country:
            return "American country music"
        case .rnb:
            return "Rhythm and blues"
        case .jazz:
            return "Improvisational jazz"
        case .classical:
            return "Classical orchestral music"
        case .hiphop:
            return "Hip-hop beats and culture"
        }
    }
    
    static func getHottest() -> [SongGenre] {
        return [.rap, .pop, .rock, .electronic]
    }
}

enum SongTheme: String, CaseIterable {
    case myPet = "My Pet"
    case myLove = "My Love"
    case myFutureSelf = "My Future Self"
    case myFamily = "My Family"
    case myDreams = "My Dreams"
    case myCity = "My City"
    case myWork = "My Work"
    case myHobbies = "My Hobbies"
    case myMemories = "My Memories"
    case myGoals = "My Goals"
    
    var displayName: String {
        return self.rawValue
    }
    
    var description: String {
        switch self {
        case .myPet:
            return "Songs about your beloved pet"
        case .myLove:
            return "Songs about love and relationships"
        case .myFutureSelf:
            return "Songs about your future aspirations"
        case .myFamily:
            return "Songs about family bonds"
        case .myDreams:
            return "Songs about dreams and aspirations"
        case .myCity:
            return "Songs about your hometown"
        case .myWork:
            return "Songs about work and career"
        case .myHobbies:
            return "Songs about your interests"
        case .myMemories:
            return "Songs about past memories"
        case .myGoals:
            return "Songs about your goals"
        }
    }
    
    static func getHottest() -> [SongTheme] {
        return [.myPet, .myLove, .myFutureSelf, .myDreams]
    }
}

// MARK: - Song Creation Data Model

struct SongCreationData {
    let mood: SongMood
    let genre: SongGenre
    let theme: SongTheme
    
    var summary: String {
        return "\(mood.displayName) \(genre.displayName) for \(theme.displayName)"
    }
    
    var description: String {
        return "A \(mood.displayName.lowercased()) \(genre.displayName.lowercased()) song about \(theme.displayName.lowercased())"
    }
}

// MARK: - Song Data Model

struct Song {
    let id: String
    let title: String
    let artist: String
    let genre: SongGenre
    let mood: SongMood
    let theme: SongTheme
    let duration: TimeInterval
    let audioFileName: String
    let lyricsFileName: String
    let coverImageName: String?
    
    static let tokyo = Song(
        id: "ai_tokyo",
        title: "AI Tokyo",
        artist: "Aivo AI",
        genre: .electronic,
        mood: .energetic,
        theme: .myCity,
        duration: 180, // 3 minutes
        audioFileName: "ai_tokyo",
        lyricsFileName: "ai_tokyo_lyric",
        coverImageName: "tokyo_cover"
    )
}
