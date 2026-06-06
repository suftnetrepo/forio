import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    var onBack: () -> Void
    @Query private var profiles: [UserProfile]

    @State private var purchaseService = PurchaseService.shared
    @State private var showProfileEdit = false
    @State private var showPaywall = false
    @State private var showResetAlert = false
    @AppStorage(Constants.Keys.onboardingComplete) private var onboardingComplete = true

    var profile: UserProfile? { profiles.first }

    var body: some View {
        ZStack {
            AppTheme.bgPrimary.ignoresSafeArea(.all)

            VStack(spacing: 0) {
                // Custom header — replaces NavigationBar entirely
                HStack {
                    Button(action: { onBack() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(AppTheme.textMuted)
                            .frame(width: 32, height: 32)
                            .background(AppTheme.bgCard)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    Spacer()
                    Text("Settings")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(AppTheme.textPrimary)
                    Spacer()
                    Color.clear.frame(width: 32, height: 32)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 16)

                ScrollView {
                    VStack(spacing: 20) {
                        profileSection
                        subscriptionSection
                        appSection
                        dangerSection
                        footerNote
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 60)
                }
            }
        }
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showProfileEdit) {
            if let profile { ProfileEditView(profile: profile) }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(onDismiss: { showPaywall = false })
        }
        .alert("Reset all data?", isPresented: $showResetAlert) {
            Button("Reset", role: .destructive) { resetAllData() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will delete your profile and all generated CVs. This cannot be undone.")
        }
    }

    // MARK: - Profile section

    private var profileSection: some View {
        VStack(spacing: 8) {
            sectionHeader("Your Profile")

            if let profile {
                Button(action: { showProfileEdit = true }) {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle().fill(AppTheme.goldFaint).frame(width: 44, height: 44)
                            Text(initials(for: profile.fullName))
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(AppTheme.gold)
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            Text(profile.fullName.isEmpty ? "Add your name" : profile.fullName)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(profile.fullName.isEmpty ? AppTheme.textMuted : AppTheme.textPrimary)
                            Text(profile.email.isEmpty ? "Add email" : profile.email)
                                .font(.system(size: 12)).foregroundStyle(AppTheme.textMuted)
                            HStack(spacing: 4) {
                                Text(profile.persona.emoji).font(.system(size: 10))
                                Text(profile.persona.displayName)
                                    .font(.system(size: 11)).foregroundStyle(AppTheme.textDisabled)
                            }
                        }
                        Spacer()
                        Image(systemName: "pencil").font(.system(size: 13)).foregroundStyle(AppTheme.textMuted)
                    }
                    .padding(16)
                    .background(AppTheme.bgCard)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
                    .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusMd).stroke(AppTheme.bgBorder, lineWidth: 0.5))
                }
                .buttonStyle(.plain)

                HStack(spacing: 0) {
                    statCell(value: "\(profile.experience.count)", label: "Roles")
                    Divider().background(AppTheme.bgBorder).frame(height: 30)
                    statCell(value: "\(profile.education.count)", label: "Education")
                    Divider().background(AppTheme.bgBorder).frame(height: 30)
                    statCell(value: "\(profile.skills.count)", label: "Skills")
                }
                .padding(.vertical, 12)
                .background(AppTheme.bgCard)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
                .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusMd).stroke(AppTheme.bgBorder, lineWidth: 0.5))
            }
        }
    }

    // MARK: - Subscription section

    private var subscriptionSection: some View {
        VStack(spacing: 8) {
            sectionHeader("Subscription")

            if purchaseService.isPremium {
                HStack(spacing: 12) {
                    ZStack {
                        Circle().fill(AppTheme.goldFaint).frame(width: 36, height: 36)
                        Text("✦").font(.system(size: 16)).foregroundStyle(AppTheme.gold)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Forio Premium").font(.system(size: 14, weight: .semibold)).foregroundStyle(AppTheme.gold)
                        Text("Unlimited CVs · All templates").font(.system(size: 12)).foregroundStyle(AppTheme.textMuted)
                    }
                    Spacer()
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(AppTheme.success)
                }
                .padding(16).background(AppTheme.goldFaint)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
                .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusMd).stroke(AppTheme.goldBorder, lineWidth: 0.5))

                settingsRow(icon: "arrow.clockwise", label: "Restore purchases") {
                    Task { try? await purchaseService.restorePurchases() }
                }
            } else {
                Button(action: { showPaywall = true }) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle().fill(AppTheme.goldFaint).frame(width: 36, height: 36)
                            Text("✦").font(.system(size: 16)).foregroundStyle(AppTheme.gold)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Upgrade to Premium")
                                .font(.system(size: 14, weight: .semibold)).foregroundStyle(AppTheme.textPrimary)
                            Text("\(purchaseService.generationsRemaining) free CV\(purchaseService.generationsRemaining == 1 ? "" : "s") remaining")
                                .font(.system(size: 12)).foregroundStyle(AppTheme.textMuted)
                        }
                        Spacer()
                        Text("Upgrade")
                            .font(.system(size: 12, weight: .semibold)).foregroundStyle(Color(hex: "0A0A0F"))
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .background(AppTheme.gold).clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .padding(16).background(AppTheme.bgCard)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
                    .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusMd).stroke(AppTheme.bgBorder, lineWidth: 0.5))
                }
                .buttonStyle(.plain)

                settingsRow(icon: "arrow.clockwise", label: "Restore purchases") {
                    Task { try? await purchaseService.restorePurchases() }
                }
            }
        }
    }

    // MARK: - App section

    private var appSection: some View {
        VStack(spacing: 8) {
            sectionHeader("App")
            VStack(spacing: 0) {
                settingsRow(icon: "star.fill", label: "Rate Forio") { openURL("https://apps.apple.com/app/id0000000000") }
                Divider().background(AppTheme.bgElevated).padding(.leading, 52)
                settingsRow(icon: "questionmark.circle.fill", label: "Help & Support") { openURL(Constants.supportURL) }
                Divider().background(AppTheme.bgElevated).padding(.leading, 52)
                settingsRow(icon: "lock.fill", label: "Privacy Policy") { openURL(Constants.privacyURL) }
                Divider().background(AppTheme.bgElevated).padding(.leading, 52)
                settingsRow(icon: "doc.text.fill", label: "Terms of Use") { openURL(Constants.termsURL) }
            }
            .background(AppTheme.bgCard)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
            .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusMd).stroke(AppTheme.bgBorder, lineWidth: 0.5))
        }
    }

    // MARK: - Danger section

    private var dangerSection: some View {
        VStack(spacing: 8) {
            sectionHeader("Data")
            VStack(spacing: 0) {
                settingsRow(icon: "trash.fill", label: "Reset all data", isDestructive: true) { showResetAlert = true }
            }
            .background(AppTheme.bgCard)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
            .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusMd).stroke(AppTheme.bgBorder, lineWidth: 0.5))
        }
    }

    private var footerNote: some View {
        VStack(spacing: 4) {
            Text("Forio · by Suftnet Ltd").font(.system(size: 12)).foregroundStyle(AppTheme.textDisabled)
            Text("Version 1.0.0").font(.system(size: 11)).foregroundStyle(AppTheme.textDisabled)
        }
        .padding(.top, 8)
    }

    // MARK: - Reusable

    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 10, weight: .medium)).foregroundStyle(AppTheme.textDisabled).kerning(0.8)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func settingsRow(icon: String, label: String, isDestructive: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon).font(.system(size: 14))
                    .foregroundStyle(isDestructive ? AppTheme.danger : AppTheme.gold).frame(width: 24)
                Text(label).font(.system(size: 14))
                    .foregroundStyle(isDestructive ? AppTheme.danger : AppTheme.textPrimary)
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 11)).foregroundStyle(AppTheme.textDisabled)
            }
            .padding(.horizontal, 16).padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }

    private func statCell(value: String, label: String) -> some View {
        VStack(spacing: 3) {
            Text(value).font(.system(size: 18, weight: .semibold)).foregroundStyle(AppTheme.gold)
            Text(label).font(.system(size: 10)).foregroundStyle(AppTheme.textMuted)
        }
        .frame(maxWidth: .infinity)
    }

    private func initials(for name: String) -> String {
        let parts = name.components(separatedBy: " ").filter { !$0.isEmpty }
        return String(parts.prefix(2).compactMap { $0.first }).uppercased().isEmpty ? "?" :
               String(parts.prefix(2).compactMap { $0.first }).uppercased()
    }

    private func openURL(_ string: String) {
        guard let url = URL(string: string) else { return }
        UIApplication.shared.open(url)
    }

    private func resetAllData() {
        let appDesc = FetchDescriptor<JobApplication>()
        let docDesc = FetchDescriptor<GeneratedDocument>()
        let profDesc = FetchDescriptor<UserProfile>()
        if let apps = try? modelContext.fetch(appDesc) { apps.forEach { modelContext.delete($0) } }
        if let docs = try? modelContext.fetch(docDesc) { docs.forEach { modelContext.delete($0) } }
        if let profs = try? modelContext.fetch(profDesc) { profs.forEach { modelContext.delete($0) } }
        try? modelContext.save()
        purchaseService.resetGenerations()
        onboardingComplete = false
    }
}
