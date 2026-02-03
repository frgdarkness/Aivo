
import Foundation
import SwiftUI

class ProfileManager: ObservableObject {
    static let shared = ProfileManager()
    
    @AppStorage("has_used_free_lyric_generation") var hasUsedFreeLyricGeneration: Bool = false
    
    private init() {}
    
    func setHasUsedFreeLyricGeneration(_ value: Bool) {
        hasUsedFreeLyricGeneration = value
    }
}
