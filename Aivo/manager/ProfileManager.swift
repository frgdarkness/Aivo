
import Foundation
import SwiftUI

class ProfileManager: ObservableObject {
    static let shared = ProfileManager()
    
    // Legacy AppStorage (kept for backward compatibility, but Keychain is source of truth)
    @AppStorage("has_used_free_lyric_generation") var hasUsedFreeLyricGenerationLegacy: Bool = false
    
    // MARK: - Free Trial Flags (Keychain-backed, survive reinstall)
    
    /// Check if user has used free song generation trial
    var hasUsedFreeSongGeneration: Bool {
        KeychainManager.shared.getBool(forKey: KeychainManager.freeTrialSongKey)
    }
    
    /// Check if user has used free cover generation trial
    var hasUsedFreeCoverGeneration: Bool {
        KeychainManager.shared.getBool(forKey: KeychainManager.freeTrialCoverKey)
    }
    
    /// Check if user has used free lyric generation trial
    var hasUsedFreeLyricGeneration: Bool {
        KeychainManager.shared.getBool(forKey: KeychainManager.freeTrialLyricKey)
    }
    
    private init() {}
    
    // MARK: - Mark Free Trial as Used
    
    func markFreeSongGenerationUsed() {
        KeychainManager.shared.saveBool(true, forKey: KeychainManager.freeTrialSongKey)
        objectWillChange.send()
        Logger.d("ProfileManager: Free song generation trial marked as used")
    }
    
    func markFreeCoverGenerationUsed() {
        KeychainManager.shared.saveBool(true, forKey: KeychainManager.freeTrialCoverKey)
        objectWillChange.send()
        Logger.d("ProfileManager: Free cover generation trial marked as used")
    }
    
    func markFreeLyricGenerationUsed() {
        KeychainManager.shared.saveBool(true, forKey: KeychainManager.freeTrialLyricKey)
        objectWillChange.send()
        Logger.d("ProfileManager: Free lyric generation trial marked as used")
    }
    
    // Legacy setter (kept for backward compatibility)
    func setHasUsedFreeLyricGeneration(_ value: Bool) {
        hasUsedFreeLyricGenerationLegacy = value
        if value {
            markFreeLyricGenerationUsed()
        }
    }
}
