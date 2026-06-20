// AeroVistaOrbButton.swift — The circular Start button at the bottom-left of the bar.
// Owner: Views/Subviews
// Depends on: Core/Services/AeroBarSettings
//
// Layered glass-sphere look built from a handful of stacked Circle/Ellipse shapes
// rather than an image asset, so the orb tint and logo color can be customized
// live from the Appearance Lab without shipping per-color image variants.

import SwiftUI
import AppKit

struct AeroVistaOrbButton: View {
    @ObservedObject private var settings = AeroBarSettings.shared
    @State private var isMouseHovering: Bool = false

    var body: some View {
        Button(action: openStartMenuOnClickedDisplay) {
            orbBody
                .frame(width: 31, height: 31)
                .scaleEffect(isMouseHovering ? 1.05 : 1.0)
                .animation(.spring(response: 0.22, dampingFraction: 0.65), value: isMouseHovering)
                .frame(width: 54, height: 54)
                .contentShape(Circle())
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { isMouseHovering = $0 }
    }

    // Resolves which display the user actually clicked on (rather than relying
    // on NSScreen.main, which tracks system focus and lags behind a real click)
    // and opens the Start Menu anchored to that display's bar.
    private func openStartMenuOnClickedDisplay() {
        let mouse = NSEvent.mouseLocation
        let targetScreen = NSScreen.screens.first { $0.frame.contains(mouse) } ?? NSScreen.main ?? NSScreen.screens[0]
        NotificationCenter.default.post(
            name: .triggerAeroStartMenu,
            object: nil,
            userInfo: ["targetScreen": targetScreen]
        )
    }

    private var orbBody: some View {
        let baseColor = Color(settings.selectedOrbColorHex)

        return ZStack {
            // Base sphere — dark vertical gradient gives the glass its depth.
            Circle()
                .fill(LinearGradient(colors: [Color.black.opacity(0.85), Color.black.opacity(0.4)],
                                      startPoint: .top, endPoint: .bottom))
                .shadow(color: Color.black.opacity(0.6), radius: isMouseHovering ? 4 : 2, x: 0, y: 1)

            // Tinted glow rising from the bottom of the sphere.
            Circle()
                .fill(RadialGradient(colors: [baseColor.opacity(0.95), baseColor.opacity(0.4), baseColor.opacity(0)],
                                      center: .init(x: 0.5, y: 0.85), startRadius: 0, endRadius: 15))
                .blendMode(.screen)

            // Soft ambient fill so the tint reads through the whole sphere, not just the base.
            Circle()
                .fill(RadialGradient(colors: [baseColor.opacity(0.35), .clear],
                                      center: .center, startRadius: 0, endRadius: 16))

            // Edge ring for contrast against the bar's background.
            Circle()
                .strokeBorder(LinearGradient(colors: [Color.black.opacity(0.4), Color.black.opacity(0.85)],
                                              startPoint: .top, endPoint: .bottom),
                              lineWidth: 1.5)

            // Apple logo, tinted independently of the orb color via the template rendering mode.
            Image("apple-logo")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundColor(Color(settings.selectedOrbLogoColorHex))
                .frame(width: 13, height: 13)
                .offset(y: -0.5)
                .shadow(color: Color.black.opacity(0.35), radius: 1, x: 0, y: 1)

            // Specular highlight across the upper third, to sell the glass look.
            GeometryReader { geo in
                Ellipse()
                    .fill(LinearGradient(colors: [Color.white.opacity(0.55), Color.white.opacity(0.05)],
                                          startPoint: .top, endPoint: .bottom))
                    .frame(width: geo.size.width * 0.76, height: geo.size.height * 0.36)
                    .offset(x: geo.size.width * 0.12, y: geo.size.height * 0.04)
            }
        }
    }
}
