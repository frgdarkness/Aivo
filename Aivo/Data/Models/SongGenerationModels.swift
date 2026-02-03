import Foundation

// MARK: - Generation Mode
enum GenerationMode: String, CaseIterable {
    case simple = "Simple"
    case custom = "Custom"
    case advanced = "Advance"
    
    var cost: Int {
        switch self {
        case .simple: return 40
        case .custom: return 50
        case .advanced: return 60
        }
    }
}

// MARK: - Vocal Options
enum VocalIntensity: String, CaseIterable {
    case soft = "Soft"
    case gentle = "Gentle"
    case warm = "Warm"
    case balanced = "Balanced"
    case powerful = "Powerful"
    case strong = "Strong"
    case aggressive = "Aggressive"
    case random = "Random"
}

enum VocalTexture: String, CaseIterable {
    case clean = "Clean"
    case breathy = "Breathy"
    case airy = "Airy"
    case smooth = "Smooth"
    case raw = "Raw"
    case gritty = "Gritty"
    case raspy = "Raspy"
    case random = "Random"
}

// MARK: - Advanced Options
enum SongTempo: String, CaseIterable {
    case verySlow = "Very Slow"
    case slow = "Slow"
    case medium = "Medium"
    case fast = "Fast"
    case veryFast = "Very Fast"
}

enum ProductionStyle: String, CaseIterable {
    case studioClean = "Studio Clean"
    case livePerformance = "Live Performance"
    case loFi = "Lo-Fi"
    case cinematic = "Cinematic"
    case minimal = "Minimal"
    case electronic = "Electronic"
    case acoustic = "Acoustic"
}

enum MixPriority: String, CaseIterable {
    case vocalForward = "Vocal-Forward"
    case balanced = "Balanced"
    case instrumentFocused = "Instrument-Focused"
    case bassHeavy = "Bass-Heavy"
    case atmospheric = "Atmospheric"
}
