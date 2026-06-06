import SwiftUI
import SwiftData

enum AppScreen: Equatable {
    case home
    case jobInput
    case output(JobApplication)
    case settings

    static func == (lhs: AppScreen, rhs: AppScreen) -> Bool {
        switch (lhs, rhs) {
        case (.home, .home), (.jobInput, .jobInput), (.settings, .settings): return true
        case (.output(let a), .output(let b)): return a.id == b.id
        default: return false
        }
    }
}

struct HomeView: View {
    @Query(sort: \JobApplication.createdAt, order: .reverse) private var applications: [JobApplication]
    @Query private var profiles: [UserProfile]

    @State private var screen: AppScreen = .home
    @State private var showPaywall = false
    @State private var purchaseService = PurchaseService.shared

    var profile: UserProfile? { profiles.first }

    var body: some View {
        ZStack {
            AppTheme.bgPrimary
                .ignoresSafeArea()

            Group {
                switch screen {
                case .home:
                    homeContent

                case .jobInput:
                    JobInputView(
                        onGenerated: { newApp in
                            withAnimation(.easeInOut(duration: 0.3)) {
                                screen = .output(newApp)
                            }
                        },
                        onBack: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                screen = .home
                            }
                        }
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                case .output(let app):
                    CVOutputView(application: app, onBack: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            screen = .home
                        }
                    })
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                case .settings:
                    SettingsView(onBack: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            screen = .home
                        }
                    })
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .sheet(isPresented: $showPaywall) {
            PaywallView(onDismiss: { showPaywall = false })
        }
    }

    // MARK: - Home content

    private var homeContent: some View {
        VStack(spacing: 0) {
            headerBar
            if applications.isEmpty {
                emptyState
            } else {
                applicationList
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Forio")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(.white)
                if let profile, !profile.fullName.isEmpty {
                    Text("Hi, \(profile.fullName.components(separatedBy: " ").first ?? "there") 👋")
                        .font(.system(size: 13))
                        .foregroundStyle(Color(hex: "888888"))
                }
            }
            Spacer()
            HStack(spacing: 10) {
                if !purchaseService.isPremium {
                    Button(action: { showPaywall = true }) {
                        HStack(spacing: 4) {
                            Text("✦").font(.system(size: 10))
                            Text(purchaseService.freeUsageLabel)
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundStyle(AppTheme.gold)
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(AppTheme.goldFaint)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .overlay(RoundedRectangle(cornerRadius: 20)
                            .stroke(AppTheme.goldBorder, lineWidth: 0.5))
                    }
                }
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) { screen = .settings }
                }) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 16))
                        .foregroundStyle(Color(hex: "aaaaaa"))
                        .frame(width: 34, height: 34)
                        .background(Color(hex: "13131a"))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(hex: "2a2a3a"), lineWidth: 0.5))
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 16) {
                Text("✦").font(.system(size: 40)).foregroundStyle(AppTheme.gold)
                Text("Your first CV\nis one tap away")
                    .font(.system(size: 24, weight: .medium)).foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                Text("Scan or paste a job description\nand AI generates a tailored CV in seconds")
                    .font(.system(size: 15)).foregroundStyle(Color(hex: "666666"))
                    .multilineTextAlignment(.center).lineSpacing(3)
            }
            Spacer()
            Button(action: { tapNewCV() }) {
                HStack(spacing: 6) { Text("✦"); Text("Make my first CV") }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color(hex: "0A0A0F"))
                    .frame(maxWidth: .infinity).padding(.vertical, 16)
                    .background(AppTheme.gold)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
            }
            .padding(.horizontal, 24).padding(.bottom, 52)
        }
    }

    // MARK: - Application list

    private var applicationList: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(applications) { app in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) { screen = .output(app) }
                    }) {
                        ApplicationRowView(application: app)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 120)
        }
        .overlay(alignment: .bottom) {
            VStack {
                Spacer()
                Button(action: { tapNewCV() }) {
                    HStack(spacing: 6) { Text("✦"); Text("New CV") }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color(hex: "0A0A0F"))
                        .frame(maxWidth: .infinity).padding(.vertical, 16)
                        .background(AppTheme.gold)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
                }
                .padding(.horizontal, 24).padding(.bottom, 48)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "0A0A0F").opacity(0), Color(hex: "0A0A0F")],
                        startPoint: .top, endPoint: .bottom
                    ).ignoresSafeArea()
                )
            }
        }
    }

    private func tapNewCV() {
        purchaseService.canGenerate
            ? (withAnimation(.easeInOut(duration: 0.3)) { screen = .jobInput })
            : (showPaywall = true)
    }
}

// MARK: - Application Row

struct ApplicationRowView: View {
    let application: JobApplication
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(application.company.isEmpty ? "Untitled" : application.company)
                    .font(.system(size: 14, weight: .medium)).foregroundStyle(.white)
                Text(application.jobTitle.isEmpty ? "—" : application.jobTitle)
                    .font(.system(size: 12)).foregroundStyle(Color(hex: "888888"))
                Text(application.createdAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: 11)).foregroundStyle(Color(hex: "555555"))
            }
            Spacer()
            StatusBadge(status: application.status)
        }
        .padding(14)
        .background(Color(hex: "13131a"))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
        .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusMd)
            .stroke(Color(hex: "2a2a3a"), lineWidth: 0.5))
    }
}

// MARK: - Status Badge

struct StatusBadge: View {
    let status: ApplicationStatus
    var body: some View {
        Text(status.rawValue)
            .font(.system(size: 10, weight: .medium)).foregroundStyle(textColor)
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(bgColor).clipShape(RoundedRectangle(cornerRadius: 6))
    }
    private var bgColor: Color {
        switch status {
        case .draft:    return AppTheme.goldFaint
        case .exported: return AppTheme.successFaint
        case .applied:  return AppTheme.info.opacity(0.12)
        }
    }
    private var textColor: Color {
        switch status {
        case .draft:    return AppTheme.gold
        case .exported: return AppTheme.success
        case .applied:  return AppTheme.info
        }
    }
}
