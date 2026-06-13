import SwiftUI
import SwiftData

// MARK: - ProfileEditView
// CV selector + independent section editing

struct ProfileEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CVProfile.updatedAt, order: .reverse) private var cvProfiles: [CVProfile]

    var onBack: (() -> Void)? = nil

    @State private var selectedCVId: UUID? = nil
    @State private var activeSheet: CVSection? = nil
    @State private var showAddCV = false

    private var selectedCV: CVProfile? {
        guard let id = selectedCVId else { return nil }
        return cvProfiles.first { $0.id == id }
    }

    var body: some View {
        ZStack {
            AppTheme.bgPrimary.ignoresSafeArea(.all)
            VStack(spacing: 0) {
                headerBar
                if cvProfiles.isEmpty {
                    emptyState
                } else {
                    cvSelectorRow
                    if let cv = selectedCV {
                        sectionList(cv: cv)
                    } else {
                        Spacer()
                        Text("Select a CV above to edit")
                            .font(.system(size: 14))
                            .foregroundStyle(AppTheme.textMuted)
                        Spacer()
                    }
                }
            }
        }
        .onAppear {
            if selectedCVId == nil, let first = cvProfiles.first {
                selectedCVId = first.id
            }
        }
        .sheet(item: $activeSheet) { section in
            if let cv = selectedCV {
                SectionEditSheet(cv: cv, section: section) {
                    cv.updatedAt = Date()
                    try? modelContext.save()
                }
            }
        }
        .sheet(isPresented: $showAddCV) {
            ScanAndNameCVView { newCV in
                selectedCVId = newCV.id
            }
        }
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack {
            Button(action: { onBack?() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppTheme.textSecond)
                    .frame(width: 32, height: 32)
                    .background(AppTheme.bgCard)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            Spacer()
            Text("Edit Profile")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(AppTheme.textPrimary)
            Spacer()
            Button(action: { showAddCV = true }) {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppTheme.gold)
                    .frame(width: 32, height: 32)
                    .background(AppTheme.goldFaint)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 60)
        .padding(.bottom, 16)
    }

    // MARK: - CV Selector

    private var cvSelectorRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("YOUR CVs")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(AppTheme.textDisabled)
                .kerning(0.5)
                .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(cvProfiles) { cv in
                        cvCard(cv)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 2)
            }
        }
        .padding(.bottom, 12)
    }

    private func cvCard(_ cv: CVProfile) -> some View {
        let isSelected = selectedCVId == cv.id
        return Button(action: {
            withAnimation(.easeOut(duration: 0.2)) { selectedCVId = cv.id }
        }) {
            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .top) {
                    Text(cv.name)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(isSelected ? AppTheme.gold : .white)
                        .lineLimit(2)
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(AppTheme.gold)
                    }
                }
                Spacer(minLength: 4)
                Text("\(cv.experience.count) roles · \(cv.skills.count) skills")
                    .font(.system(size: 10))
                    .foregroundStyle(AppTheme.textMuted)
                Text(cv.updatedAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: 9))
                    .foregroundStyle(AppTheme.textDisabled)
            }
            .padding(10)
            .frame(width: 110, height: 80)
            .background(isSelected ? AppTheme.goldFaint : AppTheme.bgCard)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected ? AppTheme.goldBorder : AppTheme.bgBorder,
                        lineWidth: isSelected ? 1 : 0.5))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Section list

    private func sectionList(cv: CVProfile) -> some View {
        ScrollView {
            VStack(spacing: 10) {
                // Selected CV summary header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(cv.name)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(AppTheme.textPrimary)
                        Text(cv.fullName.isEmpty ? "No name set" : cv.fullName)
                            .font(.system(size: 12))
                            .foregroundStyle(AppTheme.textMuted)
                    }
                    Spacer()
                    Text(cv.persona.emoji)
                        .font(.system(size: 20))
                }
                .padding(14)
                .background(AppTheme.bgCard)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
                .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                    .stroke(AppTheme.bgBorder, lineWidth: 0.5))

                // Section cards
                ForEach(CVSection.allCases, id: \.self) { section in
                    sectionCard(cv: cv, section: section)
                }

                // Delete CV option
                Button(action: { deleteCV(cv) }) {
                    HStack {
                        Image(systemName: "trash").font(.system(size: 13))
                        Text("Delete this CV")
                            .font(.system(size: 13))
                    }
                    .foregroundStyle(Color(hex: "ff4444"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color(hex: "0D1020"))
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
                    .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                        .stroke(Color(hex: "ff4444").opacity(0.3), lineWidth: 0.5))
                }
                .buttonStyle(.plain)
                .padding(.top, 8)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 60)
        }
    }

    private func sectionCard(cv: CVProfile, section: CVSection) -> some View {
        Button(action: { activeSheet = section }) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(AppTheme.goldFaint)
                        .frame(width: 36, height: 36)
                    Image(systemName: section.icon)
                        .font(.system(size: 14))
                        .foregroundStyle(AppTheme.gold)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(section.displayName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppTheme.textPrimary)
                    Text(section.preview(for: cv))
                        .font(.system(size: 11))
                        .foregroundStyle(AppTheme.textMuted)
                        .lineLimit(1)
                }
                Spacer()
                let count = section.itemCount(for: cv)
                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(AppTheme.gold)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(AppTheme.goldFaint)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 11))
                    .foregroundStyle(AppTheme.textDisabled)
            }
            .padding(14)
            .background(AppTheme.bgCard)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
            .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                .stroke(AppTheme.bgBorder, lineWidth: 0.5))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "doc.text")
                .font(.system(size: 40)).foregroundStyle(AppTheme.bgElevated)
            Text("No CVs yet")
                .font(.system(size: 18, weight: .medium)).foregroundStyle(AppTheme.textPrimary)
            Text("Add a CV to get started")
                .font(.system(size: 14)).foregroundStyle(AppTheme.textMuted)
            Button(action: { showAddCV = true }) {
                HStack { Image(systemName: "plus"); Text("Add a CV") }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppTheme.bgPrimary)
                    .padding(.horizontal, 24).padding(.vertical, 12)
                    .background(AppTheme.gold)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
            }
            Spacer()
        }
    }

    private func deleteCV(_ cv: CVProfile) {
        modelContext.delete(cv)
        try? modelContext.save()
        selectedCVId = cvProfiles.first?.id
    }
}

// MARK: - CVSection enum

enum CVSection: String, CaseIterable, Identifiable {
    case personalDetails, summary, experience, education, skills

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .personalDetails: return "Personal Details"
        case .summary:         return "Professional Summary"
        case .experience:      return "Work Experience"
        case .education:       return "Education"
        case .skills:          return "Skills"
        }
    }

    var icon: String {
        switch self {
        case .personalDetails: return "person.fill"
        case .summary:         return "text.alignleft"
        case .experience:      return "briefcase.fill"
        case .education:       return "graduationcap.fill"
        case .skills:          return "star.fill"
        }
    }

    func preview(for cv: CVProfile) -> String {
        switch self {
        case .personalDetails:
            return cv.email.isEmpty ? "Tap to add contact details" : cv.email
        case .summary:
            let s = cv.professionalSummary
            return s.isEmpty ? "Tap to add summary" : String(s.prefix(60)) + (s.count > 60 ? "…" : "")
        case .experience:
            guard !cv.experience.isEmpty else { return "No roles added" }
            let j = cv.experience[0]
            return "\(j.jobTitle) at \(j.company)"
        case .education:
            guard !cv.education.isEmpty else { return "No education added" }
            return cv.education[0].degree
        case .skills:
            return cv.skills.isEmpty ? "No skills added" : cv.skills.prefix(4).joined(separator: ", ")
        }
    }

    func itemCount(for cv: CVProfile) -> Int {
        switch self {
        case .personalDetails: return 0
        case .summary:         return cv.professionalSummary.isEmpty ? 0 : 1
        case .experience:      return cv.experience.count
        case .education:       return cv.education.count
        case .skills:          return cv.skills.count
        }
    }
}
