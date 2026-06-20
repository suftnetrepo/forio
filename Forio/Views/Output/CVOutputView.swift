import SwiftUI
import SwiftData

struct CVOutputView: View {
    @Environment(\.modelContext) private var modelContext

    let application: JobApplication
    var onBack: () -> Void

    @State private var selectedTab: OutputTab = .cv
    @State private var showShareSheet = false
    @State private var shareItems: [Any] = []
    @State private var showTemplates = false
    @State private var showInterviewPrep = false
    @State private var isEditing = false
    @State private var isExporting = false
    @State private var exportFormat: ExportFormat = .pdf
    @State private var showExportSuccess = false
    @State private var exportSuccessMessage = ""
    @State private var showAllKeywords = false

    enum OutputTab    { case cv, coverLetter, interview, ats, share }
    enum ExportFormat { case pdf, word }
    enum ExportType   { case cv, coverLetter }

    var document: GeneratedDocument? { application.document }

    var body: some View {
        ZStack {
            AppTheme.bgPrimary.ignoresSafeArea()

            if let doc = document {
                VStack(spacing: 0) {
                    headerBar
                    tabBar
                    tabContent(doc: doc)
                }
                // Floating export bar — only on CV and Letter tabs
                if selectedTab == .cv || selectedTab == .coverLetter {
                    VStack { Spacer(); exportBar(doc: doc) }
                }
            } else {
                emptyState
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showShareSheet) { ShareSheet(items: shareItems) }
        .sheet(isPresented: $showInterviewPrep) { InterviewPrepView(application: application) }
        .sheet(isPresented: $showTemplates) {
            if let doc = document {
                TemplatePickerSheet(selected: Binding(
                    get: { doc.template },
                    set: { doc.template = $0; try? modelContext.save() }
                ))
            }
        }
        .overlay(alignment: .top) {
            if showExportSuccess {
                exportToast.padding(.top, 60)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack(spacing: 12) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .frame(width: 36, height: 36)
                    .background(AppTheme.bgCard)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppTheme.bgBorder, lineWidth: 0.5))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Generated CV")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                if !application.company.isEmpty {
                    Text(application.company)
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.textMuted)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: { showTemplates = true }) {
                Image(systemName: "paintbrush.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(AppTheme.gold)
                    .frame(width: 36, height: 36)
                    .background(AppTheme.goldFaint)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppTheme.goldBorder, lineWidth: 0.5))
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 56)
        .padding(.bottom, 12)
    }

    // MARK: - Tab Bar (3 main tabs like the design)

    private var tabBar: some View {
        HStack(spacing: 0) {
            tabBtn("CV",           tab: .cv)
            tabBtn("Cover Letter", tab: .coverLetter)
            tabBtn("Interview",    tab: .interview)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }

    private func tabBtn(_ label: String, tab: OutputTab) -> some View {
        let isSelected = selectedTab == tab
        return Button(action: {
            withAnimation(.spring(response: 0.25)) { selectedTab = tab }
        }) {
            Text(label)
                .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? AppTheme.textPrimary : AppTheme.textMuted)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    isSelected
                    ? LinearGradient(colors: [AppTheme.gold.opacity(0.15), AppTheme.gold.opacity(0.05)],
                                     startPoint: .top, endPoint: .bottom)
                    : LinearGradient(colors: [Color.clear], startPoint: .top, endPoint: .bottom)
                )
                .overlay(alignment: .bottom) {
                    if isSelected {
                        Capsule().fill(AppTheme.gold).frame(height: 3)
                    }
                }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Tab Content

    @ViewBuilder
    private func tabContent(doc: GeneratedDocument) -> some View {
        switch selectedTab {
        case .cv:
            cvTab(doc: doc)
        case .coverLetter:
            coverLetterTab(doc: doc)
        case .interview:
            interviewTab
        case .ats:
            ATSScoreView(cvContent: doc.displayCV)
        case .share:
            CVShareView(application: application)
        }
    }

    // MARK: - CV Tab (main redesigned screen)

    private func cvTab(doc: GeneratedDocument) -> some View {
        ScrollView {
            VStack(spacing: 16) {

                // ── HERO MATCH CARD ──
                heroMatchCard(doc: doc)

                // ── WHY THIS CV WAS TAILORED ──
                if !doc.aiInsights.isEmpty {
                    insightsSection(doc: doc)
                }

                // ── MATCHED KEYWORDS ──
                if !doc.matchedKeywords.isEmpty {
                    keywordsSection(doc: doc)
                }

                // ── CV PREVIEW ──
                cvPreviewSection(doc: doc)

                Spacer(minLength: 200)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
    }

    // MARK: - Hero Match Card

    private func heroMatchCard(doc: GeneratedDocument) -> some View {
        ZStack {
            // Dark gradient background
            RoundedRectangle(cornerRadius: AppTheme.radiusXl)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "1A1040"),
                            Color(hex: "0E0A1A")
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Glow behind ring
            Circle()
                .fill(scoreColor(doc.matchScore).opacity(0.12))
                .frame(width: 180, height: 180)
                .offset(x: -60, y: 10)
                .blur(radius: 30)

            HStack(spacing: 20) {
                // Score ring — large
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.08), lineWidth: 10)
                        .frame(width: 110, height: 110)

                    Circle()
                        .trim(from: 0, to: CGFloat(doc.matchScore) / 100)
                        .stroke(
                            AngularGradient(
                                colors: [scoreColor(doc.matchScore), scoreColor(doc.matchScore).opacity(0.4)],
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                        )
                        .frame(width: 110, height: 110)
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(response: 0.8), value: doc.matchScore)

                    VStack(spacing: 0) {
                        Text("\(doc.matchScore)")
                            .font(.system(size: 34, weight: .black))
                            .foregroundStyle(.white)
                        Text("%")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }

                // Right side info
                VStack(alignment: .leading, spacing: 10) {
                    // Badge
                    HStack(spacing: 5) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 10))
                        Text(scoreLabel(doc.matchScore))
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(scoreColor(doc.matchScore))
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(scoreColor(doc.matchScore).opacity(0.15))
                    .clipShape(Capsule())

                    // Role name
                    Text("Strong match for")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.6))
                    if !application.jobTitle.isEmpty {
                        Text(application.jobTitle)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                            .lineLimit(2)
                    }

                    // Stats
                    VStack(alignment: .leading, spacing: 6) {
                        statRow(icon: "checkmark.circle.fill", color: AppTheme.success,
                                text: "\(doc.matchedKeywords.count) skills matched")
                        statRow(icon: "checkmark.circle.fill", color: Color(hex: "7B61FF"),
                                text: "\(doc.aiInsights.count) improvements made")
                    }
                }

                Spacer()
            }
            .padding(20)
        }
        .frame(maxWidth: .infinity)
    }

    private func statRow(icon: String, color: Color, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(color)
            Text(text)
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.85))
        }
    }

    // MARK: - Insights Section (Why this CV was tailored)

    private func insightsSection(doc: GeneratedDocument) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 14))
                    .foregroundStyle(AppTheme.gold)
                Text("Why this CV was tailored")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary)
            }

            VStack(spacing: 8) {
                ForEach(Array(doc.aiInsights.prefix(3).enumerated()), id: \.offset) { i, insight in
                    insightRow(insight: insight, index: i)
                }
            }
        }
    }

    private func insightRow(insight: String, index: Int) -> some View {
        let icons = ["pencil.and.outline", "star.fill", "chart.line.uptrend.xyaxis"]
        let colors: [Color] = [Color(hex: "6366F1"), Color(hex: "F59E0B"), Color(hex: "10B981")]
        let titles = ["Summary refocused", "Skills prioritised", "Experience optimised"]

        let icon  = index < icons.count  ? icons[index]  : "checkmark.circle.fill"
        let color = index < colors.count ? colors[index] : AppTheme.gold
        let title = index < titles.count ? titles[index] : "Improvement made"

        return HStack(spacing: 14) {
            // Icon box
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(color)
            }

            // Text
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                Text(insight)
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.textMuted)
                    .lineSpacing(3)
                    .lineLimit(3)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundStyle(AppTheme.textDisabled)
        }
        .padding(14)
        .background(AppTheme.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
        .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusMd).stroke(AppTheme.bgBorder, lineWidth: 0.5))
    }

    // MARK: - Keywords Section

    private func keywordsSection(doc: GeneratedDocument) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Matched keywords")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
                Text("\(doc.matchedKeywords.count) found")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppTheme.success)
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(AppTheme.successFaint)
                    .clipShape(Capsule())
            }

            let keywords = showAllKeywords ? doc.matchedKeywords : Array(doc.matchedKeywords.prefix(12))
            FlowLayout(spacing: 8) {
                ForEach(keywords, id: \.self) { kw in
                    HStack(spacing: 5) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(AppTheme.success)
                        Text(kw)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(AppTheme.textPrimary)
                    }
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(AppTheme.bgCard)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(AppTheme.bgBorder, lineWidth: 0.5))
                }
            }

            if doc.matchedKeywords.count > 12 {
                Button(action: { withAnimation { showAllKeywords.toggle() } }) {
                    HStack {
                        Text(showAllKeywords ? "Show fewer" : "View all matched keywords")
                            .font(.system(size: 13))
                            .foregroundStyle(AppTheme.textMuted)
                        Image(systemName: showAllKeywords ? "chevron.up" : "chevron.right")
                            .font(.system(size: 11))
                            .foregroundStyle(AppTheme.textDisabled)
                        Spacer()
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(AppTheme.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
        .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusMd).stroke(AppTheme.bgBorder, lineWidth: 0.5))
    }

    // MARK: - CV Preview Section

    private func cvPreviewSection(doc: GeneratedDocument) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("CV preview")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AppTheme.textPrimary)

            // White preview card (mimics printed CV)
            VStack(alignment: .leading, spacing: 0) {
                // CV content preview — first ~400 chars
                let preview = doc.displayCV.prefix(500)
                Text(String(preview))
                    .font(.system(size: 8.5))
                    .foregroundStyle(Color(hex: "1A1A2E"))
                    .lineSpacing(3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)

                // Fade out bottom
                LinearGradient(
                    colors: [Color.white.opacity(0), Color.white],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: 60)
                .offset(y: -60)
                .padding(.bottom, -60)
            }
            .frame(height: 240)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
            .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusMd).stroke(Color.gray.opacity(0.15), lineWidth: 0.5))
            .shadow(color: .black.opacity(0.08), radius: 8, y: 4)

            // View full CV button
            Button(action: { selectedTab = .cv }) {
                HStack {
                    Spacer()
                    Text("View full CV")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppTheme.gold)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.gold)
                    Spacer()
                }
                .padding(.vertical, 12)
                .background(AppTheme.goldFaint)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
                .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusMd).stroke(AppTheme.goldBorder, lineWidth: 0.5))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Cover Letter Tab

    private func coverLetterTab(doc: GeneratedDocument) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Image(systemName: "envelope.fill").font(.system(size: 12)).foregroundStyle(AppTheme.gold)
                    Text("Cover Letter").font(.system(size: 12, weight: .semibold)).foregroundStyle(AppTheme.textMuted)
                    Spacer()
                    Button(action: { isEditing.toggle(); if !isEditing { try? modelContext.save() } }) {
                        HStack(spacing: 4) {
                            Image(systemName: isEditing ? "checkmark" : "pencil").font(.system(size: 10))
                            Text(isEditing ? "Done" : "Edit").font(.system(size: 11, weight: .medium))
                        }
                        .foregroundStyle(isEditing ? AppTheme.gold : AppTheme.textMuted)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(isEditing ? AppTheme.goldFaint : AppTheme.bgElevated)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }
                .padding(.horizontal, 14).padding(.vertical, 10)
                .background(AppTheme.bgElevated)

                Divider().background(AppTheme.bgBorder)

                if isEditing {
                    TextEditor(text: Binding(
                        get: { doc.coverLetterContent },
                        set: { doc.coverLetterContent = $0 }
                    ))
                    .font(.system(size: 13)).foregroundStyle(AppTheme.textSecond)
                    .scrollContentBackground(.hidden).background(Color.clear)
                    .padding(14).frame(minHeight: 500)
                } else {
                    Text(doc.coverLetterContent.isEmpty ? "No cover letter generated." : doc.coverLetterContent)
                        .font(.system(size: 13)).foregroundStyle(AppTheme.textSecond)
                        .lineSpacing(5).frame(maxWidth: .infinity, alignment: .leading).padding(14)
                }
            }
            .background(AppTheme.bgCard)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
            .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusMd).stroke(AppTheme.bgBorder, lineWidth: 0.5))
            .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 200)
        }
    }

    // MARK: - Interview Tab

    private var interviewTab: some View {
        VStack {
            Spacer()
            VStack(spacing: 24) {
                ZStack {
                    Circle().fill(AppTheme.goldFaint).frame(width: 100, height: 100)
                    Image(systemName: "person.2.fill").font(.system(size: 40)).foregroundStyle(AppTheme.gold)
                }
                VStack(spacing: 10) {
                    Text("Interview Prep")
                        .font(.system(size: 26, weight: .bold)).foregroundStyle(AppTheme.textPrimary)
                    Text("Get 20 interview questions tailored to this exact role and your CV — with a suggested approach for each.")
                        .font(.system(size: 15)).foregroundStyle(AppTheme.textMuted)
                        .multilineTextAlignment(.center).lineSpacing(4)
                }
                HStack(spacing: 10) {
                    featurePill("20 questions", icon: "list.number")
                    featurePill("AI answers",   icon: "sparkles")
                    featurePill("Live coding",  icon: "keyboard")
                }
                Button(action: { showInterviewPrep = true }) {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles").font(.system(size: 15, weight: .semibold))
                        Text("Start Interview Prep").font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundStyle(AppTheme.buttonFg)
                    .frame(maxWidth: .infinity).padding(.vertical, 17)
                    .background(AppTheme.gold)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
                }
                .buttonStyle(.plain)
            }
            .padding(28)
            .background(AppTheme.bgCard)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusXl))
            .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusXl).stroke(AppTheme.bgBorder, lineWidth: 0.5))
            .shadow(color: .black.opacity(0.2), radius: 20, y: 8)
            .padding(.horizontal, 20)
            Spacer()
        }
    }

    private func featurePill(_ text: String, icon: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon).font(.system(size: 10, weight: .semibold))
            Text(text).font(.system(size: 11, weight: .semibold))
        }
        .foregroundStyle(AppTheme.gold)
        .padding(.horizontal, 10).padding(.vertical, 6)
        .background(AppTheme.goldFaint).clipShape(Capsule())
        .overlay(Capsule().stroke(AppTheme.goldBorder, lineWidth: 0.5))
    }

    // MARK: - Export Bar

    private func exportBar(doc: GeneratedDocument) -> some View {
        VStack(spacing: 10) {
            // Format selector
            HStack(spacing: 8) {
                ForEach([(ExportFormat.pdf, "PDF"), (.word, "Word")], id: \.1) { fmt, label in
                    Button(action: { exportFormat = fmt }) {
                        Text(label)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(exportFormat == fmt ? AppTheme.gold : AppTheme.textMuted)
                            .frame(maxWidth: .infinity).padding(.vertical, 7)
                            .background(exportFormat == fmt ? AppTheme.goldFaint : AppTheme.bgElevated)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .overlay(RoundedRectangle(cornerRadius: 20)
                                .stroke(exportFormat == fmt ? AppTheme.goldBorder : Color.clear, lineWidth: 0.5))
                    }
                    .buttonStyle(.plain)
                }
            }

            // Export button + share
            HStack(spacing: 10) {
                Button(action: { handleExport(doc: doc) }) {
                    HStack(spacing: 8) {
                        if isExporting {
                            ProgressView().tint(AppTheme.buttonFg).scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.down.circle.fill").font(.system(size: 16))
                        }
                        Text(isExporting ? "Exporting…"
                             : "Export \(selectedTab == .coverLetter ? "Cover Letter" : "CV") as \(exportFormat == .pdf ? "PDF" : "Word")")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundStyle(AppTheme.buttonFg)
                    .frame(maxWidth: .infinity).padding(.vertical, 15)
                    .background(isExporting ? AppTheme.gold.opacity(0.6) : AppTheme.gold)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
                }
                .buttonStyle(.plain).disabled(isExporting)

                Button(action: { handleShare(doc: doc) }) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16))
                        .foregroundStyle(AppTheme.textPrimary)
                        .frame(width: 50, height: 50)
                        .background(AppTheme.bgCard)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
                        .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusMd).stroke(AppTheme.bgBorder, lineWidth: 0.5))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16).padding(.top, 12).padding(.bottom, 36)
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) { Rectangle().fill(AppTheme.bgBorder).frame(height: 0.5) }
    }

    // MARK: - Helpers

    private func scoreColor(_ score: Int) -> Color {
        score >= 75 ? AppTheme.success : score >= 50 ? AppTheme.gold : AppTheme.danger
    }

    private func scoreLabel(_ score: Int) -> String {
        score >= 85 ? "Excellent Match" : score >= 70 ? "Strong Match" : score >= 50 ? "Good Match" : "Partial Match"
    }

    private func handleExport(doc: GeneratedDocument) {
        let content = selectedTab == .coverLetter ? doc.coverLetterContent : doc.displayCV
        let isCL    = selectedTab == .coverLetter
        let company = application.company.isEmpty ? "Application" : application.company

        if exportFormat == .pdf {
            isExporting = true
            Task {
                let filename = isCL
                    ? "CoverLetter_\(company.replacingOccurrences(of: " ", with: "_")).pdf"
                    : "CV_\(company.replacingOccurrences(of: " ", with: "_")).pdf"
                let data = PDFRenderService.render(content: content, template: doc.template,
                                                   jobTitle: application.jobTitle, company: company)
                let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
                try? data.write(to: url)
                await MainActor.run {
                    isExporting = false
                    application.status = .exported; try? modelContext.save()
                    shareItems = [url]; showShareSheet = true
                    exportSuccessMessage = isCL ? "Cover letter PDF ready" : "CV PDF ready"
                    showExportSuccess = true
                    Task { try? await Task.sleep(nanoseconds: 2_500_000_000)
                        await MainActor.run { showExportSuccess = false } }
                }
            }
        } else {
            guard let url = WordExportService.export(
                cvContent: doc.displayCV, coverLetter: doc.coverLetterContent,
                jobTitle: application.jobTitle, company: company,
                exportType: isCL ? .coverLetter : .cv
            ) else { return }
            application.status = .exported; try? modelContext.save()
            shareItems = [url]; showShareSheet = true
            exportSuccessMessage = isCL ? "Cover letter Word doc ready" : "CV Word doc ready"
            showExportSuccess = true
            Task { try? await Task.sleep(nanoseconds: 2_500_000_000)
                await MainActor.run { showExportSuccess = false } }
        }
    }

    private func handleShare(doc: GeneratedDocument) {
        let content = selectedTab == .coverLetter ? doc.coverLetterContent : doc.displayCV
        shareItems = [content]; showShareSheet = true
    }

    // MARK: - Empty / Toast

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Text("No document found").font(.system(size: 16)).foregroundStyle(AppTheme.textMuted)
            Button("Go back") { onBack() }.buttonStyle(GhostButtonStyle()).padding(.horizontal, 40)
            Spacer()
        }
    }

    private var exportToast: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill").foregroundStyle(AppTheme.success)
            Text(exportSuccessMessage).font(.system(size: 13, weight: .medium)).foregroundStyle(AppTheme.textPrimary)
        }
        .padding(.horizontal, 20).padding(.vertical, 12)
        .background(AppTheme.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
        .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusMd).stroke(AppTheme.bgBorder, lineWidth: 0.5))
    }
}

private struct NavigationControllerKey: EnvironmentKey {
    static let defaultValue: UINavigationController? = nil
}
extension EnvironmentValues {
    var navigationController: UINavigationController? {
        get { self[NavigationControllerKey.self] }
        set { self[NavigationControllerKey.self] = newValue }
    }
}
