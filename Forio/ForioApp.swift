import SwiftUI
import SwiftData
import RevenueCat

@main
struct ForioApp: App {
    @ObservedObject private var themeManager = ThemeManager.shared
    init() {
        PurchaseService.shared.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: [
                    UserProfile.self,
                    JobApplication.self,
                    GeneratedDocument.self,
                    CVProfile.self,
                    InterviewSession.self
                ])
                .preferredColorScheme(.dark)
        }
    }
}
