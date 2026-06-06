import Foundation

enum CVTemplate: String, Codable, CaseIterable {
    case classicNavy    = "classicNavy"
    case cleanMinimal   = "cleanMinimal"
    case boldTwoColumn  = "boldTwoColumn"
    case executiveGold  = "executiveGold"
    case freshStart     = "freshStart"

    var displayName: String {
        switch self {
        case .classicNavy:   return "Classic Navy"
        case .cleanMinimal:  return "Clean Minimal"
        case .boldTwoColumn: return "Bold Two-Column"
        case .executiveGold: return "Executive Gold"
        case .freshStart:    return "Fresh Start"
        }
    }

    var industryHint: String {
        switch self {
        case .classicNavy:   return "Corporate, finance, law"
        case .cleanMinimal:  return "Any industry — safe choice"
        case .boldTwoColumn: return "Tech, design, creative"
        case .executiveGold: return "Senior, management, C-suite"
        case .freshStart:    return "Graduate, entry-level"
        }
    }

    var isPro: Bool {
        switch self {
        case .boldTwoColumn, .executiveGold: return true
        default: return false
        }
    }
}
