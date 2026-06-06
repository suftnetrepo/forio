import SwiftUI
import Observation

// MARK: - Builder steps (order matters)

enum BuilderStep: Int, CaseIterable {
    case name
    case contact
    case experienceCheck   // "Any work so far?" — persona-adaptive
    case experience
    case education
    case skills
    case careerTransition  // only for .careerChanger
    case gapReason         // only for .returning
    case summary
    case done

    var progress: Double {
        Double(rawValue) / Double(BuilderStep.done.rawValue)
    }
}

@Observable
@MainActor
class ProfileBuilderViewModel {

    var persona: UserPersona
    var currentStep: BuilderStep = .name

    // MARK: Field values
    var fullName       = ""
    var email          = ""
    var phone          = ""
    var location       = ""
    var linkedIn       = ""
    var portfolio      = ""
    var summary        = ""

    var hasExperience: Bool? = nil        // nil = not answered yet
    var experience: [WorkExperience] = []
    var education: [Education] = []
    var skills: [String] = []
    var selectedPresetSkills: Set<String> = []

    var fromField      = ""              // career changer
    var toField        = ""              // career changer
    var gapReason: GapReason? = nil      // returning

    // Temp entry state
    var newJobTitle    = ""
    var newCompany     = ""
    var newStartDate   = ""
    var newEndDate     = ""
    var newIsCurrent   = false
    var newJobDesc     = ""

    var newDegree      = ""
    var newInstitution = ""
    var newGradYear    = ""
    var newGrade       = ""

    var newSkillText   = ""

    init(persona: UserPersona) {
        self.persona = persona
    }

    // MARK: - Step navigation

    var stepLabel: String {
        let steps = relevantSteps
        guard let idx = steps.firstIndex(of: currentStep) else { return "" }
        return "Step \(idx + 1) of \(steps.count - 1)"  // -1 excludes .done
    }

    var progress: Double {
        let steps = relevantSteps
        guard let idx = steps.firstIndex(of: currentStep) else { return 0 }
        return Double(idx) / Double(steps.count - 1)
    }

    /// Steps shown for this persona (skips irrelevant ones)
    var relevantSteps: [BuilderStep] {
        var steps: [BuilderStep] = [.name, .contact, .experienceCheck, .experience, .education, .skills]
        if persona == .careerChanger { steps.append(.careerTransition) }
        if persona == .returning     { steps.append(.gapReason) }
        steps.append(.summary)
        steps.append(.done)
        return steps
    }

    func goNext() {
        let steps = relevantSteps
        guard let idx = steps.firstIndex(of: currentStep),
              idx + 1 < steps.count else { return }
        // Skip experience entry if user said they have none
        var next = steps[idx + 1]
        if next == .experience && hasExperience == false {
            // skip to education
            if let eduIdx = steps.firstIndex(of: .education) {
                next = steps[eduIdx]
            }
        }
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = next
        }
    }

    func goBack() {
        let steps = relevantSteps
        guard let idx = steps.firstIndex(of: currentStep), idx > 0 else { return }
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = steps[idx - 1]
        }
    }

    var canGoNext: Bool {
        switch currentStep {
        case .name:             return !fullName.trimmingCharacters(in: .whitespaces).isEmpty
        case .contact:          return !email.trimmingCharacters(in: .whitespaces).isEmpty
        case .experienceCheck:  return hasExperience != nil
        case .experience:       return true   // optional — can skip
        case .education:        return true   // optional — can skip
        case .skills:           return !skills.isEmpty
        case .careerTransition: return !fromField.isEmpty && !toField.isEmpty
        case .gapReason:        return gapReason != nil
        case .summary:          return true
        case .done:             return true
        }
    }

    // MARK: - Experience helpers

    func addExperience() {
        guard !newJobTitle.isEmpty, !newCompany.isEmpty else { return }
        let job = WorkExperience(
            jobTitle:    newJobTitle,
            company:     newCompany,
            startDate:   newStartDate,
            endDate:     newIsCurrent ? "Present" : newEndDate,
            isCurrent:   newIsCurrent,
            description: newJobDesc
        )
        experience.append(job)
        clearJobForm()
    }

    func removeExperience(_ job: WorkExperience) {
        experience.removeAll { $0.id == job.id }
    }

    private func clearJobForm() {
        newJobTitle  = ""
        newCompany   = ""
        newStartDate = ""
        newEndDate   = ""
        newIsCurrent = false
        newJobDesc   = ""
    }

    // MARK: - Education helpers

    func addEducation() {
        guard !newDegree.isEmpty, !newInstitution.isEmpty else { return }
        let edu = Education(
            degree:          newDegree,
            institution:     newInstitution,
            graduationYear:  newGradYear,
            grade:           newGrade
        )
        education.append(edu)
        clearEduForm()
    }

    func removeEducation(_ edu: Education) {
        education.removeAll { $0.id == edu.id }
    }

    private func clearEduForm() {
        newDegree      = ""
        newInstitution = ""
        newGradYear    = ""
        newGrade       = ""
    }

    // MARK: - Skills helpers

    func togglePresetSkill(_ skill: String) {
        if selectedPresetSkills.contains(skill) {
            selectedPresetSkills.remove(skill)
            skills.removeAll { $0 == skill }
        } else {
            selectedPresetSkills.insert(skill)
            if !skills.contains(skill) { skills.append(skill) }
        }
    }

    func addCustomSkill() {
        let trimmed = newSkillText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !skills.contains(trimmed) else { return }
        skills.append(trimmed)
        newSkillText = ""
    }

    func removeSkill(_ skill: String) {
        skills.removeAll { $0 == skill }
        selectedPresetSkills.remove(skill)
    }

    // MARK: - Save to UserProfile

    func applyToProfile(_ profile: UserProfile) {
        profile.fullName            = fullName
        profile.email               = email
        profile.phone               = phone
        profile.location            = location
        profile.linkedIn            = linkedIn
        profile.portfolio           = portfolio
        profile.professionalSummary = summary
        profile.experience          = experience
        profile.education           = education
        profile.skills              = skills
        profile.fromField           = fromField
        profile.toField             = toField
        profile.gapReason           = gapReason
        profile.importedFromCV      = false
        profile.onboardingComplete  = true
        profile.updatedAt           = Date()
    }
}
