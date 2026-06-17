import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct AeroBarMainContainerView: View {
    @StateObject private var settings = AeroBarSettings.shared
    @Environment(\.colorScheme) var colorScheme
    
    @State private var draggedPinnedItem: PinnedApp? = nil
    
    // Note: Local search workspace parameters removed as requested
    
    var body: some View {
        ZStack(alignment: .leading) {
            ZStack {
                VisualEffectBlurView(
                    material: settings.selectedMaterial,
                    blendingMode: .behindWindow,
                    state: .active
                )
                .id(settings.blurMaterialRaw)
                
                Color(settings.tintColorHex)
                    .opacity(settings.backdropOpacity)
                    .blendMode(.overlay)
                
                LinearGradient(
                    gradient: Gradient(colors: [
                        colorScheme == .dark ? Color.white.opacity(0.18) : Color.white.opacity(0.28),
                        colorScheme == .dark ? Color.white.opacity(0.03) : Color.white.opacity(0.06),
                        Color.clear
                    ]),
                    startPoint: .top,
                    endPoint: .center
                )
                .blendMode(.plusLighter)
                
                SurfaceNoiseView()
                    .opacity(0.01)
                    .blendMode(.overlay)
                
                if settings.showTopBorder {
                    VStack {
                        Rectangle()
                            .fill(colorScheme == .dark ? Color.white.opacity(0.25) : Color.white.opacity(0.40))
                            .frame(height: 0.5)
                        Spacer()
                    }
                }
            }
            .frame(height: settings.barHeight)
            .offset(y: 8)
            
            HStack(spacing: 0) {
                /// =======================================================
                // 🎯 FIX: AIRTIGHT MULTI-DISPLAY ORB HOVER ENGINE
                // =======================================================
                GeometryReader { geo in
                    Button(action: {
                        // Use the mouse position AT click time — this is always accurate because
                        // the user physically clicked the orb on a specific display's aerobar.
                        // The previous focused-window-on-main-display issue was a red herring:
                        // NSEvent.mouseLocation IS on the correct display when the orb is clicked.
                        // The real fix is ensuring the start menu window frame is set BEFORE
                        // makeKeyAndOrderFront so macOS routes it to the right display.
                        let mouse = NSEvent.mouseLocation
                        // Find the aerobar panel that contains this mouse click —
                        // walk NSApp windows to find whose frame's minY matches an aerobar position
                        let activeTargetScreen = NSScreen.screens.first { screen in
                            screen.frame.contains(mouse)
                        } ?? NSScreen.main ?? NSScreen.screens[0]
                        
                        NotificationCenter.default.post(
                            name: Notification.Name("triggerAeroStartMenu"),
                            object: nil,
                            userInfo: ["targetScreen": activeTargetScreen]
                        )
                    }) {
                        AeroVistaOrbButton()
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .frame(width: 54, height: 54)
                
                // Conditionals hide/show the search glass dynamically based on stored settings
                if settings.showSearchIcon {
                    SpotlightSearchField()
                        .padding(.leading, 10)
                        .padding(.trailing, 12)
                        // Smoothly slides and fades out when toggled from the Customizer panel
                        .transition(.move(edge: .leading).combined(with: .opacity))
                } else {
                    // Maintain a tiny layout spacer cushion when the field collapses
                    Spacer()
                        .frame(width: 12)
                }
                
                PinnedAppsTray(
                    draggedPinnedItem: $draggedPinnedItem,
                    onLaunch: launchOrActivatePinnedApp,
                    onUnpin: unpinApplication
                )
                
                Rectangle()
                    .fill(colorScheme == .dark ? Color.white.opacity(0.20) : Color.black.opacity(0.20))
                    .frame(width: 1, height: 22)
                    .padding(.horizontal, 12)
                
                WindowTabsScrollView(
                    onTabInteraction: handleWindowInteraction,
                    onPinToStartMenu: { tab in
                        if let runningApp = NSRunningApplication(processIdentifier: tab.processID),
                           let bundleID = runningApp.bundleIdentifier {
                            if !settings.pinnedStartApps.contains(where: { $0.bundleIdentifier == bundleID }) {
                                settings.pinnedStartApps.append(PinnedApp(bundleIdentifier: bundleID, appName: tab.appName))
                            }
                        }
                    },
                    onPinToAeroBar: { tab in
                        if let runningApp = NSRunningApplication(processIdentifier: tab.processID),
                           let bundleID = runningApp.bundleIdentifier {
                            if !settings.pinnedBarApps.contains(where: { $0.bundleIdentifier == bundleID }) {
                                settings.pinnedBarApps.append(PinnedApp(bundleIdentifier: bundleID, appName: tab.appName))
                            }
                        }
                    }
                )
                .frame(maxWidth: .infinity)
                
                RecycleBinButton(action: launchRecycleBinTarget)
                    .padding(.trailing, 24)
            }
            .frame(height: settings.barHeight)
            .offset(y: 8)
        }
        .frame(maxWidth: .infinity, maxHeight: 56)
        .foregroundColor(colorScheme == .dark ? .white : .black)
    }
    
    // MARK: - Core Window Toggle Integration Engine
    private func handleWindowInteraction(for tab: WindowTab) {
        let appRef = AXUIElementCreateApplication(tab.processID)
        var minimizedRef: CFTypeRef?
        AXUIElementCopyAttributeValue(tab.axElement, kAXMinimizedAttribute as CFString, &minimizedRef)
        let isMinimized = (minimizedRef as? Bool) ?? false
        
        if isMinimized {
            // Pre-lock the focused element and suppress AX observer callbacks for the duration
            // of the unminimize animation. Finder (and some other apps) fire
            // kAXFocusedWindowChangedNotification with a transient Desktop/nil element during
            // restore, which clears the active-tab highlight and causes flicker.
            AeroBarSettings.shared.currentSystemFocusedElement = tab.axElement
            NotificationCenter.default.post(name: Notification.Name("suppressFocusUpdates"), object: nil)
            AXUIElementSetAttributeValue(tab.axElement, kAXMinimizedAttribute as CFString, false as CFTypeRef)
            let axElem = tab.axElement
            let pid = tab.processID
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                let delayedAppRef = AXUIElementCreateApplication(pid)
                AXUIElementSetAttributeValue(delayedAppRef, kAXFrontmostAttribute as CFString, true as CFTypeRef)
                AXUIElementSetAttributeValue(axElem, kAXMainAttribute as CFString, true as CFTypeRef)
                NSRunningApplication(processIdentifier: pid)?.activate()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    AeroBarSettings.shared.currentSystemFocusedElement = axElem
                    NotificationCenter.default.post(name: Notification.Name("resumeFocusUpdates"), object: nil)
                }
            }
        } else {
            if let frontmostApp = NSWorkspace.shared.frontmostApplication, frontmostApp.processIdentifier == tab.processID {
                var focusedWindowRef: CFTypeRef?
                let copyResult = AXUIElementCopyAttributeValue(appRef, kAXFocusedWindowAttribute as CFString, &focusedWindowRef)
                
                if copyResult == .success, let systemFocusedWindow = focusedWindowRef {
                    if CFEqual(tab.axElement, systemFocusedWindow) {
                        AXUIElementSetAttributeValue(tab.axElement, kAXMinimizedAttribute as CFString, true as CFTypeRef)
                    } else {
                        AXUIElementSetAttributeValue(tab.axElement, kAXMainAttribute as CFString, true as CFTypeRef)
                    }
                } else {
                    var mainRef: CFTypeRef?
                    AXUIElementCopyAttributeValue(tab.axElement, kAXMainAttribute as CFString, &mainRef)
                    if (mainRef as? Bool) ?? false {
                        AXUIElementSetAttributeValue(tab.axElement, kAXMinimizedAttribute as CFString, true as CFTypeRef)
                    } else {
                        AXUIElementSetAttributeValue(tab.axElement, kAXMainAttribute as CFString, true as CFTypeRef)
                    }
                }
            } else {
                AXUIElementSetAttributeValue(tab.axElement, kAXMainAttribute as CFString, true as CFTypeRef)
                AXUIElementSetAttributeValue(appRef, kAXFrontmostAttribute as CFString, true as CFTypeRef)
                if let runningApp = NSRunningApplication(processIdentifier: tab.processID) { runningApp.activate() }
            }
        }
    }
    
    private func unpinApplication(bundleID: String) {
        guard bundleID != "com.apple.finder" else { return }
        settings.pinnedBarApps.removeAll(where: { $0.bundleIdentifier == bundleID })
    }
    
    private func launchRecycleBinTarget() {
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: URL(fileURLWithPath: "\(NSHomeDirectory())/.Trash").path)
    }
    
    private func launchOrActivatePinnedApp(bundleID: String) {
        guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else { return }
        
        // Determine which display's aerobar was clicked
        let mouseLocation = NSEvent.mouseLocation
        let targetScreen = NSScreen.screens.first { $0.frame.contains(mouseLocation) } ?? NSScreen.main ?? NSScreen.screens[0]
        
        // Helper: open a new window and move it to targetScreen
        func openNewWindow() {
            // Snapshot existing window AXUIElements (not just a count) so the new window can be
            // identified by diffing — same robust approach as PinnedAppsTray's fixed path.
            var preLaunchWindows: [AXUIElement] = []
            if let running = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == bundleID }) {
                let ref = AXUIElementCreateApplication(running.processIdentifier)
                var wRef: CFTypeRef?
                if AXUIElementCopyAttributeValue(ref, kAXWindowsAttribute as CFString, &wRef) == .success,
                   let wins = wRef as? [AXUIElement] { preLaunchWindows = wins }
            }
            let config = NSWorkspace.OpenConfiguration()
            config.createsNewApplicationInstance = false
            if bundleID == "com.apple.finder" {
                NSWorkspace.shared.open(URL(fileURLWithPath: NSHomeDirectory()), configuration: config) { _, _ in
                    PinnedAppsTray.moveAndResizeNewWindow(to: targetScreen, bundleIdentifier: bundleID, existingWindows: preLaunchWindows)
                }
            } else {
                if bundleID == "com.google.Chrome" || bundleID == "com.microsoft.edgemac" || bundleID == "com.microsoft.VSCode" {
                    config.arguments = ["--new-window"]
                } else if bundleID == "org.mozilla.firefox" {
                    config.arguments = ["-new-window"]
                }
                NSWorkspace.shared.openApplication(at: appURL, configuration: config) { _, _ in
                    PinnedAppsTray.moveAndResizeNewWindow(to: targetScreen, bundleIdentifier: bundleID, existingWindows: preLaunchWindows)
                }
            }
        }
        
        if let runningApp = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == bundleID }) {
            let appRef = AXUIElementCreateApplication(runningApp.processIdentifier)
            var windowListRef: CFTypeRef?
            AXUIElementCopyAttributeValue(appRef, kAXWindowsAttribute as CFString, &windowListRef)
            let windows = windowListRef as? [AXUIElement] ?? []
            
            var validWindows: [AXUIElement] = []
            if bundleID == "com.apple.finder" {
                for window in windows {
                    var titleRef: CFTypeRef?
                    AXUIElementCopyAttributeValue(window, kAXTitleAttribute as CFString, &titleRef)
                    let t = titleRef as? String ?? ""
                    if !t.isEmpty && t != "Desktop" { validWindows.append(window) }
                }
            } else {
                validWindows = windows
            }
            
            // No windows at all — open one
            if validWindows.isEmpty {
                openNewWindow()
                return
            }
            
            // Check if any existing window lives on targetScreen
            let primaryH = NSScreen.screens[0].frame.height
            let windowOnTargetScreen = validWindows.first { win in
                var posRef: CFTypeRef?, sizeRef: CFTypeRef?
                AXUIElementCopyAttributeValue(win, kAXPositionAttribute as CFString, &posRef)
                AXUIElementCopyAttributeValue(win, kAXSizeAttribute as CFString, &sizeRef)
                var pt = CGPoint.zero; var sz = CGSize.zero
                if let pv = posRef as! AXValue? { AXValueGetValue(pv, .cgPoint, &pt) }
                if let sv = sizeRef as! AXValue? { AXValueGetValue(sv, .cgSize, &sz) }
                // Convert AX (Y-down) to Cocoa (Y-up)
                let cocoaRect = CGRect(x: pt.x, y: primaryH - pt.y - sz.height, width: sz.width, height: sz.height)
                return targetScreen.frame.intersects(cocoaRect)
            }
            
            if let existingWindow = windowOnTargetScreen {
                // Window already on targetScreen — toggle minimize or focus
                let isAppFrontmost = NSWorkspace.shared.frontmostApplication?.processIdentifier == runningApp.processIdentifier
                var minRef: CFTypeRef?
                AXUIElementCopyAttributeValue(existingWindow, kAXMinimizedAttribute as CFString, &minRef)
                let isMin = minRef as? Bool ?? false
                
                if isAppFrontmost && !isMin {
                    // App is active on this screen — minimize
                    AXUIElementSetAttributeValue(existingWindow, kAXMinimizedAttribute as CFString, true as CFTypeRef)
                } else {
                    // Restore/focus it
                    if isMin {
                        AeroBarSettings.shared.currentSystemFocusedElement = existingWindow
                        NotificationCenter.default.post(name: Notification.Name("suppressFocusUpdates"), object: nil)
                        AXUIElementSetAttributeValue(existingWindow, kAXMinimizedAttribute as CFString, false as CFTypeRef)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                            AXUIElementSetAttributeValue(existingWindow, kAXMainAttribute as CFString, true as CFTypeRef)
                            AXUIElementSetAttributeValue(appRef, kAXFrontmostAttribute as CFString, true as CFTypeRef)
                            runningApp.activate()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                AeroBarSettings.shared.currentSystemFocusedElement = existingWindow
                                NotificationCenter.default.post(name: Notification.Name("resumeFocusUpdates"), object: nil)
                            }
                        }
                    } else {
                        AXUIElementSetAttributeValue(existingWindow, kAXMainAttribute as CFString, true as CFTypeRef)
                        AXUIElementPerformAction(existingWindow, "AXRaise" as CFString)
                        runningApp.activate()
                    }
                }
            } else {
                // No window on targetScreen — open a new one there
                openNewWindow()
            }
            return
        }
        
        // 4. BASE INITIALIZATION: Process is dead — launch fresh and move to targetScreen.
        let baseConfig = NSWorkspace.OpenConfiguration()
        baseConfig.createsNewApplicationInstance = false
        if bundleID == "com.apple.finder" {
            NSWorkspace.shared.open(URL(fileURLWithPath: NSHomeDirectory()), configuration: baseConfig) { _, _ in
                PinnedAppsTray.moveAndResizeNewWindow(to: targetScreen, bundleIdentifier: bundleID, existingWindows: [])
            }
        } else {
            NSWorkspace.shared.openApplication(at: appURL, configuration: baseConfig) { _, _ in
                PinnedAppsTray.moveAndResizeNewWindow(to: targetScreen, bundleIdentifier: bundleID, existingWindows: [])
            }
        }
    }
}
