import SwiftUI

struct PasteTextView: View {
    var onSubmit: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var text: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack {
            AppTheme.bgPrimary.ignoresSafeArea(.all)

            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundStyle(AppTheme.textMuted)
                            .frame(width: 32, height: 32)
                            .background(AppTheme.bgCard)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    Spacer()
                    Text("Paste your CV")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(AppTheme.textPrimary)
                    Spacer()
                    Button(action: {
                        if let clipboard = UIPasteboard.general.string {
                            text = clipboard
                        }
                    }) {
                        Text("Paste")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(AppTheme.gold)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 16)

                // Tip
                HStack(spacing: 8) {
                    Text("💡")
                    Text("Copy all the text from your CV document, then tap Paste above.")
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.textMuted)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.goldFaint)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                        .stroke(AppTheme.goldBorder, lineWidth: 0.5)
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 12)

                // Text editor
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                        .fill(AppTheme.bgCard)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                                .stroke(isFocused ? AppTheme.goldBorder : AppTheme.bgBorder, lineWidth: 0.5)
                        )

                    if text.isEmpty {
                        Text("Paste your CV text here…")
                            .font(.system(size: 14))
                            .foregroundStyle(AppTheme.textDisabled)
                            .padding(14)
                    }

                    TextEditor(text: $text)
                        .font(.system(size: 13))
                        .foregroundStyle(AppTheme.textPrimary)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .padding(10)
                        .focused($isFocused)
                }
                .frame(maxHeight: .infinity)
                .padding(.horizontal, 20)

                // Submit button
                VStack(spacing: 8) {
                    Button(action: {
                        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        dismiss()
                        onSubmit(trimmed)
                    }) {
                        Text("Extract my profile  ✦")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(AppTheme.bgPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(text.isEmpty ? AppTheme.gold.opacity(0.4) : AppTheme.gold)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
                    }
                    .disabled(text.isEmpty)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
        .onAppear { isFocused = true }
    }
}
