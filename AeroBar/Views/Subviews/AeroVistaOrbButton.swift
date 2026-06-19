import SwiftUI
import AppKit

struct AeroVistaOrbButton: View {
    // 🎯 Changed to ObservedObject to listen live to external property data mutations
    @ObservedObject private var settings = AeroBarSettings.shared
    @State private var isMouseHovering: Bool = false
    
    var body: some View {
        Button(action: {
            // Compute the target display from the mouse position AT CLICK TIME — this is
            // always accurate because the user physically clicked the orb on a specific
            // display's aerobar. (This logic used to live in a second, OUTER Button wrapped
            // around this one in AeroBarMainContainerView.swift — but nesting a Button inside
            // another Button's label means SwiftUI only ever fires the INNERMOST button's
            // action, so that outer logic silently never ran. Every click fell through to
            // toggleModernStartMenuPopover's NSScreen.main fallback — "the screen with the
            // currently focused/key window" — which is why the start menu only ever opened on
            // display 2 once mac's actual focus had already moved there.)
            let mouse = NSEvent.mouseLocation
            let targetScreen = NSScreen.screens.first { $0.frame.contains(mouse) } ?? NSScreen.main ?? NSScreen.screens[0]
            NotificationCenter.default.post(
                name: .triggerAeroStartMenu,
                object: nil,
                userInfo: ["targetScreen": targetScreen]
            )
        }) {
            ZStack {
                let baseColor = Color(settings.selectedOrbColorHex)
                
                // 1. Core Dynamic Glass Sphere Backing Matrix
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.black.opacity(0.85), Color.black.opacity(0.4)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: Color.black.opacity(0.6), radius: isMouseHovering ? 4 : 2, x: 0, y: 1)
                
                // 2. High-Saturation Core Glow Engine (Bottom Infused Glow)
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [baseColor.opacity(0.95), baseColor.opacity(0.4), baseColor.opacity(0.0)],
                            center: .init(x: 0.5, y: 0.85),
                            startRadius: 0,
                            endRadius: 15
                        )
                    )
                    .blendMode(.screen)
                
                // 3. Ambient Internal Volumetric Fill Glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [baseColor.opacity(0.35), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 16
                        )
                    )
                
                // 4. Structural Volumetric Edge Contrast Lip
                Circle()
                    .strokeBorder(
                        LinearGradient(
                            colors: [Color.black.opacity(0.4), Color.black.opacity(0.85)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1.5
                    )
                
                // 5. High-Contrast Templates Asset Layer Mask (Centers your exact Apple logo SVG)
                Image("apple-logo")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(Color(settings.selectedOrbLogoColorHex)) // 🎯 Dynamic Logo Tint Injection
                    .frame(width: 13, height: 13)
                    .offset(y: -0.5)
                    .shadow(color: Color.black.opacity(0.35), radius: 1, x: 0, y: 1)
                
                // 6. Upper Crescent Reflection Gloss Bevel Specular Overlay
                GeometryReader { geo in
                    Ellipse()
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.55), Color.white.opacity(0.05)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: geo.size.width * 0.76, height: geo.size.height * 0.36)
                        .offset(x: geo.size.width * 0.12, y: geo.size.height * 0.04)
                }
            }
            .frame(width: 31, height: 31)
            .scaleEffect(isMouseHovering ? 1.05 : 1.0)
            .animation(.spring(response: 0.22, dampingFraction: 0.65), value: isMouseHovering)
            .frame(width: 54, height: 54)
            .contentShape(Circle())
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            self.isMouseHovering = hovering
        }
    }
}
