import Foundation

enum Constants {

    // MARK: App
    static let appName          = "Forio"
    static let bundleID         = "com.suftnet.forio"
    static let supportURL       = "https://suftnet.com/support"
    static let privacyURL       = "https://suftnet.com/forio/privacy"
    static let termsURL         = "https://suftnet.com/forio/terms"

    // MARK: RevenueCat
    static let entitlementID    = "premium"

    // MARK: Free tier  ← Fixed: was 10, now 3
    static let freeGenerations  = 3

    // MARK: UserDefaults keys
    enum Keys {
        static let onboardingComplete   = "forio_onboarding_complete"
        static let generationsUsed      = "forio_generations_used"
        static let selectedPersona      = "forio_selected_persona"
        static let hasProfile           = "forio_has_profile"
    }

    // MARK: OpenAI
    static let openAIEndpoint   = "https://api.openai.com/v1/chat/completions"
    static let openAIModel      = "gpt-4o"
    static let maxTokensExtract = 2000
    static let maxTokensGenerate = 4000

    // MARK: Scanner
    static let maxScanPages     = 10
}
