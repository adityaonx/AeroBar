import SwiftUI
import AppKit

struct AppKitTabButtonView: View {
    let tab: WindowTab
    let isActive: Bool
    
    // 🎯 THE FOCUS STATE FIX: Changed to @ObservedObject to guarantee real-time layout rendering pass synchronization
    @ObservedObject private var settings = AeroBarSettings.shared
    @Environment(\.colorScheme) var colorScheme // 1. Add color scheme detection
    
    var body: some View {
        // 🎯 THE PINPOINT VISIBILITY EVALUATION:
        // Explicitly forces the rendering engine to evaluate both the global master collapse switch
        // AND check if this specific unique tab window identifier has been flagged to hide.
        let shouldShowThisLabel = !settings.hideWindowLabelsTemporarily && !settings.manuallyHiddenWindowIDs.contains(tab.windowID)
        
        HStack(spacing: 0) {
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                Image(nsImage: tab.appIcon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.2 : 0.05), radius: 1, x: 0, y: 1)
                Spacer(minLength: 0)
            }
            .frame(width: 34, height: settings.barHeight)
            .padding(.leading, 6)
            
            // 🎯 THE DUAL-GUARD VISIBILITY CHECK:
            if shouldShowThisLabel {
                Text(tab.windowTitle.isEmpty ? tab.appName : tab.windowTitle)
                    .font(.system(size: 11, weight: isActive ? .semibold : .regular, design: .default))
                    // 2. Semantic text color: black in Light, white in Dark
                    .foregroundColor(colorScheme == .dark ? Color.white.opacity(isActive ? 0.95 : 0.80) : Color.black.opacity(isActive ? 0.90 : 0.70))
                    .lineLimit(1)
                    .frame(maxWidth: 140)
                    .padding(.leading, 6)
                    .padding(.trailing, 12)
            } else {
                // When text is collapsed globally or muted individually, inject a tight spacing
                // buffer to lock down clean trailing layout margins for the lone icon frame.
                Spacer(minLength: 0)
                    .frame(width: 6)
            }
        }
        .frame(height: settings.barHeight)
        .background(
            ZStack(alignment: .bottom) {
                // 3. Adaptive Background Material
                if isActive {
                    VisualEffectBlurView(material: colorScheme == .dark ? .selection : .headerView, blendingMode: .withinWindow, state: .active)
                        .opacity(colorScheme == .dark ? 0.4 : 0.2)
                } else {
                    VisualEffectBlurView(material: colorScheme == .dark ? .contentBackground : .underWindowBackground, blendingMode: .withinWindow, state: .active)
                        .opacity(0.25)
                }
                
                // 4. Adaptive Overlay Gradient (prevents white-block blowout)
                LinearGradient(
                    gradient: Gradient(colors: [
                        colorScheme == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.05),
                        Color.clear
                    ]),
                    startPoint: .top,
                    endPoint: .center
                )
                
                if isActive {
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color.accentColor) // Use system accent for active indicator
                        .frame(height: 2.5)
                        .padding(.horizontal, 4)
                }
            }
        )
        .cornerRadius(4)
        // 5. Adaptive Stroke
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(
                    colorScheme == .dark ? Color.white.opacity(isActive ? 0.3 : 0.1) : Color.black.opacity(isActive ? 0.2 : 0.05),
                    lineWidth: 1
                )
        )
    }
}
