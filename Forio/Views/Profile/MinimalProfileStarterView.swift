import SwiftUI
import SwiftData

struct MinimalProfileStarterView: View {
    var onComplete: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]

    @State private var name = ""
    @State private var email = ""
    @State private var skillsText = ""
    @State private var currentStep = 0
    @FocusState private var isFocused: Bool

    private let steps = ["name", "email", "skills"]

    var canContinue: Bool {
        switch currentStep {
        case 0: return !name.trimmingCharacters(in: .whitespaces).isEmpty
        case 1: return !email.trimmingCharacters(in: .whitespaces).isEmpty
        case 2: return !skillsText.trimmingCharacters(in: .whitespaces).isEmpty
        default: return false
        }
    }

    var body: some View {
        ZStack {
            AppTheme.bgPrimary.ignoresSafeArea(.all)

            VStack(spacing: 0) {
                // Progress
                VStack(spacing: 10) {
                    Text("Step \(currentStep + 1) of 3")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(AppTheme.textMuted)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(AppTheme.bgElevated)
                                .frame(height: 3)
                            RoundedRectangle(cornerRadius: 2)
                                .fill(AppTheme.gold)
                                .frame(width: geo.size.width * Double(currentStep + 1) / 3.0, height: 3)
                                .animation(.easeInOut(duration: 0.4), value: currentStep)
                        }
                    }
                    .frame(height: 3)
                    .padding(.horizontal, 24)
                }
                .padding(.top, 20)
                .padding(.bottom, 8)

                Spacer()

                // Step content
                VStack(alignment: .leading, spacing: 20) {
                    switch currentStep {
                    case 0:
                        stepContent(
                            title: "What's your name?",
                            subtitle: "This goes at the top of your CV",
                            placeholder: "e.g. Abel Aghorighor",
                            text: $name,
                            tip: "Use your full name as it appears on your ID"
                        )
                    case 1:
                        stepContent(
                            title: "Your email address?",
                            subtitle: "So employers can contact you",
                            placeholder: "you@email.com",
                            text: $email,
                            keyboard: .emailAddress,
                            tip: "Use a professional email — avoid nicknames"
                        )
                    case 2:
                        skillsStep
                    default:
                        EmptyView()
                    }
                }
                .padding(.horizontal, 24)

                Spacer()

                // Bottom nav
                VStack(spacing: 12) {
                    Button(action: advance) {
                        Text(currentStep == 2 ? "Let's go →" : "Continue →")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(AppTheme.bgPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(canContinue ? AppTheme.gold : AppTheme.gold.opacity(0.35))
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
                    }
                    .disabled(!canContinue)

                    if currentStep > 0 {
                        Button("Back") {
                            withAnimation(.easeInOut(duration: 0.25)) { currentStep -= 1 }
                        }
                        .font(.system(size: 14))
                        .foregroundStyle(AppTheme.textMuted)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 52)
            }
        }
        .onAppear { isFocused = true }
    }

    // MARK: - Step content

    private func stepContent(
        title: String,
        subtitle: String,
        placeholder: String,
        text: Binding<String>,
        keyboard: UIKeyboardType = .default,
        tip: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 26, weight: .medium))
                    .foregroundStyle(AppTheme.textPrimary)
                Text(subtitle)
                    .font(.system(size: 15))
                    .foregroundStyle(AppTheme.textMuted)
            }

            TextField(placeholder, text: text)
                .font(.system(size: 18))
                .foregroundStyle(AppTheme.textPrimary)
                .keyboardType(keyboard)
                .focused($isFocused)
                .padding(14)
                .background(AppTheme.bgCard)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                        .stroke(text.wrappedValue.isEmpty ? AppTheme.bgBorder : AppTheme.goldBorder,
                                lineWidth: 0.5)
                )

            HStack(alignment: .top, spacing: 8) {
                Text("💡")
                Text(tip)
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.textMuted)
                    .lineSpacing(2)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.goldFaint)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                    .stroke(AppTheme.goldBorder, lineWidth: 0.5)
            )
        }
        .onAppear { isFocused = true }
    }

    // MARK: - Skills step

    private var skillsStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("What are you good at?")
                    .font(.system(size: 26, weight: .medium))
                    .foregroundStyle(AppTheme.textPrimary)
                Text("List a few skills — separated by commas")
                    .font(.system(size: 15))
                    .foregroundStyle(AppTheme.textMuted)
            }

            TextField("e.g. Communication, Excel, Python, Teamwork",
                      text: $skillsText, axis: .vertical)
                .font(.system(size: 16))
                .foregroundStyle(AppTheme.textPrimary)
                .lineLimit(3...5)
                .focused($isFocused)
                .padding(14)
                .background(AppTheme.bgCard)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                        .stroke(skillsText.isEmpty ? AppTheme.bgBorder : AppTheme.goldBorder,
                                lineWidth: 0.5)
                )

            HStack(alignment: .top, spacing: 8) {
                Text("💡")
                Text("Don't overthink it — just write whatever you're confident doing. AI will refine this for each job.")
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.textMuted)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.goldFaint)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                    .stroke(AppTheme.goldBorder, lineWidth: 0.5)
            )
        }
        .onAppear { isFocused = true }
    }

    // MARK: - Advance

    private func advance() {
        if currentStep < 2 {
            withAnimation(.easeInOut(duration: 0.25)) { currentStep += 1 }
            isFocused = true
        } else {
            saveAndComplete()
        }
    }

    private func saveAndComplete() {
        guard let profile = profiles.first else { return }
        profile.fullName = name.trimmingCharacters(in: .whitespaces)
        profile.email    = email.trimmingCharacters(in: .whitespaces)
        profile.skills   = skillsText
            .components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        profile.onboardingComplete = true
        profile.updatedAt = Date()
        try? modelContext.save()
        onComplete()
    }
}
