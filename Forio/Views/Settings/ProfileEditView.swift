import SwiftUI
import SwiftData

struct ProfileEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var profile: UserProfile

    @State private var showExperienceForm = false
    @State private var showEducationForm = false
    @State private var newSkillText = ""

    // Temp experience form
    @State private var newJobTitle = ""
    @State private var newCompany = ""
    @State private var newStartDate = ""
    @State private var newEndDate = ""
    @State private var newIsCurrent = false
    @State private var newJobDesc = ""

    // Temp education form
    @State private var newDegree = ""
    @State private var newInstitution = ""
    @State private var newGradYear = ""
    @State private var newGrade = ""

    var body: some View {
        ZStack {
            AppTheme.bgPrimary.ignoresSafeArea(.all)

            VStack(spacing: 0) {
                headerBar

                ScrollView {
                    VStack(spacing: 20) {
                        personaSection
                        basicInfoSection
                        experienceSection
                        educationSection
                        skillsSection
                        summarySection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 60)
                }
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .foregroundStyle(AppTheme.textMuted)
                    .frame(width: 32, height: 32)
                    .background(AppTheme.bgCard)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            Spacer()
            Text("Edit Profile")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(AppTheme.textPrimary)
            Spacer()
            Button("Save") {
                profile.updatedAt = Date()
                try? modelContext.save()
                dismiss()
            }
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(AppTheme.gold)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 16)
    }

    // MARK: - Persona section

    private var personaSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("I am")
            HStack(spacing: 8) {
                ForEach(UserPersona.allCases, id: \.self) { p in
                    Button(action: { profile.persona = p }) {
                        VStack(spacing: 4) {
                            Text(p.emoji).font(.system(size: 18))
                            Text(p.displayName.components(separatedBy: " ").first ?? "")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundStyle(profile.persona == p
                                                 ? AppTheme.gold : AppTheme.textMuted)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(profile.persona == p ? AppTheme.goldFaint : AppTheme.bgCard)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                                .stroke(profile.persona == p ? AppTheme.goldBorder : AppTheme.bgBorder,
                                        lineWidth: profile.persona == p ? 1.0 : 0.5)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            // Career changer extra fields
            if profile.persona == .careerChanger {
                HStack(spacing: 10) {
                    editField(label: "From", placeholder: "e.g. Finance",
                              value: $profile.fromField)
                    Image(systemName: "arrow.right")
                        .foregroundStyle(AppTheme.gold)
                    editField(label: "Into", placeholder: "e.g. Design",
                              value: $profile.toField)
                }
            }

            // Gap reason
            if profile.persona == .returning {
                VStack(alignment: .leading, spacing: 6) {
                    sectionLabel("Gap reason")
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(GapReason.allCases, id: \.self) { reason in
                                Button(action: { profile.gapReason = reason }) {
                                    Text(reason.rawValue)
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundStyle(profile.gapReason == reason
                                                         ? AppTheme.gold : AppTheme.textMuted)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(profile.gapReason == reason
                                                    ? AppTheme.goldFaint : AppTheme.bgCard)
                                        .clipShape(RoundedRectangle(cornerRadius: 20))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 20)
                                                .stroke(profile.gapReason == reason
                                                        ? AppTheme.goldBorder : AppTheme.bgBorder,
                                                        lineWidth: 0.5)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(AppTheme.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                .stroke(AppTheme.bgBorder, lineWidth: 0.5)
        )
    }

    // MARK: - Basic info

    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Basic info")
            editField(label: "Full Name",      placeholder: "Your full name",    value: $profile.fullName)
            editField(label: "Email",          placeholder: "you@email.com",     value: $profile.email)
            editField(label: "Phone",          placeholder: "+44 7700 000000",   value: $profile.phone)
            editField(label: "Location",       placeholder: "London, UK",        value: $profile.location)
            editField(label: "LinkedIn",       placeholder: "linkedin.com/in/…", value: $profile.linkedIn)
            editField(label: "Portfolio",      placeholder: "yoursite.com",      value: $profile.portfolio)
        }
        .padding(16)
        .background(AppTheme.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                .stroke(AppTheme.bgBorder, lineWidth: 0.5)
        )
    }

    // MARK: - Experience

    private var experienceSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                sectionLabel("Work experience")
                Spacer()
                Text("\(profile.experience.count) roles")
                    .font(.system(size: 11))
                    .foregroundStyle(AppTheme.textMuted)
            }

            ForEach(profile.experience) { job in
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(job.jobTitle)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(AppTheme.textPrimary)
                        Text(job.company)
                            .font(.system(size: 12))
                            .foregroundStyle(AppTheme.gold)
                        Text("\(job.startDate) – \(job.endDate)")
                            .font(.system(size: 11))
                            .foregroundStyle(AppTheme.textMuted)
                    }
                    Spacer()
                    Button(action: {
                        var exp = profile.experience
                        exp.removeAll { $0.id == job.id }
                        profile.experience = exp
                    }) {
                        Image(systemName: "trash")
                            .font(.system(size: 12))
                            .foregroundStyle(AppTheme.textDisabled)
                    }
                }
                .padding(12)
                .background(AppTheme.bgElevated)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            if showExperienceForm {
                addExperienceForm
            } else {
                addButton(label: "Add role") { showExperienceForm = true }
            }
        }
        .padding(16)
        .background(AppTheme.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                .stroke(AppTheme.bgBorder, lineWidth: 0.5)
        )
    }

    // MARK: - Education

    private var educationSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Education")

            ForEach(profile.education) { edu in
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(edu.degree)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(AppTheme.textPrimary)
                        Text(edu.institution)
                            .font(.system(size: 12))
                            .foregroundStyle(AppTheme.gold)
                        Text("\(edu.graduationYear)\(edu.grade.isEmpty ? "" : " · \(edu.grade)")")
                            .font(.system(size: 11))
                            .foregroundStyle(AppTheme.textMuted)
                    }
                    Spacer()
                    Button(action: {
                        var eds = profile.education
                        eds.removeAll { $0.id == edu.id }
                        profile.education = eds
                    }) {
                        Image(systemName: "trash")
                            .font(.system(size: 12))
                            .foregroundStyle(AppTheme.textDisabled)
                    }
                }
                .padding(12)
                .background(AppTheme.bgElevated)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            if showEducationForm {
                addEducationForm
            } else {
                addButton(label: "Add qualification") { showEducationForm = true }
            }
        }
        .padding(16)
        .background(AppTheme.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                .stroke(AppTheme.bgBorder, lineWidth: 0.5)
        )
    }

    // MARK: - Skills

    private var skillsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Skills · \(profile.skills.count)")

            FlowLayout(spacing: 6) {
                ForEach(profile.skills, id: \.self) { skill in
                    HStack(spacing: 4) {
                        Text(skill)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(AppTheme.gold)
                        Button(action: {
                            var s = profile.skills
                            s.removeAll { $0 == skill }
                            profile.skills = s
                        }) {
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
            }

            HStack(spacing: 8) {
                TextField("Add a skill", text: $newSkillText)
                    .font(.system(size: 13))
                    .foregroundStyle(AppTheme.textPrimary)
                    .padding(10)
                    .background(AppTheme.bgElevated)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .onSubmit { addSkill() }
                Button(action: addSkill) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(newSkillText.isEmpty ? AppTheme.textDisabled : AppTheme.gold)
                }
                .disabled(newSkillText.isEmpty)
            }
        }
        .padding(16)
        .background(AppTheme.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                .stroke(AppTheme.bgBorder, lineWidth: 0.5)
        )
    }

    // MARK: - Summary

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Professional summary")
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(AppTheme.bgElevated)
                if profile.professionalSummary.isEmpty {
                    Text("A short paragraph about yourself…")
                        .font(.system(size: 13))
                        .foregroundStyle(AppTheme.textDisabled)
                        .padding(12)
                        .allowsHitTesting(false)
                }
                TextEditor(text: $profile.professionalSummary)
                    .font(.system(size: 13))
                    .foregroundStyle(AppTheme.textPrimary)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .padding(8)
                    .frame(minHeight: 100)
            }
        }
        .padding(16)
        .background(AppTheme.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                .stroke(AppTheme.bgBorder, lineWidth: 0.5)
        )
    }

    // MARK: - Add experience form

    private var addExperienceForm: some View {
        VStack(spacing: 10) {
            editField(label: "Job Title",    placeholder: "e.g. iOS Developer", value: $newJobTitle)
            editField(label: "Company",      placeholder: "e.g. Suftnet Ltd",   value: $newCompany)
            HStack(spacing: 10) {
                editField(label: "From", placeholder: "Sep 2022", value: $newStartDate)
                if !newIsCurrent {
                    editField(label: "To", placeholder: "Present", value: $newEndDate)
                }
            }
            Toggle(isOn: $newIsCurrent) {
                Text("I currently work here")
                    .font(.system(size: 13))
                    .foregroundStyle(AppTheme.textSecond)
            }.tint(AppTheme.gold)

            HStack(spacing: 10) {
                Button("Cancel") { showExperienceForm = false }
                    .buttonStyle(GhostButtonStyle())
                Button("Add") {
                    guard !newJobTitle.isEmpty, !newCompany.isEmpty else { return }
                    var exp = profile.experience
                    exp.append(WorkExperience(
                        jobTitle: newJobTitle, company: newCompany,
                        startDate: newStartDate,
                        endDate: newIsCurrent ? "Present" : newEndDate,
                        isCurrent: newIsCurrent, description: ""
                    ))
                    profile.experience = exp
                    newJobTitle = ""; newCompany = ""
                    newStartDate = ""; newEndDate = ""
                    newIsCurrent = false
                    showExperienceForm = false
                }
                .buttonStyle(GoldButtonStyle(isDisabled: newJobTitle.isEmpty))
                .disabled(newJobTitle.isEmpty || newCompany.isEmpty)
            }
        }
        .padding(12)
        .background(AppTheme.bgElevated)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Add education form

    private var addEducationForm: some View {
        VStack(spacing: 10) {
            editField(label: "Degree",      placeholder: "BSc Computer Science", value: $newDegree)
            editField(label: "Institution", placeholder: "University of …",      value: $newInstitution)
            HStack(spacing: 10) {
                editField(label: "Year",  placeholder: "2024", value: $newGradYear)
                editField(label: "Grade", placeholder: "2:1",  value: $newGrade)
            }
            HStack(spacing: 10) {
                Button("Cancel") { showEducationForm = false }
                    .buttonStyle(GhostButtonStyle())
                Button("Add") {
                    guard !newDegree.isEmpty, !newInstitution.isEmpty else { return }
                    var eds = profile.education
                    eds.append(Education(
                        degree: newDegree, institution: newInstitution,
                        graduationYear: newGradYear, grade: newGrade
                    ))
                    profile.education = eds
                    newDegree = ""; newInstitution = ""
                    newGradYear = ""; newGrade = ""
                    showEducationForm = false
                }
                .buttonStyle(GoldButtonStyle(isDisabled: newDegree.isEmpty))
                .disabled(newDegree.isEmpty || newInstitution.isEmpty)
            }
        }
        .padding(12)
        .background(AppTheme.bgElevated)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(AppTheme.textMuted)
            .kerning(0.5)
    }

    private func editField(label: String, placeholder: String, value: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(AppTheme.textDisabled)
                .kerning(0.4)
            TextField(placeholder, text: value)
                .font(.system(size: 14))
                .foregroundStyle(AppTheme.textPrimary)
                .padding(10)
                .background(AppTheme.bgElevated)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private func addButton(label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: "plus.circle.fill").foregroundStyle(AppTheme.gold)
                Text(label).font(.system(size: 13, weight: .medium)).foregroundStyle(AppTheme.gold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(AppTheme.goldFaint)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppTheme.goldBorder, lineWidth: 0.5))
        }
        .buttonStyle(.plain)
    }

    private func addSkill() {
        let t = newSkillText.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty, !profile.skills.contains(t) else { return }
        var s = profile.skills; s.append(t); profile.skills = s
        newSkillText = ""
    }
}
