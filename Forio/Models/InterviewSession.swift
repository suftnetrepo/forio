import Foundation
import SwiftData
import SwiftUI

@Model
class InterviewSession {
    var id: UUID = UUID()
    var createdAt: Date = Date()
    var jobTitle: String = ""
    var company: String = ""
    var questions: [InterviewQuestion] = []
    var promptVersion: Int = 2

    init(jobTitle: String, company: String) {
        self.jobTitle = jobTitle
        self.company = company
    }
}

struct InterviewQuestion: Codable, Identifiable {
    var id: UUID = UUID()
    var text: String
    var category: String
    var difficulty: String
    var suggestedAnswer: String
    var liveCodingAdvice: String
    var order: Int

    // Custom Codable implementation — makes all fields optional during decode
    // so old cached questions without liveCodingAdvice don't crash
    enum CodingKeys: String, CodingKey {
        case id, text, category, difficulty, suggestedAnswer, liveCodingAdvice, order
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id                = (try? c.decode(UUID.self,   forKey: .id))              ?? UUID()
        text              = (try? c.decode(String.self, forKey: .text))            ?? ""
        category          = (try? c.decode(String.self, forKey: .category))        ?? "behavioral"
        difficulty        = (try? c.decode(String.self, forKey: .difficulty))      ?? "medium"
        suggestedAnswer   = (try? c.decode(String.self, forKey: .suggestedAnswer)) ?? ""
        liveCodingAdvice  = (try? c.decode(String.self, forKey: .liveCodingAdvice)) ?? ""
        order             = (try? c.decode(Int.self,    forKey: .order))            ?? 0
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id,               forKey: .id)
        try c.encode(text,             forKey: .text)
        try c.encode(category,         forKey: .category)
        try c.encode(difficulty,       forKey: .difficulty)
        try c.encode(suggestedAnswer,  forKey: .suggestedAnswer)
        try c.encode(liveCodingAdvice, forKey: .liveCodingAdvice)
        try c.encode(order,            forKey: .order)
    }

    init(text: String, category: String, difficulty: String,
         suggestedAnswer: String, liveCodingAdvice: String = "", order: Int) {
        self.text             = text
        self.category         = category
        self.difficulty       = difficulty
        self.suggestedAnswer  = suggestedAnswer
        self.liveCodingAdvice = liveCodingAdvice
        self.order            = order
    }

    var isLiveCoding: Bool {
        category == "live_coding" || (!liveCodingAdvice.isEmpty && category == "technical")
    }

    var categoryEmoji: String {
        switch category {
        case "behavioral":  return "👥"
        case "technical":   return "💻"
        case "situational": return "🎯"
        case "live_coding": return "⌨️"
        default:            return "❓"
        }
    }

    var categoryLabel: String {
        category == "live_coding" ? "Live Coding" : category.capitalized
    }

    var difficultyColor: Color {
        switch difficulty {
        case "easy":   return .green
        case "medium": return .orange
        case "hard":   return .red
        default:       return .gray
        }
    }
}
