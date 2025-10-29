import Foundation

// MARK: - Request Type
enum RequestType: String, CaseIterable {
    case coverSong = "cover_song"
    case generateSong = "generate_song"
    
    var displayName: String {
        switch self {
        case .coverSong:
            return "Cover Song"
        case .generateSong:
            return "Generate Song"
        }
    }
}

// MARK: - Cover Language
enum CoverLanguage: String, CaseIterable {
    case english = "english"
    case arabic = "arabic"
    case brazilianPortuguese = "brazilian portuguese"
    case chinese = "chinese"
    case dutch = "dutch"
    case french = "french"
    case hindi = "hindi"
    case hungarian = "hungarian"
    case italian = "italian"
    case japanese = "japanese"
    case korean = "korean"
    case polish = "polish"
    case russian = "russian"
    case turkish = "turkish"
    
    var displayName: String {
        switch self {
        case .english:
            return "English"
        case .arabic:
            return "Arabic"
        case .brazilianPortuguese:
            return "Brazilian Portuguese"
        case .chinese:
            return "Chinese"
        case .dutch:
            return "Dutch"
        case .french:
            return "French"
        case .hindi:
            return "Hindi"
        case .hungarian:
            return "Hungarian"
        case .italian:
            return "Italian"
        case .japanese:
            return "Japanese"
        case .korean:
            return "Korean"
        case .polish:
            return "Polish"
        case .russian:
            return "Russian"
        case .turkish:
            return "Turkish"
        }
    }
}

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
    case whimsical = "Whimsical"
    case depressive = "Depressive"
    case confident = "Confident"
    case nostalgic = "Nostalgic"
    case mysterious = "Mysterious"
    case playful = "Playful"
    case intense = "Intense"
    case dreamy = "Dreamy"
    case rebellious = "Rebellious"
    case hopeful = "Hopeful"
    case melancholic = "Melancholic"
    case productivity = "Productivity"
    case uplifting = "Uplifting"
    case hype = "Hype"
    case joyful = "Joyful"
    case dark = "Dark"
    case passionate = "Passionate"
    case spiritual = "Spiritual"
    case eclectic = "Eclectic"
    case emotion = "Emotion"
    case hard = "Hard"
    case lyrical = "Lyrical"
    case magical = "Magical"
    case minimal = "Minimal"
    case party = "Party"
    case weird = "Weird"
    
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
        case .whimsical:
            return "Playful and quirky"
        case .depressive:
            return "Dark and somber"
        case .confident:
            return "Bold and self-assured"
        case .nostalgic:
            return "Sentimental and wistful"
        case .mysterious:
            return "Enigmatic and intriguing"
        case .playful:
            return "Fun and lighthearted"
        case .intense:
            return "Powerful and dramatic"
        case .dreamy:
            return "Ethereal and otherworldly"
        case .rebellious:
            return "Defiant and non-conformist"
        case .hopeful:
            return "Optimistic and uplifting"
        case .melancholic:
            return "Pensive and reflective"
        case .productivity:
            return "Focused and driven"
        case .uplifting:
            return "Positive and inspiring"
        case .hype:
            return "Exciting and energetic"
        case .joyful:
            return "Happy and celebratory"
        case .dark:
            return "Mysterious and brooding"
        case .passionate:
            return "Intense and emotional"
        case .spiritual:
            return "Transcendent and meaningful"
        case .eclectic:
            return "Diverse and varied"
        case .emotion:
            return "Deeply emotional"
        case .hard:
            return "Tough and aggressive"
        case .lyrical:
            return "Poetic and expressive"
        case .magical:
            return "Enchanting and mystical"
        case .minimal:
            return "Simple and clean"
        case .party:
            return "Fun and celebratory"
        case .weird:
            return "Unconventional and quirky"
        }
    }
    
    static func getHottest() -> [SongMood] {
        return [.whimsical, .depressive, .confident, .happy, .chill, .motivational, .energetic, .romantic, .calm, .aggressive]
    }
    
    static func getIntroList() -> [SongMood] {
        return [.happy, .chill, .sad, .romantic]
    }
}

enum SongGenre: String, CaseIterable {
    case pop = "Pop"
    case pop_ballad = "Pop Ballad"
    case pop_rock = "Pop Rock"
    case synthpop = "Synthpop"
    case electropop = "Electropop"
    case indie_pop = "Indie Pop"
    case kpop = "K-Pop"
    case jpop = "J-Pop"
    case vpop = "V-Pop"
    case dance_pop = "Dance Pop"
    case dream_pop = "Dream Pop"
    case city_pop = "City Pop"

    // MARK: - ROCK
    case rock = "Rock"
    case soft_rock = "Soft Rock"
    case hard_rock = "Hard Rock"
    case alternative_rock = "Alternative Rock"
    case indie_rock = "Indie Rock"
    case punk_rock = "Punk Rock"
    case pop_punk = "Pop Punk"
    case classic_rock = "Classic Rock"
    case folk_rock = "Folk Rock"
    case country_rock = "Country Rock"
    case emo_rock = "Emo Rock"
    case grunge = "Grunge"

    // MARK: - EDM / ELECTRONIC
    case edm = "EDM"
    case electronic = "Electronic"
    case house = "House"
    case deep_house = "Deep House"
    case tropical_house = "Tropical House"
    case progressive_house = "Progressive House"
    case future_house = "Future House"
    case trance = "Trance"
    case techno = "Techno"
    case dubstep = "Dubstep"
    case melodic_dubstep = "Melodic Dubstep"
    case drum_and_bass = "Drum & Bass"
    case future_bass = "Future Bass"
    case chill_edm = "Chill EDM"
    case chillstep = "Chillstep"
    case synthwave = "Synthwave"
    case retrowave = "Retrowave"
    case lo_fi_edm = "Lo-Fi EDM"

    // MARK: - HIP-HOP / RAP
    case hiphop = "Hip-Hop"
    case rap = "Rap"
    case trap = "Trap"
    case boom_bap = "Boom Bap"
    case drill = "Drill"
    case melodic_rap = "Melodic Rap"
    case old_school_rap = "Old School Rap"
    case alternative_hiphop = "Alternative Hip-Hop"
    case lo_fi_hiphop = "Lo-Fi Hip-Hop"

    // MARK: - R&B / SOUL / FUNK
    case rnb = "R&B"
    case soul = "Soul"
    case neo_soul = "Neo-Soul"
    case funk = "Funk"
    case motown = "Motown"
    case gospel = "Gospel"

    // MARK: - BALLAD / ACOUSTIC / FOLK
    case ballad = "Ballad"
    case acoustic = "Acoustic"
    case acoustic_pop = "Acoustic Pop"
    case acoustic_folk = "Acoustic Folk"
    case indie_folk = "Indie Folk"
    case singer_songwriter = "Singer-Songwriter"
    case country = "Country"
    case country_pop = "Country Pop"
    case country_ballad = "Country Ballad"

    // MARK: - JAZZ / BLUES
    case jazz = "Jazz"
    case smooth_jazz = "Smooth Jazz"
    case blues = "Blues"
    case blues_rock = "Blues Rock"
    case soul_blues = "Soul Blues"

    // MARK: - CLASSICAL / CINEMATIC
    case classical = "Classical"
    case orchestral = "Orchestral"
    case cinematic = "Cinematic"
    case piano = "Piano"
    case modern_classical = "Modern Classical"
    case epic_trailer = "Epic Trailer"
    case ambient_soundtrack = "Ambient Soundtrack"

    // MARK: - LO-FI / CHILL / AMBIENT
    case lo_fi = "Lo-Fi"
    case chillhop = "Chillhop"
    case vaporwave = "Vaporwave"
    case ambient = "Ambient"
    case chillout = "Chillout"
    case lounge = "Lounge"
    case chill_vibes = "Chill Vibes"

    // MARK: - WORLD / LATIN / AFRO
    case latin_pop = "Latin Pop"
    case reggaeton = "Reggaeton"
    case afrobeat = "Afrobeat"
    case afrobeats = "Afrobeats"
    case amapiano = "Amapiano"
    case dancehall = "Dancehall"
    case bollywood_pop = "Bollywood Pop"
    case arabic_pop = "Arabic Pop"
    case chinese_pop = "Chinese Pop"

    // MARK: - EXPERIMENTAL / OTHER
    case hyperpop = "Hyperpop"
    case electro_swing = "Electro Swing"
    case industrial = "Industrial"
    case world_music = "World Music"
    case new_age = "New Age"
    
    var displayName: String {
        return self.rawValue
    }
    
    var icon: String {
        switch self {
        case .edm:
            return "icon_edm"
        case .hiphop:
            return "icon_hiphop"
        case .rap:
            return "icon_rap"
        default:
            return "icon_edm" // Default icon
        }
    }
    
    static func getHottest() -> [SongGenre] {
        return [
            .pop,              // nhạc đại chúng, dễ nghe nhất
            .pop_ballad,       // tình cảm, phổ biến toàn cầu
            .edm,              // nhạc điện tử sôi động
            .future_bass,      // EDM hiện đại, hợp AI gen nhạc
            .pop_rock,         // pha giữa pop và rock, trẻ trung
            .rnb,              // R&B tình cảm, hợp vocal nữ
            .hiphop,           // hip-hop đại chúng
            .kpop,             // K-Pop thịnh hành ở châu Á
            .acoustic_pop,     // pop mộc, kiểu Ed Sheeran
            .latin_pop         // Latin Pop, xu hướng dance global
        ]
    }
    
    static func getIntroList() -> [SongGenre] {
        return [.edm, .pop, .rap, .rock]
    }
}

enum SongTheme: String, CaseIterable {
    
    case love = "Love"
    case party = "Party"
    case feelTheEnergy = "Feel the Energy"
    case friendship = "Friendship"
    case dream = "Dream"
    case aspirations = "Aspirations"
    case dreamAndFreedom = "Dream and Freedom"
    
    case motivation = "Motivation"
    case intro = "Intro"
    
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
    
//    var description: String {
//        switch self {
//        case .myPet:
//            return "Songs about your beloved pet"
//        case .myLove:
//            return "Songs about love and relationships"
//        case .myFutureSelf:
//            return "Songs about your future aspirations"
//        case .myFamily:
//            return "Songs about family bonds"
//        case .myDreams:
//            return "Songs about dreams and aspirations"
//        case .myCity:
//            return "Songs about your hometown"
//        case .myWork:
//            return "Songs about work and career"
//        case .myHobbies:
//            return "Songs about your interests"
//        case .myMemories:
//            return "Songs about past memories"
//        case .myGoals:
//            return "Songs about your goals"
//        }
//    }
    
    static func getHottest() -> [SongTheme] {
        return [.love, .party, .friendship, .dream]
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
