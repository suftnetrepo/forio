import SwiftUI
import SwiftData

struct OnboardingView: View {
    var onComplete: () -> Void

    @Environment(\.modelContext) private var modelContext
    @State private var step: OnboardingStep = .splash
    @State private var selectedPersona: UserPersona = .graduate

    enum OnboardingStep {
        case splash, pages, persona, importChoice
    }

    var body: some View {
        ZStack {
            AppTheme.bgPrimary.ignoresSafeArea(.all)

            switch step {
            case .splash:
                SplashScreen {
                    withAnimation(.easeInOut(duration: 0.35)) { step = .pages }
                }
                .transition(.opacity)

            case .pages:
                OnboardingPagesView {
                    withAnimation(.easeInOut(duration: 0.35)) { step = .persona }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal:   .move(edge: .leading).combined(with: .opacity)
                ))

            case .persona:
                PersonaPickerScreen(selected: $selectedPersona) {
                    withAnimation(.easeInOut(duration: 0.35)) { step = .importChoice }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal:   .move(edge: .leading).combined(with: .opacity)
                ))

            case .importChoice:
                ImportChoiceScreen(
                    persona: selectedPersona,
                    onImport: { createProfile(persona: selectedPersona, imported: true) },
                    onManual: { createProfile(persona: selectedPersona, imported: false) }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal:   .move(edge: .leading).combined(with: .opacity)
                ))
            }
        }
        .animation(.easeInOut(duration: 0.35), value: step)
    }

    private func createProfile(persona: UserPersona, imported: Bool) {
        let profile = UserProfile(persona: persona)
        profile.importedFromCV = imported
        modelContext.insert(profile)
        try? modelContext.save()
        onComplete()
    }
}

// MARK: - Splash Screen

struct SplashScreen: View {
    var onContinue: () -> Void
    @State private var appear = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 28) {
                ZStack {
                    RoundedRectangle(cornerRadius: 22)
                        .fill(LinearGradient(
                            colors: [AppTheme.gold, AppTheme.goldLight],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ))
                        .frame(width: 80, height: 80)
                        .shadow(color: AppTheme.gold.opacity(0.4), radius: 20, y: 8)
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 34))
                        .foregroundStyle(Color(hex: "0A0A0F"))
                }
                .scaleEffect(appear ? 1 : 0.7)
                .opacity(appear ? 1 : 0)

                VStack(spacing: 10) {
                    Text("Forio")
                        .font(.system(size: 38, weight: .medium))
                        .foregroundStyle(AppTheme.textPrimary)
                    Text("AI CV & Cover Letter Builder")
                        .font(.system(size: 16))
                        .foregroundStyle(AppTheme.textMuted)
                }
                .opacity(appear ? 1 : 0)
                .offset(y: appear ? 0 : 12)

                VStack(spacing: 10) {
                    featurePill("✦", "AI tailored to every job")
                    featurePill("📄", "CV + Cover Letter together")
                    featurePill("⚡", "Ready in under 3 minutes")
                }
                .opacity(appear ? 1 : 0)
                .offset(y: appear ? 0 : 16)
            }
            .padding(.horizontal, 32)

            Spacer()

            VStack(spacing: 14) {
                Button(action: onContinue) {
                    Text("Get Started")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color(hex: "0A0A0F"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppTheme.gold)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
                }
                Text("by Suftnet Ltd")
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.textDisabled)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 52)
            .opacity(appear ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(duration: 0.7, bounce: 0.3).delay(0.2)) {
                appear = true
            }
        }
    }

    private func featurePill(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 10) {
            Text(icon).font(.system(size: 14))
            Text(text)
                .font(.system(size: 14))
                .foregroundStyle(AppTheme.textSecond)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
        .background(AppTheme.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                .stroke(AppTheme.bgBorder, lineWidth: 0.5)
        )
    }
}

// MARK: - Onboarding Pages

struct OnboardingPagesView: View {
    var onComplete: () -> Void
    @State private var page = 0

    struct Page {
        let icon: String
        let title: String
        let subtitle: String
    }

    let pages: [Page] = [
        Page(icon: "person.text.rectangle.fill",
             title: "One profile,\nevery job",
             subtitle: "Set up your profile once — AI tailors your CV for every application automatically"),
        Page(icon: "sparkles",
             title: "AI writes it\nfor you",
             subtitle: "Paste any job description and get a fully tailored CV and cover letter in seconds"),
        Page(icon: "arrow.down.doc.fill",
             title: "Export and\napply",
             subtitle: "Download a professional PDF and apply with confidence — every single time")
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            TabView(selection: $page) {
                ForEach(pages.indices, id: \.self) { i in
                    pageView(pages[i]).tag(i)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 380)

            HStack(spacing: 7) {
                ForEach(pages.indices, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(i == page ? AppTheme.gold : AppTheme.bgBorder)
                        .frame(width: i == page ? 20 : 7, height: 7)
                        .animation(.easeInOut(duration: 0.25), value: page)
                }
            }
            .padding(.top, 24)
            Spacer()

            VStack(spacing: 12) {
                Button(action: {
                    if page < pages.count - 1 { withAnimation { page += 1 } }
                    else { onComplete() }
                }) {
                    Text(page == pages.count - 1 ? "Let's go →" : "Next")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color(hex: "0A0A0F"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppTheme.gold)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
                }
                if page < pages.count - 1 {
                    Button("Skip") { onComplete() }
                        .font(.system(size: 14))
                        .foregroundStyle(AppTheme.textMuted)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 52)
        }
    }

    private func pageView(_ p: Page) -> some View {
        VStack(spacing: 28) {
            ZStack {
                Circle()
                    .fill(AppTheme.goldFaint)
                    .frame(width: 110, height: 110)
                Image(systemName: p.icon)
                    .font(.system(size: 46))
                    .foregroundStyle(AppTheme.gold)
            }
            VStack(spacing: 12) {
                Text(p.title)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(AppTheme.textPrimary)
                    .multilineTextAlignment(.center)
                Text(p.subtitle)
                    .font(.system(size: 16))
                    .foregroundStyle(AppTheme.textMuted)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 16)
            }
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Persona Picker Screen

struct PersonaPickerScreen: View {
    @Binding var selected: UserPersona
    var onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 28) {
                VStack(spacing: 8) {
                    Text("Where are you\nright now?")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundStyle(AppTheme.textPrimary)
                        .multilineTextAlignment(.center)
                    Text("We'll tailor everything to you")
                        .font(.system(size: 15))
                        .foregroundStyle(AppTheme.textMuted)
                }
                VStack(spacing: 10) {
                    ForEach(UserPersona.allCases, id: \.self) { persona in
                        personaCard(persona)
                    }
                }
                .padding(.horizontal, 24)
            }
            Spacer()
            Button("Continue", action: onContinue)
                .buttonStyle(GoldButtonStyle())
                .padding(.horizontal, 24)
                .padding(.bottom, 52)
        }
    }

    private func personaCard(_ persona: UserPersona) -> some View {
        let isSelected = selected == persona
        return Button(action: { selected = persona }) {
            HStack(spacing: 14) {
                Text(persona.emoji)
                    .font(.system(size: 26))
                    .frame(width: 36)
                VStack(alignment: .leading, spacing: 4) {
                    Text(persona.displayName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(isSelected ? AppTheme.gold : AppTheme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(personaSubtitle(persona))
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.textMuted)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineLimit(nil)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AppTheme.gold)
                        .font(.system(size: 20))
                        .frame(width: 24)
                }
            }
            .padding(16)
            .background(isSelected ? AppTheme.goldFaint : AppTheme.bgCard)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                    .stroke(isSelected ? AppTheme.goldBorder : AppTheme.bgBorder,
                            lineWidth: isSelected ? 1.0 : 0.5)
            )
        }
        .buttonStyle(.plain)
    }

    private func personaSubtitle(_ persona: UserPersona) -> String {
        switch persona {
        case .graduate:      return "First job, limited experience"
        case .experienced:   return "Got experience, need an update"
        case .careerChanger: return "Moving to a different field"
        case .returning:     return "After a break or pause"
        }
    }
}

// MARK: - Import Choice Screen

struct ImportChoiceScreen: View {
    let persona: UserPersona
    var onImport: () -> Void
    var onManual: () -> Void

    var body: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(spacing: 24) {

                    // Title block — safe area aware so it never clips
                    VStack(spacing: 8) {
                        Text("Import your CV")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundStyle(AppTheme.textPrimary)
                        Text("We'll read it and build\nyour profile automatically")
                            .font(.system(size: 15))
                            .foregroundStyle(AppTheme.textMuted)
                            .multilineTextAlignment(.center)
                            .lineSpacing(3)
                    }
                    .padding(.top, 16)

                    // Three import cards
                    VStack(spacing: 10) {
                        importCard(
                            icon: "camera.fill",
                            title: "Scan your CV",
                            subtitle: "Point your camera at any printed or on-screen CV",
                            isFeatured: true,
                            action: onImport
                        )
                        importCard(
                            icon: "doc.fill",
                            title: "Upload a PDF or Word doc",
                            subtitle: "Pick a file from your iPhone or iCloud Drive",
                            isFeatured: false,
                            action: onImport
                        )
                        importCard(
                            icon: "doc.on.clipboard.fill",
                            title: "Paste your CV text",
                            subtitle: "Copy text from any document and paste it here",
                            isFeatured: false,
                            action: onImport
                        )
                    }

                    // Divider + fallback
                    HStack {
                        Rectangle().fill(AppTheme.bgBorder).frame(height: 0.5)
                        Text("or")
                            .font(.system(size: 12))
                            .foregroundStyle(AppTheme.textDisabled)
                            .padding(.horizontal, 12)
                        Rectangle().fill(AppTheme.bgBorder).frame(height: 0.5)
                    }

                    Button(action: onManual) {
                        Text("I don't have a CV yet — start fresh")
                            .font(.system(size: 13))
                            .foregroundStyle(AppTheme.textMuted)
                            .underline()
                    }

                    // Tip
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundStyle(AppTheme.gold)
                            .font(.system(size: 13))
                        Text("Even a rough draft works — AI extracts what it can and you can fill in the rest.")
                            .font(.system(size: 12))
                            .foregroundStyle(AppTheme.textMuted)
                            .lineSpacing(2)
                            .fixedSize(horizontal: false, vertical: true)
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
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                // Ensure minimum content height fills screen so title appears centred on tall phones
                .frame(minHeight: geo.size.height)
            }
        }
    }

    private func importCard(
        icon: String,
        title: String,
        subtitle: String,
        isFeatured: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(isFeatured ? AppTheme.gold.opacity(0.2) : AppTheme.bgElevated)
                        .frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundStyle(isFeatured ? AppTheme.gold : AppTheme.textSecond)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(isFeatured ? AppTheme.gold : AppTheme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.textMuted)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineLimit(nil)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(isFeatured ? AppTheme.gold : AppTheme.textMuted)
            }
            .padding(16)
            .background(isFeatured ? AppTheme.goldFaint : AppTheme.bgCard)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                    .stroke(isFeatured ? AppTheme.goldBorder : AppTheme.bgBorder,
                            lineWidth: isFeatured ? 1.0 : 0.5)
            )
        }
        .buttonStyle(.plain)
    }
}
