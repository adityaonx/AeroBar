import SwiftUI

// 🎯 Clear, descriptive names for your custom layout wrappers
struct AeroPillContainer<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }

    var body: some View {
        content
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.04))
            .cornerRadius(6)
    }
}

struct AeroRainbowSlider<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }

    var body: some View {
        content.background(
            LinearGradient(colors: [.red, .orange, .yellow, .green, .blue, .purple],
                           startPoint: .leading, endPoint: .trailing)
                .frame(height: 3)
                .cornerRadius(1.5)
                .opacity(0.4),
            alignment: .bottom
        )
    }
}
