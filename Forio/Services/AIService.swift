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

// MARK: - AIService (GPT-5.5)

class AIService {
    static let shared = AIService()

    var apiKey: String {
        Bundle.main.infoDictionary?["OPENAI_API_KEY"] as? String ?? ""
    }

    private let endpoint = "https://api.openai.com/v1/chat/completions"
    private let model    = "gpt-5.4"

    // MARK: - CV Extraction from images

    func extractProfile(from images: [UIImage]) async throws -> ExtractedProfile {
        var contentParts: [[String: Any]] = []

        for image in images {
            let resized = resizeImageForClaude(image)
            guard let data = resized.jpegData(compressionQuality: 0.9) else { continue }
            print("📷 CV image: \(data.count / 1024)KB")
            contentParts.append([
                "type": "image_url",
                "image_url": [
                    "url": "data:image/jpeg;base64,\(data.base64EncodedString())",
                    "detail": "high"
                ]
            ])
        }

        contentParts.append(["type": "text", "text": extractionPrompt])

        return try await callGPT(messages: [
            ["role": "user", "content": contentParts]
        ], maxTokens: 2000)
    }

    // MARK: - CV Extraction from text

    func extractProfile(from text: String) async throws -> ExtractedProfile {
        return try await callGPT(messages: [
            ["role": "user", "content": "Here is a CV as plain text.\n\n\(extractionPrompt)\n\nCV TEXT:\n\(text)"]
        ], maxTokens: 2000)
    }

    // MARK: - CV Generation

    func generateCV(profile: UserProfile, jobDescription: String, template: CVTemplate) async throws -> GeneratedCV {
        let prompt = PromptBuilder.build(profile: profile, jobDescription: jobDescription, template: template)
        return try await callGPT(messages: [
            ["role": "user", "content": prompt]
        ], maxTokens: 4000)
    }

    // MARK: - Core GPT-5.5 API call

    func callGPT<T: Decodable>(messages: [[String: Any]], maxTokens: Int) async throws -> T {
        guard !apiKey.isEmpty else {
            throw NSError(domain: "Forio", code: 1,
                userInfo: [NSLocalizedDescriptionKey: "OpenAI API key not configured"])
        }

        let body: [String: Any] = [
            "model":      model,
            "max_completion_tokens": maxTokens,
            "messages":   messages
        ]

        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json",  forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 120
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        print("📤 Sending to GPT-5.5...")
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        print("📥 GPT-5.5 status: \(http.statusCode)")

        guard http.statusCode == 200 else {
            let err = String(data: data, encoding: .utf8) ?? "unknown"
            print("❌ GPT-5.5 error: \(err)")
            throw NSError(domain: "Forio", code: http.statusCode,
                userInfo: [NSLocalizedDescriptionKey: "GPT-5.5 error \(http.statusCode)"])
        }

        // Log full raw response for debugging
        let fullResponse = String(data: data, encoding: .utf8) ?? "no data"
        print("📦 Full GPT response: \(fullResponse.prefix(1000))")

        // GPT response: { "choices": [{ "message": { "content": "..." } }] }
        let json    = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let choices = json?["choices"] as? [[String: Any]]
        let message = choices?.first?["message"] as? [String: Any]

        // Handle both content string and refusal
        var rawText = message?["content"] as? String ?? ""

        // GPT-5.5 may use refusal field instead of content
        if rawText.isEmpty, let refusal = message?["refusal"] as? String {
            print("⚠️ GPT refusal: \(refusal)")
        }

        // Try alternate response structures
        if rawText.isEmpty {
            rawText = (json?["choices"] as? [[String: Any]])?
                .first?["text"] as? String ?? ""
        }

        print("📝 GPT-5.5 content: \(rawText.prefix(300))")

        let cleaned = rawText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```",     with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let jsonData = cleaned.data(using: .utf8) else {
            throw NSError(domain: "Forio", code: 422,
                userInfo: [NSLocalizedDescriptionKey: "Could not encode response text"])
        }

        do {
            return try JSONDecoder().decode(T.self, from: jsonData)
        } catch {
            print("❌ JSON decode error: \(error)")
            print("❌ Raw text was: \(cleaned.prefix(500))")
            // Try to extract JSON object from within the text
            if let start = cleaned.firstIndex(of: "{"),
               let end = cleaned.lastIndex(of: "}") {
                let extracted = String(cleaned[start...end])
                if let extractedData = extracted.data(using: .utf8) {
                    return try JSONDecoder().decode(T.self, from: extractedData)
                }
            }
            throw NSError(domain: "Forio", code: 422,
                userInfo: [NSLocalizedDescriptionKey: "AI returned unexpected format. Please try again."])
        }
    }

    // MARK: - Image resize helper

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

    // MARK: - Extraction prompt

    private var extractionPrompt: String {
        """
        You are an expert CV reader. Extract all information from this CV.
        CRITICAL: Return ONLY raw JSON. No markdown. No ```json. No explanation. No text before or after.
        Start your response with { and end with }. Nothing else.

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
        - Copy dates exactly as written in the CV
        - Copy all achievements and numbers exactly — do not paraphrase
        - For current roles set endDate to "Present" and isCurrent to true
        - Generate a UUID string for each id field
        - Return only valid JSON, nothing else
        """
    }
}
