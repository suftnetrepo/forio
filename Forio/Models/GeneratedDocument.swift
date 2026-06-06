import Foundation
import SwiftData

@Model
class GeneratedDocument {
    var id: UUID
    var createdAt: Date
    var updatedAt: Date

    // Generated content
    var cvContent: String
    var coverLetterContent: String

    // Template
    var templateRaw: String

    // Match analysis
    var matchScore: Int          // 0-100
    var matchedKeywordsJSON: String   // [String]
    var aiInsightsJSON: String        // [String]

    // Edit tracking
    var isEdited: Bool
    var editedCVContent: String       // user-edited version, empty = use cvContent

    var template: CVTemplate {
        get { CVTemplate(rawValue: templateRaw) ?? .cleanMinimal }
        set { templateRaw = newValue.rawValue }
    }

    var matchedKeywords: [String] {
        get { (try? JSONDecoder().decode([String].self, from: Data(matchedKeywordsJSON.utf8))) ?? [] }
        set { matchedKeywordsJSON = (try? String(data: JSONEncoder().encode(newValue), encoding: .utf8)) ?? "[]" }
    }

    var aiInsights: [String] {
        get { (try? JSONDecoder().decode([String].self, from: Data(aiInsightsJSON.utf8))) ?? [] }
        set { aiInsightsJSON = (try? String(data: JSONEncoder().encode(newValue), encoding: .utf8)) ?? "[]" }
    }

    var displayCV: String {
        isEdited && !editedCVContent.isEmpty ? editedCVContent : cvContent
    }

    init(cvContent: String = "", coverLetterContent: String = "", template: CVTemplate = .cleanMinimal) {
        self.id = UUID()
        self.createdAt = Date()
        self.updatedAt = Date()
        self.cvContent = cvContent
        self.coverLetterContent = coverLetterContent
        self.templateRaw = template.rawValue
        self.matchScore = 0
        self.matchedKeywordsJSON = "[]"
        self.aiInsightsJSON = "[]"
        self.isEdited = false
        self.editedCVContent = ""
    }
}
