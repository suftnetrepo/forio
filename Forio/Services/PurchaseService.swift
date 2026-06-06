import Foundation
import RevenueCat

@Observable
class PurchaseService {
    static let shared = PurchaseService()

    var isPremium = false
    var monthlyProduct: StoreProduct?
    var yearlyProduct: StoreProduct?
    var lifetimeProduct: StoreProduct?
    var isLoading = false

    // MARK: Free tier — 3 CV generations
    var generationsUsed: Int {
        get { UserDefaults.standard.integer(forKey: Constants.Keys.generationsUsed) }
        set { UserDefaults.standard.set(newValue, forKey: Constants.Keys.generationsUsed) }
    }

    var canGenerate: Bool {
        isPremium || generationsUsed < Constants.freeGenerations
    }

    var generationsRemaining: Int {
        isPremium ? Int.max : max(0, Constants.freeGenerations - generationsUsed)
    }

    var freeUsageLabel: String {
        if isPremium { return "Unlimited" }
        return "\(generationsRemaining) of \(Constants.freeGenerations) free"
    }

    // MARK: Configure

    func configure() {
        let apiKey = Bundle.main.infoDictionary?["REVENUECAT_API_KEY"] as? String ?? ""
        Purchases.configure(withAPIKey: apiKey)
        Purchases.logLevel = .error
        Task { await refreshStatus() }
        Task { await loadProducts() }
    }

    // MARK: Status

    func refreshStatus() async {
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            isPremium = customerInfo.entitlements[Constants.entitlementID]?.isActive == true
        } catch {
            print("❌ RevenueCat refresh error: \(error)")
        }
    }

    // MARK: Products

    func loadProducts() async {
        isLoading = true
        do {
            let offerings = try await Purchases.shared.offerings()
            if let current = offerings.current {
                for package in current.availablePackages {
                    switch package.packageType {
                    case .monthly:  monthlyProduct  = package.storeProduct
                    case .annual:   yearlyProduct   = package.storeProduct
                    case .lifetime: lifetimeProduct = package.storeProduct
                    default: break
                    }
                }
            }
        } catch {
            print("❌ Failed to load products: \(error)")
        }
        isLoading = false
    }

    // MARK: Purchase

    func purchase(_ product: StoreProduct) async throws {
        let result = try await Purchases.shared.purchase(product: product)
        isPremium = result.customerInfo.entitlements[Constants.entitlementID]?.isActive == true
    }

    func restorePurchases() async throws {
        let customerInfo = try await Purchases.shared.restorePurchases()
        isPremium = customerInfo.entitlements[Constants.entitlementID]?.isActive == true
    }

    // MARK: Generation tracking

    func recordGeneration() {
        generationsUsed += 1
    }

    func resetGenerations() {
        generationsUsed = 0
    }
}
