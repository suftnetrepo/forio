import SwiftUI
import Combine

// MARK: - App Theme System
// 5 themes, persisted via @AppStorage("selectedTheme")

enum ThemeID: String, CaseIterable {
    case midnightGold   = "midnightGold"
    case arcticBlue     = "arcticBlue"
    case emeraldNight   = "emeraldNight"
    case roseQuartz     = "roseQuartz"
    case obsidianPurple = "obsidianPurple"

    var displayName: String {
        switch self {
        case .midnightGold:   return "Midnight Gold"
        case .arcticBlue:     return "Arctic Blue"
        case .emeraldNight:   return "Emerald Night"
        case .roseQuartz:     return "Rose Quartz"
        case .obsidianPurple: return "Obsidian Purple"
        }
    }

    var previewAccent: String {
        switch self {
        case .midnightGold:   return "C9A84C"
        case .arcticBlue:     return "3B9EFF"
        case .emeraldNight:   return "2ECC71"
        case .roseQuartz:     return "C9506E"
        case .obsidianPurple: return "8B5CF6"
        }
    }

    var previewBg: String {
        switch self {
        case .midnightGold:   return "0A0A0F"
        case .arcticBlue:     return "0D1B2A"
        case .emeraldNight:   return "0A0F0D"
        case .roseQuartz:     return "F9F5F6"
        case .obsidianPurple: return "0E0A1A"
        }
    }

    var isLight: Bool { self == .roseQuartz }
}

// MARK: - ThemeManager (Observable singleton)

class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    @AppStorage("selectedTheme") var themeID: String = ThemeID.midnightGold.rawValue {
        didSet { objectWillChange.send() }
    }
    var current: ThemeID { ThemeID(rawValue: themeID) ?? .midnightGold }
}

// MARK: - AppTheme (reads from ThemeManager)

enum AppTheme {

    // MARK: - Accent / brand colour

    static var gold: Color {
        switch ThemeManager.shared.current {
        case .midnightGold:   return Color(hex: "C9A84C")
        case .arcticBlue:     return Color(hex: "3B9EFF")
        case .emeraldNight:   return Color(hex: "2ECC71")
        case .roseQuartz:     return Color(hex: "C9506E")
        case .obsidianPurple: return Color(hex: "8B5CF6")
        }
    }
    static var goldLight: Color {
        switch ThemeManager.shared.current {
        case .midnightGold:   return Color(hex: "E8C96A")
        case .arcticBlue:     return Color(hex: "72BAFF")
        case .emeraldNight:   return Color(hex: "5DDEA0")
        case .roseQuartz:     return Color(hex: "E07090")
        case .obsidianPurple: return Color(hex: "A67CF8")
        }
    }
    static var goldFaint:  Color { gold.opacity(0.12) }
    static var goldBorder: Color { gold.opacity(0.30) }

    // MARK: - Backgrounds

    static var bgPrimary: Color {
        switch ThemeManager.shared.current {
        case .midnightGold:   return Color(hex: "0A0A0F")
        case .arcticBlue:     return Color(hex: "0D1B2A")
        case .emeraldNight:   return Color(hex: "0A0F0D")
        case .roseQuartz:     return Color(hex: "F9F5F6")
        case .obsidianPurple: return Color(hex: "0E0A1A")
        }
    }
    static var bgCard: Color {
        switch ThemeManager.shared.current {
        case .midnightGold:   return Color(hex: "12111A")
        case .arcticBlue:     return Color(hex: "132236")
        case .emeraldNight:   return Color(hex: "111A14")
        case .roseQuartz:     return Color(hex: "FFFFFF")
        case .obsidianPurple: return Color(hex: "160F28")
        }
    }
    static var bgElevated: Color {
        switch ThemeManager.shared.current {
        case .midnightGold:   return Color(hex: "1E1C2A")
        case .arcticBlue:     return Color(hex: "1A2E47")
        case .emeraldNight:   return Color(hex: "162B1E")
        case .roseQuartz:     return Color(hex: "F0E8EC")
        case .obsidianPurple: return Color(hex: "1E1538")
        }
    }
    static var bgBorder: Color {
        switch ThemeManager.shared.current {
        case .midnightGold:   return Color(hex: "2A2838")
        case .arcticBlue:     return Color(hex: "1E3A55")
        case .emeraldNight:   return Color(hex: "1E3828")
        case .roseQuartz:     return Color(hex: "E0CDD5")
        case .obsidianPurple: return Color(hex: "2A1E48")
        }
    }

    // MARK: - Text

    static var textPrimary: Color {
        switch ThemeManager.shared.current {
        case .roseQuartz: return Color(hex: "1A0810")
        default:          return Color(hex: "F0EEE8")
        }
    }
    static var textSecond: Color {
        switch ThemeManager.shared.current {
        case .midnightGold:   return Color(hex: "A09CB0")
        case .arcticBlue:     return Color(hex: "8AAEC8")
        case .emeraldNight:   return Color(hex: "7AAA8A")
        case .roseQuartz:     return Color(hex: "9B7A82")
        case .obsidianPurple: return Color(hex: "9B8AB8")
        }
    }
    static var textMuted: Color {
        switch ThemeManager.shared.current {
        case .midnightGold:   return Color(hex: "6B6878")
        case .arcticBlue:     return Color(hex: "5A7A94")
        case .emeraldNight:   return Color(hex: "4A7A5A")
        case .roseQuartz:     return Color(hex: "A08088")
        case .obsidianPurple: return Color(hex: "6A5A88")
        }
    }
    static var textDisabled: Color {
        switch ThemeManager.shared.current {
        case .roseQuartz: return Color(hex: "C0A8B0")
        default:          return Color(hex: "4A4760")
        }
    }

    // MARK: - Button foreground (dark on light theme, white on dark)

    static var buttonFg: Color {
        ThemeManager.shared.current.isLight ? Color(hex: "1A0810") : .white
    }

    // MARK: - Status

    static let success      = Color(hex: "5DB870")
    static let successFaint = Color(hex: "5DB870").opacity(0.12)
    static let danger       = Color(hex: "E24B4A")
    static var info: Color  { gold }

    // MARK: - Corner radii

    static let radiusSm: CGFloat = 8
    static let radiusMd: CGFloat = 12
    static let radiusLg: CGFloat = 16
    static let radiusXl: CGFloat = 22

    // MARK: - Typography helpers

    static func title(_ size: CGFloat = 26) -> Font { .system(size: size, weight: .medium) }
    static func body(_ size: CGFloat = 15) -> Font  { .system(size: size, weight: .regular) }
    static func label(_ size: CGFloat = 12) -> Font { .system(size: size, weight: .medium) }
    static func caption(_ size: CGFloat = 11) -> Font { .system(size: size, weight: .regular) }
}

// MARK: - Reusable View Modifiers

struct ForioCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(AppTheme.bgCard)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
            .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                .stroke(AppTheme.bgBorder, lineWidth: 0.5))
    }
}

struct GoldButtonStyle: ButtonStyle {
    var isDisabled: Bool = false
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(AppTheme.buttonFg)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(isDisabled ? AppTheme.gold.opacity(0.4) : AppTheme.gold)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct GhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(AppTheme.textSecond)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(AppTheme.bgElevated.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
            .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                .stroke(AppTheme.bgBorder, lineWidth: 0.5))
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

extension View {
    func forioCard() -> some View { modifier(ForioCardStyle()) }
}
