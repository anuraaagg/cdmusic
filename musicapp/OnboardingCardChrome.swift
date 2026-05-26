import SwiftUI

/// Shared card frame for carousel previews — dark glass over gradient.
struct OnboardingCardChrome<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.black.opacity(0.42))
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.white.opacity(0.22), lineWidth: 1)
            content()
                .padding(12)
        }
    }
}
