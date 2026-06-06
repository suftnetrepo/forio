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
    @State private var isScanning = false
    @State private var scanError: String? = nil

    enum Screen { case input, generating }
    @State private var screen: Screen = .input

    var onGenerated: (JobApplication) -> Void
    var onBack: () -> Void
    var profile: UserProfile? { profiles.first }

    private var topSafeArea: CGFloat {
        (UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows
            .first?.safeAreaInsets.top) ?? 44
    }

    var body: some View {
        ZStack {
            Color(hex: "0A0A0F").ignoresSafeArea(.all)
            switch screen {
            case .input:     inputView
            case .generating: GenerationProgressView(viewModel: viewModel)
            }
        }
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
                            scanError = "Couldn't read the job ad — try paste instead."
                        }
                        isScanning = false
                    }
                }
            }
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
        .sheet(isPresented: $showAddCV) {
            ScanAndNameCVView { newProfile in
                viewModel.selectedCVProfile = newProfile
            }
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
                        .background(Color(hex: "13131a"))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(hex: "2a2a3a"), lineWidth: 0.5))
                }
                Spacer()
                Text("New Application")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white)
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
            .padding(.top, topSafeArea + 16)
            .padding(.bottom, 16)
            .background(Color(hex: "0A0A0F"))

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {

                    // ── CV PICKER SECTION ─────────────────────────────────
                    VStack(alignment: .leading, spacing: 8) {
                        Text("SELECT CV")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(Color(hex: "666666"))
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
                            .foregroundStyle(Color(hex: "666666"))
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
                                    .font(.system(size: 13)).foregroundStyle(Color(hex: "888888"))
                            }
                            .frame(maxWidth: .infinity).padding(14)
                            .background(Color(hex: "13131a"))
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
                        .foregroundStyle(Color(hex: "0A0A0F"))
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
                        .fill(isSelected ? AppTheme.gold : Color(hex: "2a2a3a"))
                        .frame(width: 32, height: 32)
                    Text(initials(cv.fullName))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(isSelected ? Color(hex: "0A0A0F") : Color(hex: "888888"))
                }

                Text(cv.name)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(isSelected ? AppTheme.gold : .white)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text("\(cv.experience.count) roles")
                    .font(.system(size: 9))
                    .foregroundStyle(Color(hex: "666666"))

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
            .background(isSelected ? AppTheme.goldFaint : Color(hex: "13131a"))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? AppTheme.goldBorder : Color(hex: "2a2a3a"),
                            lineWidth: isSelected ? 1.0 : 0.5)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Add CV card

    private var addCVCard: some View {
        Button(action: { showAddCV = true }) {
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
                    .foregroundStyle(Color(hex: "666666"))
                    .multilineTextAlignment(.center)
            }
            .padding(10)
            .frame(width: 88)
            .background(Color(hex: "12111A"))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(style: StrokeStyle(lineWidth: 0.5, dash: [4]))
                    .foregroundStyle(Color(hex: "3A3850"))
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
                    .foregroundStyle(Color(hex: "888888"))
            }
            Spacer()
            Button(action: { viewModel.selectedCVProfile = nil }) {
                Text("Clear")
                    .font(.system(size: 10))
                    .foregroundStyle(Color(hex: "666666"))
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
                .foregroundStyle(Color(hex: "555555")).font(.system(size: 14))
            Text("Using: \(profile.fullName.isEmpty ? "My saved profile" : profile.fullName)")
                .font(.system(size: 11)).foregroundStyle(Color(hex: "888888"))
            Spacer()
        }
        .padding(10)
        .background(Color(hex: "13131a"))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: "2a2a3a"), lineWidth: 0.5))
    }

    // MARK: - Input method card

    private func inputMethodCard(icon: String, label: String, subtitle: String,
                                  isFeatured: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isFeatured ? AppTheme.gold.opacity(0.2) : Color(hex: "1E1C2A"))
                        .frame(width: 52, height: 52)
                    Image(systemName: icon).font(.system(size: 22))
                        .foregroundStyle(isFeatured ? AppTheme.gold : Color(hex: "888888"))
                }
                Text(label).font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(isFeatured ? AppTheme.gold : .white)
                Text(subtitle).font(.system(size: 10)).foregroundStyle(Color(hex: "666666"))
                    .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 16).padding(.horizontal, 4)
            .background(isFeatured ? AppTheme.goldFaint : Color(hex: "13131a"))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
            .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                .stroke(isFeatured ? AppTheme.goldBorder : Color(hex: "2a2a3a"),
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
                .font(.system(size: 12)).foregroundStyle(Color(hex: "666666"))
            }
            Text(viewModel.jobDescription)
                .font(.system(size: 12)).foregroundStyle(Color(hex: "888888"))
                .lineLimit(5).lineSpacing(3).frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14).background(Color(hex: "13131a"))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
        .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusMd)
            .stroke(AppTheme.success.opacity(0.4), lineWidth: 1))
    }

    // MARK: - Empty state

    private var emptyStateCard: some View {
        VStack(spacing: 10) {
            Image(systemName: "camera.viewfinder").font(.system(size: 34))
                .foregroundStyle(Color(hex: "333333"))
            Text("Scan a job ad, paste text,\nor share from LinkedIn / Indeed")
                .font(.system(size: 13)).foregroundStyle(Color(hex: "555555"))
                .multilineTextAlignment(.center).lineSpacing(3)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 28)
        .background(Color(hex: "13131a"))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
        .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusMd)
            .stroke(Color(hex: "2a2a3a"), lineWidth: 0.5))
    }

    // MARK: - LinkedIn tip

    private var linkedInTip: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "lightbulb.fill").foregroundStyle(AppTheme.gold).font(.system(size: 13))
            VStack(alignment: .leading, spacing: 3) {
                Text("From LinkedIn or Indeed")
                    .font(.system(size: 12, weight: .semibold)).foregroundStyle(AppTheme.gold)
                Text("Open the job → Share → Copy text → come back and tap Paste. Or scan the screen.")
                    .font(.system(size: 11)).foregroundStyle(Color(hex: "888888"))
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
                    Text("Template").font(.system(size: 13, weight: .medium)).foregroundStyle(.white)
                    Text(viewModel.selectedTemplate.displayName)
                        .font(.system(size: 11)).foregroundStyle(Color(hex: "888888"))
                }
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 11))
                    .foregroundStyle(Color(hex: "555555"))
            }
            .padding(14).background(Color(hex: "13131a"))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
            .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                .stroke(Color(hex: "2a2a3a"), lineWidth: 0.5))
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
                        .font(.system(size: 13, weight: .semibold)).foregroundStyle(.white)
                    Text("Upgrade for unlimited generation")
                        .font(.system(size: 11)).foregroundStyle(Color(hex: "888888"))
                }
                Spacer()
                Text("Upgrade").font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color(hex: "0A0A0F")).padding(.horizontal, 10).padding(.vertical, 5)
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
            Color(hex: "0A0A0F").ignoresSafeArea(.all)
            VStack(spacing: 0) {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark").foregroundStyle(Color(hex: "888888"))
                            .frame(width: 36, height: 36).background(Color(hex: "13131a"))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(RoundedRectangle(cornerRadius: 10)
                                .stroke(Color(hex: "2a2a3a"), lineWidth: 0.5))
                    }
                    Spacer()
                    Text("Paste job description")
                        .font(.system(size: 15, weight: .semibold)).foregroundStyle(.white)
                    Spacer()
                    Button(action: {
                        if let clip = UIPasteboard.general.string, !clip.isEmpty { text = clip }
                    }) {
                        Text("Paste").font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color(hex: "0A0A0F"))
                            .padding(.horizontal, 14).padding(.vertical, 8)
                            .background(AppTheme.gold).clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
                .padding(.horizontal, 20).padding(.top, 20).padding(.bottom, 10)
                .background(Color(hex: "0A0A0F"))

                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "lightbulb.fill").foregroundStyle(AppTheme.gold).font(.system(size: 11))
                    Text("LinkedIn / Indeed → open job → Share → Copy text → tap Paste above")
                        .font(.system(size: 11)).foregroundStyle(Color(hex: "888888"))
                        .lineSpacing(2).fixedSize(horizontal: false, vertical: true)
                }
                .padding(10).frame(maxWidth: .infinity, alignment: .leading).background(AppTheme.goldFaint)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppTheme.goldBorder, lineWidth: 0.5))
                .padding(.horizontal, 20).padding(.bottom, 10).background(Color(hex: "0A0A0F"))

                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: AppTheme.radiusMd).fill(Color(hex: "13131a"))
                        .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                            .stroke(focused ? AppTheme.goldBorder : Color(hex: "2a2a3a"), lineWidth: 0.5))
                    if text.isEmpty {
                        Text("Paste the full job description here…")
                            .font(.system(size: 14)).foregroundStyle(Color(hex: "444444"))
                            .padding(14).allowsHitTesting(false)
                    }
                    TextEditor(text: $text).font(.system(size: 13)).foregroundStyle(.white)
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
                        .font(.system(size: 15, weight: .semibold)).foregroundStyle(Color(hex: "0A0A0F"))
                        .frame(maxWidth: .infinity).padding(.vertical, 15)
                        .background(text.isEmpty ? AppTheme.gold.opacity(0.4) : AppTheme.gold)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
                }
                .disabled(text.isEmpty)
                .padding(.horizontal, 20).padding(.top, 12).padding(.bottom, 36)
                .background(Color(hex: "0A0A0F"))
            }
        }
        .onAppear { focused = true }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}
