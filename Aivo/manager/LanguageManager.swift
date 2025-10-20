import SwiftUI
import Combine

/// Key lưu trong UserDefaults
private let kAppLanguageKey = "appLanguage"

final class LanguageManager: ObservableObject {
    static let shared = LanguageManager()

    /// Mã ngôn ngữ hiện tại (ví dụ: "en", "vi", "fr", "pt-BR", "es-MX")
    @Published private(set) var code: String

    /// Locale sử dụng để bơm vào SwiftUI .environment(\.locale, ...)
    var locale: Locale { Locale(identifier: code) }
    
    /// Current language data for compatibility
    var currentLanguageData: LanguageData {
        return LanguageData.supportedLanguages.first { $0.code == code } ?? LanguageData.supportedLanguages[0]
    }

    private init() {
        // Ưu tiên giá trị đã lưu; fallback theo hệ thống
        let saved = UserDefaults.standard.string(forKey: kAppLanguageKey)
        self.code = LanguageManager.canonicalCode(saved ?? Locale.preferredLanguages.first ?? "en")
    }

    /// Đổi ngôn ngữ và phát sự kiện tới toàn app
    func setLanguage(code newCode: String) {
        Logger.d("setLanguage: \(newCode)")
        let canonical = LanguageManager.canonicalCode(newCode)
        guard canonical != code else { return }
        Logger.d("canonical: \(canonical)")
        code = canonical
        UserDefaults.standard.set(canonical, forKey: kAppLanguageKey)
        UserDefaults.standard.synchronize()
        
        // Tùy trường hợp muốn ép refresh layout mạnh hơn:
        objectWillChange.send()
        
        // Gửi notification để các view khác có thể listen
        NotificationCenter.default.post(name: Notification.Name("LanguageChanged"), object: nil)
    }

    /// Chuẩn hoá mã ngôn ngữ sang định danh iOS chấp nhận tốt
    private static func canonicalCode(_ raw: String) -> String {
        // Normalize một số case thường gặp
        switch raw.lowercased() {
        case "pt", "pt-pt": return "pt-PT"      // Bồ Đào Nha
        case "pt-br":       return "pt-BR"      // Brazil
        case "zh", "zh-hans": return "zh-Hans"  // Trung giản thể
        case "zh-hant":       return "zh-Hant"  // Trung phồn thể
        case "en-gb":       return "en-GB"
        case "en-us":       return "en-US"
        case "es-mx":       return "es-MX"
        default:
            // Trả về dạng "language[-REGION]" viết hoa vùng
            var parts = raw.split(separator: "-").map(String.init)
            if parts.count == 2 { parts[1] = parts[1].uppercased() }
            return parts.joined(separator: parts.count == 2 ? "-" : "")
        }
    }
}

// MARK: - String Extension for Easy Localization
extension String {
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
    
    func localized(with arguments: CVarArg...) -> String {
        return String(format: NSLocalizedString(self, comment: ""), arguments: arguments)
    }
    
    /// Localized string using LanguageManager's current locale
    var localizedWithCurrentLanguage: String {
        let languageCode = LanguageManager.shared.code
        guard let path = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return NSLocalizedString(self, comment: "")
        }
        return bundle.localizedString(forKey: self, value: nil, table: nil)
    }
}
