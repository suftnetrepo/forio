import SwiftUI
import SwiftData
import Observation

enum GenerationState {
    case idle
    case generating
    case complete(GeneratedDocument)
    case failed(String)
}

enum JobInputMethod {
    case paste, scan, url
}

@Observable
@MainActor
class GenerationViewModel {

    // MARK: State
    var generationState: GenerationState = .idle
    var jobDescription: String = ""
    var jobTitle: String = ""
    var company: String = ""
    var selectedTemplate: CVTemplate = .cleanMinimal
    var inputMethod: JobInputMethod = .paste
    var urlText: String = ""
    var selectedCVProfile: CVProfile? = nil  // nil = use main UserProfile

    // MARK: Generation progress
    var progressSteps: [GenerationStep] = GenerationStep.allSteps
    var currentStepIndex: Int = 0
    var aiInsightText: String = ""

    var isGenerating: Bool {
        if case .generating = generationState { return true }
        return false
    }

    var canGenerate: Bool {
        !jobDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Generate with CVProfile (multiple CV support)

    func generate(cvProfile: CVProfile, purchaseService: PurchaseService) async {
        guard canGenerate else { return }
        guard purchaseService.canGenerate else { return }

        generationState = .generating
        progressSteps = GenerationStep.allSteps
        currentStepIndex = 0
        aiInsightText = ""

        if selectedTemplate == .cleanMinimal {
            selectedTemplate = cvProfile.persona.defaultTemplate
        }

        async let animationTask: Void = animateSteps()
        async let apiTask = callAPIWithCVProfile(cvProfile)

        do {
            let (_, result) = try await (animationTask, apiTask)
            purchaseService.recordGeneration()
            generationState = .complete(result)
        } catch {
            generationState = .failed("Generation failed. Please try again.")
        }
    }

    private func callAPIWithCVProfile(_ cvProfile: CVProfile) async throws -> GeneratedDocument {
        // Build a temporary UserProfile from the CVProfile so we can reuse the same API path
        let tempProfile = UserProfile(persona: cvProfile.persona)
        tempProfile.fullName            = cvProfile.fullName
        tempProfile.email               = cvProfile.email
        tempProfile.phone               = cvProfile.phone
        tempProfile.location            = cvProfile.location
        tempProfile.linkedIn            = cvProfile.linkedIn
        tempProfile.portfolio           = cvProfile.portfolio
        tempProfile.professionalSummary = cvProfile.professionalSummary
        tempProfile.experience          = cvProfile.experience
        tempProfile.education           = cvProfile.education
        tempProfile.skills              = cvProfile.skills

        let result = try await AIService.shared.generateCV(
            profile: tempProfile,
            jobDescription: jobDescription,
            template: selectedTemplate
        )
        let doc = GeneratedDocument(cvContent: result.cvContent,
                                    coverLetterContent: result.coverLetterContent,
                                    template: selectedTemplate)
        doc.matchScore       = result.matchScore
        doc.matchedKeywords  = result.matchedKeywords
        doc.aiInsights       = result.aiInsights
        return doc
    }

    // MARK: - Generate CV

    func generate(profile: UserProfile, purchaseService: PurchaseService) async {
        guard canGenerate else { return }
        guard purchaseService.canGenerate else { return }

        generationState = .generating
        progressSteps = GenerationStep.allSteps
        currentStepIndex = 0
        aiInsightText = ""

        // Use persona default template if not manually chosen
        if selectedTemplate == .cleanMinimal {
            selectedTemplate = profile.persona.defaultTemplate
        }

        // Animate steps concurrently with the actual API call
        async let animationTask: Void = animateSteps()
        async let apiTask = callAPI(profile: profile)

        do {
            let (_, result) = try await (animationTask, apiTask)
            purchaseService.recordGeneration()
            generationState = .complete(result)
        } catch {
            generationState = .failed("Generation failed. Please check your connection and try again.")
        }
    }

    // MARK: - API call

    private func callAPI(profile: UserProfile) async throws -> GeneratedDocument {
        let result = try await AIService.shared.generateCV(
            profile: profile,
            jobDescription: jobDescription,
            template: selectedTemplate
        )

        let doc = GeneratedDocument(
            cvContent: result.cvContent,
            coverLetterContent: result.coverLetterContent,
            template: selectedTemplate
        )
        doc.matchScore = result.matchScore
        doc.matchedKeywords = result.matchedKeywords
        doc.aiInsights = result.aiInsights
        return doc
    }

    // MARK: - Animate generation steps

    private func animateSteps() async {
        let insights = [
            "Analysing job requirements…",
            "Matching your skills to the role…",
            "Tailoring language for this industry…",
            "Crafting your cover letter…"
        ]

        for i in 0..<progressSteps.count {
            try? await Task.sleep(nanoseconds: 900_000_000)
            currentStepIndex = i
            progressSteps[i].isDone = true
            if i < insights.count {
                aiInsightText = insights[i]
            }
        }
    }

    // MARK: - Reset

    func reset() {
        generationState = .idle
        jobDescription  = ""
        jobTitle        = ""
        company         = ""
        urlText         = ""
        progressSteps   = GenerationStep.allSteps
        currentStepIndex = 0
        aiInsightText   = ""
    }
}

// MARK: - Generation step model

struct GenerationStep: Identifiable {
    let id = UUID()
    let label: String
    var isDone: Bool = false

    static var allSteps: [GenerationStep] {
        [
            GenerationStep(label: "Reading job description"),
            GenerationStep(label: "Matching your profile"),
            GenerationStep(label: "Writing your CV"),
            GenerationStep(label: "Writing cover letter"),
        ]
    }
}
