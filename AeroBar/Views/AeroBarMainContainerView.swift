import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct AeroBarMainContainerView: View {
    @StateObject private var settings = AeroBarSettings.shared
    @Environment(\.colorScheme) var colorScheme
    
    @State private var draggedPinnedItem: PinnedApp? = nil
    
    var body: some View {
        ZStack(alignment: .leading) {
            ZStack {
                VisualEffectBlurView(
                    material: settings.selectedMaterial,
                    blendingMode: .behindWindow,
                    state: .active
                )
                .id(settings.blurMaterialRaw)
                
                Color(hex: settings.tintColorHex)
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
                GeometryReader { geo in
                    Button(action: {
                        let mouseCoordinates = NSEvent.mouseLocation
                        let activeTargetScreen = NSScreen.screens.first { screen in
                            screen.frame.contains(mouseCoordinates)
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
                
                if settings.showSearchIcon {
                    SpotlightSearchField()
                        .padding(.leading, 10)
                        .padding(.trailing, 12)
                        .transition(.move(edge: .leading).combined(with: .opacity))
                } else {
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
        
        let runningApp = NSRunningApplication(processIdentifier: tab.processID)
        
        // 🎯 THE FIX: kAXRaiseAction and activateIgnoringOtherApps are now systematically injected
        // into every single conditional execution path to guarantee single-tap visual raising.
        if isMinimized {
            AXUIElementSetAttributeValue(tab.axElement, kAXMinimizedAttribute as CFString, false as CFTypeRef)
            AXUIElementSetAttributeValue(tab.axElement, kAXMainAttribute as CFString, true as CFTypeRef)
            AXUIElementSetAttributeValue(appRef, kAXFrontmostAttribute as CFString, true as CFTypeRef)
            AXUIElementPerformAction(tab.axElement, kAXRaiseAction as CFString)
            if let app = runningApp {
    if #available(macOS 14.0, *) {
        NSApp.yieldActivation(to: app)
        app.activate()
    } else {
        app.activate(options: .activateIgnoringOtherApps)
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
                        AXUIElementPerformAction(tab.axElement, kAXRaiseAction as CFString)
                        if let app = runningApp {
    if #available(macOS 14.0, *) {
        NSApp.yieldActivation(to: app)
        app.activate()
    } else {
        app.activate(options: .activateIgnoringOtherApps)
    }
}
                    }
                } else {
                    var mainRef: CFTypeRef?
                    AXUIElementCopyAttributeValue(tab.axElement, kAXMainAttribute as CFString, &mainRef)
                    if (mainRef as? Bool) ?? false {
                        AXUIElementSetAttributeValue(tab.axElement, kAXMinimizedAttribute as CFString, true as CFTypeRef)
                    } else {
                        AXUIElementSetAttributeValue(tab.axElement, kAXMainAttribute as CFString, true as CFTypeRef)
                        AXUIElementPerformAction(tab.axElement, kAXRaiseAction as CFString)
                        if let app = runningApp {
    if #available(macOS 14.0, *) {
        NSApp.yieldActivation(to: app)
        app.activate()
    } else {
        app.activate(options: .activateIgnoringOtherApps)
    }
}
                    }
                }
            } else {
                AXUIElementSetAttributeValue(tab.axElement, kAXMainAttribute as CFString, true as CFTypeRef)
                AXUIElementSetAttributeValue(appRef, kAXFrontmostAttribute as CFString, true as CFTypeRef)
                AXUIElementPerformAction(tab.axElement, kAXRaiseAction as CFString)
                if let app = runningApp {
    if #available(macOS 14.0, *) {
        NSApp.yieldActivation(to: app)
        app.activate()
    } else {
        app.activate(options: .activateIgnoringOtherApps)
    }
}
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
        _ = NSApp.keyWindow?.screen ?? NSScreen.main ?? NSScreen.screens[0]
        
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
            
            if validWindowsToProcess.isEmpty {
                let config = NSWorkspace.OpenConfiguration()
                config.createsNewApplicationInstance = false
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
                return
            }
            
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
            
            if #available(macOS 14.0, *) {
                NSApp.yieldActivation(to: runningApp)
                runningApp.activate()
            } else {
                runningApp.activate(options: .activateIgnoringOtherApps)
            }
            
            for window in validWindowsToProcess.reversed() {
                AXUIElementSetAttributeValue(window, kAXMinimizedAttribute as CFString, false as CFTypeRef)
                AXUIElementPerformAction(window, "AXRaise" as CFString)
            }
            return
        }
        
        let baseConfig = NSWorkspace.OpenConfiguration()
        baseConfig.createsNewApplicationInstance = false
        
        if bundleID == "com.apple.finder" {
            NSWorkspace.shared.open(URL(fileURLWithPath: NSHomeDirectory()), configuration: baseConfig, completionHandler: nil)
        } else {
            NSWorkspace.shared.openApplication(at: appURL, configuration: baseConfig, completionHandler: nil)
        }
    }
}
