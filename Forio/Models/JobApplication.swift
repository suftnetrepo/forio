import Foundation
import SwiftData

enum ApplicationStatus: String, Codable {
    case draft    = "Draft"
    case exported = "Exported"
    case applied  = "Applied"
}

@Model
class JobApplication {
    var id: UUID
    var createdAt: Date
    var updatedAt: Date

    // Job details
    var jobTitle: String
    var company: String
    var jobDescription: String
    var jobSource: String      // "pasted", "scanned", "url"

    // Status
    var statusRaw: String

    // Relationship
    @Relationship(deleteRule: .cascade) var document: GeneratedDocument?

    var status: ApplicationStatus {
        get { ApplicationStatus(rawValue: statusRaw) ?? .draft }
        set { statusRaw = newValue.rawValue }
    }

    init(jobTitle: String = "", company: String = "", jobDescription: String = "", jobSource: String = "pasted") {
        self.id = UUID()
        self.createdAt = Date()
        self.updatedAt = Date()
        self.jobTitle = jobTitle
        self.company = company
        self.jobDescription = jobDescription
        self.jobSource = jobSource
        self.statusRaw = ApplicationStatus.draft.rawValue
    }
}
