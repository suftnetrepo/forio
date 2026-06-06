import SwiftUI
import SwiftData

struct CVOutputView: View {
    @Environment(\.modelContext) private var modelContext

    let application: JobApplication
    var onBack: () -> Void

    @State private var selectedTab: OutputTab = .cv
    @State private var isEditing = false
    @State private var showShareSheet = false
    @State private var shareItems: [Any] = []
    @State private var showTemplates = false
    @State private var isExportingCV = false
    @State private var isExportingCL = false
    @State private var showExportSuccess = false
    @State private var exportSuccessMessage = ""
    @State private var purchaseService = PurchaseService.shared

    enum OutputTab { case cv, coverLetter }

    var document: GeneratedDocument? { application.document }

    private var topSafeArea: CGFloat {
        (UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows
            .first?.safeAreaInsets.top) ?? 44
    }

    var body: some View {
        ZStack {
            AppTheme.bgPrimary.ignoresSafeArea(.all)

            if let doc = document {
                VStack(spacing: 0) {
                    headerBar(doc: doc)
                    tabSelector
                    // Full screen scrollable content
                    contentArea(doc: doc)
                    bottomBar(doc: doc)
                }
            } else {
                emptyState
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: shareItems)
        }
        .sheet(isPresented: $showTemplates) {
            if let doc = document {
                TemplatePickerSheet(selected: Binding(
                    get: { doc.template },
                    set: { doc.template = $0; try? modelContext.save() }
                ))
            }
        }
        .overlay(alignment: .bottom) {
            if showExportSuccess {
                exportToast
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.spring(duration: 0.4), value: showExportSuccess)
                    .padding(.bottom, 110)
            }
        }
    }

    // MARK: - Header

    private func headerBar(doc: GeneratedDocument) -> some View {
        HStack(spacing: 12) {
            Button(action: { onBack() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppTheme.textMuted)
                    .frame(width: 32, height: 32)
                    .background(AppTheme.bgCard)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(application.company.isEmpty ? "Your CV" : application.company)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppTheme.textPrimary)
                Text(application.jobTitle.isEmpty ? "Generated CV" : application.jobTitle)
                    .font(.system(size: 11))
                    .foregroundStyle(AppTheme.textMuted)
            }

            Spacer()

            matchScoreBadge(score: doc.matchScore)

            Button(action: { showTemplates = true }) {
                Image(systemName: "paintbrush")
                    .font(.system(size: 14))
                    .foregroundStyle(AppTheme.textMuted)
                    .frame(width: 32, height: 32)
                    .background(AppTheme.bgCard)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, topSafeArea + 16)
        .padding(.bottom, 10)
    }

    // MARK: - Tab selector

    private var tabSelector: some View {
        HStack(spacing: 0) {
            tabButton("CV", tab: .cv)
            tabButton("Cover Letter", tab: .coverLetter)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 10)
    }

    private func tabButton(_ label: String, tab: OutputTab) -> some View {
        let isSelected = selectedTab == tab
        return Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) { selectedTab = tab }
        }) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(isSelected ? AppTheme.gold : AppTheme.textMuted)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background(isSelected ? AppTheme.goldFaint : AppTheme.bgCard)
                .overlay(alignment: .bottom) {
                    if isSelected {
                        Rectangle().fill(AppTheme.gold).frame(height: 2)
                    }
                }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Content area — FULL SCREEN scrollable

    private func contentArea(doc: GeneratedDocument) -> some View {
        ScrollView {
            VStack(spacing: 12) {

                // AI insights
                if !doc.aiInsights.isEmpty {
                    aiInsightsPanel(doc: doc)
                }

                // Matched keywords
                if !doc.matchedKeywords.isEmpty {
                    keywordsPanel(doc: doc)
                }

                // Edit / Done bar
                HStack {
                    if isEditing {
                        Text("Editing")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(AppTheme.gold)
                    }
                    Spacer()
                    Button(action: {
                        isEditing.toggle()
                        if !isEditing { try? modelContext.save() }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: isEditing ? "checkmark" : "pencil")
                                .font(.system(size: 11))
                            Text(isEditing ? "Done" : "Edit")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundStyle(isEditing ? AppTheme.gold : AppTheme.textMuted)
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(AppTheme.bgCard)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppTheme.bgBorder, lineWidth: 0.5))
                    }
                }

                // Document text — full content, no line limit
                if isEditing {
                    editableContentView(doc: doc)
                } else {
                    readonlyContentView(doc: doc)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 160) // space for bottom bar
        }
    }

    // MARK: - Readonly — full text, no truncation

    private func readonlyContentView(doc: GeneratedDocument) -> some View {
        let content = selectedTab == .cv ? doc.displayCV : doc.coverLetterContent
        return Text(content.isEmpty ? "No content generated." : content)
            .font(.system(size: 13))
            .foregroundStyle(AppTheme.textSecond)
            .lineSpacing(5)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(AppTheme.bgCard)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
            .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                .stroke(AppTheme.bgBorder, lineWidth: 0.5))
    }

    // MARK: - Editable

    private func editableContentView(doc: GeneratedDocument) -> some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: AppTheme.radiusMd).fill(AppTheme.bgCard)
                .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                    .stroke(AppTheme.goldBorder, lineWidth: 0.5))
            if selectedTab == .cv {
                TextEditor(text: Binding(
                    get: { doc.isEdited ? doc.editedCVContent : doc.cvContent },
                    set: { doc.editedCVContent = $0; doc.isEdited = true }
                ))
                .font(.system(size: 13)).foregroundStyle(AppTheme.textSecond)
                .scrollContentBackground(.hidden).background(Color.clear)
                .padding(10).frame(minHeight: 500)
            } else {
                TextEditor(text: Binding(
                    get: { doc.coverLetterContent },
                    set: { doc.coverLetterContent = $0 }
                ))
                .font(.system(size: 13)).foregroundStyle(AppTheme.textSecond)
                .scrollContentBackground(.hidden).background(Color.clear)
                .padding(10).frame(minHeight: 300)
            }
        }
    }

    // MARK: - AI insights

    private func aiInsightsPanel(doc: GeneratedDocument) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text("✦").font(.system(size: 11)).foregroundStyle(AppTheme.gold)
                Text("What AI did for you")
                    .font(.system(size: 12, weight: .semibold)).foregroundStyle(AppTheme.gold)
            }
            ForEach(doc.aiInsights, id: \.self) { insight in
                HStack(alignment: .top, spacing: 8) {
                    Circle().fill(AppTheme.gold).frame(width: 4, height: 4).padding(.top, 5)
                    Text(insight).font(.system(size: 12)).foregroundStyle(AppTheme.textMuted).lineSpacing(2)
                }
            }
        }
        .padding(12).frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.goldFaint)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
        .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusMd).stroke(AppTheme.goldBorder, lineWidth: 0.5))
    }

    // MARK: - Keywords

    private func keywordsPanel(doc: GeneratedDocument) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Matched keywords")
                    .font(.system(size: 12, weight: .medium)).foregroundStyle(AppTheme.textMuted)
                Spacer()
                Text("\(doc.matchedKeywords.count) found")
                    .font(.system(size: 11)).foregroundStyle(AppTheme.success)
            }
            FlowLayout(spacing: 6) {
                ForEach(doc.matchedKeywords, id: \.self) { kw in
                    Text(kw).font(.system(size: 11, weight: .medium)).foregroundStyle(AppTheme.success)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(AppTheme.successFaint).clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
        }
        .padding(12).background(AppTheme.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
        .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusMd).stroke(AppTheme.bgBorder, lineWidth: 0.5))
    }

    // MARK: - Bottom bar — TWO export buttons

    private func bottomBar(doc: GeneratedDocument) -> some View {
        VStack(spacing: 0) {
            Divider().background(AppTheme.bgElevated)

            VStack(spacing: 8) {
                // Export CV PDF
                Button(action: { exportPDF(doc: doc, type: .cv) }) {
                    HStack(spacing: 6) {
                        if isExportingCV {
                            ProgressView().tint(Color(hex: "0A0A0F")).scaleEffect(0.7)
                        } else {
                            Image(systemName: "arrow.down.doc.fill").font(.system(size: 13))
                        }
                        Text(isExportingCV ? "Exporting…" : "Export CV as PDF")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundStyle(Color(hex: "0A0A0F"))
                    .frame(maxWidth: .infinity).padding(.vertical, 13)
                    .background(isExportingCV ? AppTheme.gold.opacity(0.6) : AppTheme.gold)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
                }
                .disabled(isExportingCV || isExportingCL)

                // Export Cover Letter PDF
                Button(action: { exportPDF(doc: doc, type: .coverLetter) }) {
                    HStack(spacing: 6) {
                        if isExportingCL {
                            ProgressView().tint(AppTheme.gold).scaleEffect(0.7)
                        } else {
                            Image(systemName: "envelope.fill").font(.system(size: 13))
                        }
                        Text(isExportingCL ? "Exporting…" : "Export Cover Letter as PDF")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundStyle(AppTheme.gold)
                    .frame(maxWidth: .infinity).padding(.vertical, 13)
                    .background(AppTheme.bgCard)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
                    .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                        .stroke(AppTheme.goldBorder, lineWidth: 1))
                }
                .disabled(isExportingCV || isExportingCL)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 36)
            .background(AppTheme.bgPrimary)
        }
    }

    // MARK: - Match score badge

    private func matchScoreBadge(score: Int) -> some View {
        HStack(spacing: 4) {
            ZStack {
                Circle().stroke(AppTheme.bgBorder, lineWidth: 2).frame(width: 32, height: 32)
                Circle().trim(from: 0, to: CGFloat(score) / 100)
                    .stroke(scoreColor(score), lineWidth: 2)
                    .frame(width: 32, height: 32).rotationEffect(.degrees(-90))
                Text("\(score)").font(.system(size: 9, weight: .bold)).foregroundStyle(scoreColor(score))
            }
            Text("match").font(.system(size: 10)).foregroundStyle(AppTheme.textMuted)
        }
    }

    private func scoreColor(_ score: Int) -> Color {
        score >= 75 ? AppTheme.success : score >= 50 ? AppTheme.gold : AppTheme.danger
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Text("No document found").font(.system(size: 16)).foregroundStyle(AppTheme.textMuted)
            Button("Go back") { onBack() }.buttonStyle(GhostButtonStyle()).padding(.horizontal, 40)
            Spacer()
        }
    }

    // MARK: - Export toast

    private var exportToast: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill").foregroundStyle(AppTheme.success)
            Text(exportSuccessMessage)
                .font(.system(size: 13, weight: .medium)).foregroundStyle(AppTheme.textPrimary)
        }
        .padding(.horizontal, 20).padding(.vertical, 12)
        .background(AppTheme.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
        .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusMd).stroke(AppTheme.bgBorder, lineWidth: 0.5))
        .shadow(color: .black.opacity(0.3), radius: 12, y: 4)
    }

    // MARK: - Export actions

    enum ExportType { case cv, coverLetter }

    private func exportPDF(doc: GeneratedDocument, type: ExportType) {
        if type == .cv { isExportingCV = true } else { isExportingCL = true }

        Task {
            let content: String
            let filename: String
            let company = application.company.isEmpty ? "Application" : application.company

            switch type {
            case .cv:
                content = doc.displayCV
                filename = "CV_\(company.replacingOccurrences(of: " ", with: "_")).pdf"
            case .coverLetter:
                content = doc.coverLetterContent
                filename = "CoverLetter_\(company.replacingOccurrences(of: " ", with: "_")).pdf"
            }

            let data = PDFRenderService.render(
                content: content,
                template: doc.template,
                jobTitle: application.jobTitle,
                company: application.company
            )

            // Write to temp file with proper name
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
            try? data.write(to: tempURL)

            await MainActor.run {
                if type == .cv { isExportingCV = false } else { isExportingCL = false }
                application.status = .exported
                try? modelContext.save()

                // Share sheet
                shareItems = [tempURL]
                showShareSheet = true

                // Toast
                exportSuccessMessage = type == .cv ? "CV PDF ready to share" : "Cover letter PDF ready to share"
                showExportSuccess = true
                Task {
                    try? await Task.sleep(nanoseconds: 2_500_000_000)
                    await MainActor.run { showExportSuccess = false }
                }
            }
        }
    }
}

// MARK: - Navigation controller environment key (for pop to root)

private struct NavigationControllerKey: EnvironmentKey {
    static let defaultValue: UINavigationController? = nil
}

extension EnvironmentValues {
    var navigationController: UINavigationController? {
        get { self[NavigationControllerKey.self] }
        set { self[NavigationControllerKey.self] = newValue }
    }
}
