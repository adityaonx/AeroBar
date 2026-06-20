// SpotlightSearchField.swift — Search icon in the bar that opens native Spotlight.
// Owner: Views/Subviews
// Depends on: AppKit (Accessibility, CGEvent)
//
// There's no public API to simply "open Spotlight" — we locate and click its
// menu-bar status item via the Accessibility API, falling back to simulating
// the Cmd+Space keyboard shortcut if that item can't be found.

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
    
    private func triggerNativeMacSpotlight() {
        NotificationCenter.default.post(name: Notification.Name("dismissStartMenuWindow"), object: nil)
        
        // Locate the Spotlight status item inside SystemUIServer's menu bar and
        // press it directly via the Accessibility API.
        _ = AXUIElementCreateSystemWide()
        var menuBarRef: CFTypeRef?
        
        let systemUIApps = NSWorkspace.shared.runningApplications.filter { $0.bundleIdentifier == "com.apple.systemuiserver" }
        let targetPID = systemUIApps.first?.processIdentifier ?? 0
        
        let appRef = AXUIElementCreateApplication(targetPID)
        guard AXUIElementCopyAttributeValue(appRef, kAXMenuBarAttribute as CFString, &menuBarRef) == .success,
              let menuBar = menuBarRef else {
            // SystemUIServer's menu bar wasn't reachable — fall back to the keyboard shortcut.
            simulateSpotlightHardwareShortcut()
            return
        }
        
        var childrenRef: CFTypeRef?
        if AXUIElementCopyAttributeValue(menuBar as! AXUIElement, kAXChildrenAttribute as CFString, &childrenRef) == .success,
           let children = childrenRef as? [AXUIElement] {
            
            for child in children {
                var descriptionRef: CFTypeRef?
                AXUIElementCopyAttributeValue(child, kAXDescriptionAttribute as CFString, &descriptionRef)
                
                if let description = descriptionRef as? String, description.localizedCaseInsensitiveContains("spotlight") {
                    AXUIElementPerformAction(child, kAXPressAction as CFString)
                    return
                }
            }
        }
        
        // Spotlight's status item isn't present in the menu bar (e.g. user removed
        // it) — fall back to the keyboard shortcut as a last resort.
        simulateSpotlightHardwareShortcut()
    }
    
    private func simulateSpotlightHardwareShortcut() {
        let src = CGEventSource(stateID: .combinedSessionState)
        // Cmd+Space (virtual keycode 49), posted as raw hardware events.
        let cmdDown = CGEvent(keyboardEventSource: src, virtualKey: 49, keyDown: true)
        let cmdUp = CGEvent(keyboardEventSource: src, virtualKey: 49, keyDown: false)
        
        cmdDown?.flags = .maskCommand
        cmdUp?.flags = []
        
        cmdDown?.post(tap: .cghidEventTap)
        cmdUp?.post(tap: .cghidEventTap)
    }
}
