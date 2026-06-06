import SwiftUI
import SwiftData
import RevenueCat

@main
struct ForioApp: App {
    init() {
        PurchaseService.shared.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: [UserProfile.self, JobApplication.self, GeneratedDocument.self, CVProfile.self])
                .preferredColorScheme(.dark)
        }
    }
}
