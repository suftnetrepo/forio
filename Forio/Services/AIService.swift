import Foundation
import UIKit

// MARK: - Response Models

struct ExtractedProfile: Codable {
    let fullName: String
    let email: String
    let phone: String
    let location: String
    let linkedIn: String
    let portfolio: String
    let professionalSummary: String
    let skills: [String]
    let experience: [WorkExperience]
    let education: [Education]
}

struct GeneratedCV: Codable {
    let cvContent: String
    let coverLetterContent: String
    let matchScore: Int
    let matchedKeywords: [String]
    let aiInsights: [String]
}

// MARK: - AIService

class AIService {
    static let shared = AIService()

    var apiKey: String {
        Bundle.main.infoDictionary?["OPENAI_API_KEY"] as? String ?? ""
    }

    private let endpoint = Constants.openAIEndpoint

    // MARK: - CV Extraction from images (scan path)

    func extractProfile(from images: [UIImage]) async throws -> ExtractedProfile {
        var imageContent: [[String: Any]] = []

        for image in images {
            guard let imageData = image.jpegData(compressionQuality: 0.7) else { continue }
            let base64 = imageData.base64EncodedString()
            imageContent.append([
                "type": "image_url",
                "image_url": ["url": "data:image/jpeg;base64,\(base64)"]
            ])
        }

        imageContent.append([
            "type": "text",
            "text": extractionPrompt
        ])

        return try await callOpenAI(content: imageContent, maxTokens: Constants.maxTokensExtract)
    }

    // MARK: - CV Extraction from plain text (paste/PDF path)

    func extractProfile(from text: String) async throws -> ExtractedProfile {
        let content: [[String: Any]] = [[
            "type": "text",
            "text": "Here is a CV as plain text. \(extractionPrompt)\n\nCV TEXT:\n\(text)"
        ]]

        return try await callOpenAI(content: content, maxTokens: Constants.maxTokensExtract)
    }

    // MARK: - CV Generation

    func generateCV(
        profile: UserProfile,
        jobDescription: String,
        template: CVTemplate
    ) async throws -> GeneratedCV {

        let prompt = PromptBuilder.build(
            profile: profile,
            jobDescription: jobDescription,
            template: template
        )

        let content: [[String: Any]] = [["type": "text", "text": prompt]]

        return try await callOpenAI(content: content, maxTokens: Constants.maxTokensGenerate)
    }

    // MARK: - Private helpers

    private func callOpenAI<T: Decodable>(content: [[String: Any]], maxTokens: Int) async throws -> T {
        let body: [String: Any] = [
            "model": Constants.openAIModel,
            "max_tokens": maxTokens,
            "messages": [["role": "user", "content": content]]
        ]

        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let choices = json?["choices"] as? [[String: Any]]
        let message = choices?.first?["message"] as? [String: Any]
        let rawContent = message?["content"] as? String ?? ""

        let cleaned = rawContent
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let jsonData = cleaned.data(using: .utf8) else {
            throw URLError(.cannotParseResponse)
        }

        return try JSONDecoder().decode(T.self, from: jsonData)
    }

    // MARK: - Extraction prompt

    private var extractionPrompt: String {
        """
        You are an expert CV reader. Extract all information from this CV carefully.
        Return ONLY a valid JSON object, no markdown, no extra text.
        
        Required format:
        {
          "fullName": "",
          "email": "",
          "phone": "",
          "location": "",
          "linkedIn": "",
          "portfolio": "",
          "professionalSummary": "",
          "skills": ["skill1", "skill2"],
          "experience": [
            {
              "id": "uuid-string",
              "jobTitle": "",
              "company": "",
              "startDate": "",
              "endDate": "",
              "isCurrent": false,
              "description": ""
            }
          ],
          "education": [
            {
              "id": "uuid-string",
              "degree": "",
              "institution": "",
              "graduationYear": "",
              "grade": ""
            }
          ]
        }
        
        Rules:
        - Extract ALL experience entries, most recent first
        - For current roles, set endDate to "Present" and isCurrent to true
        - Skills should be individual items, not sentences
        - If a field is not found, use an empty string
        - Generate a UUID string for each experience and education id
        - Return only valid JSON, nothing else
        """
    }
    // MARK: - Image resize (Claude limit: 1568px, 5MB)
    func resizeImageForClaude(_ image: UIImage, maxDimension: CGFloat = 1568) -> UIImage {
        let size = image.size
        guard size.width > maxDimension || size.height > maxDimension else { return image }
        let ratio = min(maxDimension / size.width, maxDimension / size.height)
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resized = UIGraphicsGetImageFromCurrentImageContext() ?? image
        UIGraphicsEndImageContext()
        return resized
    }

}