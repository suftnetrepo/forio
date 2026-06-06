import Foundation
import SwiftData

// MARK: - Enums

enum UserPersona: String, Codable, CaseIterable {
    case graduate       = "graduate"
    case experienced    = "experienced"
    case careerChanger  = "careerChanger"
    case returning      = "returning"

    var displayName: String {
        switch self {
        case .graduate:      return "Just graduated"
        case .experienced:   return "Working, want a new job"
        case .careerChanger: return "Changing careers"
        case .returning:     return "Gap / returning to work"
        }
    }

    var emoji: String {
        switch self {
        case .graduate:      return "🎓"
        case .experienced:   return "💼"
        case .careerChanger: return "🔄"
        case .returning:     return "⏸️"
        }
    }

    var defaultTemplate: CVTemplate {
        switch self {
        case .graduate:      return .freshStart
        case .experienced:   return .classicNavy
        case .careerChanger: return .boldTwoColumn
        case .returning:     return .cleanMinimal
        }
    }
}

enum GapReason: String, Codable, CaseIterable {
    case family     = "Family / caring responsibilities"
    case health     = "Health reasons"
    case studying   = "Studying / upskilling"
    case travel     = "Travel / personal"
    case other      = "Other"
}

// MARK: - Supporting Structs (stored as JSON strings in SwiftData)

struct WorkExperience: Codable, Identifiable {
    var id: UUID = UUID()
    var jobTitle: String
    var company: String
    var startDate: String
    var endDate: String        // "Present" if current
    var isCurrent: Bool
    var description: String
}

struct Education: Codable, Identifiable {
    var id: UUID = UUID()
    var degree: String
    var institution: String
    var graduationYear: String
    var grade: String          // e.g. "2:1", "First", "Merit"
}

// MARK: - UserProfile Model

@Model
class UserProfile {
    var id: UUID
    var createdAt: Date
    var updatedAt: Date

    // Core
    var fullName: String
    var email: String
    var phone: String
    var location: String
    var linkedIn: String
    var portfolio: String
    var professionalSummary: String

    // Persona
    var personaRaw: String
    var fromField: String      // career changer: moving from
    var toField: String        // career changer: moving into
    var gapReasonRaw: String   // returning: reason for gap

    // Serialised arrays (JSON strings)
    var experienceJSON: String
    var educationJSON: String
    var skillsJSON: String     // [String]

    // Onboarding state
    var importedFromCV: Bool
    var onboardingComplete: Bool

    // MARK: Computed

    var persona: UserPersona {
        get { UserPersona(rawValue: personaRaw) ?? .graduate }
        set { personaRaw = newValue.rawValue }
    }

    var gapReason: GapReason? {
        get { GapReason(rawValue: gapReasonRaw) }
        set { gapReasonRaw = newValue?.rawValue ?? "" }
    }

    var experience: [WorkExperience] {
        get { (try? JSONDecoder().decode([WorkExperience].self, from: Data(experienceJSON.utf8))) ?? [] }
        set { experienceJSON = (try? String(data: JSONEncoder().encode(newValue), encoding: .utf8)) ?? "[]" }
    }

    var education: [Education] {
        get { (try? JSONDecoder().decode([Education].self, from: Data(educationJSON.utf8))) ?? [] }
        set { educationJSON = (try? String(data: JSONEncoder().encode(newValue), encoding: .utf8)) ?? "[]" }
    }

    var skills: [String] {
        get { (try? JSONDecoder().decode([String].self, from: Data(skillsJSON.utf8))) ?? [] }
        set { skillsJSON = (try? String(data: JSONEncoder().encode(newValue), encoding: .utf8)) ?? "[]" }
    }

    // MARK: Init

    init(
        fullName: String = "",
        email: String = "",
        phone: String = "",
        location: String = "",
        linkedIn: String = "",
        portfolio: String = "",
        professionalSummary: String = "",
        persona: UserPersona = .graduate
    ) {
        self.id = UUID()
        self.createdAt = Date()
        self.updatedAt = Date()
        self.fullName = fullName
        self.email = email
        self.phone = phone
        self.location = location
        self.linkedIn = linkedIn
        self.portfolio = portfolio
        self.professionalSummary = professionalSummary
        self.personaRaw = persona.rawValue
        self.fromField = ""
        self.toField = ""
        self.gapReasonRaw = ""
        self.experienceJSON = "[]"
        self.educationJSON = "[]"
        self.skillsJSON = "[]"
        self.importedFromCV = false
        self.onboardingComplete = false
    }
}
