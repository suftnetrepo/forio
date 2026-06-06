import Foundation
import UIKit

struct ExtractedJobDescription: Codable {
    let title: String
    let company: String
    let description: String
}

extension AIService {

    func extractJobDescription(from images: [UIImage]) async throws -> ExtractedJobDescription {
        guard !images.isEmpty else {
            throw NSError(domain: "Forio", code: 1,
                userInfo: [NSLocalizedDescriptionKey: "No images to process"])
        }
        guard !apiKey.isEmpty else {
            throw NSError(domain: "Forio", code: 2,
                userInfo: [NSLocalizedDescriptionKey: "API key not configured"])
        }

        var imageContent: [[String: Any]] = []
        for image in images {
            let resized = resizeImageForClaude(image)
            guard let data = resized.jpegData(compressionQuality: 0.8) else { continue }
            print("📷 Scan image: \(data.count / 1024)KB")
            imageContent.append([
                "type": "image",
                "source": ["type": "base64", "media_type": "image/jpeg",
                           "data": data.base64EncodedString()]
            ])
        }
        guard !imageContent.isEmpty else {
            throw NSError(domain: "Forio", code: 3,
                userInfo: [NSLocalizedDescriptionKey: "Could not process images"])
        }

        imageContent.append(["type": "text", "text": """
        Extract the job description from this image.
        Return ONLY valid JSON, no markdown:
        {"title":"job title","company":"company name","description":"full job description text"}
        Use empty string for any field not found.
        """])

        let body: [String: Any] = [
            "model": "claude-sonnet-4-6",
            "max_tokens": 2000,
            "messages": [["role": "user", "content": imageContent]]
        ]

        var req = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
        req.httpMethod = "POST"
        req.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        req.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.timeoutInterval = 60
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        print("📥 Claude scan status: \(http.statusCode)")

        guard http.statusCode == 200 else {
            let err = String(data: data, encoding: .utf8) ?? "unknown"
            print("❌ Claude scan error: \(err)")
            throw NSError(domain: "Forio", code: http.statusCode,
                userInfo: [NSLocalizedDescriptionKey: "API error \(http.statusCode)"])
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let rawText = (json?["content"] as? [[String: Any]])?
            .first(where: { $0["type"] as? String == "text" })?["text"] as? String ?? ""
        print("📝 Claude scan response: \(rawText.prefix(200))")

        let cleaned = rawText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if let jsonData = cleaned.data(using: .utf8),
           let result = try? JSONDecoder().decode(ExtractedJobDescription.self, from: jsonData) {
            return result
        }
        // Fallback — return raw text as description
        return ExtractedJobDescription(title: "", company: "", description: rawText)
    }
}
