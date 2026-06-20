import SwiftUI
import SwiftData

// MARK: - Application Tracker

struct ApplicationTrackerView: View {
    @Query(sort: \JobApplication.updatedAt, order: .reverse) private var all: [JobApplication]
    @State private var selected: JobApplication?

    private func apps(_ status: ApplicationStatus) -> [JobApplication] {
        all.filter { $0.status == status }
    }

    var body: some View {
        ZStack {
            AppTheme.bgPrimary.ignoresSafeArea()
            VStack(spacing: 0) {
                header
                if all.isEmpty { emptyState } else { pipeline }
            }
        }
        .sheet(item: $selected) { app in ApplicationDetailSheet(application: app) }
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Job Pipeline")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(AppTheme.textPrimary)
                    Text(subtitleText)
                        .font(.system(size: 14))
                        .foregroundStyle(AppTheme.textMuted)
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 56)

            // Stat row — only when there are apps
            if !all.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(ApplicationStatus.pipelineStatuses, id: \.self) { status in
                            statTile(status: status, count: apps(status).count)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
        .padding(.bottom, 16)
    }

    private var subtitleText: String {
        let active = ApplicationStatus.pipelineStatuses.reduce(0) { $0 + apps($1).count }
        if active == 0 { return "No active applications" }
        return "\(active) active application\(active == 1 ? "" : "s")"
    }

    private func statTile(status: ApplicationStatus, count: Int) -> some View {
        VStack(spacing: 6) {
            Text("\(count)")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(count > 0 ? status.color : AppTheme.textDisabled)
            HStack(spacing: 4) {
                Image(systemName: status.icon)
                    .font(.system(size: 10))
                Text(status.displayName)
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundStyle(count > 0 ? status.color.opacity(0.8) : AppTheme.textDisabled)
        }
        .frame(width: 88)
        .padding(.vertical, 14)
        .background(count > 0 ? status.color.opacity(0.07) : AppTheme.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
        .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusMd)
            .stroke(count > 0 ? status.color.opacity(0.18) : AppTheme.bgBorder, lineWidth: 0.5))
    }

    // MARK: Pipeline columns

    private var pipeline: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 12) {
                ForEach(ApplicationStatus.pipelineStatuses, id: \.self) { status in
                    KanbanColumn(status: status, apps: apps(status)) { selected = $0 }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
    }

    // MARK: Empty

    private var emptyState: some View {
        VStack(spacing: 24) {
            Spacer()
            ZStack {
                Circle().fill(AppTheme.goldFaint).frame(width: 110, height: 110)
                Image(systemName: "briefcase.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(AppTheme.gold)
            }
            VStack(spacing: 10) {
                Text("Start tracking your search")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)
                Text("Generate a CV for a role and it will\nappear here in your pipeline.")
                    .font(.system(size: 15))
                    .foregroundStyle(AppTheme.textMuted)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            Spacer()
        }
        .padding(.horizontal, 32)
    }
}

// MARK: - Kanban Column

struct KanbanColumn: View {
    let status: ApplicationStatus
    let apps: [JobApplication]
    let onTap: (JobApplication) -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Column header
            HStack(spacing: 8) {
                ZStack {
                    Circle().fill(status.color.opacity(0.15)).frame(width: 28, height: 28)
                    Image(systemName: status.icon)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(status.color)
                }
                Text(status.displayName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
                Text("\(apps.count)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(apps.isEmpty ? AppTheme.textDisabled : .white)
                    .frame(minWidth: 22, minHeight: 22)
                    .padding(.horizontal, apps.count >= 10 ? 6 : 0)
                    .background(apps.isEmpty ? AppTheme.bgElevated : status.color)
                    .clipShape(Capsule())
            }
            .padding(14)

            Divider().background(AppTheme.bgBorder)

            // Cards
            VStack(spacing: 8) {
                if apps.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: status.icon)
                            .font(.system(size: 26))
                            .foregroundStyle(AppTheme.bgBorder)
                        Text("None yet")
                            .font(.system(size: 13))
                            .foregroundStyle(AppTheme.textDisabled)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 36)
                } else {
                    ForEach(apps) { app in
                        PipelineCard(application: app)
                            .onTapGesture { onTap(app) }
                    }
                }
            }
            .padding(10)
        }
        .frame(width: 240)
        .background(AppTheme.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusLg))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.radiusLg)
                .stroke(AppTheme.bgBorder, lineWidth: 0.5)
        )
        // Coloured top accent line
        .overlay(alignment: .top) {
            RoundedRectangle(cornerRadius: AppTheme.radiusLg)
                .fill(status.color)
                .frame(height: 3)
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: AppTheme.radiusLg,
                        topTrailingRadius: AppTheme.radiusLg
                    )
                )
        }
    }
}

// MARK: - Pipeline Card

struct PipelineCard: View {
    let application: JobApplication

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Company
            VStack(alignment: .leading, spacing: 3) {
                Text(application.company.isEmpty ? "Company" : application.company)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(1)
                Text(application.jobTitle.isEmpty ? "Role" : application.jobTitle)
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.textMuted)
                    .lineLimit(1)
            }

            // Score + salary chips
            if application.preMatchScore != nil || !application.salaryDisplay.isEmpty {
                HStack(spacing: 6) {
                    if let score = application.preMatchScore {
                        chip("\(score)%", color: scoreColor(score), icon: "target")
                    }
                    if !application.salaryDisplay.isEmpty {
                        chip(application.salaryDisplay, color: AppTheme.success, icon: "sterlingsign")
                    }
                }
            }

            // Footer
            HStack {
                Image(systemName: "calendar").font(.system(size: 10)).foregroundStyle(AppTheme.textDisabled)
                Text(application.daysAgo == 0 ? "Today" : "\(application.daysAgo)d ago")
                    .font(.system(size: 11)).foregroundStyle(AppTheme.textDisabled)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(AppTheme.textDisabled)
            }
        }
        .padding(12)
        .background(AppTheme.bgElevated)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
        .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusMd).stroke(AppTheme.bgBorder, lineWidth: 0.5))
    }

    private func chip(_ text: String, color: Color, icon: String) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon).font(.system(size: 9, weight: .bold))
            Text(text).font(.system(size: 10, weight: .semibold))
        }
        .foregroundStyle(color)
        .padding(.horizontal, 8).padding(.vertical, 4)
        .background(color.opacity(0.1))
        .clipShape(Capsule())
    }

    private func scoreColor(_ s: Int) -> Color {
        s >= 70 ? AppTheme.success : s >= 50 ? AppTheme.gold : AppTheme.danger
    }
}

