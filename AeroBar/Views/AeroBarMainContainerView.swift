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
                        // 1. Snag the absolute, real-time mouse position on your display topology matrix
                        let mouseCoordinates = NSEvent.mouseLocation
                        
                        // 2. Scan every connected screen surface to find which one bounds the click origin
                        let activeTargetScreen = NSScreen.screens.first { screen in
                            screen.frame.contains(mouseCoordinates)
                        } ?? NSScreen.main ?? NSScreen.screens[0]
                        
                        // 3. Dispatch the definitive screen object directly to your window controller pipeline
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
        // 1. Resolve the physical application URL on the local disk file system
        guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else { return }
        
        // 2. Resolve target screen: use current mouse position to determine which aerobar was clicked
        let mouseLocation = NSEvent.mouseLocation
        let targetScreen = NSScreen.screens.first { $0.frame.contains(mouseLocation) } ?? NSScreen.main ?? NSScreen.screens[0]
        
        // 3. Check if the target application is already executing in the active process tree
        if let runningApp = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == bundleID }) {
            let appRef = AXUIElementCreateApplication(runningApp.processIdentifier)
            var windowListRef: CFTypeRef?
            
            AXUIElementCopyAttributeValue(appRef, kAXWindowsAttribute as CFString, &windowListRef)
            let windows = windowListRef as? [AXUIElement] ?? []
            
            var validWindowsToProcess: [AXUIElement] = []
            
            if bundleID == "com.apple.finder" {
                for window in windows {
                    var titleRef: CFTypeRef?
                    AXUIElementCopyAttributeValue(window, kAXTitleAttribute as CFString, &titleRef)
                    let windowTitle = titleRef as? String ?? ""
                    
                    if !windowTitle.isEmpty && windowTitle != "Desktop" {
                        validWindowsToProcess.append(window)
                    }
                }
            } else {
                validWindowsToProcess = windows
            }
            
            // FALLBACK: If there are absolutely zero open windows, launch a fresh workspace instance
            if validWindowsToProcess.isEmpty {
                let config = NSWorkspace.OpenConfiguration()
                config.createsNewApplicationInstance = false
                if bundleID == "com.apple.finder" {
                    NSWorkspace.shared.open(URL(fileURLWithPath: NSHomeDirectory()), configuration: config) { app, _ in
                        if targetScreen != NSScreen.screens.first {
                            self.moveNewWindowToScreen(targetScreen, app: app, bundleID: bundleID)
                        }
                    }
                } else {
                    if bundleID == "com.google.Chrome" || bundleID == "com.microsoft.edgemac" || bundleID == "com.microsoft.VSCode" {
                        config.arguments = ["--new-window"]
                    } else if bundleID == "org.mozilla.firefox" {
                        config.arguments = ["-new-window"]
                    }
                    NSWorkspace.shared.openApplication(at: appURL, configuration: config) { app, _ in
                        if targetScreen != NSScreen.screens.first {
                            self.moveNewWindowToScreen(targetScreen, app: app, bundleID: bundleID)
                        }
                    }
                }
                return
            }
            
            // Determine application focus status profile layers
            let isAppCurrentlyFrontmost = NSWorkspace.shared.frontmostApplication?.processIdentifier == runningApp.processIdentifier
            
            if isAppCurrentlyFrontmost {
                var isAlreadyMinimizedRef: CFTypeRef?
                AXUIElementCopyAttributeValue(validWindowsToProcess[0], kAXMinimizedAttribute as CFString, &isAlreadyMinimizedRef)
                let isFirstWindowMinimized = isAlreadyMinimizedRef as? Bool ?? false
                
                if !isFirstWindowMinimized {
                    for window in validWindowsToProcess {
                        AXUIElementSetAttributeValue(window, kAXMinimizedAttribute as CFString, true as CFTypeRef)
                    }
                    return
                }
            }
            
            // Surface all windows backwards onto foreground stack layers
            runningApp.activate()
            
            for window in validWindowsToProcess.reversed() {
                AXUIElementSetAttributeValue(window, kAXMinimizedAttribute as CFString, false as CFTypeRef)
                AXUIElementPerformAction(window, "AXRaise" as CFString)
            }
            return
        }
        
        // 4. BASE INITIALIZATION: Process is dead. Configure pristine workspace display parameters.
        let baseConfig = NSWorkspace.OpenConfiguration()
        baseConfig.createsNewApplicationInstance = false
        
        if bundleID == "com.apple.finder" {
            NSWorkspace.shared.open(URL(fileURLWithPath: NSHomeDirectory()), configuration: baseConfig) { app, _ in
                if targetScreen != NSScreen.screens.first {
                    self.moveNewWindowToScreen(targetScreen, app: app, bundleID: bundleID)
                }
            }
        } else {
            NSWorkspace.shared.openApplication(at: appURL, configuration: baseConfig) { app, _ in
                if targetScreen != NSScreen.screens.first {
                    self.moveNewWindowToScreen(targetScreen, app: app, bundleID: bundleID)
                }
            }
        }
    }
    
    /// Moves the newest window of an app to the target screen, just above the aerobar.
    private func moveNewWindowToScreen(_ screen: NSScreen, app: NSRunningApplication?, bundleID: String) {
        guard let app = app else { return }
        let primaryH = NSScreen.screens[0].frame.height
        var attempts = 0
        func attempt() {
            let appRef = AXUIElementCreateApplication(app.processIdentifier)
            var windowListRef: CFTypeRef?
            guard AXUIElementCopyAttributeValue(appRef, kAXWindowsAttribute as CFString, &windowListRef) == .success,
                  let windows = windowListRef as? [AXUIElement], let window = windows.first else {
                if attempts < 15 {
                    attempts += 1
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { attempt() }
                }
                return
            }
            var sizeRef: CFTypeRef?
            var winSize = CGSize(width: 800, height: 600)
            if AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &sizeRef) == .success,
               let sizeVal = sizeRef as! AXValue? {
                AXValueGetValue(sizeVal, .cgSize, &winSize)
            }
            // Center on target screen above aerobar (Cocoa: Y-up; AX: Y-down from top of primary)
            let cocoaX = screen.frame.minX + (screen.frame.width - winSize.width) / 2
            let cocoaY = screen.frame.minY + 56 + 24
            let axY = primaryH - cocoaY - winSize.height
            var newOrigin = CGPoint(x: cocoaX, y: max(0, axY))
            if let posVal = AXValueCreate(.cgPoint, &newOrigin) {
                AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, posVal)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { attempt() }
    }
}
