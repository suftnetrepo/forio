import Foundation
import SwiftData
import SwiftUI

// MARK: - Application Status (expanded pipeline)

enum ApplicationStatus: String, Codable, CaseIterable {
    case draft      = "Draft"
    case applied    = "Applied"
    case interview  = "Interview"
    case offer      = "Offer"
    case rejected   = "Rejected"
    case exported   = "Exported"
    case archived   = "Archived"

    var displayName: String { rawValue }

    var emoji: String {
        switch self {
        case .draft:     return "📝"
        case .applied:   return "📨"
        case .interview: return "🎤"
        case .offer:     return "🎉"
        case .rejected:  return "❌"
        case .exported:  return "📄"
        case .archived:  return "📦"
        }
    }

    var color: Color {
        switch self {
        case .draft:     return Color.gray
        case .applied:   return Color.blue
        case .interview: return Color.orange
        case .offer:     return Color.green
        case .rejected:  return Color.red
        case .exported:  return Color.purple
        case .archived:  return Color.gray
        }
    }

    var icon: String {
        switch self {
        case .draft:     return "doc.fill"
        case .applied:   return "paperplane.fill"
        case .interview: return "person.2.fill"
        case .offer:     return "checkmark.seal.fill"
        case .rejected:  return "xmark.circle.fill"
        case .exported:  return "arrow.down.circle.fill"
        case .archived:  return "archivebox.fill"
        }
    }

    // Pipeline statuses shown in tracker (excludes draft/exported/archived)
    static var pipelineStatuses: [ApplicationStatus] {
        [.applied, .interview, .offer, .rejected]
    }
}

// MARK: - JobApplication Model

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
    var jobURL: String?        // LinkedIn/Indeed URL if imported

    // Pipeline status
    var statusRaw: String

    // Salary extracted from JD
    var salaryMin: Double?
    var salaryMax: Double?
    var salaryCurrency: String = "GBP"

    // CV match score (before generation)
    var preMatchScore: Int?

    // ATS score (after generation)
    var atsScore: Int?

    // Interview date (when scheduled)
    var interviewDate: Date?

    // Notes
    var notes: String = ""

    // Share token for public CV link
    var shareToken: String?

    // Relationships
    @Relationship(deleteRule: .cascade) var document: GeneratedDocument?
    @Relationship(deleteRule: .cascade) var interviewSessions: [InterviewSession]?

    var status: ApplicationStatus {
        get { ApplicationStatus(rawValue: statusRaw) ?? .draft }
        set { statusRaw = newValue.rawValue; updatedAt = Date() }
    }

    init(jobTitle: String = "", company: String = "", jobDescription: String = "", jobSource: String = "pasted", jobURL: String? = nil) {
        self.id = UUID()
        self.createdAt = Date()
        self.updatedAt = Date()
        self.jobTitle = jobTitle
        self.company = company
        self.jobDescription = jobDescription
        self.jobSource = jobSource
        self.jobURL = jobURL
        self.statusRaw = ApplicationStatus.draft.rawValue
    }

    // MARK: Computed helpers

    var daysAgo: Int {
        Calendar.current.dateComponents([.day], from: createdAt, to: Date()).day ?? 0
    }

    var salaryDisplay: String {
        guard let min = salaryMin, let max = salaryMax else { return "" }
        let fmt = NumberFormatter()
        fmt.numberStyle = .currency
        fmt.currencyCode = salaryCurrency
        fmt.maximumFractionDigits = 0
        if let minS = fmt.string(from: NSNumber(value: min / 1000)),
           let maxS = fmt.string(from: NSNumber(value: max / 1000)) {
            return "\(minS)K – \(maxS)K"
        }
        return ""
    }

    func generateShareToken() -> String {
        if let existing = shareToken { return existing }
        let token = UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(12).lowercased()
        self.shareToken = String(token)
        return String(token)
    }
}
