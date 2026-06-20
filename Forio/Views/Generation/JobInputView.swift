import SwiftUI
import SwiftData
import VisionKit

struct JobInputView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @Query(sort: \CVProfile.createdAt, order: .reverse) private var savedCVs: [CVProfile]

    @State private var viewModel = GenerationViewModel()
    @State private var purchaseService = PurchaseService.shared
    @State private var showScanner = false
    @State private var showPaywall = false
    @State private var showTemplates = false
    @State private var showPasteSheet = false
    @State private var showAddCV = false
    enum AddCVScreen { case none, addCV }
    @State private var showURLImport = false
    @State private var showCVScore = false
    @State private var cvScoreForJob: String = ""
    @State private var addCVScreen: AddCVScreen = .none
    @State private var isScanning = false
    @State private var scanError: String? = nil

    enum Screen { case input, generating }
    @State private var screen: Screen = .input

    var onGenerated: (JobApplication) -> Void
    var onBack: () -> Void
    var profile: UserProfile? { profiles.first }

    var body: some View {
        ZStack {
            AppTheme.bgPrimary.ignoresSafeArea(.all)

            // Main screens
            switch screen {
            case .input:      inputView
            case .generating: GenerationProgressView(viewModel: viewModel)
            }

            // Add CV screen — slides in over the top, no sheet
            if addCVScreen == .addCV {
                ScanAndNameCVView(
                    onSaved: { newProfile in
                        viewModel.selectedCVProfile = newProfile
                        withAnimation(.easeInOut(duration: 0.3)) {
                            addCVScreen = .none
                        }
                    },
                    onBack: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            addCVScreen = .none
                        }
                    }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(10)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: addCVScreen == .none)
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .fullScreenCover(isPresented: $showScanner) {
            DocumentScannerView { result in
                showScanner = false
                guard case .success(let scan) = result else { return }
                let images = (0..<min(scan.pageCount, 5)).map { scan.imageOfPage(at: $0) }
                isScanning = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    Task { @MainActor in
                        do {
                            let extracted = try await AIService.shared.extractJobDescription(from: images)
                            if !extracted.description.isEmpty { viewModel.jobDescription = extracted.description }
                            if !extracted.title.isEmpty   { viewModel.jobTitle   = extracted.title }
                            if !extracted.company.isEmpty { viewModel.company    = extracted.company }
                        } catch {
                            scanError = "Couldn't read the job ad clearly.\n\nTips:\n• Hold phone steady\n• Ensure good lighting\n• Zoom in on the text\n\nOr tap Paste to copy the text instead."
                        }
                        isScanning = false
                    }
                }
            }
        }
        .sheet(isPresented: $showURLImport) {
            URLImportView { extracted in
                if !extracted.description.isEmpty { viewModel.jobDescription = extracted.description }
                if !extracted.title.isEmpty       { viewModel.jobTitle = extracted.title }
                if !extracted.company.isEmpty     { viewModel.company  = extracted.company }
            }
        }
        .sheet(isPresented: $showCVScore) {
            CVScoreSheet(
                jobDescription: viewModel.jobDescription,
                cvContent: viewModel.selectedCVProfile?.professionalSummary ?? profile?.professionalSummary ?? "",
                onGenerate: {
                    showCVScore = false
                    if let cvProfile = viewModel.selectedCVProfile {
                        Task { await viewModel.generate(cvProfile: cvProfile, purchaseService: purchaseService) }
                    } else if let p = profile {
                        Task { await viewModel.generate(profile: p, purchaseService: purchaseService) }
                    }
                }
            )
        }
        .sheet(isPresented: $showPasteSheet) {
            JobPasteView { text in viewModel.jobDescription = text }
        }
        .sheet(isPresented: $showTemplates) {
            TemplatePickerSheet(selected: $viewModel.selectedTemplate)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(onDismiss: { showPaywall = false })
        }

        .alert("Scan failed", isPresented: Binding(
            get: { scanError != nil }, set: { if !$0 { scanError = nil } }
        )) {
            Button("OK") { scanError = nil }
        } message: { Text(scanError ?? "") }
    }

    // MARK: - Input view

    private var inputView: some View {
        VStack(spacing: 0) {

            // Header
            HStack {
                Button(action: { onBack() }) {
                    Image(systemName: "xmark")
                        .foregroundStyle(AppTheme.textMuted)
                        .frame(width: 32, height: 32)
                        .background(AppTheme.bgCard)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8)
                            .stroke(AppTheme.bgBorder, lineWidth: 0.5))
                }
                Spacer()
                Text("New Application")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
                if !purchaseService.isPremium {
                    Button(action: { showPaywall = true }) {
                        Text(purchaseService.freeUsageLabel)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(AppTheme.gold)
                            .padding(.horizontal, 9).padding(.vertical, 4)
                            .background(AppTheme.goldFaint)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .overlay(RoundedRectangle(cornerRadius: 20)
                                .stroke(AppTheme.goldBorder, lineWidth: 0.5))
                    }
                } else {
                    Color.clear.frame(width: 60)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 60)
            .padding(.bottom, 16)
            .background(AppTheme.bgPrimary)

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {

                    // ── CV PICKER SECTION ─────────────────────────────────
                    VStack(alignment: .leading, spacing: 8) {
                        Text("SELECT CV")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(AppTheme.textMuted)
                            .kerning(0.5)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                // Saved CV cards
                                ForEach(savedCVs) { cv in
                                    cvCard(cv)
                                }
                                // + Add new CV card
                                addCVCard
                            }
                            .padding(.vertical, 2)
                        }

                        // Selected CV banner
                        if let selected = viewModel.selectedCVProfile {
                            selectedCVBanner(selected)
                        } else if let profile {
                            defaultProfileBanner(profile)
                        }
                    }

                    // ── JD SECTION ────────────────────────────────────────
                    VStack(alignment: .leading, spacing: 8) {
                        Text("JOB DESCRIPTION")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(AppTheme.textMuted)
                            .kerning(0.5)

                        // Input method cards
                        HStack(spacing: 8) {
                            inputMethodCard(icon: "camera.fill",          label: "Scan",  subtitle: "Point at job ad",  isFeatured: true)  { showScanner = true }
                            inputMethodCard(icon: "doc.on.clipboard.fill", label: "Paste", subtitle: "From clipboard",  isFeatured: false) { showPasteSheet = true }
                            inputMethodCard(icon: "square.and.arrow.up",   label: "Share", subtitle: "From any app",   isFeatured: false) { showPasteSheet = true }
                        }

                        // Scanning spinner
                        if isScanning {
                            HStack(spacing: 10) {
                                ProgressView().tint(AppTheme.gold).scaleEffect(0.85)
                                Text("Reading job description…")
                                    .font(.system(size: 13)).foregroundStyle(AppTheme.textMuted)
                            }
                            .frame(maxWidth: .infinity).padding(14)
                            .background(AppTheme.bgCard)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
                        }

                        // JD content
                        if !viewModel.jobDescription.isEmpty {
                            jdReadyCard
                        } else if !isScanning {
                            emptyStateCard
                        }
                    }

                    // LinkedIn tip
                    linkedInTip

                    // Template
                    templateRow

                    // Paywall
                    if !purchaseService.canGenerate { paywallBanner }

                    // Generate button
                    Button(action: { generate() }) {
                        HStack(spacing: 8) {
                            Text("✦")
                            Text("Generate with AI")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundStyle(AppTheme.bgPrimary)
                        .frame(maxWidth: .infinity).padding(.vertical, 16)
                        .background(!viewModel.canGenerate || !purchaseService.canGenerate
                                    ? AppTheme.gold.opacity(0.4) : AppTheme.gold)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
                    }
                    .disabled(!viewModel.canGenerate || isScanning)
                    .padding(.top, 4)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 52)
            }
        }
    }

    // MARK: - CV Card

    private func cvCard(_ cv: CVProfile) -> some View {
        let isSelected = viewModel.selectedCVProfile?.id == cv.id
        return Button(action: {
            withAnimation(.easeOut(duration: 0.2)) {
                viewModel.selectedCVProfile = isSelected ? nil : cv
            }
        }) {
            VStack(alignment: .leading, spacing: 6) {
                // Initials circle
                ZStack {
                    Circle()
                        .fill(isSelected ? AppTheme.gold : AppTheme.bgBorder)
                        .frame(width: 32, height: 32)
                    Text(initials(cv.fullName))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(isSelected ? AppTheme.bgPrimary : AppTheme.textMuted)
                }

                Text(cv.name)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(isSelected ? AppTheme.gold : .white)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text("\(cv.experience.count) roles")
                    .font(.system(size: 9))
                    .foregroundStyle(AppTheme.textMuted)

                // Selected indicator
                if isSelected {
                    HStack(spacing: 3) {
                        Circle().fill(AppTheme.gold).frame(width: 5, height: 5)
                        Text("Selected")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundStyle(AppTheme.gold)
                    }
                }
            }
            .padding(10)
            .frame(width: 88)
            .background(isSelected ? AppTheme.goldFaint : AppTheme.bgCard)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? AppTheme.goldBorder : AppTheme.bgBorder,
                            lineWidth: isSelected ? 1.0 : 0.5)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Add CV card

    private var addCVCard: some View {
        Button(action: { withAnimation(.easeInOut(duration: 0.3)) { addCVScreen = .addCV } }) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(AppTheme.goldFaint)
                        .frame(width: 32, height: 32)
                        .overlay(Circle().stroke(AppTheme.goldBorder, lineWidth: 0.5))
                    Text("+")
                        .font(.system(size: 18, weight: .light))
                        .foregroundStyle(AppTheme.gold)
                }
                Text("Add CV")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AppTheme.gold)
                Text("Scan or upload")
                    .font(.system(size: 9))
                    .foregroundStyle(AppTheme.textMuted)
                    .multilineTextAlignment(.center)
            }
            .padding(10)
            .frame(width: 88)
            .background(AppTheme.bgCard)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(style: StrokeStyle(lineWidth: 0.5, dash: [4]))
                    .foregroundStyle(AppTheme.bgBorder)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Selected CV banner

    private func selectedCVBanner(_ cv: CVProfile) -> some View {
        HStack(spacing: 10) {
            Text("✦").font(.system(size: 11)).foregroundStyle(AppTheme.gold)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(cv.name) selected")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppTheme.gold)
                Text("\(cv.fullName.isEmpty ? "CV" : cv.fullName) · \(cv.experience.count) roles · \(cv.skills.count) skills")
                    .font(.system(size: 10))
                    .foregroundStyle(AppTheme.textMuted)
            }
            Spacer()
            Button(action: { viewModel.selectedCVProfile = nil }) {
                Text("Clear")
                    .font(.system(size: 10))
                    .foregroundStyle(AppTheme.textMuted)
            }
        }
        .padding(10)
        .background(AppTheme.goldFaint)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppTheme.goldBorder, lineWidth: 0.5))
    }

    private func defaultProfileBanner(_ profile: UserProfile) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "person.circle.fill")
                .foregroundStyle(AppTheme.textDisabled).font(.system(size: 14))
            Text("Using: \(profile.fullName.isEmpty ? "My saved profile" : profile.fullName)")
                .font(.system(size: 11)).foregroundStyle(AppTheme.textMuted)
            Spacer()
        }
        .padding(10)
        .background(AppTheme.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppTheme.bgBorder, lineWidth: 0.5))
    }

    // MARK: - Input method card

    private func inputMethodCard(icon: String, label: String, subtitle: String,
                                  isFeatured: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isFeatured ? AppTheme.gold.opacity(0.2) : AppTheme.bgElevated)
                        .frame(width: 52, height: 52)
                    Image(systemName: icon).font(.system(size: 22))
                        .foregroundStyle(isFeatured ? AppTheme.gold : AppTheme.textMuted)
                }
                Text(label).font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(isFeatured ? AppTheme.gold : .white)
                Text(subtitle).font(.system(size: 10)).foregroundStyle(AppTheme.textMuted)
                    .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 16).padding(.horizontal, 4)
            .background(isFeatured ? AppTheme.goldFaint : AppTheme.bgCard)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
            .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                .stroke(isFeatured ? AppTheme.goldBorder : AppTheme.bgBorder,
                        lineWidth: isFeatured ? 1.0 : 0.5))
        }
        .buttonStyle(.plain)
    }

    // MARK: - JD ready card

    private var jdReadyCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AppTheme.success).font(.system(size: 13))
                    Text("Job description ready")
                        .font(.system(size: 13, weight: .medium)).foregroundStyle(AppTheme.success)
                }
                Spacer()
                Button("Clear") {
                    viewModel.jobDescription = ""
                    viewModel.jobTitle = ""
                    viewModel.company = ""
                }
                .font(.system(size: 12)).foregroundStyle(AppTheme.textMuted)
            }
            Text(viewModel.jobDescription)
                .font(.system(size: 12)).foregroundStyle(AppTheme.textMuted)
                .lineLimit(5).lineSpacing(3).frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14).background(AppTheme.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
        .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusMd)
            .stroke(AppTheme.success.opacity(0.4), lineWidth: 1))
    }

    // MARK: - Empty state

    private var emptyStateCard: some View {
        VStack(spacing: 10) {
            Image(systemName: "camera.viewfinder").font(.system(size: 34))
                .foregroundStyle(AppTheme.bgElevated)
            Text("Scan a job ad, paste text,\nor share from LinkedIn / Indeed")
                .font(.system(size: 13)).foregroundStyle(AppTheme.textDisabled)
                .multilineTextAlignment(.center).lineSpacing(3)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 28)
        .background(AppTheme.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
        .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusMd)
            .stroke(AppTheme.bgBorder, lineWidth: 0.5))
    }

    // MARK: - LinkedIn tip

    private var linkedInTip: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "lightbulb.fill").foregroundStyle(AppTheme.gold).font(.system(size: 13))
            VStack(alignment: .leading, spacing: 3) {
                Text("From LinkedIn or Indeed")
                    .font(.system(size: 12, weight: .semibold)).foregroundStyle(AppTheme.gold)
                Text("Open the job → Share → Copy text → come back and tap Paste. Or scan the screen.")
                    .font(.system(size: 11)).foregroundStyle(AppTheme.textMuted)
                    .lineSpacing(2).fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12).frame(maxWidth: .infinity, alignment: .leading).background(AppTheme.goldFaint)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
        .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusMd).stroke(AppTheme.goldBorder, lineWidth: 0.5))
    }

    // MARK: - Template row

    private var templateRow: some View {
        Button(action: { showTemplates = true }) {
            HStack(spacing: 12) {
                Image(systemName: "paintbrush").font(.system(size: 14))
                    .foregroundStyle(AppTheme.gold).frame(width: 24)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Template").font(.system(size: 13, weight: .medium)).foregroundStyle(AppTheme.textPrimary)
                    Text(viewModel.selectedTemplate.displayName)
                        .font(.system(size: 11)).foregroundStyle(AppTheme.textMuted)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 11))
                    .foregroundStyle(AppTheme.textDisabled)
            }
            .padding(14).background(AppTheme.bgCard)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
            .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                .stroke(AppTheme.bgBorder, lineWidth: 0.5))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Paywall banner

    private var paywallBanner: some View {
        Button(action: { showPaywall = true }) {
            HStack(spacing: 12) {
                Text("✦").font(.system(size: 16)).foregroundStyle(AppTheme.gold)
                VStack(alignment: .leading, spacing: 2) {
                    Text("You've used all free CVs")
                        .font(.system(size: 13, weight: .semibold)).foregroundStyle(AppTheme.textPrimary)
                    Text("Upgrade for unlimited generation")
                        .font(.system(size: 11)).foregroundStyle(AppTheme.textMuted)
                }
                Spacer()
                Text("Upgrade").font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AppTheme.bgPrimary).padding(.horizontal, 10).padding(.vertical, 5)
                    .background(AppTheme.gold).clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .padding(14).background(AppTheme.goldFaint)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
            .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                .stroke(AppTheme.goldBorder, lineWidth: 1.0))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Generate

    private func generate() {
        guard purchaseService.canGenerate else { showPaywall = true; return }
        screen = .generating
        Task { @MainActor in
            if let cvProfile = viewModel.selectedCVProfile {
                await viewModel.generate(cvProfile: cvProfile, purchaseService: purchaseService)
            } else if let profile {
                await viewModel.generate(profile: profile, purchaseService: purchaseService)
            } else {
                screen = .input; return
            }
            if case .complete(let doc) = viewModel.generationState {
                let app = JobApplication(
                    jobTitle:        viewModel.jobTitle,
                    company:         viewModel.company,
                    jobDescription:  viewModel.jobDescription,
                    jobSource:       "scanned"
                )
                app.document = doc
                modelContext.insert(app); modelContext.insert(doc)
                try? modelContext.save()
                onGenerated(app)
            } else {
                screen = .input
            }
        }
    }

    private func initials(_ name: String) -> String {
        let p = name.components(separatedBy: " ").filter { !$0.isEmpty }
        return String(p.prefix(2).compactMap { $0.first }).uppercased().isEmpty ? "CV" :
               String(p.prefix(2).compactMap { $0.first }).uppercased()
    }
}

// MARK: - Job Paste View

struct JobPasteView: View {
    var onSubmit: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    @FocusState private var focused: Bool

    var body: some View {
        ZStack {
            AppTheme.bgPrimary.ignoresSafeArea(.all)
            VStack(spacing: 0) {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark").foregroundStyle(AppTheme.textMuted)
                            .frame(width: 36, height: 36).background(AppTheme.bgCard)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(RoundedRectangle(cornerRadius: 10)
                                .stroke(AppTheme.bgBorder, lineWidth: 0.5))
                    }
                    Spacer()
                    Text("Paste job description")
                        .font(.system(size: 15, weight: .semibold)).foregroundStyle(AppTheme.textPrimary)
                    Spacer()
                    Button(action: {
                        if let clip = UIPasteboard.general.string, !clip.isEmpty { text = clip }
                    }) {
                        Text("Paste").font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(AppTheme.bgPrimary)
                            .padding(.horizontal, 14).padding(.vertical, 8)
                            .background(AppTheme.gold).clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
                .padding(.horizontal, 20).padding(.top, 20).padding(.bottom, 10)
                .background(AppTheme.bgPrimary)

                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "lightbulb.fill").foregroundStyle(AppTheme.gold).font(.system(size: 11))
                    Text("LinkedIn / Indeed → open job → Share → Copy text → tap Paste above")
                        .font(.system(size: 11)).foregroundStyle(AppTheme.textMuted)
                        .lineSpacing(2).fixedSize(horizontal: false, vertical: true)
                }
                .padding(10).frame(maxWidth: .infinity, alignment: .leading).background(AppTheme.goldFaint)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppTheme.goldBorder, lineWidth: 0.5))
                .padding(.horizontal, 20).padding(.bottom, 10).background(AppTheme.bgPrimary)

                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: AppTheme.radiusMd).fill(AppTheme.bgCard)
                        .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                            .stroke(focused ? AppTheme.goldBorder : AppTheme.bgBorder, lineWidth: 0.5))
                    if text.isEmpty {
                        Text("Paste the full job description here…")
                            .font(.system(size: 14)).foregroundStyle(AppTheme.textDisabled)
                            .padding(14).allowsHitTesting(false)
                    }
                    TextEditor(text: $text).font(.system(size: 13)).foregroundStyle(AppTheme.textPrimary)
                        .scrollContentBackground(.hidden).background(Color.clear)
                        .padding(10).focused($focused)
                }
                .padding(.horizontal, 20).frame(maxHeight: .infinity)

                Button(action: {
                    let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !t.isEmpty else { return }
                    dismiss(); onSubmit(t)
                }) {
                    Text("Use this job description  ✦")
                        .font(.system(size: 15, weight: .semibold)).foregroundStyle(AppTheme.bgPrimary)
                        .frame(maxWidth: .infinity).padding(.vertical, 15)
                        .background(text.isEmpty ? AppTheme.gold.opacity(0.4) : AppTheme.gold)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
                }
                .disabled(text.isEmpty)
                .padding(.horizontal, 20).padding(.top, 12).padding(.bottom, 36)
                .background(AppTheme.bgPrimary)
            }
        }
        .onAppear { focused = true }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}

// MARK: - CV Score Sheet (pre-generation match analysis)

struct CVScoreSheet: View {
    let jobDescription: String
    let cvContent: String
    let onGenerate: () -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var result: AIService.MatchResult?
    @State private var isLoading = true
    @State private var error: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if isLoading {
                    VStack(spacing: 14) {
                        Spacer()
                        ProgressView().tint(AppTheme.gold).scaleEffect(1.4)
                        Text("Analysing your CV against this role…")
                            .font(.system(size: 14)).foregroundStyle(AppTheme.textMuted)
                        Spacer()
                    }
                } else if let err = error {
                    VStack(spacing: 12) {
                        Spacer()
                        Text(err).font(.system(size: 14)).foregroundStyle(AppTheme.textMuted).multilineTextAlignment(.center)
                        Button("Skip & Generate") { dismiss(); onGenerate() }.buttonStyle(GoldButtonStyle())
                        Spacer()
                    }
                    .padding(32)
                } else if let r = result {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Score ring
                            ZStack {
                                Circle().stroke(AppTheme.bgBorder, lineWidth: 14).frame(width: 150, height: 150)
                                Circle().trim(from: 0, to: CGFloat(r.score) / 100)
                                    .stroke(scoreColor(r.score), style: StrokeStyle(lineWidth: 14, lineCap: .round))
                                    .frame(width: 150, height: 150).rotationEffect(.degrees(-90))
                                    .animation(.easeInOut(duration: 0.9), value: r.score)
                                VStack(spacing: 2) {
                                    Text("\(r.score)%").font(.system(size: 38, weight: .bold)).foregroundStyle(scoreColor(r.score))
                                    Text("CV Match").font(.system(size: 12)).foregroundStyle(AppTheme.textMuted)
                                }
                            }
                            .padding(.top, 8)

                            // Interpretation
                            Text(interpretation(r.score))
                                .font(.system(size: 14)).foregroundStyle(AppTheme.textMuted)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)

                            // Insights
                            if !r.insights.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("How to improve your match")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(AppTheme.textPrimary)
                                    ForEach(r.insights, id: \.self) { insight in
                                        HStack(alignment: .top, spacing: 8) {
                                            Image(systemName: "lightbulb.fill").foregroundStyle(AppTheme.gold).font(.system(size: 12)).padding(.top, 1)
                                            Text(insight).font(.system(size: 12)).foregroundStyle(AppTheme.textSecond).lineSpacing(3)
                                        }
                                        .padding(10)
                                        .background(AppTheme.goldFaint)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppTheme.goldBorder, lineWidth: 0.5))
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 4)
                            }

                            Spacer(minLength: 40)
                        }
                        .padding(20)
                    }

                    // Generate button
                    VStack(spacing: 10) {
                        Button(action: { dismiss(); onGenerate() }) {
                            HStack(spacing: 8) {
                                Image(systemName: "sparkles")
                                Text("Generate Optimised CV")
                            }
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(AppTheme.bgPrimary)
                            .frame(maxWidth: .infinity).padding(.vertical, 15)
                            .background(AppTheme.gold)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
                        }
                        .buttonStyle(.plain)

                        Text("AI will boost your score by tailoring the CV to this role")
                            .font(.system(size: 11)).foregroundStyle(AppTheme.textDisabled)
                    }
                    .padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 34)
                    .background(.ultraThinMaterial)
                    .overlay(alignment: .top) { Rectangle().fill(AppTheme.bgBorder).frame(height: 0.5) }
                }
            }
            .background(AppTheme.bgPrimary)
            .navigationTitle("Match Score")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundStyle(AppTheme.textMuted)
                }
            }
        }
        .task {
            guard !jobDescription.isEmpty && !cvContent.isEmpty else {
                error = "Add your CV and job description first"; isLoading = false; return
            }
            do {
                let r = try await AIService.shared.calculateMatchScore(cvContent: cvContent, jobDescription: jobDescription)
                withAnimation { self.result = r; self.isLoading = false }
            } catch {
                self.error = "Couldn't analyse score. You can still generate."
                self.isLoading = false
            }
        }
    }

    private func scoreColor(_ s: Int) -> Color { s >= 70 ? AppTheme.success : s >= 50 ? AppTheme.gold : AppTheme.danger }
    private func interpretation(_ s: Int) -> String {
        switch s {
        case 0..<40: return "Your CV is a \(s)% match. Generating will boost it significantly for this role."
        case 40..<65: return "Your CV is a \(s)% match. AI will tailor it to improve the fit."
        case 65..<80: return "Good match at \(s)%. Generating will fine-tune it further."
        default:      return "Excellent \(s)% match! Generating will optimise the final details."
        }
    }
}
