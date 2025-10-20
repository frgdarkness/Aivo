//
//  LanguageData.swift
//  DreamHomeAI
//
//  Created by AI Assistant on 2025-01-01.
//

import Foundation

struct LanguageData: Identifiable {
    let id = UUID()
    let name: String
    let flagEmoji: String
    let code: String
    
    init(name: String, flagEmoji: String, code: String) {
        self.name = name
        self.flagEmoji = flagEmoji
        self.code = code
    }
}

// MARK: - Static Data
extension LanguageData {
    static let supportedLanguages: [LanguageData] = [
        LanguageData(name: "English (US)", flagEmoji: "🇺🇸", code: "en"),        // hoặc "en-US"
        LanguageData(name: "English (UK)", flagEmoji: "🇬🇧", code: "en-GB"),
        LanguageData(name: "French", flagEmoji: "🇫🇷", code: "fr"),
        LanguageData(name: "German", flagEmoji: "🇩🇪", code: "de"),
        LanguageData(name: "Japanese", flagEmoji: "🇯🇵", code: "ja"),
        LanguageData(name: "Korean", flagEmoji: "🇰🇷", code: "ko"),
        LanguageData(name: "Portuguese", flagEmoji: "🇵🇹", code: "pt-PT"),       // hoặc "pt"
        LanguageData(name: "Spanish", flagEmoji: "🇪🇸", code: "es"),
        LanguageData(name: "Arabic", flagEmoji: "🇸🇦", code: "ar"),
        LanguageData(name: "Chinese (Simplified)", flagEmoji: "🇨🇳", code: "zh-Hans"),
        LanguageData(name: "Hindi", flagEmoji: "🇮🇳", code: "hi"),
        LanguageData(name: "Vietnamese", flagEmoji: "🇻🇳", code: "vi"),
        LanguageData(name: "Mexican Spanish", flagEmoji: "🇲🇽", code: "es-MX")
    ]
}
