import SwiftUI

// MARK: - LinkedIn / Indeed URL Import Sheet

struct URLImportView: View {
    @Environment(\.dismiss) private var dismiss
    let onExtracted: (ExtractedJobDescription) -> Void

    @State private var urlText = ""
    @State private var isLoading = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Paste a job URL")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AppTheme.textPrimary)
                    Text("Works best with Indeed. LinkedIn may require login — if it fails, copy-paste the job text instead.")
                        .font(.system(size: 13))
                        .foregroundStyle(AppTheme.textMuted)
                        .lineSpacing(3)
                }

                // URL field
                HStack {
                    Image(systemName: "link").foregroundStyle(AppTheme.textMuted)
                    TextField("https://indeed.com/jobs/...", text: $urlText)
                        .font(.system(size: 14))
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .foregroundStyle(AppTheme.textPrimary)
                }
                .padding(12)
                .background(AppTheme.bgCard)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
                .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusMd).stroke(AppTheme.bgBorder, lineWidth: 0.5))

                // Error message
                if let error = error {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(AppTheme.danger)
                            .font(.system(size: 13))
                        Text(error)
                            .font(.system(size: 12))
                            .foregroundStyle(AppTheme.danger)
                            .lineSpacing(3)
                    }
                    .padding(10)
                    .background(AppTheme.danger.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                // Extract button
                Button(action: extract) {
                    HStack(spacing: 8) {
                        if isLoading {
                            ProgressView().tint(AppTheme.buttonFg).scaleEffect(0.8)
                            Text("Extracting…")
                        } else {
                            Image(systemName: "wand.and.stars")
                            Text("Extract Job Details")
                        }
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppTheme.buttonFg)
                    .frame(maxWidth: .infinity).padding(.vertical, 15)
                    .background(canExtract ? AppTheme.gold : AppTheme.gold.opacity(0.4))
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
                }
                .buttonStyle(.plain)
                .disabled(!canExtract || isLoading)

                Spacer()
            }
            .padding(20)
            .background(AppTheme.bgPrimary)
            .navigationTitle("Import from URL")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundStyle(AppTheme.textMuted)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private var canExtract: Bool {
        urlText.trimmingCharacters(in: .whitespaces).hasPrefix("http")
    }

    private func extract() {
        isLoading = true; error = nil
        Task {
            do {
                let result = try await AIService.shared.extractJobFromURL(urlText.trimmingCharacters(in: .whitespaces))
                await MainActor.run {
                    isLoading = false
                    onExtracted(result)
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    self.error = error.localizedDescription
                }
            }
        }
    }
}
