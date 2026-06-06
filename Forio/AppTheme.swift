import SwiftUI

// MARK: - Forio App Theme

enum AppTheme {

    // MARK: Brand Colours
    static let gold         = Color(hex: "C9A84C")
    static let goldLight    = Color(hex: "E8C96A")
    static let goldFaint    = Color(hex: "C9A84C").opacity(0.12)
    static let goldBorder   = Color(hex: "C9A84C").opacity(0.30)

    // MARK: Backgrounds
    static let bgPrimary    = Color(hex: "0A0A0F")   // deepest — app background
    static let bgCard       = Color(hex: "12111A")   // card surface
    static let bgElevated   = Color(hex: "1E1C2A")   // elevated / divider
    static let bgBorder     = Color(hex: "2A2838")   // border / outline

    // MARK: Text
    static let textPrimary  = Color(hex: "F0EEE8")
    static let textSecond   = Color(hex: "A09CB0")
    static let textMuted    = Color(hex: "6B6878")
    static let textDisabled = Color(hex: "4A4760")

    // MARK: Status
    static let success      = Color(hex: "5DB870")
    static let successFaint = Color(hex: "5DB870").opacity(0.12)
    static let danger       = Color(hex: "E24B4A")
    static let info         = Color(hex: "378ADD")

    // MARK: Persona accent colours
    static let graduate     = Color(hex: "C9A84C")   // gold
    static let experienced  = Color(hex: "378ADD")   // blue
    static let changer      = Color(hex: "1D9E75")   // teal
    static let returning    = Color(hex: "D4537E")   // pink

    // MARK: Corner radii
    static let radiusSm: CGFloat = 8
    static let radiusMd: CGFloat = 12
    static let radiusLg: CGFloat = 16
    static let radiusXl: CGFloat = 22

    // MARK: Typography helpers
    static func title(_ size: CGFloat = 26) -> Font {
        .system(size: size, weight: .medium)
    }
    static func body(_ size: CGFloat = 15) -> Font {
        .system(size: size, weight: .regular)
    }
    static func label(_ size: CGFloat = 12) -> Font {
        .system(size: size, weight: .medium)
    }
    static func caption(_ size: CGFloat = 11) -> Font {
        .system(size: size, weight: .regular)
    }
}

// MARK: - Reusable View Modifiers

struct ForioCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(AppTheme.bgCard)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                    .stroke(AppTheme.bgBorder, lineWidth: 0.5)
            )
    }
}

struct GoldButtonStyle: ButtonStyle {
    var isDisabled: Bool = false
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(Color(hex: "0A0A0F"))
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
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                    .stroke(AppTheme.bgBorder, lineWidth: 0.5)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

extension View {
    func forioCard() -> some View {
        modifier(ForioCardStyle())
    }
}
