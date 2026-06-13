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
    @State private var isExportingWordCV = false
    @State private var isExportingWordCL = false
    @State private var showExportSuccess = false
    @State private var exportSuccessMessage = ""
    @State private var exportContent: ExportContent = .cv
    @State private var exportFormat: ExportFormat = .pdf
    @State private var purchaseService = PurchaseService.shared

    enum OutputTab    { case cv, coverLetter }
    enum ExportContent { case cv, coverLetter }
    enum ExportFormat  { case pdf, word }
    enum ExportType    { case cv, coverLetter }

    var document: GeneratedDocument? { application.document }

    var body: some View {
        ZStack {
            AppTheme.bgPrimary.ignoresSafeArea(.all)

            if let doc = document {
                VStack(spacing: 0) {
                    headerBar(doc: doc)
                    tabBar
                    ScrollView {
                        VStack(spacing: 14) {
                            matchBanner(doc: doc)
                            aiInsightsCard(doc: doc)
                            keywordsCard(doc: doc)
                            cvContentCard(doc: doc)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 14)
                        .padding(.bottom, 180)
                    }
                }
                // Floating export bar
                VStack {
                    Spacer()
                    exportBar(doc: doc)
                }
            } else {
                emptyState
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showShareSheet) { ShareSheet(items: shareItems) }
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
                exportToast
                    .padding(.top, 60)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(.spring(duration: 0.4), value: showExportSuccess)
            }
        }
    }

    // MARK: - Header

    private func headerBar(doc: GeneratedDocument) -> some View {
        HStack(spacing: 12) {
            Button(action: { onBack() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .frame(width: 36, height: 36)
                    .background(AppTheme.bgCard)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10)
                        .stroke(AppTheme.bgBorder, lineWidth: 0.5))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(application.company.isEmpty ? "Generated CV" : application.company)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(1)
                if !application.jobTitle.isEmpty {
                    Text(application.jobTitle)
                        .font(.system(size: 11))
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
                    .overlay(RoundedRectangle(cornerRadius: 10)
                        .stroke(AppTheme.goldBorder, lineWidth: 0.5))
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 60)
        .padding(.bottom, 12)
    }

    // MARK: - Tab bar

    private var tabBar: some View {
        HStack(spacing: 0) {
            tabButton("CV", icon: "doc.text.fill", tab: .cv)
            tabButton("Cover Letter", icon: "envelope.fill", tab: .coverLetter)
        }
        .background(AppTheme.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.bgBorder, lineWidth: 0.5))
        .padding(.horizontal, 16)
        .padding(.bottom, 4)
    }

    private func tabButton(_ label: String, icon: String, tab: OutputTab) -> some View {
        let isSelected = selectedTab == tab
        return Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) { selectedTab = tab }
        }) {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 12))
                Text(label).font(.system(size: 13, weight: .medium))
            }
            .foregroundStyle(isSelected ? AppTheme.buttonFg : AppTheme.textMuted)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(isSelected ? AppTheme.gold : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(3)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Match banner

    private func matchBanner(doc: GeneratedDocument) -> some View {
        HStack(spacing: 14) {
            // Score ring
            ZStack {
                Circle()
                    .stroke(AppTheme.bgBorder, lineWidth: 3)
                    .frame(width: 52, height: 52)
                Circle()
                    .trim(from: 0, to: CGFloat(doc.matchScore) / 100)
                    .stroke(scoreColor(doc.matchScore), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 52, height: 52)
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 0) {
                    Text("\(doc.matchScore)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(scoreColor(doc.matchScore))
                    Text("%")
                        .font(.system(size: 9))
                        .foregroundStyle(AppTheme.textMuted)
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(scoreLabel(doc.matchScore))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                Text("\(doc.matchedKeywords.count) keywords matched · \(doc.aiInsights.count) improvements made")
                    .font(.system(size: 11))
                    .foregroundStyle(AppTheme.textMuted)
            }

            Spacer()
        }
        .padding(14)
        .background(AppTheme.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
        .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusMd)
            .stroke(scoreColor(doc.matchScore).opacity(0.3), lineWidth: 1))
    }

    // MARK: - AI Insights card

    private func aiInsightsCard(doc: GeneratedDocument) -> some View {
        guard !doc.aiInsights.isEmpty else { return AnyView(EmptyView()) }
        return AnyView(
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 13))
                        .foregroundStyle(AppTheme.gold)
                    Text("What AI did for you")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppTheme.gold)
                    Spacer()
                }

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(doc.aiInsights, id: \.self) { insight in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 13))
                                .foregroundStyle(AppTheme.gold)
                                .padding(.top, 1)
                            Text(insight)
                                .font(.system(size: 12))
                                .foregroundStyle(AppTheme.textMuted)
                                .lineSpacing(3)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
            .padding(14)
            .background(AppTheme.goldFaint)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
            .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                .stroke(AppTheme.goldBorder, lineWidth: 0.5))
        )
    }

    // MARK: - Keywords card

    private func keywordsCard(doc: GeneratedDocument) -> some View {
        guard !doc.matchedKeywords.isEmpty else { return AnyView(EmptyView()) }
        return AnyView(
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Matched keywords")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppTheme.textPrimary)
                    Spacer()
                    Text("\(doc.matchedKeywords.count) found")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(AppTheme.success)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(AppTheme.successFaint)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                FlowLayout(spacing: 6) {
                    ForEach(doc.matchedKeywords, id: \.self) { kw in
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(AppTheme.success)
                            Text(kw)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(AppTheme.success)
                        }
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(AppTheme.successFaint)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                    }
                }
            }
            .padding(14)
            .background(AppTheme.bgCard)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
            .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                .stroke(AppTheme.bgBorder, lineWidth: 0.5))
        )
    }

    // MARK: - CV Content card

    private func cvContentCard(doc: GeneratedDocument) -> some View {
        let content = selectedTab == .cv ? doc.displayCV : doc.coverLetterContent

        return VStack(alignment: .leading, spacing: 0) {
            // Card header
            HStack {
                Image(systemName: selectedTab == .cv ? "doc.text.fill" : "envelope.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.gold)
                Text(selectedTab == .cv ? "Your CV" : "Cover Letter")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppTheme.textMuted)
                Spacer()
                Button(action: {
                    isEditing.toggle()
                    if !isEditing { try? modelContext.save() }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: isEditing ? "checkmark" : "pencil")
                            .font(.system(size: 10))
                        Text(isEditing ? "Done" : "Edit")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundStyle(isEditing ? AppTheme.gold : AppTheme.textMuted)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(isEditing ? AppTheme.goldFaint : AppTheme.bgElevated)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(AppTheme.bgElevated)

            Divider().background(AppTheme.bgBorder)

            if isEditing {
                editableContent(doc: doc)
            } else {
                Text(content.isEmpty ? "No content generated." : content)
                    .font(.system(size: 12.5))
                    .foregroundStyle(AppTheme.textSecond)
                    .lineSpacing(5)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
            }
        }
        .background(AppTheme.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
        .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusMd)
            .stroke(AppTheme.bgBorder, lineWidth: 0.5))
    }

    private func editableContent(doc: GeneratedDocument) -> some View {
        ZStack(alignment: .topLeading) {
            if selectedTab == .cv {
                TextEditor(text: Binding(
                    get: { doc.isEdited ? doc.editedCVContent : doc.cvContent },
                    set: { doc.editedCVContent = $0; doc.isEdited = true }
                ))
                .font(.system(size: 12.5)).foregroundStyle(AppTheme.textSecond)
                .scrollContentBackground(.hidden).background(Color.clear)
                .padding(10).frame(minHeight: 500)
            } else {
                TextEditor(text: Binding(
                    get: { doc.coverLetterContent },
                    set: { doc.coverLetterContent = $0 }
                ))
                .font(.system(size: 12.5)).foregroundStyle(AppTheme.textSecond)
                .scrollContentBackground(.hidden).background(Color.clear)
                .padding(10).frame(minHeight: 300)
            }
        }
    }

    // MARK: - Export bar (floating)

    private func exportBar(doc: GeneratedDocument) -> some View {
        VStack(spacing: 10) {
            // Format chips row
            HStack(spacing: 8) {
                // Content chips
                ForEach([(ExportContent.cv, "CV"), (.coverLetter, "Cover Letter")], id: \.1) { c, label in
                    Button(action: { exportContent = c }) {
                        Text(label)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(exportContent == c ? AppTheme.buttonFg : AppTheme.textMuted)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 7)
                            .background(exportContent == c ? AppTheme.gold : AppTheme.bgElevated)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                    }
                    .buttonStyle(.plain)
                }

                // Divider
                Rectangle().fill(AppTheme.bgBorder).frame(width: 1, height: 24)

                // Format chips
                ForEach([(ExportFormat.pdf, "PDF"), (.word, "Word")], id: \.1) { f, label in
                    Button(action: { exportFormat = f }) {
                        Text(label)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(exportFormat == f ? AppTheme.gold : AppTheme.textMuted)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 7)
                            .background(exportFormat == f ? AppTheme.goldFaint : AppTheme.bgElevated)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .overlay(RoundedRectangle(cornerRadius: 20)
                                .stroke(exportFormat == f ? AppTheme.goldBorder : Color.clear, lineWidth: 0.5))
                    }
                    .buttonStyle(.plain)
                }
            }

            // Export button
            let isExporting = isExportingCV || isExportingCL || isExportingWordCV || isExportingWordCL
            Button(action: { handleExport(doc: doc) }) {
                HStack(spacing: 8) {
                    if isExporting {
                        ProgressView().tint(AppTheme.buttonFg).scaleEffect(0.8)
                    } else {
                        Image(systemName: "arrow.down.circle.fill").font(.system(size: 16))
                    }
                    Text(isExporting ? "Exporting…" : "Export \(exportContent == .cv ? "CV" : "Cover Letter") as \(exportFormat == .pdf ? "PDF" : "Word")")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundStyle(AppTheme.buttonFg)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(isExporting ? AppTheme.gold.opacity(0.6) : AppTheme.gold)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
            }
            .disabled(isExporting)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 34)
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) {
            Rectangle().fill(AppTheme.bgBorder).frame(height: 0.5)
        }
    }

    // MARK: - Helpers

    private func scoreColor(_ score: Int) -> Color {
        score >= 75 ? AppTheme.success : score >= 50 ? AppTheme.gold : AppTheme.danger
    }

    private func scoreLabel(_ score: Int) -> String {
        score >= 85 ? "Excellent match" : score >= 70 ? "Strong match" : score >= 50 ? "Good match" : "Partial match"
    }

    private func handleExport(doc: GeneratedDocument) {
        let type: ExportType = exportContent == .cv ? .cv : .coverLetter
        exportFormat == .pdf ? exportPDF(doc: doc, type: type) : exportWord(doc: doc, type: type)
    }

    private func exportPDF(doc: GeneratedDocument, type: ExportType) {
        if type == .cv { isExportingCV = true } else { isExportingCL = true }
        Task {
            let content  = type == .cv ? doc.displayCV : doc.coverLetterContent
            let company  = application.company.isEmpty ? "Application" : application.company
            let filename = type == .cv
                ? "CV_\(company.replacingOccurrences(of: " ", with: "_")).pdf"
                : "CoverLetter_\(company.replacingOccurrences(of: " ", with: "_")).pdf"
            let data = PDFRenderService.render(content: content, template: doc.template,
                                               jobTitle: application.jobTitle, company: application.company)
            let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
            try? data.write(to: url)
            await MainActor.run {
                if type == .cv { isExportingCV = false } else { isExportingCL = false }
                application.status = .exported; try? modelContext.save()
                shareItems = [url]; showShareSheet = true
                exportSuccessMessage = type == .cv ? "CV PDF ready" : "Cover letter PDF ready"
                showExportSuccess = true
                Task { try? await Task.sleep(nanoseconds: 2_500_000_000)
                    await MainActor.run { showExportSuccess = false } }
            }
        }
    }

    private func exportWord(doc: GeneratedDocument, type: ExportType) {
        let company = application.company.isEmpty ? "Application" : application.company
        guard let url = WordExportService.export(cvContent: doc.displayCV,
            coverLetter: doc.coverLetterContent, jobTitle: application.jobTitle,
            company: company, exportType: type == .cv ? .cv : .coverLetter) else { return }
        application.status = .exported; try? modelContext.save()
        shareItems = [url]; showShareSheet = true
        exportSuccessMessage = type == .cv ? "CV Word doc ready" : "Cover letter Word doc ready"
        showExportSuccess = true
        Task { try? await Task.sleep(nanoseconds: 2_500_000_000)
            await MainActor.run { showExportSuccess = false } }
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

    // MARK: - Toast

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
