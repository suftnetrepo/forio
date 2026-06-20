import Foundation
import UIKit

// MARK: - All New AI Features for Forio

extension AIService {

    // MARK: 1. CV Match Score (before generation)

    struct MatchResult: Codable {
        let score: Int
        let matchedKeywords: [String]
        let insights: [String]
    }

    func calculateMatchScore(cvContent: String, jobDescription: String) async throws -> MatchResult {
        let prompt = """
        Analyse how well this CV matches this job description.

        Return ONLY valid JSON – no markdown, no explanation:
        {
          "score": 67,
          "matchedKeywords": ["Swift", "iOS", "SwiftUI"],
          "insights": [
            "Add more mentions of UIKit to match the JD",
            "Highlight your team leadership experience",
            "Include specific metrics from your projects"
          ]
        }

        Score 0-100 based on: skill alignment, experience relevance, keyword match, education fit.
        Provide exactly 3 insights – short, actionable, specific to the gap.

        CV:
        \(cvContent.prefix(3000))

        JOB DESCRIPTION:
        \(jobDescription.prefix(2000))
        """
        return try await callGPT(messages: [["role": "user", "content": prompt]], maxTokens: 800)
    }

    // MARK: 2. Interview Question Generation

    struct InterviewQuestionsResult: Codable {
        let questions: [InterviewQuestionData]
    }

    struct InterviewQuestionData: Codable {
        let text: String
        let category: String
        let difficulty: String
        let suggestedAnswer: String
        let liveCodingAdvice: String
        let order: Int
    }

    func generateInterviewQuestions(jobDescription: String, cvContent: String, count: Int = 20) async throws -> [InterviewQuestion] {
        let prompt = """
        Generate \(count) interview questions for this specific role. Use the job description and CV to make everything highly personalised.

        QUESTION MIX:
        - 8 behavioral questions (past experience, teamwork, challenges)
        - 7 technical questions (specific to the tech stack in the JD)
        - 3 situational questions (hypothetical scenarios)
        - 2 live_coding questions (only if the role involves coding — algorithm, data structure, or system design)

        FOR ALL QUESTIONS — "suggestedAnswer" rules:
        - Write a FULL, COMPLETE, READY-TO-SPEAK answer in FIRST PERSON
        - Reference actual companies, projects, technologies from the candidate CV
        - 3-5 sentences — a real spoken answer as if the candidate is saying it
        - NEVER write "Use STAR method" or any meta-coaching — write the actual answer words
        - Sound natural and confident

        BAD suggestedAnswer: "Use STAR to describe a situation."
        GOOD suggestedAnswer: "At PlasmPro I led the migration to Expo SDK 50. I handled the module compatibility issues myself across two sprints and we shipped on time, cutting CI build time by 40%."

        FOR live_coding QUESTIONS ONLY — also fill "liveCodingAdvice":
        - Practical tips for coding live in front of an interviewer
        - What to say before writing code, how to handle being stuck, how to test
        - 3-5 bullet points as a single string separated by newlines

        Return ONLY valid JSON — no markdown, no explanation, no code fences:
        {
          "questions": [
            {
              "text": "Question text here?",
              "category": "behavioral",
              "difficulty": "medium",
              "suggestedAnswer": "Full first-person spoken answer here.",
              "liveCodingAdvice": "",
              "order": 1
            },
            {
              "text": "Implement a function to find duplicates in an array.",
              "category": "live_coding",
              "difficulty": "medium",
              "suggestedAnswer": "I would start by clarifying the input and output with the interviewer. I would use a Set to track seen values and return an array of duplicates. The time complexity is O(n) and space is O(n).",
              "liveCodingAdvice": "• Repeat the question back to confirm you understand\n• Ask about edge cases before writing anything\n• Think out loud as you code — silence is bad\n• Write the brute force first, then optimise\n• Test with a simple example when done",
              "order": 9
            }
          ]
        }

        JOB DESCRIPTION:
        \(jobDescription.prefix(2000))

        CANDIDATE CV:
        \(cvContent.prefix(2500))
        """

        let result: InterviewQuestionsResult = try await callGPT(
            messages: [["role": "user", "content": prompt]], maxTokens: 8000)

        return result.questions.map { d in
            InterviewQuestion(
                text: d.text,
                category: d.category,
                difficulty: d.difficulty,
                suggestedAnswer: d.suggestedAnswer,
                liveCodingAdvice: d.liveCodingAdvice,
                order: d.order
            )
        }
    }

    // MARK: 3. ATS Score Analysis

    struct ATSResult: Codable {
        let score: Int
        let issues: [ATSIssue]
        let recommendations: [String]
    }

    struct ATSIssue: Codable {
        let severity: String   // "critical" | "warning" | "info"
        let title: String
        let description: String
        let suggestion: String
    }

    func analyseATSCompatibility(cvContent: String) async throws -> ATSResult {
        let prompt = """
        Analyse this CV for ATS (Applicant Tracking System) compatibility.

        Check: keyword density, formatting issues (tables/columns/graphics), section names, length, contact info visibility.

        Return ONLY valid JSON:
        {
          "score": 72,
          "issues": [
            {
              "severity": "critical",
              "title": "Tables detected",
              "description": "CV appears to use table formatting which many ATS systems cannot parse.",
              "suggestion": "Replace tables with plain text bullet points."
            }
          ],
          "recommendations": [
            "Use standard section headings: Experience, Education, Skills",
            "Keep CV to 1-2 pages for best ATS ranking"
          ]
        }

        Severity levels: critical (blocks parsing), warning (reduces score), info (nice to fix).
        Provide 2-5 issues and 3 recommendations.

        CV CONTENT:
        \(cvContent.prefix(4000))
        """
        return try await callGPT(messages: [["role": "user", "content": prompt]], maxTokens: 1500)
    }

    // MARK: 4. Salary Extraction

    struct SalaryResult: Codable {
        let min: Double?
        let max: Double?
        let currency: String
        let period: String     // "annual" | "hourly" | "daily"
        let found: Bool
    }

    func extractSalary(from jobDescription: String) async throws -> SalaryResult {
        let prompt = """
        Extract salary information from this job posting.

        Return ONLY valid JSON:
        {
          "min": 60000,
          "max": 80000,
          "currency": "GBP",
          "period": "annual",
          "found": true
        }

        If no salary mentioned set found: false and min/max: null.
        Currency should be ISO 4217 code (GBP, USD, EUR etc).
        Period: annual, hourly, or daily.

        JOB POSTING:
        \(jobDescription.prefix(2000))
        """
        do {
            return try await callGPT(messages: [["role": "user", "content": prompt]], maxTokens: 200)
        } catch {
            return SalaryResult(min: nil, max: nil, currency: "GBP", period: "annual", found: false)
        }
    }

    // MARK: 5. URL Job Extraction

    func extractJobFromURL(_ urlString: String) async throws -> ExtractedJobDescription {
        guard let url = URL(string: urlString),
              urlString.hasPrefix("http") else {
            throw NSError(domain: "Forio", code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Invalid URL. Please check and try again."])
        }

        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 15

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw NSError(domain: "Forio", code: 2,
                userInfo: [NSLocalizedDescriptionKey: "Couldn't load that page. LinkedIn requires login — try copying and pasting the job text instead."])
        }

        guard let html = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "Forio", code: 3,
                userInfo: [NSLocalizedDescriptionKey: "Couldn't read page content."])
        }

        // Strip HTML tags to get readable text
        let text = html
            .replacingOccurrences(of: "<script[^>]*>.*?</script>", with: "", options: [.regularExpression, .caseInsensitive])
            .replacingOccurrences(of: "<style[^>]*>.*?</style>", with: "", options: [.regularExpression, .caseInsensitive])
            .replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let prompt = """
        Extract job posting details from this webpage text.

        Return ONLY valid JSON:
        {
          "title": "Senior iOS Developer",
          "company": "Acme Ltd",
          "description": "Full job description text here..."
        }

        Use empty string for any field not found.
        For description: include all job requirements, responsibilities, and qualifications you can find.

        WEBPAGE TEXT:
        \(text.prefix(5000))
        """

        return try await callGPT(messages: [["role": "user", "content": prompt]], maxTokens: 2000)
    }
}
