import SwiftUI
import SwiftData

// MARK: - Application Detail Sheet (used by both Tracker and History)

struct ApplicationDetailSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var notesText: String = ""
    @State private var interviewDate: Date = Date()

    let application: JobApplication

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.bgPrimary.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {

                        // Hero
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 8) {
                                Text(application.status.emoji).font(.system(size: 16))
                                Text(application.status.displayName)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(application.status.color)
                            }
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .background(application.status.color.opacity(0.1))
                            .clipShape(Capsule())

                            Text(application.company.isEmpty ? "Company" : application.company)
                                .font(.system(size: 28, weight: .bold))
                                .foregroundStyle(AppTheme.textPrimary)
                                .padding(.top, 6)
                            Text(application.jobTitle.isEmpty ? "Role" : application.jobTitle)
                                .font(.system(size: 17))
                                .foregroundStyle(AppTheme.textMuted)
                        }
                        .padding(.horizontal, 20).padding(.top, 20).padding(.bottom, 20)

                        separator

                        // Status picker
                        sectionLabel("Change Status")
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(ApplicationStatus.allCases.filter { $0 != .exported }, id: \.self) { s in
                                    statusPill(s)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        .padding(.bottom, 20)

                        separator

                        // Metrics
                        if application.preMatchScore != nil || !application.salaryDisplay.isEmpty {
                            HStack(spacing: 10) {
                                if let score = application.preMatchScore {
                                    metricBlock(value: "\(score)%", label: "CV Match",
                                                color: score >= 70 ? AppTheme.success : AppTheme.gold)
                                }
                                if !application.salaryDisplay.isEmpty {
                                    metricBlock(value: application.salaryDisplay, label: "Salary", color: AppTheme.success)
                                }
                                metricBlock(
                                    value: application.daysAgo == 0 ? "Today" : "\(application.daysAgo)d",
                                    label: "Applied", color: AppTheme.textMuted
                                )
                            }
                            .padding(.horizontal, 20).padding(.vertical, 16)
                            separator
                        }

                        // Interview date
                        if application.status == .interview {
                            sectionLabel("Interview Date")
                            DatePicker("", selection: $interviewDate,
                                       displayedComponents: [.date, .hourAndMinute])
                                .datePickerStyle(.compact)
                                .labelsHidden()
                                .padding(.horizontal, 20).padding(.bottom, 16)
                                .onChange(of: interviewDate) { _, new in
                                    application.interviewDate = new; save()
                                }
                            separator
                        }

                        // Notes
                        sectionLabel("Notes")
                        ZStack(alignment: .topLeading) {
                            if notesText.isEmpty {
                                Text("Add notes about this application…")
                                    .font(.system(size: 14))
                                    .foregroundStyle(AppTheme.textDisabled)
                                    .padding(.horizontal, 20).padding(.top, 18)
                            }
                            TextEditor(text: $notesText)
                                .font(.system(size: 14))
                                .foregroundStyle(AppTheme.textPrimary)
                                .scrollContentBackground(.hidden)
                                .frame(minHeight: 110)
                                .padding(.horizontal, 16)
                                .onChange(of: notesText) { _, new in
                                    application.notes = new; save()
                                }
                        }
                        .background(AppTheme.bgCard)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
                        .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                            .stroke(AppTheme.bgBorder, lineWidth: 0.5))
                        .padding(.horizontal, 20).padding(.bottom, 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Application Detail")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppTheme.textPrimary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppTheme.gold)
                }
            }
        }
        .onAppear {
            notesText = application.notes
            interviewDate = application.interviewDate ?? Date()
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(AppTheme.bgPrimary)
    }

    // MARK: Components

    private var separator: some View {
        Rectangle().fill(AppTheme.bgBorder).frame(height: 0.5).padding(.bottom, 16)
    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(AppTheme.textDisabled)
            .textCase(.uppercase).tracking(0.8)
            .padding(.horizontal, 20).padding(.bottom, 10)
    }

    private func statusPill(_ s: ApplicationStatus) -> some View {
        let isSelected = application.status == s
        return Button {
            withAnimation(.spring(response: 0.25)) { application.status = s }
            save()
        } label: {
            HStack(spacing: 6) {
                Text(s.emoji).font(.system(size: 14))
                Text(s.displayName).font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(isSelected ? .white : AppTheme.textMuted)
            .padding(.horizontal, 14).padding(.vertical, 9)
            .background(isSelected ? s.color : AppTheme.bgCard)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(isSelected ? s.color : AppTheme.bgBorder, lineWidth: 0.5))
        }
        .buttonStyle(.plain)
    }

    private func metricBlock(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(color)
                .lineLimit(1).minimumScaleFactor(0.6)
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(AppTheme.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(AppTheme.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
        .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusMd)
            .stroke(AppTheme.bgBorder, lineWidth: 0.5))
    }

    private func save() { try? modelContext.save() }
}
