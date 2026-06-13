import SwiftUI
import SwiftData

struct ProfileBuilderView: View {
    let persona: UserPersona
    var onComplete: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]

    @State private var viewModel: ProfileBuilderViewModel

    init(persona: UserPersona, onComplete: @escaping () -> Void) {
        self.persona = persona
        self.onComplete = onComplete
        _viewModel = State(initialValue: ProfileBuilderViewModel(persona: persona))
    }

    var body: some View {
        ZStack {
            AppTheme.bgPrimary.ignoresSafeArea(.all)

            VStack(spacing: 0) {
                // Progress header
                progressHeader

                // Step content
                ZStack {
                    switch viewModel.currentStep {
                    case .name:
                        NameStepView(viewModel: viewModel)
                    case .contact:
                        ContactStepView(viewModel: viewModel)
                    case .experienceCheck:
                        ExperienceCheckStepView(viewModel: viewModel)
                    case .experience:
                        ExperienceStepView(viewModel: viewModel)
                    case .education:
                        EducationStepView(viewModel: viewModel)
                    case .skills:
                        SkillsStepView(viewModel: viewModel)
                    case .careerTransition:
                        CareerTransitionStepView(viewModel: viewModel)
                    case .gapReason:
                        GapReasonStepView(viewModel: viewModel)
                    case .summary:
                        SummaryStepView(viewModel: viewModel)
                    case .done:
                        Color.clear.onAppear { saveAndComplete() }
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal:   .move(edge: .leading).combined(with: .opacity)
                ))
                .animation(.easeInOut(duration: 0.28), value: viewModel.currentStep)

                // Bottom nav
                bottomNav
            }
            .safeAreaPadding(.top)
        }
    }

    // MARK: - Progress header

    private var progressHeader: some View {
        VStack(spacing: 10) {
            HStack {
                if viewModel.currentStep != .name {
                    Button(action: { viewModel.goBack() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(AppTheme.textMuted)
                    }
                } else {
                    Color.clear.frame(width: 20)
                }
                Spacer()
                Text(viewModel.stepLabel)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppTheme.textMuted)
                Spacer()
                Color.clear.frame(width: 20)
            }
            .padding(.horizontal, 24)

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(AppTheme.bgElevated)
                        .frame(height: 3)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(AppTheme.gold)
                        .frame(width: geo.size.width * viewModel.progress, height: 3)
                        .animation(.easeInOut(duration: 0.4), value: viewModel.progress)
                }
            }
            .frame(height: 3)
            .padding(.horizontal, 24)
        }
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    // MARK: - Bottom nav

    private var bottomNav: some View {
        VStack(spacing: 10) {
            Button(action: { viewModel.goNext() }) {
                Text(nextButtonLabel)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppTheme.bgPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(viewModel.canGoNext ? AppTheme.gold : AppTheme.gold.opacity(0.35))
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
            }
            .disabled(!viewModel.canGoNext)

            // Skip option for optional steps
            if isSkippable {
                Button("Skip for now") { viewModel.goNext() }
                    .font(.system(size: 14))
                    .foregroundStyle(AppTheme.textMuted)
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 48)
        .padding(.top, 8)
    }

    private var nextButtonLabel: String {
        switch viewModel.currentStep {
        case .name:       return "That's my name →"
        case .contact:    return "Those are my details →"
        case .skills:     return "These are my skills →"
        case .summary:    return "Done — build my profile →"
        default:          return "Continue →"
        }
    }

    private var isSkippable: Bool {
        switch viewModel.currentStep {
        case .experience, .education, .summary: return true
        default: return false
        }
    }

    // MARK: - Save

    private func saveAndComplete() {
        guard let profile = profiles.first else { return }
        viewModel.applyToProfile(profile)
        try? modelContext.save()
        onComplete()
    }
}
