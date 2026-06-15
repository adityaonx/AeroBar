import SwiftUI
import AppKit

struct SpotlightSearchField: View {
    @ObservedObject private var settings = AeroBarSettings.shared
    @Environment(\.colorScheme) private var colorScheme
    
    private var shouldAssetsGoDark: Bool {
        if colorScheme == .light {
            if settings.blurMaterialRaw != 8 { return true }
        }
        if settings.blurMaterialRaw == 11 || settings.blurMaterialRaw == 0 { return true }
        return false
    }
    
    private var optimalTextColor: Color {
        shouldAssetsGoDark ? Color(red: 0.12, green: 0.12, blue: 0.14) : .white
    }
    
    var body: some View {
        Button(action: triggerNativeMacSpotlight) {
            ZStack {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(optimalTextColor.opacity(0.85))
            }
            .frame(width: 28, height: 26)
            .background(
                ZStack {
                    if shouldAssetsGoDark {
                        Color.black.opacity(0.06)
                    } else {
                        VisualEffectBlurView(material: .selection, blendingMode: .withinWindow, state: .active)
                            .opacity(0.15)
                        Color.black.opacity(0.25)
                    }
                }
            )
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(optimalTextColor.opacity(shouldAssetsGoDark ? 0.08 : 0.12), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .help("Search with Spotlight")
    }
    
    // MARK: - 🚀 System Menu Bar Core-Click Integration
    private func triggerNativeMacSpotlight() {
        // 1. Clear out our custom flyout panel
        NotificationCenter.default.post(name: Notification.Name("dismissStartMenuWindow"), object: nil)
        
        // 2. Query the Window Server for the native system Menu Bar (Process ID 0 or SystemUI)
        _ = AXUIElementCreateSystemWide()
        var menuBarRef: CFTypeRef?
        
        // Locate the structural menu bar element array layer
        let systemUIApps = NSWorkspace.shared.runningApplications.filter { $0.bundleIdentifier == "com.apple.systemuiserver" }
        let targetPID = systemUIApps.first?.processIdentifier ?? 0
        
        let appRef = AXUIElementCreateApplication(targetPID)
        guard AXUIElementCopyAttributeValue(appRef, kAXMenuBarAttribute as CFString, &menuBarRef) == .success,
              let menuBar = menuBarRef else {
            // Fallback: If SystemUI reference is locked down, simulate the direct keyboard layout register
            simulateSpotlightHardwareShortcut()
            return
        }
        
        // 3. Scan the status item list handles for the native Spotlight MenuExtra icon
        var childrenRef: CFTypeRef?
        if AXUIElementCopyAttributeValue(menuBar as! AXUIElement, kAXChildrenAttribute as CFString, &childrenRef) == .success,
           let children = childrenRef as? [AXUIElement] {
            
            for child in children {
                var descriptionRef: CFTypeRef?
                AXUIElementCopyAttributeValue(child, kAXDescriptionAttribute as CFString, &descriptionRef)
                
                if let description = descriptionRef as? String, description.localizedCaseInsensitiveContains("spotlight") {
                    // 🎯 FOUND IT: Perform a native accessibility click on the macOS menu bar asset item
                    AXUIElementPerformAction(child, kAXPressAction as CFString)
                    return
                }
            }
        }
        
        // 4. Ultimate Fallback
        simulateSpotlightHardwareShortcut()
    }
    
    private func simulateSpotlightHardwareShortcut() {
        let src = CGEventSource(stateID: .combinedSessionState)
        // Global virtual hardware key events for Cmd + Space (Keycode 49)
        let cmdDown = CGEvent(keyboardEventSource: src, virtualKey: 49, keyDown: true)
        let cmdUp = CGEvent(keyboardEventSource: src, virtualKey: 49, keyDown: false)
        
        cmdDown?.flags = .maskCommand
        cmdUp?.flags = []
        
        cmdDown?.post(tap: .cghidEventTap)
        cmdUp?.post(tap: .cghidEventTap)
    }
}
