import SwiftUI
import VisionKit
import Observation

enum ImportSource {
    case scan, pdf, paste
}

enum ImportState {
    case idle
    case scanning
    case extracting
    case reviewing
    case complete
    case failed(String)
}

@Observable
@MainActor
class CVImportViewModel {

    // MARK: State
    var importState: ImportState = .idle
    var scannedImages: [UIImage] = []
    var pastedText: String = ""
    var extractedProfile: ExtractedProfile?
    var importSource: ImportSource = .paste

    // MARK: Extraction progress (for animated checklist)
    var extractionSteps: [ExtractionStep] = ExtractionStep.allSteps
    var currentStepIndex: Int = 0

    // MARK: Review editable fields
    var reviewName: String = ""
    var reviewEmail: String = ""
    var reviewPhone: String = ""
    var reviewLocation: String = ""
    var reviewLinkedIn: String = ""
    var reviewPortfolio: String = ""
    var reviewSummary: String = ""
    var reviewSkills: [String] = []
    var reviewExperience: [WorkExperience] = []
    var reviewEducation: [Education] = []

    var newSkillText: String = ""

    var isExtracting: Bool {
        if case .extracting = importState { return true }
        return false
    }

    // MARK: - Scan handler (from VisionKit)
    func handleScan(result: Result<VNDocumentCameraScan, Error>) {
        switch result {
        case .success(let scan):
            scannedImages = []
            let count = min(scan.pageCount, Constants.maxScanPages)
            for i in 0..<count {
                scannedImages.append(scan.imageOfPage(at: i))
            }
            importSource = .scan
            Task { await extractFromImages() }
        case .failure(let error):
            importState = .failed(error.localizedDescription)
        }
    }

    // MARK: - PDF text handler
    func handlePDFText(_ text: String) {
        pastedText = text
        importSource = .pdf
        Task { await extractFromText() }
    }

    // MARK: - Paste handler
    func handlePaste(_ text: String) {
        pastedText = text
        importSource = .paste
        Task { await extractFromText() }
    }

    // MARK: - Extract from images
    private func extractFromImages() async {
        guard !scannedImages.isEmpty else { return }
        importState = .extracting
        await animateExtractionSteps()
        do {
            let profile = try await AIService.shared.extractProfile(from: scannedImages)
            populateReviewFields(from: profile)
            importState = .reviewing
        } catch {
            importState = .failed("Couldn't read your CV. Please try again or paste the text instead.")
        }
    }

    // MARK: - Extract from text
    private func extractFromText() async {
        guard !pastedText.isEmpty else { return }
        importState = .extracting
        await animateExtractionSteps()
        do {
            let profile = try await AIService.shared.extractProfile(from: pastedText)
            populateReviewFields(from: profile)
            importState = .reviewing
        } catch {
            importState = .failed("Couldn't read your CV. Please try again.")
        }
    }

    // MARK: - Animate extraction checklist
    private func animateExtractionSteps() async {
        extractionSteps = ExtractionStep.allSteps
        currentStepIndex = 0
        for i in 0..<extractionSteps.count {
            try? await Task.sleep(nanoseconds: 600_000_000) // 0.6s per step
            currentStepIndex = i
            extractionSteps[i].isDone = true
        }
    }

    // MARK: - Populate review fields
    private func populateReviewFields(from profile: ExtractedProfile) {
        extractedProfile = profile
        reviewName       = profile.fullName
        reviewEmail      = profile.email
        reviewPhone      = profile.phone
        reviewLocation   = profile.location
        reviewLinkedIn   = profile.linkedIn
        reviewPortfolio  = profile.portfolio
        reviewSummary    = profile.professionalSummary
        reviewSkills     = profile.skills
        reviewExperience = profile.experience
        reviewEducation  = profile.education
    }

    // MARK: - Apply to UserProfile SwiftData model
    func applyToProfile(_ profile: UserProfile) {
        profile.fullName             = reviewName
        profile.email                = reviewEmail
        profile.phone                = reviewPhone
        profile.location             = reviewLocation
        profile.linkedIn             = reviewLinkedIn
        profile.portfolio            = reviewPortfolio
        profile.professionalSummary  = reviewSummary
        profile.skills               = reviewSkills
        profile.experience           = reviewExperience
        profile.education            = reviewEducation
        profile.importedFromCV       = true
        profile.onboardingComplete   = true
        profile.updatedAt            = Date()
    }

    // MARK: - Skills helpers
    func addSkill(_ skill: String) {
        let trimmed = skill.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !reviewSkills.contains(trimmed) else { return }
        reviewSkills.append(trimmed)
        newSkillText = ""
    }

    func removeSkill(_ skill: String) {
        reviewSkills.removeAll { $0 == skill }
    }

    // MARK: - Reset
    func reset() {
        importState      = .idle
        scannedImages    = []
        pastedText       = ""
        extractedProfile = nil
        extractionSteps  = ExtractionStep.allSteps
        currentStepIndex = 0
        reviewName       = ""
        reviewEmail      = ""
        reviewPhone      = ""
        reviewLocation   = ""
        reviewLinkedIn   = ""
        reviewPortfolio  = ""
        reviewSummary    = ""
        reviewSkills     = []
        reviewExperience = []
        reviewEducation  = []
        newSkillText     = ""
    }
}

// MARK: - Extraction step model

struct ExtractionStep: Identifiable {
    let id = UUID()
    let label: String
    var isDone: Bool = false

    static var allSteps: [ExtractionStep] {
        [
            ExtractionStep(label: "Name & contact details"),
            ExtractionStep(label: "Work experience"),
            ExtractionStep(label: "Education"),
            ExtractionStep(label: "Skills & summary"),
        ]
    }
}
