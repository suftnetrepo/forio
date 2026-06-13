import SwiftUI
import SwiftData

struct ContentView: View {
    @Query private var profiles: [UserProfile]

    var profile: UserProfile? { profiles.first }

    var body: some View {
        ZStack {
            AppTheme.bgPrimary.ignoresSafeArea(.all)
            Group {
                if profile == nil {
                    // No profile yet — show onboarding
                    OnboardingView(onComplete: { })

                } else if let profile, !profile.onboardingComplete, profile.importedFromCV {
                    // Chose to import — show import flow then dashboard
                    CVImportView(onComplete: {
                        profile.onboardingComplete = true
                    }, autoTrigger: AutoTriggerStore.shared.trigger)

                } else if let profile, !profile.onboardingComplete {
                    // Skipped — go straight to dashboard
                    HomeView().onAppear { profile.onboardingComplete = true }

                } else {
                    HomeView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
    }
}

// Singleton to safely pass trigger across the re-render boundary
class AutoTriggerStore {
    static let shared = AutoTriggerStore()
    var trigger: CVImportView.AutoTrigger = .none
}
