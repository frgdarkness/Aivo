import Foundation

// MARK: - Lyric Generation Configuration
struct LyricConfiguration: Codable, Equatable {
    var mode: LyricGenerationMode = .simple
    var prompt: String = ""
    var language: String = "English"
    var moods: [SongMood] = []
    var genres: [SongGenre] = []
    
    // Custom/Advance Options
    var length: LyricLength = .medium
    var perspective: LyricPerspective = .any
    var lyricCount: Int = 2
    
    // Advance Options
    var rhymeScheme: RhymeScheme = .simple
    var writingStyle: WritingStyle = .simpleDirect
    var avoid: Set<LyricAvoidance> = [] // Using Set for unique selections
    var structure: Set<SongStructurePart> = [.verse, .chorus]
    
    // Helper to get effective description for prompt
    var promptDescription: String {
        var desc = "Write lyrics in \(language). Topic: \(prompt)."
        
        if !moods.isEmpty {
            desc += " Mood: \(moods.map { $0.displayName }.joined(separator: ", "))."
        }
        if !genres.isEmpty {
            desc += " Genre: \(genres.map { $0.displayName }.joined(separator: ", "))."
        }
        
        if !structure.isEmpty {
            let parts = structure.sorted { $0.order < $1.order }.map { $0.rawValue }
            desc += " Structure: \(parts.joined(separator: ", "))."
        }
        
        if mode == .custom || mode == .advance {
            desc += " Length: \(length.rawValue)."
            if perspective != .any {
                desc += " Perspective: \(perspective.rawValue)."
            }
        }
        
        if mode == .advance {
            desc += " Style: \(writingStyle.rawValue). Rhyme Scheme: \(rhymeScheme.rawValue)."
            if !avoid.isEmpty {
                desc += " AVOID: \(avoid.map { $0.rawValue }.joined(separator: ", "))."
            }
        }
        
        desc += " Ensure the song ALWAYS has exactly 2 verses."
        desc += " ALL section headers (like [Verse 1], [Chorus], [Bridge]) MUST be enclosed in square brackets []."
        desc += " You MUST include a [Chorus] after [Verse 2] if a chorus is part of the structure."
        desc += " Follow this exact structure if unsure: [Verse 1], [Chorus], [Verse 2], [Chorus], [Outro]."
        
        return desc
    }
}

// MARK: - Enums
enum SongStructurePart: String, CaseIterable, Codable, Identifiable {
    var id: String { rawValue }
    
    case intro = "Intro"
    case verse = "Verse"
    case preChorus = "Pre-Chorus"
    case chorus = "Chorus"
    case bridge = "Bridge"
    case finalChorus = "Final Chorus"
    case outro = "Outro"
    
    var order: Int {
        switch self {
        case .intro: return 0
        case .verse: return 1
        case .preChorus: return 2
        case .chorus: return 3
        case .bridge: return 4
        case .finalChorus: return 5
        case .outro: return 6
        }
    }
}
enum LyricGenerationMode: String, CaseIterable, Codable {
    case simple = "Simple"
    case custom = "Custom"
    case advance = "Advance"
}

enum LyricLength: String, CaseIterable, Codable {
    case short = "Short"
    case medium = "Medium"
    case long = "Long"
}

enum LyricPerspective: String, CaseIterable, Codable {
    case any = "Any"
    case firstPerson = "First person (I/me)"
    case secondPerson = "Second person (You)"
    case thirdPerson = "Third person (He/She/They)"
}

enum RhymeScheme: String, CaseIterable, Codable {
    case simple = "Simple Scheme"
    case strong = "Strong Scheme"
    case freeVerse = "Free Verse"
}

enum WritingStyle: String, CaseIterable, Codable {
    case simpleDirect = "Simple & Direct"
    case poetic = "Poetic"
    case metaphorical = "Metaphorical"
    case storytelling = "Storytelling"
    case abstract = "Abstract"
}

enum LyricAvoidance: String, CaseIterable, Codable, Identifiable {
    var id: String { rawValue }
    
    case profanity = "Avoid Profanity"
    case sadEnding = "Avoid Sad Ending"
    case explicitContent = "Avoid Explicit Content"
    case clichePhrases = "Avoid Cliché Phrases"
}
