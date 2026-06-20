import SwiftUI
import SwiftData

// MARK: - Application History (Swipe-to-review)

struct SwipeHistoryView: View {
    @Query(sort: \JobApplication.createdAt, order: .reverse) private var apps: [JobApplication]
    @State private var currentIndex = 0
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false
    @State private var selected: JobApplication?

    private var current: JobApplication? {
        guard currentIndex < apps.count else { return nil }
        return apps[currentIndex]
    }
    private var nextApp: JobApplication? {
        guard currentIndex + 1 < apps.count else { return nil }
        return apps[currentIndex + 1]
    }

    var body: some View {
        ZStack {
            AppTheme.bgPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                header

                if apps.isEmpty {
                    emptyState
                } else if currentIndex >= apps.count {
                    doneState
                } else {
                    cardArea
                }
            }
        }
        .sheet(item: $selected) { app in
            ApplicationDetailSheet(application: app)
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 4) {
                Text("History")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)
                if !apps.isEmpty && currentIndex < apps.count {
                    Text("\(currentIndex + 1) of \(apps.count)")
                        .font(.system(size: 14))
                        .foregroundStyle(AppTheme.textMuted)
                }
            }
            Spacer()
            if !apps.isEmpty && currentIndex < apps.count {
                Button(action: { selected = apps[currentIndex] }) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(AppTheme.textDisabled)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 56)
        .padding(.bottom, 24)
    }

    // MARK: Card Area

    private var cardArea: some View {
        VStack(spacing: 0) {
            // Card stack
            ZStack {
                // Background card (next)
                if let next = nextApp {
                    HistoryCard(application: next)
                        .scaleEffect(0.94)
                        .offset(y: 14)
                        .opacity(0.5)
                }

                // Active card
                if let app = current {
                    HistoryCard(application: app)
                        .offset(x: dragOffset)
                        .rotationEffect(.degrees(Double(dragOffset) / 30), anchor: .bottom)
                        .overlay(dragIndicators)
                        .gesture(
                            DragGesture()
                                .onChanged { v in
                                    dragOffset = v.translation.width
                                    isDragging = true
                                }
                                .onEnded { v in
                                    isDragging = false
                                    let threshold: CGFloat = 90
                                    if v.translation.width > threshold { confirmSwipe(app: app, direction: .right) }
                                    else if v.translation.width < -threshold { confirmSwipe(app: app, direction: .left) }
                                    else { withAnimation(.spring(response: 0.4)) { dragOffset = 0 } }
                                }
                        )
                        .animation(isDragging ? nil : .spring(response: 0.35), value: dragOffset)
                }
            }
            .padding(.horizontal, 20)

            Spacer(minLength: 20)

            // Action hint row
            HStack {
                Label("Archive", systemImage: "archivebox")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppTheme.textDisabled)
                Spacer()
                Text("Swipe or tap")
                    .font(.system(size: 11))
                    .foregroundStyle(AppTheme.textDisabled)
                Spacer()
                Label("Re-use", systemImage: "arrow.clockwise")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppTheme.textDisabled)
            }
            .padding(.horizontal, 48)
            .padding(.bottom, 16)

            // Action buttons — well above the tab bar
            HStack(spacing: 20) {
                // Archive
                actionButton(
                    icon: "archivebox.fill",
                    label: "Archive",
                    color: AppTheme.textMuted,
                    size: 60
                ) {
                    if let app = current { confirmSwipe(app: app, direction: .left) }
                }

                // Re-use (primary)
                actionButton(
                    icon: "arrow.clockwise",
                    label: "Re-use",
                    color: AppTheme.bgPrimary,
                    bgColor: AppTheme.gold,
                    size: 70
                ) {
                    if let app = current { confirmSwipe(app: app, direction: .right) }
                }
            }
            .padding(.bottom, 100) // above tab bar
        }
    }

    // MARK: Drag Indicators

    private var dragIndicators: some View {
        ZStack {
            // Archive label — left
            HStack {
                Label("Archive", systemImage: "archivebox.fill")
                    .font(.system(size: 16, weight: .black))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16).padding(.vertical, 10)
                    .background(Color.gray.opacity(0.9))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .rotationEffect(.degrees(-12))
                    .opacity(dragOffset < -40 ? Double(min(1, (-dragOffset - 40) / 50)) : 0)
                    .padding(.leading, 20)
                    .padding(.top, 40)
                Spacer()
            }

            // Re-use label — right
            HStack {
                Spacer()
                Label("Re-use", systemImage: "arrow.clockwise")
                    .font(.system(size: 16, weight: .black))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16).padding(.vertical, 10)
                    .background(AppTheme.gold.opacity(0.95))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .rotationEffect(.degrees(12))
                    .opacity(dragOffset > 40 ? Double(min(1, (dragOffset - 40) / 50)) : 0)
                    .padding(.trailing, 20)
                    .padding(.top, 40)
            }
        }
    }

    // MARK: Action Button

    private func actionButton(icon: String, label: String, color: Color, bgColor: Color = AppTheme.bgCard, size: CGFloat, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(bgColor == AppTheme.bgCard ? AppTheme.bgCard : bgColor)
                        .frame(width: size, height: size)
                        .overlay(Circle().stroke(AppTheme.bgBorder, lineWidth: bgColor == AppTheme.bgCard ? 0.5 : 0))
                        .shadow(color: bgColor == AppTheme.gold ? AppTheme.gold.opacity(0.35) : .black.opacity(0.15),
                                radius: bgColor == AppTheme.gold ? 12 : 6, y: 4)
                    Image(systemName: icon)
                        .font(.system(size: size * 0.36, weight: .semibold))
                        .foregroundStyle(color)
                }
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(AppTheme.textDisabled)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: Empty / Done States

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            ZStack {
                Circle().fill(AppTheme.goldFaint).frame(width: 110, height: 110)
                Image(systemName: "tray.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(AppTheme.gold)
            }
            VStack(spacing: 10) {
                Text("No applications yet")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)
                Text("Once you generate a CV, your applications will appear here to review.")
                    .font(.system(size: 15))
                    .foregroundStyle(AppTheme.textMuted)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            Spacer()
        }
        .padding(.horizontal, 32)
    }

    private var doneState: some View {
        VStack(spacing: 20) {
            Spacer()
            ZStack {
                Circle().fill(AppTheme.success.opacity(0.1)).frame(width: 110, height: 110)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(AppTheme.success)
            }
            VStack(spacing: 10) {
                Text("All caught up!")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)
                Text("You've reviewed all \(apps.count) applications.")
                    .font(.system(size: 15))
                    .foregroundStyle(AppTheme.textMuted)
            }
            Button("Start over") {
                withAnimation { currentIndex = 0; dragOffset = 0 }
            }
            .buttonStyle(GoldButtonStyle())
            .padding(.horizontal, 60)
            Spacer()
        }
        .padding(.horizontal, 32)
    }

    // MARK: Swipe action

    enum SwipeDirection { case left, right }

    private func confirmSwipe(app: JobApplication, direction: SwipeDirection) {
        let screenWidth = UIScreen.main.bounds.width
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            dragOffset = direction == .right ? screenWidth * 1.4 : -screenWidth * 1.4
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
            if direction == .left { app.status = .archived }
            dragOffset = 0
            withAnimation { currentIndex += 1 }
        }
    }
}

// MARK: - History Card

struct HistoryCard: View {
    let application: JobApplication

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Status accent top strip
            HStack {
                HStack(spacing: 6) {
                    Text(application.status.emoji).font(.system(size: 13))
                    Text(application.status.displayName)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(application.status.color)
                }
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(application.status.color.opacity(0.12))
                .clipShape(Capsule())

                Spacer()

                Text(application.createdAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.textDisabled)
            }
            .padding(.horizontal, 20).padding(.top, 20)

            // Company + role
            VStack(alignment: .leading, spacing: 6) {
                Text(application.company.isEmpty ? "Company" : application.company)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(1)
                Text(application.jobTitle.isEmpty ? "Role" : application.jobTitle)
                    .font(.system(size: 16))
                    .foregroundStyle(AppTheme.textMuted)
                    .lineLimit(2)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)

            Divider().background(AppTheme.bgBorder).padding(.horizontal, 20).padding(.vertical, 16)

            // Metrics
            HStack(spacing: 10) {
                if let score = application.preMatchScore {
                    metricBox(
                        value: "\(score)%",
                        label: "Match",
                        color: score >= 70 ? AppTheme.success : AppTheme.gold
                    )
                }
                if !application.salaryDisplay.isEmpty {
                    metricBox(value: application.salaryDisplay, label: "Salary", color: AppTheme.success)
                }
                metricBox(
                    value: application.daysAgo == 0 ? "Today" : "\(application.daysAgo)d",
                    label: "Applied",
                    color: AppTheme.textMuted
                )
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(AppTheme.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusXl))
        .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusXl).stroke(AppTheme.bgBorder, lineWidth: 0.5))
        .shadow(color: .black.opacity(0.25), radius: 20, y: 8)
    }

    private func metricBox(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(color)
                .lineLimit(1).minimumScaleFactor(0.7)
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(AppTheme.textDisabled)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(AppTheme.bgElevated)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
    }
}
