import SwiftUI
import SwiftData

// MARK: - ATS Score View

struct ATSScoreView: View {
    let cvContent: String
    @State private var result: AIService.ATSResult?
    @State private var isLoading = true
    @State private var error: String?

    var body: some View {
        Group {
            if isLoading {
                VStack(spacing: 12) {
                    ProgressView().tint(AppTheme.gold)
                    Text("Analysing ATS compatibility…")
                        .font(.system(size: 13)).foregroundStyle(AppTheme.textMuted)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let err = error {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(AppTheme.danger)
                    Text(err).font(.system(size: 13)).foregroundStyle(AppTheme.textMuted).multilineTextAlignment(.center)
                    Button("Retry") { Task { await load() } }.buttonStyle(GoldButtonStyle())
                }
                .padding(32)
            } else if let r = result {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        scoreRing(r.score)
                        if !r.issues.isEmpty { issuesList(r.issues) }
                        if !r.recommendations.isEmpty { recommendationsList(r.recommendations) }
                        Spacer(minLength: 30)
                    }
                    .padding(16)
                }
            }
        }
        .background(AppTheme.bgPrimary)
        .task { await load() }
    }

    // MARK: Score Ring

    private func scoreRing(_ score: Int) -> some View {
        let color = atsColor(score)
        return HStack(spacing: 20) {
            ZStack {
                Circle().stroke(AppTheme.bgBorder, lineWidth: 10).frame(width: 90, height: 90)
                Circle().trim(from: 0, to: CGFloat(score) / 100)
                    .stroke(color, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .frame(width: 90, height: 90)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.8), value: score)
                VStack(spacing: 0) {
                    Text("\(score)").font(.system(size: 22, weight: .bold)).foregroundStyle(color)
                    Text("/100").font(.system(size: 10)).foregroundStyle(AppTheme.textDisabled)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(atsLabel(score)).font(.system(size: 16, weight: .semibold)).foregroundStyle(AppTheme.textPrimary)
                Text("ATS Compatibility Score")
                    .font(.system(size: 12)).foregroundStyle(AppTheme.textMuted)
                Text(atsDescription(score))
                    .font(.system(size: 11)).foregroundStyle(AppTheme.textMuted)
                    .lineLimit(2)
            }
        }
        .padding(14)
        .background(AppTheme.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
        .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusMd).stroke(color.opacity(0.3), lineWidth: 1))
    }

    // MARK: Issues

    private func issuesList(_ issues: [AIService.ATSIssue]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Issues Found")
                .font(.system(size: 13, weight: .semibold)).foregroundStyle(AppTheme.textPrimary)

            ForEach(issues, id: \.title) { issue in
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: severityIcon(issue.severity))
                            .foregroundStyle(severityColor(issue.severity))
                            .font(.system(size: 13))
                        Text(issue.title)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(AppTheme.textPrimary)
                    }
                    Text(issue.description)
                        .font(.system(size: 12)).foregroundStyle(AppTheme.textMuted)

                    HStack(spacing: 6) {
                        Image(systemName: "wrench.fill").font(.system(size: 10)).foregroundStyle(AppTheme.gold)
                        Text(issue.suggestion).font(.system(size: 11)).foregroundStyle(AppTheme.textSecond)
                    }
                    .padding(8)
                    .background(AppTheme.goldFaint)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .padding(12)
                .background(AppTheme.bgCard)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
                .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                    .stroke(severityColor(issue.severity).opacity(0.3), lineWidth: 0.5))
            }
        }
    }

    // MARK: Recommendations

    private func recommendationsList(_ recs: [String]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recommendations")
                .font(.system(size: 13, weight: .semibold)).foregroundStyle(AppTheme.textPrimary)

            ForEach(recs, id: \.self) { rec in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(AppTheme.gold)
                        .font(.system(size: 12))
                        .padding(.top, 1)
                    Text(rec).font(.system(size: 12)).foregroundStyle(AppTheme.textSecond).lineSpacing(3)
                }
                .padding(10)
                .background(AppTheme.goldFaint)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppTheme.goldBorder, lineWidth: 0.5))
            }
        }
    }

    // MARK: Helpers

    private func load() async {
        isLoading = true; error = nil
        guard !cvContent.isEmpty else { error = "No CV content to analyse"; isLoading = false; return }
        do {
            let r = try await AIService.shared.analyseATSCompatibility(cvContent: cvContent)
            withAnimation { self.result = r; self.isLoading = false }
        } catch {
            self.error = error.localizedDescription; self.isLoading = false
        }
    }

    private func atsColor(_ s: Int) -> Color { s >= 75 ? AppTheme.success : s >= 50 ? AppTheme.gold : AppTheme.danger }
    private func atsLabel(_ s: Int) -> String { s >= 80 ? "Excellent" : s >= 65 ? "Good" : s >= 50 ? "Fair" : "Needs Work" }
    private func atsDescription(_ s: Int) -> String {
        s >= 75 ? "CV is well-formatted for ATS systems" :
        s >= 50 ? "Some improvements will boost ATS ranking" :
        "Significant formatting issues may block parsing"
    }
    private func severityColor(_ sev: String) -> Color { sev == "critical" ? AppTheme.danger : sev == "warning" ? AppTheme.gold : AppTheme.info }
    private func severityIcon(_ sev: String) -> String { sev == "critical" ? "xmark.circle.fill" : sev == "warning" ? "exclamationmark.triangle.fill" : "info.circle.fill" }
}

// MARK: - CV Share View

struct CVShareView: View {
    let application: JobApplication
    @Environment(\.modelContext) private var modelContext
    @State private var showCopied = false

    private var shareToken: String {
        application.shareToken ?? application.generateShareToken()
    }
    private var shareURL: String { "https://forio.app/cv/\(shareToken)" }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Image(systemName: "link.circle.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(AppTheme.gold)

                VStack(spacing: 4) {
                    Text("Share your CV").font(.system(size: 18, weight: .semibold)).foregroundStyle(AppTheme.textPrimary)
                    Text("Create a public link to send to recruiters")
                        .font(.system(size: 13)).foregroundStyle(AppTheme.textMuted)
                }

                // Link card
                VStack(alignment: .leading, spacing: 6) {
                    Text("Your CV link").font(.system(size: 11, weight: .semibold)).foregroundStyle(AppTheme.textMuted)
                    HStack {
                        Text(shareURL)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(AppTheme.textSecond)
                            .lineLimit(1)
                        Spacer()
                        Button(action: copy) {
                            Image(systemName: showCopied ? "checkmark.circle.fill" : "doc.on.doc.fill")
                                .foregroundStyle(showCopied ? AppTheme.success : AppTheme.gold)
                        }
                    }
                    .padding(12)
                    .background(AppTheme.bgElevated)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppTheme.bgBorder, lineWidth: 0.5))

                    if showCopied {
                        Text("✓ Link copied to clipboard")
                            .font(.system(size: 11))
                            .foregroundStyle(AppTheme.success)
                    }
                }

                // Share button
                if let url = URL(string: shareURL) {
                    ShareLink(item: url, subject: Text("My CV"), message: Text("Here's my CV on Forio")) {
                        HStack(spacing: 8) {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share via…")
                        }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppTheme.bgPrimary)
                        .frame(maxWidth: .infinity).padding(.vertical, 15)
                        .background(AppTheme.gold)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
                    }
                    .buttonStyle(.plain)
                }

                Text("The link will show a clean version of your CV to anyone who opens it.")
                    .font(.system(size: 11))
                    .foregroundStyle(AppTheme.textDisabled)
                    .multilineTextAlignment(.center)

                Spacer(minLength: 40)
            }
            .padding(20)
        }
        .background(AppTheme.bgPrimary)
    }

    private func copy() {
        UIPasteboard.general.string = shareURL
        try? modelContext.save()
        withAnimation { showCopied = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { showCopied = false }
        }
    }
}
