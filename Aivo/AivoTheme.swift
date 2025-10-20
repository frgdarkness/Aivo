//
//  AivoTheme.swift
//  Aivo
//
//  Created by Claude AI on 20/12/2024.
//

import SwiftUI

// MARK: - Aivo Theme System
struct AivoTheme {
    
    // MARK: - Primary Colors (Orange Theme)
    struct Primary {
        static let orange = Color(red: 1.0, green: 0.5, blue: 0.0)      // #FF8000 - Bright Orange
        static let orangeLight = Color(red: 1.0, green: 0.7, blue: 0.2) // #FFB333 - Light Orange
        static let orangeDark = Color(red: 0.9, green: 0.4, blue: 0.0)   // #E66600 - Dark Orange
        static let orangeAccent = Color(red: 1.0, green: 0.8, blue: 0.3) // #FFCC4D - Accent Orange
        static let orangeBright = Color(red: 1.0, green: 0.6, blue: 0.1) // #FF991A - Bright Orange
    }
    
    // MARK: - Background Colors
    struct Background {
        static let primary = Color.black
        static let secondary = Color(red: 0.05, green: 0.05, blue: 0.05) // Very dark gray
        static let card = Color(red: 0.1, green: 0.1, blue: 0.1)        // Dark card background
    }
    
    // MARK: - Text Colors
    struct Text {
        static let primary = Color.white
        static let secondary = Color(red: 0.8, green: 0.8, blue: 0.8)   // Light gray
        static let accent = Primary.orange
        static let muted = Color(red: 0.6, green: 0.6, blue: 0.6)      // Muted gray
    }
    
    // MARK: - Gradient Colors
    struct Gradient {
        static let topStart = Color(red: 1.0, green: 0.5, blue: 0.0, opacity: 0.6)  // Bright Orange with opacity
        static let topEnd = Color.clear
        static let bottomStart = Color.clear
        static let bottomEnd = Color(red: 1.0, green: 0.6, blue: 0.1, opacity: 0.5) // Bright Orange with opacity
        static let centerGlow = Color(red: 1.0, green: 0.5, blue: 0.0, opacity: 0.1) // Center orange glow
    }
    
    // MARK: - Button Colors
    struct Button {
        static let primary = Primary.orange
        static let primaryPressed = Primary.orangeDark
        static let secondary = Color.clear
        static let secondaryBorder = Primary.orange
        static let text = Color.white
    }
    
    // MARK: - Shadow Colors
    struct Shadow {
        static let orange = Color(red: 1.0, green: 0.6, blue: 0.2, opacity: 0.3)
        static let black = Color.black.opacity(0.5)
    }
}

// MARK: - Theme Environment
class AivoThemeManager: ObservableObject {
    static let shared = AivoThemeManager()
    
    @Published var currentTheme: AivoThemeType = .orange
    
    private init() {}
    
    func setTheme(_ theme: AivoThemeType) {
        currentTheme = theme
    }
}

enum AivoThemeType {
    case orange
    case dark
    case light
    
    var name: String {
        switch self {
        case .orange:
            return "Orange Theme"
        case .dark:
            return "Dark Theme"
        case .light:
            return "Light Theme"
        }
    }
}

// MARK: - Theme Extensions
extension Color {
    static let aivoOrange = AivoTheme.Primary.orange
    static let aivoOrangeLight = AivoTheme.Primary.orangeLight
    static let aivoOrangeDark = AivoTheme.Primary.orangeDark
    static let aivoBackground = AivoTheme.Background.primary
    static let aivoText = AivoTheme.Text.primary
}

// MARK: - Custom View Modifiers
struct AivoBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        ZStack {
            // Base black background
            AivoTheme.Background.primary
                .ignoresSafeArea()
            
            // Top gradient (diagonal from top-right)
            LinearGradient(
                gradient: Gradient(colors: [
                    AivoTheme.Gradient.topStart,
                    AivoTheme.Gradient.topEnd
                ]),
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )
            .ignoresSafeArea()
            
            // Bottom gradient (diagonal from bottom-left)
            LinearGradient(
                gradient: Gradient(colors: [
                    AivoTheme.Gradient.bottomStart,
                    AivoTheme.Gradient.bottomEnd
                ]),
                startPoint: .bottomLeading,
                endPoint: .topTrailing
            )
            .ignoresSafeArea()
            
            // Content
            content
        }
    }
}

struct AivoButtonStyle: ButtonStyle {
    var style: AivoButtonType = .primary
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(backgroundColor)
            .foregroundColor(textColor)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
    
    private var backgroundColor: Color {
        switch style {
        case .primary:
            return AivoTheme.Button.primary
        case .secondary:
            return AivoTheme.Button.secondary
        }
    }
    
    private var textColor: Color {
        switch style {
        case .primary:
            return AivoTheme.Button.text
        case .secondary:
            return AivoTheme.Button.secondaryBorder
        }
    }
    
    private var borderColor: Color {
        switch style {
        case .primary:
            return Color.clear
        case .secondary:
            return AivoTheme.Button.secondaryBorder
        }
    }
    
    private var borderWidth: CGFloat {
        switch style {
        case .primary:
            return 0
        case .secondary:
            return 1
        }
    }
}

enum AivoButtonType {
    case primary
    case secondary
}

// MARK: - View Extensions
extension View {
    func aivoBackground() -> some View {
        modifier(AivoBackgroundModifier())
    }
    
    func aivoButton(_ style: AivoButtonType = .primary) -> some View {
        buttonStyle(AivoButtonStyle(style: style))
    }
    
    func aivoText(_ style: AivoTextStyle = .primary) -> some View {
        foregroundColor(style.color)
            .font(style.font)
    }
}

enum AivoTextStyle {
    case primary
    case secondary
    case accent
    case muted
    case title
    case subtitle
    
    var color: Color {
        switch self {
        case .primary:
            return AivoTheme.Text.primary
        case .secondary:
            return AivoTheme.Text.secondary
        case .accent:
            return AivoTheme.Text.accent
        case .muted:
            return AivoTheme.Text.muted
        case .title:
            return AivoTheme.Text.primary
        case .subtitle:
            return AivoTheme.Text.secondary
        }
    }
    
    var font: Font {
        switch self {
        case .primary:
            return .body
        case .secondary:
            return .body
        case .accent:
            return .body.weight(.semibold)
        case .muted:
            return .caption
        case .title:
            return .largeTitle.weight(.bold)
        case .subtitle:
            return .title2.weight(.medium)
        }
    }
}
