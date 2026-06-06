import SwiftUI

// MARK: - Step 6: Skills

struct SkillsStepView: View {
    @Bindable var viewModel: ProfileBuilderViewModel
    @FocusState private var customFocused: Bool

    private var presetSkills: [String] {
        PresetSkills.skills(for: viewModel.persona)
    }

    var body: some View {
        StepContainer(
            title: "What are you good at?",
            subtitle: "Tap everything that fits — you can always add more",
            tip: "Add at least 5 skills. Be specific — \"Excel\" beats \"Microsoft Office.\""
        ) {
            VStack(alignment: .leading, spacing: 16) {
                // Preset chips
                FlowLayout(spacing: 8) {
                    ForEach(presetSkills, id: \.self) { skill in
                        presetChip(skill)
                    }
                }

                // Selected counter
                if !viewModel.skills.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(AppTheme.success)
                            .font(.system(size: 13))
                        Text("\(viewModel.skills.count) skill\(viewModel.skills.count == 1 ? "" : "s") selected")
                            .font(.system(size: 12))
                            .foregroundStyle(AppTheme.textMuted)
                    }
                }

                // Custom skill entry
                VStack(alignment: .leading, spacing: 6) {
                    Text("ADD YOUR OWN")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(AppTheme.textMuted)
                        .kerning(0.5)

                    HStack(spacing: 8) {
                        TextField("Type a skill and press return", text: $viewModel.newSkillText)
                            .font(.system(size: 14))
                            .foregroundStyle(AppTheme.textPrimary)
                            .focused($customFocused)
                            .onSubmit { viewModel.addCustomSkill() }
                            .padding(12)
                            .background(AppTheme.bgCard)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                                    .stroke(customFocused ? AppTheme.goldBorder : AppTheme.bgBorder,
                                            lineWidth: 0.5)
                            )
                        Button(action: { viewModel.addCustomSkill() }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(viewModel.newSkillText.isEmpty
                                                 ? AppTheme.textDisabled : AppTheme.gold)
                        }
                        .disabled(viewModel.newSkillText.isEmpty)
                    }
                }

                // Custom skills added (not from presets)
                let customSkills = viewModel.skills.filter { !presetSkills.contains($0) }
                if !customSkills.isEmpty {
                    FlowLayout(spacing: 8) {
                        ForEach(customSkills, id: \.self) { skill in
                            customSkillChip(skill)
                        }
                    }
                }
            }
        }
    }

    private func presetChip(_ skill: String) -> some View {
        let isOn = viewModel.selectedPresetSkills.contains(skill)
        return Button(action: { viewModel.togglePresetSkill(skill) }) {
            Text(skill)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(isOn ? AppTheme.gold : AppTheme.textSecond)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(isOn ? AppTheme.goldFaint : AppTheme.bgCard)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isOn ? AppTheme.goldBorder : AppTheme.bgBorder,
                                lineWidth: isOn ? 1.0 : 0.5)
                )
        }
        .buttonStyle(.plain)
        .animation(.easeOut(duration: 0.15), value: isOn)
    }

    private func customSkillChip(_ skill: String) -> some View {
        HStack(spacing: 4) {
            Text(skill)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppTheme.gold)
            Button(action: { viewModel.removeSkill(skill) }) {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(AppTheme.textMuted)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(AppTheme.goldFaint)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(AppTheme.goldBorder, lineWidth: 0.5)
        )
    }
}

// MARK: - Step 7: Career transition (careerChanger only)

struct CareerTransitionStepView: View {
    @Bindable var viewModel: ProfileBuilderViewModel

    var body: some View {
        StepContainer(
            title: "Tell us about\nyour switch",
            subtitle: "AI will bridge your past experience into your new direction",
            tip: "Your previous experience has more transferable value than you think. We'll surface it."
        ) {
            VStack(spacing: 14) {
                ForioTextField(
                    label: "I'm moving FROM",
                    placeholder: "e.g. Finance, Teaching, Retail",
                    text: $viewModel.fromField
                )
                HStack {
                    Spacer()
                    Image(systemName: "arrow.down")
                        .font(.system(size: 16))
                        .foregroundStyle(AppTheme.gold)
                    Spacer()
                }
                ForioTextField(
                    label: "I'm moving INTO",
                    placeholder: "e.g. UX Design, Software, Marketing",
                    text: $viewModel.toField
                )

                // Example bridge
                if !viewModel.fromField.isEmpty && !viewModel.toField.isEmpty {
                    HStack(alignment: .top, spacing: 10) {
                        Text("✦")
                            .foregroundStyle(AppTheme.gold)
                        Text("AI will reframe your \(viewModel.fromField) experience as transferable skills for \(viewModel.toField) roles.")
                            .font(.system(size: 12))
                            .foregroundStyle(AppTheme.textMuted)
                            .lineSpacing(2)
                    }
                    .padding(12)
                    .background(AppTheme.goldFaint)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                            .stroke(AppTheme.goldBorder, lineWidth: 0.5)
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.97)))
                    .animation(.easeOut(duration: 0.25), value: viewModel.toField)
                }
            }
        }
    }
}

// MARK: - Step 8: Gap reason (returning only)

struct GapReasonStepView: View {
    @Bindable var viewModel: ProfileBuilderViewModel

    var body: some View {
        StepContainer(
            title: "What was your\ngap for?",
            subtitle: "We handle gaps with dignity — you don't need to hide this",
            tip: "Recruiters respect honesty. AI will frame your gap positively in your cover letter."
        ) {
            VStack(spacing: 10) {
                ForEach(GapReason.allCases, id: \.self) { reason in
                    Button(action: { viewModel.gapReason = reason }) {
                        HStack {
                            Text(reason.rawValue)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(viewModel.gapReason == reason
                                                 ? AppTheme.gold : AppTheme.textPrimary)
                            Spacer()
                            if viewModel.gapReason == reason {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(AppTheme.gold)
                                    .font(.system(size: 18))
                            }
                        }
                        .padding(16)
                        .background(viewModel.gapReason == reason
                                    ? AppTheme.goldFaint : AppTheme.bgCard)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                                .stroke(viewModel.gapReason == reason
                                        ? AppTheme.goldBorder : AppTheme.bgBorder,
                                        lineWidth: viewModel.gapReason == reason ? 1.0 : 0.5)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Step 9: Summary (optional)

struct SummaryStepView: View {
    @Bindable var viewModel: ProfileBuilderViewModel
    @FocusState private var focused: Bool

    private var placeholder: String {
        switch viewModel.persona {
        case .graduate:
            return "e.g. Motivated Computer Science graduate with a passion for mobile development and a strong academic record. Seeking my first role in iOS development."
        case .experienced:
            return "e.g. iOS Developer with 4 years of experience building AI-powered consumer apps. Proven track record of shipping products from concept to App Store."
        case .careerChanger:
            return "e.g. Former finance analyst transitioning into UX design. Brings strong analytical thinking and stakeholder communication skills."
        case .returning:
            return "e.g. Experienced project manager returning to work after a career break. Skills sharpened through recent certification and freelance work."
        }
    }

    var body: some View {
        StepContainer(
            title: "Your professional\nsummary",
            subtitle: "A short paragraph about you — AI will improve this for each job",
            tip: "Don't overthink it. Write 2–3 sentences. AI rewrites it for every application anyway."
        ) {
            VStack(alignment: .leading, spacing: 6) {
                Text("SUMMARY")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(AppTheme.textMuted)
                    .kerning(0.5)

                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                        .fill(AppTheme.bgCard)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                                .stroke(focused ? AppTheme.goldBorder : AppTheme.bgBorder,
                                        lineWidth: 0.5)
                        )
                        .frame(minHeight: 140)

                    if viewModel.summary.isEmpty {
                        Text(placeholder)
                            .font(.system(size: 13))
                            .foregroundStyle(AppTheme.textDisabled)
                            .padding(14)
                            .allowsHitTesting(false)
                    }

                    TextEditor(text: $viewModel.summary)
                        .font(.system(size: 14))
                        .foregroundStyle(AppTheme.textPrimary)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .focused($focused)
                        .padding(10)
                        .frame(minHeight: 140)
                }
            }
        }
    }
}
