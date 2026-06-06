import SwiftUI

struct TemplatePickerSheet: View {
    @Binding var selected: CVTemplate
    @Environment(\.dismiss) private var dismiss
    @State private var purchaseService = PurchaseService.shared
    @State private var showPaywall = false

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
                    Text("Choose a style")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(AppTheme.textPrimary)
                    Spacer()
                    Color.clear.frame(width: 32, height: 32)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 8)

                Text("Pick the one that fits your industry")
                    .font(.system(size: 13))
                    .foregroundStyle(AppTheme.textMuted)
                    .padding(.bottom, 16)

                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(CVTemplate.allCases, id: \.self) { template in
                            templateRow(template)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }

                Button("Use \(selected.displayName)") { dismiss() }
                    .buttonStyle(GoldButtonStyle())
                    .padding(.horizontal, 20)
                    .padding(.bottom, 48)
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(onDismiss: { showPaywall = false })
        }
    }

    private func templateRow(_ template: CVTemplate) -> some View {
        let isSelected = selected == template
        let isLocked = template.isPro && !purchaseService.isPremium

        return Button(action: {
            if isLocked {
                showPaywall = true
            } else {
                selected = template
            }
        }) {
            HStack(spacing: 14) {
                // Template colour swatch
                templateSwatch(template)
                    .frame(width: 36, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: 5))

                VStack(alignment: .leading, spacing: 3) {
                    Text(template.displayName)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(isSelected ? AppTheme.gold : AppTheme.textPrimary)
                    Text(template.industryHint)
                        .font(.system(size: 11))
                        .foregroundStyle(AppTheme.textMuted)
                }

                Spacer()

                if isLocked {
                    Text("Pro")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(AppTheme.gold)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(AppTheme.goldFaint)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(AppTheme.goldBorder, lineWidth: 0.5)
                        )
                } else if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AppTheme.gold)
                        .font(.system(size: 20))
                } else {
                    Text("Free")
                        .font(.system(size: 9))
                        .foregroundStyle(AppTheme.textDisabled)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(AppTheme.bgElevated)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }
            .padding(14)
            .background(isSelected ? AppTheme.goldFaint : AppTheme.bgCard)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                    .stroke(
                        isSelected ? AppTheme.goldBorder : AppTheme.bgBorder,
                        lineWidth: isSelected ? 1.0 : 0.5
                    )
            )
            .opacity(isLocked && !isSelected ? 0.7 : 1.0)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func templateSwatch(_ template: CVTemplate) -> some View {
        switch template {
        case .classicNavy:
            ZStack(alignment: .topLeading) {
                Color(hex: "1a1a2e")
                VStack(alignment: .leading, spacing: 2) {
                    Color(hex: "C9A84C").frame(height: 10)
                    ForEach(0..<4) { _ in
                        Color.white.opacity(0.2).frame(height: 3).padding(.horizontal, 4)
                    }
                }
            }
        case .cleanMinimal:
            ZStack(alignment: .topLeading) {
                Color.white
                VStack(alignment: .leading, spacing: 2) {
                    Color(hex: "111111").frame(height: 8)
                    ForEach(0..<4) { _ in
                        Color(hex: "cccccc").frame(height: 3).padding(.horizontal, 4)
                    }
                }
            }
        case .boldTwoColumn:
            HStack(spacing: 0) {
                Color(hex: "0d3b2e").frame(width: 14)
                ZStack(alignment: .topLeading) {
                    Color.white
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(0..<5) { _ in
                            Color(hex: "dddddd").frame(height: 3).padding(.horizontal, 3)
                        }
                    }
                    .padding(.top, 4)
                }
            }
        case .executiveGold:
            ZStack(alignment: .leading) {
                Color(hex: "fdfcf8")
                HStack(spacing: 0) {
                    Color(hex: "C9A84C").frame(width: 3)
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(0..<5) { _ in
                            Color(hex: "ccbb88").frame(height: 3).padding(.horizontal, 4)
                        }
                    }
                    .padding(.top, 4)
                }
            }
        case .freshStart:
            ZStack(alignment: .topLeading) {
                Color.white
                VStack(alignment: .leading, spacing: 0) {
                    Color(hex: "4a6cf7").frame(height: 10)
                    ForEach(0..<4) { _ in
                        Color(hex: "d8deff").frame(height: 3).padding(.horizontal, 4).padding(.top, 2)
                    }
                }
            }
        }
    }
}
