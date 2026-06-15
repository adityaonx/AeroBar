import SwiftUI
import AppKit

struct AeroVistaOrbButton: View {
    @StateObject private var settings = AeroBarSettings.shared
    @State private var isMouseHovering: Bool = false
    
    var body: some View {
        Button(action: {
            // Broadcasts the modern Start Menu flyout signal instantly on interaction
            NotificationCenter.default.post(name: .triggerAeroStartMenu, object: nil)
        }) {
            ZStack {
                // Instantiates your adaptive asset slices directly based on hover bounds tracking
                Image(isMouseHovering ? "orb-hover" : "orb")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32) // Keeps the glossy sphere layout uniform and crisp
                    .scaleEffect(isMouseHovering ? 1.05 : 1.0) // Subtle physics scaling on micro-interactions
                    .animation(.spring(response: 0.22, dampingFraction: 0.65), value: isMouseHovering)
            }
            .frame(width: 54, height: 54) // Keeps the hit target aligned with the bar layout bounds
            .contentShape(Circle()) // Forces the mouse tracker boundary layout to remain perfectly circular
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            self.isMouseHovering = hovering
        }
    }
}

// MARK: - Core Start Menu Communication Token
extension Notification.Name {
    static let triggerAeroStartMenu = Notification.Name("triggerAeroStartMenu")
}
