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
                // Instantiated directly without outer button wrappers to maintain structural event stability
                AeroVistaOrbButton()
                
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
            
            let config = NSWorkspace.OpenConfiguration()
            config.createsNewApplicationInstance = false
            
            // Helper: open a new window natively without screen interception models
            func openNewWindow() {
                if bundleID == "com.apple.finder" {
                    NSWorkspace.shared.open(URL(fileURLWithPath: NSHomeDirectory()), configuration: config, completionHandler: nil)
                } else {
                    if bundleID == "com.google.Chrome" || bundleID == "com.microsoft.edgemac" || bundleID == "com.microsoft.VSCode" {
                        config.arguments = ["--new-window"]
                    } else if bundleID == "org.mozilla.firefox" {
                        config.arguments = ["-new-window"]
                    }
                    NSWorkspace.shared.openApplication(at: appURL, configuration: config, completionHandler: nil)
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
                
                // If running but no windows are active, open one natively
                if validWindows.isEmpty {
                    openNewWindow()
                    return
                }
                
                // Toggle minimize or focus layer natively on the primary open window
                if let primaryWindow = validWindows.first {
                    let isAppFrontmost = NSWorkspace.shared.frontmostApplication?.processIdentifier == runningApp.processIdentifier
                    var minRef: CFTypeRef?
                    AXUIElementCopyAttributeValue(primaryWindow, kAXMinimizedAttribute as CFString, &minRef)
                    let isMin = minRef as? Bool ?? false
                    
                    if isAppFrontmost && !isMin {
                        AXUIElementSetAttributeValue(primaryWindow, kAXMinimizedAttribute as CFString, true as CFTypeRef)
                    } else {
                        if isMin {
                            // 🎯 FIXED: Removed broken AXValueCreate(.cgPoint, nil) call entirely
                            AXUIElementSetAttributeValue(primaryWindow, kAXMinimizedAttribute as CFString, false as CFTypeRef)
                        }
                        AXUIElementSetAttributeValue(primaryWindow, kAXMainAttribute as CFString, true as CFTypeRef)
                        AXUIElementPerformAction(primaryWindow, "AXRaise" as CFString)
                        runningApp.activate()
                    }
                }
            } else {
                // Cold launch: Open app natively and let the OS handle monitor placement parameters
                if bundleID == "com.apple.finder" {
                    NSWorkspace.shared.open(URL(fileURLWithPath: NSHomeDirectory()), configuration: config, completionHandler: nil)
                } else {
                    NSWorkspace.shared.openApplication(at: appURL, configuration: config, completionHandler: nil)
                }
            }
        }
}
