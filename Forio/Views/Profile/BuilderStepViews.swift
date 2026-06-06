import SwiftUI

// MARK: - Shared step container

struct StepContainer<Content: View>: View {
    let title: String
    let subtitle: String
    var tip: String? = nil
    @ViewBuilder var content: () -> Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Title block
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.system(size: 26, weight: .medium))
                        .foregroundStyle(AppTheme.textPrimary)
                    Text(subtitle)
                        .font(.system(size: 15))
                        .foregroundStyle(AppTheme.textMuted)
                        .lineSpacing(3)
                }
                .padding(.top, 8)

                content()

                // Tip panel
                if let tip {
                    HStack(alignment: .top, spacing: 10) {
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
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }
}

// MARK: - Shared field style

struct ForioTextField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var isOptional = false

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 4) {
                Text(label.uppercased())
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(AppTheme.textMuted)
                    .kerning(0.5)
                if isOptional {
                    Text("optional")
                        .font(.system(size: 9))
                        .foregroundStyle(AppTheme.textDisabled)
                }
            }
            TextField(placeholder, text: $text)
                .font(.system(size: 15))
                .foregroundStyle(AppTheme.textPrimary)
                .keyboardType(keyboardType)
                .padding(12)
                .background(AppTheme.bgCard)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                        .stroke(text.isEmpty ? AppTheme.bgBorder : AppTheme.goldBorder, lineWidth: 0.5)
                )
        }
    }
}

// MARK: - Step 1: Name

struct NameStepView: View {
    @Bindable var viewModel: ProfileBuilderViewModel
    @FocusState private var focused: Bool

    var body: some View {
        StepContainer(
            title: "What's your name?",
            subtitle: "This goes at the top of your CV",
            tip: "Use your full legal name exactly as it appears on your ID — recruiters check this."
        ) {
            VStack(alignment: .leading, spacing: 5) {
                Text("FULL NAME")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(AppTheme.textMuted)
                    .kerning(0.5)
                TextField("e.g. Abel Aghorighor", text: $viewModel.fullName)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(AppTheme.textPrimary)
                    .focused($focused)
                    .padding(14)
                    .background(AppTheme.bgCard)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                            .stroke(focused ? AppTheme.goldBorder : AppTheme.bgBorder, lineWidth: 0.5)
                    )
            }
        }
        .onAppear { focused = true }
    }
}

// MARK: - Step 2: Contact

struct ContactStepView: View {
    @Bindable var viewModel: ProfileBuilderViewModel

    var body: some View {
        StepContainer(
            title: "How can employers reach you?",
            subtitle: "Your email is required — the rest is optional but recommended"
        ) {
            VStack(spacing: 12) {
                ForioTextField(label: "Email", placeholder: "you@email.com",
                               text: $viewModel.email, keyboardType: .emailAddress)
                ForioTextField(label: "Phone", placeholder: "+44 7700 000000",
                               text: $viewModel.phone, keyboardType: .phonePad, isOptional: true)
                ForioTextField(label: "Location", placeholder: "London, UK",
                               text: $viewModel.location, isOptional: true)
                ForioTextField(label: "LinkedIn", placeholder: "linkedin.com/in/yourname",
                               text: $viewModel.linkedIn, keyboardType: .URL, isOptional: true)
                ForioTextField(label: "Portfolio / GitHub", placeholder: "yoursite.com",
                               text: $viewModel.portfolio, keyboardType: .URL, isOptional: true)
            }
        }
    }
}

// MARK: - Step 3: Experience check (persona-adaptive)

struct ExperienceCheckStepView: View {
    @Bindable var viewModel: ProfileBuilderViewModel

    private var options: [(title: String, subtitle: String, value: Bool)] {
        switch viewModel.persona {
        case .graduate:
            return [
                ("Yes — I've had some work", "Part-time, internship, placement, volunteering…", true),
                ("Not really, I'm fresh out of uni", "No worries — we'll use your projects and degree", false)
            ]
        case .experienced, .careerChanger:
            return [
                ("Yes, I have work history", "I've held paid roles I want to include", true),
                ("Skip — add later", "I'll fill this in manually", false)
            ]
        case .returning:
            return [
                ("Yes, I have past experience", "Before my career break", true),
                ("Skip — add later", "I'll fill this in when I'm ready", false)
            ]
        }
    }

    private var tip: String {
        switch viewModel.persona {
        case .graduate:
            return "University projects, society roles, and volunteering all count as real experience. Don't skip them."
        case .returning:
            return "Any freelance, volunteer or training work during your break counts too — we'll frame it positively."
        default:
            return "Include all roles, even short contracts. Gaps are fine — we'll handle them."
        }
    }

    var body: some View {
        StepContainer(
            title: "Any work so far?",
            subtitle: personaSubtitle,
            tip: tip
        ) {
            VStack(spacing: 10) {
                ForEach(options, id: \.title) { option in
                    Button(action: { viewModel.hasExperience = option.value }) {
                        HStack(spacing: 14) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(option.title)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(viewModel.hasExperience == option.value
                                                     ? AppTheme.gold : AppTheme.textPrimary)
                                Text(option.subtitle)
                                    .font(.system(size: 12))
                                    .foregroundStyle(AppTheme.textMuted)
                            }
                            Spacer()
                            if viewModel.hasExperience == option.value {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(AppTheme.gold)
                                    .font(.system(size: 20))
                            }
                        }
                        .padding(16)
                        .background(viewModel.hasExperience == option.value
                                    ? AppTheme.goldFaint : AppTheme.bgCard)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                                .stroke(viewModel.hasExperience == option.value
                                        ? AppTheme.goldBorder : AppTheme.bgBorder,
                                        lineWidth: viewModel.hasExperience == option.value ? 1.0 : 0.5)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var personaSubtitle: String {
        switch viewModel.persona {
        case .graduate:      return "Even part-time or uni projects count"
        case .experienced:   return "We'll include your most recent roles"
        case .careerChanger: return "Include roles from your previous career too"
        case .returning:     return "Before and during your career break"
        }
    }
}

// MARK: - Step 4: Experience entry

struct ExperienceStepView: View {
    @Bindable var viewModel: ProfileBuilderViewModel
    @State private var showForm = false

    private var stepTitle: String {
        switch viewModel.persona {
        case .graduate: return "Tell us about your work"
        default:        return "Your work history"
        }
    }

    private var stepSubtitle: String {
        switch viewModel.persona {
        case .graduate: return "Part-time jobs, internships, placements, volunteering — all count"
        default:        return "Add your roles, most recent first"
        }
    }

    var body: some View {
        StepContainer(title: stepTitle, subtitle: stepSubtitle) {
            VStack(spacing: 12) {
                // Existing entries
                ForEach(viewModel.experience) { job in
                    experienceCard(job)
                }

                // Add form
                if showForm {
                    addJobForm
                } else {
                    Button(action: { showForm = true }) {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(AppTheme.gold)
                            Text(viewModel.experience.isEmpty ? "Add your first role" : "Add another role")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(AppTheme.gold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(16)
                        .background(AppTheme.goldFaint)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                                .stroke(AppTheme.goldBorder, lineWidth: 0.5)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func experienceCard(_ job: WorkExperience) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(job.jobTitle)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppTheme.textPrimary)
                Text(job.company)
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.gold)
                Text("\(job.startDate) – \(job.endDate)")
                    .font(.system(size: 11))
                    .foregroundStyle(AppTheme.textMuted)
            }
            Spacer()
            Button(action: { viewModel.removeExperience(job) }) {
                Image(systemName: "trash")
                    .font(.system(size: 13))
                    .foregroundStyle(AppTheme.textDisabled)
            }
        }
        .padding(14)
        .background(AppTheme.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                .stroke(AppTheme.bgBorder, lineWidth: 0.5)
        )
    }

    private var addJobForm: some View {
        VStack(spacing: 10) {
            ForioTextField(label: "Job Title", placeholder: "e.g. iOS Developer",
                           text: $viewModel.newJobTitle)
            ForioTextField(label: "Company", placeholder: "e.g. Suftnet Ltd",
                           text: $viewModel.newCompany)
            HStack(spacing: 10) {
                ForioTextField(label: "From", placeholder: "Sep 2022",
                               text: $viewModel.newStartDate)
                if !viewModel.newIsCurrent {
                    ForioTextField(label: "To", placeholder: "Present",
                                   text: $viewModel.newEndDate)
                }
            }
            Toggle(isOn: $viewModel.newIsCurrent) {
                Text("I currently work here")
                    .font(.system(size: 13))
                    .foregroundStyle(AppTheme.textSecond)
            }
            .tint(AppTheme.gold)

            VStack(alignment: .leading, spacing: 5) {
                Text("DESCRIPTION")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(AppTheme.textMuted)
                    .kerning(0.5)
                TextField("What did you do / achieve? (optional)",
                          text: $viewModel.newJobDesc, axis: .vertical)
                    .font(.system(size: 14))
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(3...5)
                    .padding(12)
                    .background(AppTheme.bgCard)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                            .stroke(AppTheme.bgBorder, lineWidth: 0.5)
                    )
            }

            HStack(spacing: 10) {
                Button("Cancel") { showForm = false }
                    .buttonStyle(GhostButtonStyle())
                Button("Add role") {
                    viewModel.addExperience()
                    showForm = false
                }
                .buttonStyle(GoldButtonStyle(isDisabled: viewModel.newJobTitle.isEmpty))
                .disabled(viewModel.newJobTitle.isEmpty || viewModel.newCompany.isEmpty)
            }
        }
        .padding(14)
        .background(AppTheme.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                .stroke(AppTheme.goldBorder, lineWidth: 0.5)
        )
    }
}

// MARK: - Step 5: Education

struct EducationStepView: View {
    @Bindable var viewModel: ProfileBuilderViewModel
    @State private var showForm = false

    var body: some View {
        StepContainer(
            title: "Your education",
            subtitle: "Degrees, diplomas, courses — anything relevant",
            tip: viewModel.persona == .graduate
                ? "For graduates, education leads your CV — include your grade and key modules if strong."
                : nil
        ) {
            VStack(spacing: 12) {
                ForEach(viewModel.education) { edu in
                    educationCard(edu)
                }

                if showForm {
                    addEduForm
                } else {
                    Button(action: { showForm = true }) {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(AppTheme.gold)
                            Text(viewModel.education.isEmpty ? "Add qualification" : "Add another")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(AppTheme.gold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(16)
                        .background(AppTheme.goldFaint)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                                .stroke(AppTheme.goldBorder, lineWidth: 0.5)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func educationCard(_ edu: Education) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 3) {
                Text(edu.degree)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppTheme.textPrimary)
                Text(edu.institution)
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.gold)
                Text("\(edu.graduationYear)\(edu.grade.isEmpty ? "" : " · \(edu.grade)")")
                    .font(.system(size: 11))
                    .foregroundStyle(AppTheme.textMuted)
            }
            Spacer()
            Button(action: { viewModel.removeEducation(edu) }) {
                Image(systemName: "trash")
                    .font(.system(size: 13))
                    .foregroundStyle(AppTheme.textDisabled)
            }
        }
        .padding(14)
        .background(AppTheme.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                .stroke(AppTheme.bgBorder, lineWidth: 0.5)
        )
    }

    private var addEduForm: some View {
        VStack(spacing: 10) {
            ForioTextField(label: "Degree / Qualification",
                           placeholder: "BSc Computer Science", text: $viewModel.newDegree)
            ForioTextField(label: "Institution",
                           placeholder: "University of Birmingham", text: $viewModel.newInstitution)
            HStack(spacing: 10) {
                ForioTextField(label: "Year", placeholder: "2024",
                               text: $viewModel.newGradYear, keyboardType: .numberPad)
                ForioTextField(label: "Grade", placeholder: "2:1",
                               text: $viewModel.newGrade, isOptional: true)
            }
            HStack(spacing: 10) {
                Button("Cancel") { showForm = false }
                    .buttonStyle(GhostButtonStyle())
                Button("Add") {
                    viewModel.addEducation()
                    showForm = false
                }
                .buttonStyle(GoldButtonStyle(isDisabled: viewModel.newDegree.isEmpty))
                .disabled(viewModel.newDegree.isEmpty || viewModel.newInstitution.isEmpty)
            }
        }
        .padding(14)
        .background(AppTheme.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                .stroke(AppTheme.goldBorder, lineWidth: 0.5)
        )
    }
}
