import SwiftUI
import SwiftData

// MARK: - SectionEditSheet
// Sheet-based independent section editor for CVProfile

struct SectionEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var cv: CVProfile
    let section: CVSection
    let onSave: () -> Void

    @State private var hasChanges = false
    @State private var showDiscardAlert = false

    var body: some View {
        ZStack {
            AppTheme.bgPrimary.ignoresSafeArea(.all)
            VStack(spacing: 0) {
                // Header — safe area aware
                HStack {
                    Button(action: {
                        if hasChanges { showDiscardAlert = true } else { dismiss() }
                    }) {
                        Text("Cancel")
                            .font(.system(size: 14))
                            .foregroundStyle(AppTheme.textMuted)
                    }
                    Spacer()
                    Text(section.displayName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppTheme.textPrimary)
                    Spacer()
                    Button(action: { onSave(); dismiss() }) {
                        Text("Save")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(AppTheme.bgPrimary)
                            .padding(.horizontal, 14).padding(.vertical, 6)
                            .background(AppTheme.gold)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 14)
                .background(AppTheme.bgPrimary)

                Divider().background(AppTheme.bgBorder)

                sectionContent
            }
        }
        .alert("Discard changes?", isPresented: $showDiscardAlert) {
            Button("Discard", role: .destructive) { dismiss() }
            Button("Keep editing", role: .cancel) {}
        } message: {
            Text("You have unsaved changes.")
        }
    }

    @ViewBuilder
    private var sectionContent: some View {
        switch section {
        case .personalDetails: PersonalDetailsEditor(cv: cv, hasChanges: $hasChanges)
        case .summary:         SummaryEditor(cv: cv, hasChanges: $hasChanges)
        case .experience:      ExperienceEditor(cv: cv, hasChanges: $hasChanges)
        case .education:       EducationEditor(cv: cv, hasChanges: $hasChanges)
        case .skills:          SkillsEditor(cv: cv, hasChanges: $hasChanges)
        }
    }
}

// MARK: - Personal Details Editor

struct PersonalDetailsEditor: View {
    @Bindable var cv: CVProfile
    @Binding var hasChanges: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                editField("Full Name",  placeholder: "e.g. Abel Aghorighor", value: $cv.fullName)
                editField("Email",      placeholder: "you@email.com",         value: $cv.email)
                editField("Phone",      placeholder: "+44 7700 000000",        value: $cv.phone)
                editField("Location",   placeholder: "London, UK",             value: $cv.location)
                editField("LinkedIn",   placeholder: "linkedin.com/in/…",      value: $cv.linkedIn)
                editField("Portfolio",  placeholder: "yoursite.com",           value: $cv.portfolio)
            }
            .padding(20)
        }
        .onChange(of: cv.fullName)   { hasChanges = true }
        .onChange(of: cv.email)      { hasChanges = true }
        .onChange(of: cv.phone)      { hasChanges = true }
        .onChange(of: cv.location)   { hasChanges = true }
        .onChange(of: cv.linkedIn)   { hasChanges = true }
        .onChange(of: cv.portfolio)  { hasChanges = true }
    }

    private func editField(_ label: String, placeholder: String, value: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label.uppercased())
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(AppTheme.textDisabled).kerning(0.4)
            TextField(placeholder, text: value)
                .font(.system(size: 14)).foregroundStyle(AppTheme.textPrimary)
                .padding(12).background(AppTheme.bgCard)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
                .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                    .stroke(AppTheme.bgBorder, lineWidth: 0.5))
        }
    }
}

// MARK: - Summary Editor

struct SummaryEditor: View {
    @Bindable var cv: CVProfile
    @Binding var hasChanges: Bool
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("PROFESSIONAL SUMMARY")
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(AppTheme.textDisabled).kerning(0.4)
                .padding(.horizontal, 20)
                .padding(.top, 16)

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                    .fill(AppTheme.bgCard)
                    .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                        .stroke(focused ? AppTheme.goldBorder : AppTheme.bgBorder, lineWidth: 0.5))
                if cv.professionalSummary.isEmpty {
                    Text("Write a 3-4 sentence professional summary…")
                        .font(.system(size: 13)).foregroundStyle(AppTheme.textDisabled)
                        .padding(14).allowsHitTesting(false)
                }
                TextEditor(text: $cv.professionalSummary)
                    .font(.system(size: 13)).foregroundStyle(AppTheme.textPrimary)
                    .scrollContentBackground(.hidden).background(Color.clear)
                    .padding(10).focused($focused)
                    .frame(minHeight: 200)
            }
            .padding(.horizontal, 20)

            Text("\(cv.professionalSummary.count) characters")
                .font(.system(size: 10)).foregroundStyle(AppTheme.textDisabled)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.horizontal, 20)

            Spacer()
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .onChange(of: cv.professionalSummary) { hasChanges = true }
        .onAppear { focused = true }
    }
}

// MARK: - Experience Editor

struct ExperienceEditor: View {
    @Bindable var cv: CVProfile
    @Binding var hasChanges: Bool
    @State private var showAddForm = false
    @State private var editingJob: WorkExperience? = nil

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                if cv.experience.isEmpty {
                    emptyBanner(icon: "briefcase", text: "No roles added yet")
                } else {
                    ForEach(cv.experience) { job in
                        experienceCard(job)
                    }
                }
                addBanner(label: "Add role") { showAddForm = true }
            }
            .padding(20)
        }
        .sheet(isPresented: $showAddForm) {
            JobEntryForm(job: nil) { newJob in
                cv.experience.append(newJob)
                hasChanges = true
            }
        }
        .sheet(item: $editingJob) { job in
            JobEntryForm(job: job) { updated in
                if let idx = cv.experience.firstIndex(where: { $0.id == updated.id }) {
                    cv.experience[idx] = updated
                    hasChanges = true
                }
            }
        }
    }

    private func experienceCard(_ job: WorkExperience) -> some View {
        HStack(alignment: .top, spacing: 10) {
            // Text content with right padding so it never runs under icons
            VStack(alignment: .leading, spacing: 4) {
                Text(job.jobTitle)
                    .font(.system(size: 13, weight: .semibold)).foregroundStyle(AppTheme.textPrimary)
                Text(job.company)
                    .font(.system(size: 12)).foregroundStyle(AppTheme.gold)
                Text("\(job.startDate) – \(job.endDate)")
                    .font(.system(size: 11)).foregroundStyle(AppTheme.textMuted)
                if !job.description.isEmpty {
                    Text(job.description)
                        .font(.system(size: 10)).foregroundStyle(AppTheme.textDisabled)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Action icons — horizontal, fixed width
            HStack(spacing: 12) {
                Button(action: { editingJob = job }) {
                    Image(systemName: "pencil")
                        .font(.system(size: 14))
                        .foregroundStyle(AppTheme.gold)
                }
                Button(action: {
                    cv.experience.removeAll { $0.id == job.id }
                    hasChanges = true
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                        .foregroundStyle(Color(hex: "ff4444"))
                }
            }
            .padding(.top, 2)
        }
        .padding(14)
        .background(AppTheme.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
        .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusMd)
            .stroke(AppTheme.bgBorder, lineWidth: 0.5))
    }
}

// MARK: - Education Editor

struct EducationEditor: View {
    @Bindable var cv: CVProfile
    @Binding var hasChanges: Bool
    @State private var showAddForm = false
    @State private var editingEdu: Education? = nil

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                if cv.education.isEmpty {
                    emptyBanner(icon: "graduationcap", text: "No education added yet")
                } else {
                    ForEach(cv.education) { edu in
                        educationCard(edu)
                    }
                }
                addBanner(label: "Add qualification") { showAddForm = true }
            }
            .padding(20)
        }
        .sheet(isPresented: $showAddForm) {
            EduEntryForm(edu: nil) { newEdu in
                cv.education.append(newEdu)
                hasChanges = true
            }
        }
        .sheet(item: $editingEdu) { edu in
            EduEntryForm(edu: edu) { updated in
                if let idx = cv.education.firstIndex(where: { $0.id == updated.id }) {
                    cv.education[idx] = updated
                    hasChanges = true
                }
            }
        }
    }

    private func educationCard(_ edu: Education) -> some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text(edu.degree)
                    .font(.system(size: 13, weight: .semibold)).foregroundStyle(AppTheme.textPrimary)
                if !edu.institution.isEmpty {
                    Text(edu.institution)
                        .font(.system(size: 12)).foregroundStyle(AppTheme.gold)
                }
                if !edu.graduationYear.isEmpty {
                    Text("\(edu.graduationYear)\(edu.grade.isEmpty ? "" : " · \(edu.grade)")")
                        .font(.system(size: 11)).foregroundStyle(AppTheme.textMuted)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 12) {
                Button(action: { editingEdu = edu }) {
                    Image(systemName: "pencil")
                        .font(.system(size: 14)).foregroundStyle(AppTheme.gold)
                }
                Button(action: {
                    cv.education.removeAll { $0.id == edu.id }
                    hasChanges = true
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 14)).foregroundStyle(Color(hex: "ff4444"))
                }
            }
            .padding(.top, 2)
        }
        .padding(14)
        .background(AppTheme.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
        .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusMd)
            .stroke(AppTheme.bgBorder, lineWidth: 0.5))
    }
}

// MARK: - Skills Editor

struct SkillsEditor: View {
    @Bindable var cv: CVProfile
    @Binding var hasChanges: Bool
    @State private var newSkill = ""
    @FocusState private var fieldFocused: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                // Add skill row
                HStack(spacing: 8) {
                    TextField("Add a skill…", text: $newSkill)
                        .font(.system(size: 14)).foregroundStyle(AppTheme.textPrimary)
                        .padding(12).background(AppTheme.bgCard)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
                        .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                            .stroke(fieldFocused ? AppTheme.goldBorder : AppTheme.bgBorder, lineWidth: 0.5))
                        .focused($fieldFocused)
                        .onSubmit { addSkill() }
                    Button(action: addSkill) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(newSkill.isEmpty ? AppTheme.bgElevated : AppTheme.gold)
                    }
                    .disabled(newSkill.isEmpty)
                }

                // Skill chips
                if cv.skills.isEmpty {
                    Text("No skills added yet")
                        .font(.system(size: 13)).foregroundStyle(AppTheme.textMuted)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 16)
                } else {
                    FlowLayout(spacing: 8) {
                        ForEach(cv.skills, id: \.self) { skill in
                            HStack(spacing: 5) {
                                Text(skill)
                                    .font(.system(size: 12, weight: .medium)).foregroundStyle(AppTheme.gold)
                                Button(action: {
                                    cv.skills.removeAll { $0 == skill }
                                    hasChanges = true
                                }) {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundStyle(AppTheme.textMuted)
                                }
                            }
                            .padding(.horizontal, 10).padding(.vertical, 5)
                            .background(AppTheme.goldFaint)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .overlay(RoundedRectangle(cornerRadius: 20)
                                .stroke(AppTheme.goldBorder, lineWidth: 0.5))
                        }
                    }
                }
                Text("\(cv.skills.count) skills")
                    .font(.system(size: 10)).foregroundStyle(AppTheme.textDisabled)
            }
            .padding(20)
        }
    }

    private func addSkill() {
        let s = newSkill.trimmingCharacters(in: .whitespaces)
        guard !s.isEmpty, !cv.skills.contains(s) else { return }
        cv.skills.append(s); hasChanges = true; newSkill = ""
    }
}

// MARK: - Shared helpers

private func emptyBanner(icon: String, text: String) -> some View {
    VStack(spacing: 8) {
        Image(systemName: icon).font(.system(size: 28)).foregroundStyle(AppTheme.bgElevated)
        Text(text).font(.system(size: 13)).foregroundStyle(AppTheme.textMuted)
    }
    .frame(maxWidth: .infinity).padding(.vertical, 20)
    .background(AppTheme.bgCard)
    .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
}

private func addBanner(label: String, action: @escaping () -> Void) -> some View {
    Button(action: action) {
        HStack(spacing: 6) {
            Image(systemName: "plus.circle.fill")
            Text(label)
        }
        .font(.system(size: 13, weight: .semibold)).foregroundStyle(AppTheme.gold)
        .frame(maxWidth: .infinity).padding(.vertical, 12)
        .background(AppTheme.goldFaint)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
        .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusMd)
            .stroke(AppTheme.goldBorder, lineWidth: 0.5))
    }
    .buttonStyle(.plain)
}

// MARK: - Job Entry Form (keyboard-aware)

struct JobEntryForm: View {
    @Environment(\.dismiss) private var dismiss
    let job: WorkExperience?
    let onSave: (WorkExperience) -> Void

    @State private var title = ""
    @State private var company = ""
    @State private var startDate = ""
    @State private var endDate = ""
    @State private var isCurrent = false
    @State private var description = ""

    var body: some View {
        ZStack {
            AppTheme.bgPrimary.ignoresSafeArea(.all)
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button("Cancel") { dismiss() }
                        .font(.system(size: 14)).foregroundStyle(AppTheme.textMuted)
                    Spacer()
                    Text(job == nil ? "Add Role" : "Edit Role")
                        .font(.system(size: 15, weight: .semibold)).foregroundStyle(AppTheme.textPrimary)
                    Spacer()
                    Button("Save") {
                        let j = WorkExperience(
                            id: job?.id ?? UUID(),
                            jobTitle: title, company: company,
                            startDate: startDate,
                            endDate: isCurrent ? "Present" : endDate,
                            isCurrent: isCurrent, description: description
                        )
                        onSave(j); dismiss()
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(title.isEmpty || company.isEmpty ? AppTheme.textDisabled : AppTheme.bgPrimary)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(title.isEmpty || company.isEmpty ? AppTheme.bgElevated : AppTheme.gold)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .disabled(title.isEmpty || company.isEmpty)
                }
                .padding(.horizontal, 20).padding(.top, 20).padding(.bottom, 14)

                Divider().background(AppTheme.bgBorder)

                // Keyboard-aware scroll
                ScrollView {
                    VStack(spacing: 12) {
                        formField("Job Title",  ph: "e.g. iOS Developer",  v: $title)
                        formField("Company",    ph: "e.g. Aviva",           v: $company)
                        HStack(spacing: 10) {
                            formField("From", ph: "e.g. 08/2024", v: $startDate)
                            if !isCurrent { formField("To", ph: "e.g. 03/2025", v: $endDate) }
                        }
                        Toggle(isOn: $isCurrent) {
                            Text("I currently work here")
                                .font(.system(size: 13)).foregroundStyle(AppTheme.textPrimary)
                        }.tint(AppTheme.gold)

                        VStack(alignment: .leading, spacing: 5) {
                            Text("KEY ACHIEVEMENTS")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundStyle(AppTheme.textDisabled).kerning(0.4)
                            TextEditor(text: $description)
                                .font(.system(size: 13)).foregroundStyle(AppTheme.textPrimary)
                                .scrollContentBackground(.hidden)
                                .padding(10)
                                .frame(minHeight: 120)
                                .background(AppTheme.bgCard)
                                .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
                                .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                                    .stroke(AppTheme.bgBorder, lineWidth: 0.5))
                        }
                        // Bottom padding so keyboard doesn't hide content
                        Color.clear.frame(height: 120)
                    }
                    .padding(20)
                }
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onAppear {
            if let j = job {
                title = j.jobTitle; company = j.company
                startDate = j.startDate; endDate = j.endDate
                isCurrent = j.isCurrent; description = j.description
            }
        }
    }

    private func formField(_ label: String, ph: String, v: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label.uppercased())
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(AppTheme.textDisabled).kerning(0.4)
            TextField(ph, text: v)
                .font(.system(size: 14)).foregroundStyle(AppTheme.textPrimary)
                .padding(12).background(AppTheme.bgCard)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
                .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                    .stroke(AppTheme.bgBorder, lineWidth: 0.5))
        }
    }
}

// MARK: - Education Entry Form

struct EduEntryForm: View {
    @Environment(\.dismiss) private var dismiss
    let edu: Education?
    let onSave: (Education) -> Void

    @State private var degree = ""
    @State private var institution = ""
    @State private var year = ""
    @State private var grade = ""

    var body: some View {
        ZStack {
            AppTheme.bgPrimary.ignoresSafeArea(.all)
            VStack(spacing: 0) {
                HStack {
                    Button("Cancel") { dismiss() }
                        .font(.system(size: 14)).foregroundStyle(AppTheme.textMuted)
                    Spacer()
                    Text(edu == nil ? "Add Education" : "Edit Education")
                        .font(.system(size: 15, weight: .semibold)).foregroundStyle(AppTheme.textPrimary)
                    Spacer()
                    Button("Save") {
                        onSave(Education(id: edu?.id ?? UUID(),
                                         degree: degree, institution: institution,
                                         graduationYear: year, grade: grade))
                        dismiss()
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(degree.isEmpty ? AppTheme.textDisabled : AppTheme.bgPrimary)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(degree.isEmpty ? AppTheme.bgElevated : AppTheme.gold)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .disabled(degree.isEmpty)
                }
                .padding(.horizontal, 20).padding(.top, 20).padding(.bottom, 14)

                Divider().background(AppTheme.bgBorder)

                ScrollView {
                    VStack(spacing: 12) {
                        eduField("Degree / Qualification", ph: "e.g. BSc Computer Science", v: $degree)
                        eduField("Institution",            ph: "University of…",              v: $institution)
                        HStack(spacing: 10) {
                            eduField("Year",  ph: "2024", v: $year)
                            eduField("Grade", ph: "2:1",  v: $grade)
                        }
                        Color.clear.frame(height: 60)
                    }
                    .padding(20)
                }
            }
        }
        .onAppear {
            if let e = edu {
                degree = e.degree; institution = e.institution
                year = e.graduationYear; grade = e.grade
            }
        }
    }

    private func eduField(_ label: String, ph: String, v: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label.uppercased())
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(AppTheme.textDisabled).kerning(0.4)
            TextField(ph, text: v)
                .font(.system(size: 14)).foregroundStyle(AppTheme.textPrimary)
                .padding(12).background(AppTheme.bgCard)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
                .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                    .stroke(AppTheme.bgBorder, lineWidth: 0.5))
        }
    }
}
