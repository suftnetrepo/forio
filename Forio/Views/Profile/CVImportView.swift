import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import VisionKit

struct CVImportView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]

    @State private var viewModel = CVImportViewModel()
    @State private var showScanner = false
    @State private var showDocPicker = false
    @State private var showPasteSheet = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""

    var onComplete: () -> Void

    var body: some View {
        ZStack {
            AppTheme.bgPrimary.ignoresSafeArea(.all)

            switch viewModel.importState {
            case .idle:
                idleView

            case .scanning:
                // Scanner is presented as fullScreenCover — idle view stays behind
                idleView

            case .extracting:
                ExtractionProgressView(steps: viewModel.extractionSteps)

            case .reviewing:
                CVReviewView(viewModel: viewModel) {
                    saveAndComplete()
                }

            case .complete:
                Color.clear

            case .failed(let msg):
                idleView.onAppear {
                    errorMessage = msg
                    showErrorAlert = true
                }
            }
        }
        // Scanner as fullScreenCover — cleaner than sheet for camera
        .fullScreenCover(isPresented: $showScanner) {
            DocumentScannerView { result in
                showScanner = false
                // Small delay so the cover dismisses before we start processing
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    viewModel.handleScan(result: result)
                }
            }
        }
        .sheet(isPresented: $showDocPicker) {
            PDFPickerView { text in
                guard !text.isEmpty else {
                    errorMessage = "Couldn't read that file. Try pasting the text instead."
                    showErrorAlert = true
                    return
                }
                viewModel.handlePDFText(text)
            }
        }
        .sheet(isPresented: $showPasteSheet) {
            PasteTextView { text in
                viewModel.handlePaste(text)
            }
        }
        .alert("Couldn't read CV", isPresented: $showErrorAlert) {
            Button("Try again") { viewModel.reset() }
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Idle / choice view

    private var idleView: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(spacing: 24) {

                    // Header
                    VStack(spacing: 8) {
                        Text("Import your CV")
                            .font(.system(size: 26, weight: .medium))
                            .foregroundStyle(AppTheme.textPrimary)
                        Text("AI reads it and builds your\nprofile in seconds")
                            .font(.system(size: 15))
                            .foregroundStyle(AppTheme.textMuted)
                            .multilineTextAlignment(.center)
                            .lineSpacing(3)
                    }
                    .padding(.top, 20)

                    // Import options — each triggers its own action directly
                    VStack(spacing: 10) {
                        importCard(
                            icon: "camera.fill",
                            title: "Scan CV pages",
                            subtitle: "Use your camera — works with printed or on-screen CVs",
                            isFeatured: true
                        ) {
                            showScanner = true
                        }

                        importCard(
                            icon: "doc.fill",
                            title: "Upload PDF",
                            subtitle: "Pick a PDF from your Files or iCloud Drive",
                            isFeatured: false
                        ) {
                            showDocPicker = true
                        }

                        importCard(
                            icon: "doc.on.clipboard.fill",
                            title: "Paste CV text",
                            subtitle: "Copy your CV text from any document and paste it here",
                            isFeatured: false
                        ) {
                            showPasteSheet = true
                        }
                    }

                    // What gets extracted
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "sparkles")
                            .foregroundStyle(AppTheme.gold)
                            .font(.system(size: 13))
                        VStack(alignment: .leading, spacing: 3) {
                            Text("What gets extracted")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(AppTheme.gold)
                            Text("Name · Contact · Work experience · Education · Skills · Summary")
                                .font(.system(size: 11))
                                .foregroundStyle(AppTheme.textMuted)
                                .lineSpacing(2)
                        }
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
                .frame(minHeight: geo.size.height)
            }
        }
        .safeAreaPadding(.top)
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

    // MARK: - Save

    private func saveAndComplete() {
        guard let profile = profiles.first else { return }
        viewModel.applyToProfile(profile)
        try? modelContext.save()
        onComplete()
    }
}
