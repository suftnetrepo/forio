import SwiftUI

extension View {
    func adaptiveTopPadding(_ extra: CGFloat = 16) -> some View {
        self.modifier(SafeAreaTopModifier(extra: extra))
    }
}

struct SafeAreaTopModifier: ViewModifier {
    let extra: CGFloat
    func body(content: Content) -> some View {
        content
            .safeAreaInset(edge: .top, spacing: 0) {
                Color.clear.frame(height: extra)
            }
    }
}
