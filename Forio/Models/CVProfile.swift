import Foundation
import SwiftData

// MARK: - CVProfile
// A saved CV — user can have multiple (React CV, .NET CV, Mobile CV etc.)

@Model
class CVProfile {
    var id: UUID
    var createdAt: Date
    var updatedAt: Date

    // Profile name — user sets this (e.g. "React CV", ".NET CV")
    var name: String

    // All the same fields as UserProfile
    var fullName: String
    var email: String
    var phone: String
    var location: String
    var linkedIn: String
    var portfolio: String
    var professionalSummary: String

    // Serialised JSON
    var experienceJSON: String
    var educationJSON: String
    var skillsJSON: String

    // Which persona this CV is for
    var personaRaw: String

    var persona: UserPersona {
        get { UserPersona(rawValue: personaRaw) ?? .experienced }
        set { personaRaw = newValue.rawValue }
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

    // Summary display for picker
    var summaryLine: String {
        let roleCount = experience.count
        let skillCount = skills.count
        return "\(roleCount) roles · \(skillCount) skills"
    }

    init(name: String = "My CV", persona: UserPersona = .experienced) {
        self.id              = UUID()
        self.createdAt       = Date()
        self.updatedAt       = Date()
        self.name            = name
        self.fullName        = ""
        self.email           = ""
        self.phone           = ""
        self.location        = ""
        self.linkedIn        = ""
        self.portfolio       = ""
        self.professionalSummary = ""
        self.experienceJSON  = "[]"
        self.educationJSON   = "[]"
        self.skillsJSON      = "[]"
        self.personaRaw      = persona.rawValue
    }

    // MARK: - Build from extracted profile

    static func from(extracted: ExtractedProfile, name: String, persona: UserPersona) -> CVProfile {
        let p = CVProfile(name: name, persona: persona)
        p.fullName            = extracted.fullName
        p.email               = extracted.email
        p.phone               = extracted.phone
        p.location            = extracted.location
        p.linkedIn            = extracted.linkedIn
        p.portfolio           = extracted.portfolio
        p.professionalSummary = extracted.professionalSummary
        p.experience          = extracted.experience
        p.education           = extracted.education
        p.skills              = extracted.skills
        return p
    }

    // MARK: - Build from UserProfile (migrate existing profile)

    static func from(userProfile: UserProfile, name: String = "My CV") -> CVProfile {
        let p = CVProfile(name: name, persona: userProfile.persona)
        p.fullName            = userProfile.fullName
        p.email               = userProfile.email
        p.phone               = userProfile.phone
        p.location            = userProfile.location
        p.linkedIn            = userProfile.linkedIn
        p.portfolio           = userProfile.portfolio
        p.professionalSummary = userProfile.professionalSummary
        p.experience          = userProfile.experience
        p.education           = userProfile.education
        p.skills              = userProfile.skills
        return p
    }
}
