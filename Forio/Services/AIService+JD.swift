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
                userInfo: [NSLocalizedDescriptionKey: "No images provided"])
        }

        var contentParts: [[String: Any]] = []

        for image in images {
            let resized = resizeImageForClaude(image, maxDimension: 1568)
            guard let data = resized.jpegData(compressionQuality: 0.9) else { continue }
            print("📷 JD scan: \(data.count / 1024)KB")
            contentParts.append([
                "type": "image_url",
                "image_url": [
                    "url": "data:image/jpeg;base64,\(data.base64EncodedString())",
                    "detail": "high"
                ]
            ])
        }

        contentParts.append([
            "type": "text",
            "text": """
            Extract the job description from this image.
            Return ONLY valid JSON, no markdown, no explanation:
            {
              "title": "job title",
              "company": "company name",
              "description": "ALL text from the job posting"
            }
            Use empty string for any field not visible. Put everything readable in description.
            """
        ])

        let result: ExtractedJobDescription = try await callGPT(
            messages: [["role": "user", "content": contentParts]],
            maxTokens: 2000
        )
        return result
    }
}
