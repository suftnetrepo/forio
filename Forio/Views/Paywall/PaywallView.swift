import SwiftUI
import RevenueCat

struct PaywallView: View {
    var onDismiss: () -> Void

    @State private var purchaseService = PurchaseService.shared
    @State private var selectedPlan = 1   // default: yearly
    @State private var isPurchasing = false
    @State private var errorMessage: String?
    @State private var showError = false

    let plans = ["Monthly", "Yearly", "Lifetime"]

    private var topSafeArea: CGFloat {
        (UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows
            .first?.safeAreaInsets.top) ?? 44
    }

    var selectedProduct: StoreProduct? {
        switch selectedPlan {
        case 0: return purchaseService.monthlyProduct
        case 1: return purchaseService.yearlyProduct
        case 2: return purchaseService.lifetimeProduct
        default: return nil
        }
    }

    var body: some View {
        ZStack {
            AppTheme.bgPrimary.ignoresSafeArea(.all)

            VStack(spacing: 0) {
                headerBar
                ScrollView {
                    VStack(spacing: 24) {
                        heroSection
                        featuresSection
                        planSelector
                        purchaseButton
                        footerLinks
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage ?? "Something went wrong")
        }
        .task { await purchaseService.loadProducts() }
    }

    // MARK: Header

    private var headerBar: some View {
        HStack {
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .foregroundStyle(AppTheme.textMuted)
                    .frame(width: 32, height: 32)
                    .background(AppTheme.bgCard)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            Spacer()
            Text("Forio Premium")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(AppTheme.textPrimary)
            Spacer()
            Color.clear.frame(width: 32, height: 32)
        }
        .padding(.horizontal, 16)
        .padding(.top, topSafeArea + 16)
        .padding(.bottom, 16)
    }

    // MARK: Hero

    private var heroSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(AppTheme.goldFaint)
                    .frame(width: 80, height: 80)
                Text("✦")
                    .font(.system(size: 32))
                    .foregroundStyle(AppTheme.gold)
            }
            VStack(spacing: 8) {
                Text("Land your dream job faster")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(AppTheme.textPrimary)
                    .multilineTextAlignment(.center)
                Text("Unlimited AI-tailored CVs for every\njob you apply to")
                    .font(.system(size: 15))
                    .foregroundStyle(AppTheme.textMuted)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }
        }
        .padding(.top, 8)
    }

    // MARK: Features

    private var featuresSection: some View {
        VStack(spacing: 0) {
            featureRow(icon: "infinity",         color: AppTheme.gold,    title: "Unlimited CV generations",   sub: "Apply to as many jobs as you want")
            Divider().background(AppTheme.bgElevated)
            featureRow(icon: "paintbrush",       color: AppTheme.info,    title: "All 5 premium templates",    sub: "Bold Two-Column & Executive Gold")
            Divider().background(AppTheme.bgElevated)
            featureRow(icon: "doc.text",         color: AppTheme.success, title: "Cover letter included",      sub: "Tailored letter for every application")
            Divider().background(AppTheme.bgElevated)
            featureRow(icon: "sparkles",         color: AppTheme.gold,    title: "AI match score",             sub: "Know how well you match before applying")
        }
        .background(AppTheme.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusLg))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.radiusLg)
                .stroke(AppTheme.bgBorder, lineWidth: 0.5)
        )
    }

    private func featureRow(icon: String, color: Color, title: String, sub: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(color)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppTheme.textPrimary)
                Text(sub)
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.textMuted)
            }
            Spacer()
            Image(systemName: "checkmark")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(AppTheme.gold)
        }
        .padding(14)
    }

    // MARK: Plan selector

    private var planSelector: some View {
        VStack(spacing: 10) {
            ForEach(0..<3, id: \.self) { index in
                planCard(index: index)
            }
        }
    }

    private func planCard(index: Int) -> some View {
        let isSelected = selectedPlan == index
        let product = index == 0 ? purchaseService.monthlyProduct
                    : index == 1 ? purchaseService.yearlyProduct
                    : purchaseService.lifetimeProduct

        return Button(action: { selectedPlan = index }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(plans[index])
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(AppTheme.textPrimary)
                        if index == 1 {
                            Text("BEST VALUE")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundStyle(AppTheme.success)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(AppTheme.successFaint)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                    }
                    Text(product != nil
                         ? (index == 2 ? "One-time payment" : "per \(index == 0 ? "month" : "year")")
                         : "Loading...")
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.textMuted)
                }
                Spacer()
                if let product {
                    Text(product.localizedPriceString)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(isSelected ? AppTheme.gold : AppTheme.textPrimary)
                }
                ZStack {
                    Circle()
                        .stroke(isSelected ? AppTheme.gold : AppTheme.bgBorder, lineWidth: 1.5)
                        .frame(width: 20, height: 20)
                    if isSelected {
                        Circle()
                            .fill(AppTheme.gold)
                            .frame(width: 12, height: 12)
                    }
                }
            }
            .padding(16)
            .background(AppTheme.bgCard)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                    .stroke(
                        isSelected ? AppTheme.gold : AppTheme.bgBorder,
                        lineWidth: isSelected ? 1.0 : 0.5
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: Purchase button

    private var purchaseButton: some View {
        VStack(spacing: 12) {
            Button(action: { Task { await purchase() } }) {
                HStack(spacing: 8) {
                    if isPurchasing {
                        ProgressView().tint(Color(hex: "0A0A0F")).scaleEffect(0.8)
                    }
                    Text(isPurchasing ? "Processing..." : "Start Premium  ✦")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color(hex: "0A0A0F"))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(AppTheme.gold)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
            }
            .disabled(isPurchasing || selectedProduct == nil)

            Text(selectedPlan == 2 ? "One-time purchase, no subscription"
                                   : "Cancel anytime in App Store settings")
                .font(.system(size: 12))
                .foregroundStyle(AppTheme.textDisabled)
        }
    }

    // MARK: Footer

    private var footerLinks: some View {
        HStack(spacing: 20) {
            Button("Restore") { Task { await restore() } }
            Button("Privacy")  { openURL(Constants.privacyURL) }
            Button("Terms")    { openURL(Constants.termsURL) }
        }
        .font(.system(size: 13))
        .foregroundStyle(AppTheme.textDisabled)
    }

    // MARK: Actions

    private func purchase() async {
        guard let product = selectedProduct else { return }
        isPurchasing = true
        do {
            try await purchaseService.purchase(product)
            onDismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        isPurchasing = false
    }

    private func restore() async {
        do {
            try await purchaseService.restorePurchases()
            if purchaseService.isPremium { onDismiss() }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func openURL(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
    }
}
