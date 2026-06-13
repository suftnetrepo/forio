import SwiftUI

struct CVReviewView: View {
    @Bindable var viewModel: CVImportViewModel
    var onConfirm: () -> Void

    @State private var expandedSection: ReviewSection? = .contact
    @State private var showAddSkill = false

    enum ReviewSection: String, CaseIterable {
        case contact    = "Contact details"
        case experience = "Work experience"
        case education  = "Education"
        case skills     = "Skills"
    }

    var extractedCount: Int {
        var count = 0
        if !viewModel.reviewName.isEmpty     { count += 1 }
        if !viewModel.reviewEmail.isEmpty    { count += 1 }
        if !viewModel.reviewLocation.isEmpty { count += 1 }
        if !viewModel.reviewExperience.isEmpty { count += viewModel.reviewExperience.count }
        if !viewModel.reviewEducation.isEmpty  { count += viewModel.reviewEducation.count }
        if !viewModel.reviewSkills.isEmpty     { count += 1 }
        return count
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Review your profile")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(AppTheme.textPrimary)
                    Text("Tap any section to edit")
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.textMuted)
                }
                Spacer()
                // AI badge
                HStack(spacing: 4) {
                    Text("✦")
                        .font(.system(size: 9))
                    Text("AI read")
                        .font(.system(size: 10, weight: .semibold))
                }
                .foregroundStyle(AppTheme.gold)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(AppTheme.goldFaint)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(AppTheme.goldBorder, lineWidth: 0.5)
                )
            }
            .padding(.horizontal, 20)
            .padding(.top, 60)
            .padding(.bottom, 16)

            // AI summary banner
            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(AppTheme.success)
                Text("\(extractedCount) fields extracted · Tap to review each section")
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.textMuted)
                Spacer()
            }
            .padding(12)
            .background(AppTheme.successFaint)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                    .stroke(AppTheme.success.opacity(0.2), lineWidth: 0.5)
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 12)

            ScrollView {
                VStack(spacing: 8) {
                    contactSection
                    experienceSection
                    educationSection
                    skillsSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 120)
            }

            // Confirm button
            VStack {
                Spacer()
                VStack(spacing: 8) {
                    Button("Confirm & continue  →", action: onConfirm)
                        .buttonStyle(GoldButtonStyle())

                    Button("Re-import") {
                        viewModel.reset()
                    }
                    .font(.system(size: 13))
                    .foregroundStyle(AppTheme.textMuted)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
                .background(
                    LinearGradient(
                        colors: [AppTheme.bgPrimary.opacity(0), AppTheme.bgPrimary],
                        startPoint: .top, endPoint: .bottom
                    )
                    .ignoresSafeArea()
                )
            }
            .frame(height: 130)
        }
        .safeAreaPadding(.top)
    }

    // MARK: - Contact section

    private var contactSection: some View {
        reviewSection(title: "Contact details", icon: "person.fill", section: .contact) {
            VStack(spacing: 8) {
                editableField(label: "Full Name",  value: $viewModel.reviewName,     placeholder: "Your full name")
                editableField(label: "Email",      value: $viewModel.reviewEmail,    placeholder: "email@example.com")
                editableField(label: "Phone",      value: $viewModel.reviewPhone,    placeholder: "+44 7700 000000")
                editableField(label: "Location",   value: $viewModel.reviewLocation, placeholder: "London, UK")
                editableField(label: "LinkedIn",   value: $viewModel.reviewLinkedIn, placeholder: "linkedin.com/in/yourname")
                editableField(label: "Portfolio",  value: $viewModel.reviewPortfolio,placeholder: "yoursite.com")
            }
        }
    }

    // MARK: - Experience section

    private var experienceSection: some View {
        reviewSection(
            title: "Work experience",
            icon: "briefcase.fill",
            section: .experience,
            badge: "\(viewModel.reviewExperience.count) roles"
        ) {
            VStack(spacing: 8) {
                if viewModel.reviewExperience.isEmpty {
                    emptyState("No experience found", "You can add it manually in your profile later")
                } else {
                    ForEach($viewModel.reviewExperience) { $job in
                        experienceCard($job)
                    }
                }
            }
        }
    }

    // MARK: - Education section

    private var educationSection: some View {
        reviewSection(
            title: "Education",
            icon: "graduationcap.fill",
            section: .education,
            badge: "\(viewModel.reviewEducation.count) entries"
        ) {
            VStack(spacing: 8) {
                if viewModel.reviewEducation.isEmpty {
                    emptyState("No education found", "You can add it manually in your profile later")
                } else {
                    ForEach($viewModel.reviewEducation) { $edu in
                        educationCard($edu)
                    }
                }
            }
        }
    }

    // MARK: - Skills section

    private var skillsSection: some View {
        reviewSection(
            title: "Skills",
            icon: "star.fill",
            section: .skills,
            badge: "\(viewModel.reviewSkills.count) skills"
        ) {
            VStack(alignment: .leading, spacing: 10) {
                FlowLayout(spacing: 6) {
                    ForEach(viewModel.reviewSkills, id: \.self) { skill in
                        skillChip(skill)
                    }
                    addSkillChip
                }

                if showAddSkill {
                    HStack(spacing: 8) {
                        TextField("Add a skill", text: $viewModel.newSkillText)
                            .font(.system(size: 13))
                            .foregroundStyle(AppTheme.textPrimary)
                            .padding(10)
                            .background(AppTheme.bgElevated)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .onSubmit {
                                viewModel.addSkill(viewModel.newSkillText)
                                showAddSkill = false
                            }
                        Button("Add") {
                            viewModel.addSkill(viewModel.newSkillText)
                            showAddSkill = false
                        }
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(AppTheme.gold)
                    }
                }
            }
        }
    }

    // MARK: - Reusable review section

    private func reviewSection<Content: View>(
        title: String,
        icon: String,
        section: ReviewSection,
        badge: String? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        let isExpanded = expandedSection == section
        return VStack(spacing: 0) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.25)) {
                    expandedSection = isExpanded ? nil : section
                }
            }) {
                HStack(spacing: 10) {
                    Image(systemName: icon)
                        .font(.system(size: 13))
                        .foregroundStyle(AppTheme.gold)
                        .frame(width: 24)
                    Text(title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppTheme.textPrimary)
                    Spacer()
                    if let badge {
                        Text(badge)
                            .font(.system(size: 10))
                            .foregroundStyle(AppTheme.textMuted)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(AppTheme.bgElevated)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11))
                        .foregroundStyle(AppTheme.textMuted)
                }
                .padding(14)
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(spacing: 0) {
                    Divider().background(AppTheme.bgElevated)
                    content()
                        .padding(14)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(AppTheme.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                .stroke(isExpanded ? AppTheme.goldBorder : AppTheme.bgBorder, lineWidth: 0.5)
        )
    }

    // MARK: - Sub-components

    private func editableField(label: String, value: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(AppTheme.textMuted)
                .textCase(.uppercase)
                .kerning(0.5)
            TextField(placeholder, text: value)
                .font(.system(size: 13))
                .foregroundStyle(AppTheme.textPrimary)
                .padding(10)
                .background(AppTheme.bgElevated)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private func experienceCard(_ job: Binding<WorkExperience>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            TextField("Job title", text: job.jobTitle)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppTheme.textPrimary)
            TextField("Company", text: job.company)
                .font(.system(size: 12))
                .foregroundStyle(AppTheme.gold)
            HStack(spacing: 6) {
                TextField("Start", text: job.startDate)
                    .font(.system(size: 11))
                    .foregroundStyle(AppTheme.textMuted)
                Text("–")
                    .foregroundStyle(AppTheme.textMuted)
                TextField("End / Present", text: job.endDate)
                    .font(.system(size: 11))
                    .foregroundStyle(AppTheme.textMuted)
            }
            TextField("Description", text: job.description, axis: .vertical)
                .font(.system(size: 11))
                .foregroundStyle(AppTheme.textSecond)
                .lineLimit(3...6)
        }
        .padding(12)
        .background(AppTheme.bgElevated)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func educationCard(_ edu: Binding<Education>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            TextField("Degree", text: edu.degree)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppTheme.textPrimary)
            TextField("Institution", text: edu.institution)
                .font(.system(size: 12))
                .foregroundStyle(AppTheme.gold)
            HStack(spacing: 12) {
                TextField("Year", text: edu.graduationYear)
                    .font(.system(size: 11))
                    .foregroundStyle(AppTheme.textMuted)
                TextField("Grade (e.g. 2:1)", text: edu.grade)
                    .font(.system(size: 11))
                    .foregroundStyle(AppTheme.textMuted)
            }
        }
        .padding(12)
        .background(AppTheme.bgElevated)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func skillChip(_ skill: String) -> some View {
        HStack(spacing: 4) {
            Text(skill)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(AppTheme.gold)
            Button(action: { viewModel.removeSkill(skill) }) {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(AppTheme.textMuted)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(AppTheme.goldFaint)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(AppTheme.goldBorder, lineWidth: 0.5)
        )
    }

    private var addSkillChip: some View {
        Button(action: { showAddSkill.toggle() }) {
            HStack(spacing: 4) {
                Image(systemName: "plus")
                    .font(.system(size: 10, weight: .bold))
                Text("Add skill")
                    .font(.system(size: 12))
            }
            .foregroundStyle(AppTheme.textMuted)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(AppTheme.bgElevated)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(AppTheme.bgBorder, lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }

    private func emptyState(_ title: String, _ subtitle: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppTheme.textMuted)
            Text(subtitle)
                .font(.system(size: 11))
                .foregroundStyle(AppTheme.textDisabled)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }
}

// MARK: - Simple flow layout for skill chips

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        var height: CGFloat = 0
        var x: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > width, x > 0 {
                height += rowHeight + spacing
                x = 0
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        height += rowHeight
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                y += rowHeight + spacing
                x = bounds.minX
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
