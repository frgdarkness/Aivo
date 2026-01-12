import Foundation
import SwiftUI

// MARK: - Playlist Model
struct Playlist: Codable, Identifiable, Equatable {
    var id: String
    var name: String
    var description: String
    var coverImageData: Data?
    var coverColor: String? // Hex color
    var isCustomCover: Bool
    var isSystemPlaylist: Bool
    var systemIconName: String?
    var systemGradientColors: [String]? // Hex colors
    var createdAt: Int64
    var updatedAt: Int64
    var songIds: [String] // List of SunoData IDs
    
    // Initializer
    init(
        id: String = UUID().uuidString,
        name: String,
        description: String = "",
        coverImageData: Data? = nil,
        coverColor: String? = nil,
        isCustomCover: Bool = false,
        isSystemPlaylist: Bool = false,
        systemIconName: String? = nil,
        systemGradientColors: [String]? = nil,
        createdAt: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
        updatedAt: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
        songIds: [String] = []
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.coverImageData = coverImageData
        self.coverColor = coverColor
        self.isCustomCover = isCustomCover
        self.isSystemPlaylist = isSystemPlaylist
        self.systemIconName = systemIconName
        self.systemGradientColors = systemGradientColors
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.songIds = songIds
    }
    
    static func == (lhs: Playlist, rhs: Playlist) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Smart Playlist Type
enum SmartPlaylistType: String, CaseIterable, Identifiable {
    case favorites = "My Favorites"
    case recentlyAdded = "Recently Added"
    case recentlyPlayed = "Recently Played"
    case topTracks = "My Top Track"
    
    var id: String { rawValue }
    
    var iconName: String {
        switch self {
        case .favorites: return "heart.fill"
        case .recentlyAdded: return "plus.circle.fill"
        case .recentlyPlayed: return "clock.fill"
        case .topTracks: return "chart.bar.fill"
        }
    }
    
    var gradientColors: [Color] {
        switch self {
        case .favorites:
            return [Color(hex: 0xC2185B), Color(hex: 0x880E4F)]
        case .recentlyAdded:
            return [Color(hex: 0x0097A7), Color(hex: 0x006064)]
        case .recentlyPlayed:
            return [Color(hex: 0x5E35B1), Color(hex: 0x311B92)]
        case .topTracks:
            return [Color(hex: 0xD84315), Color(hex: 0xBF360C)]
        }
    }
}
