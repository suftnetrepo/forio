import SwiftUI
import SwiftData

struct ContentView: View {
    @AppStorage(Constants.Keys.onboardingComplete) private var onboardingComplete = false
    @Query private var profiles: [UserProfile]

    var profile: UserProfile? { profiles.first }

    var body: some View {
        ZStack {
            AppTheme.bgPrimary.ignoresSafeArea(.all)

            Group {
                if let profile, profile.onboardingComplete {
                    HomeView()
                } else if let profile, profile.importedFromCV, !profile.onboardingComplete {
                    CVImportView {
                        profile.onboardingComplete = true
                    }
                } else if let profile, !profile.importedFromCV, !profile.onboardingComplete {
                    MinimalProfileStarterView {
                        profile.onboardingComplete = true
                    }
                } else {
                    OnboardingView {
                        onboardingComplete = true
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
    }
}
