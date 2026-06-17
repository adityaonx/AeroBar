import SwiftUI
import AppKit

struct PinnedAppsTray: View {
    @ObservedObject var settings = AeroBarSettings.shared
    @Binding var draggedPinnedItem: PinnedApp?
    let onLaunch: (String) -> Void
    let onUnpin: (String) -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(settings.pinnedBarApps) { app in
                Button(action: {
                    onLaunch(app.bundleIdentifier)
                }) {
                    Image(nsImage: app.appIcon)
                        .resizable()
                        .frame(width: 24, height: 24)
                        .contextMenu {
                            // 🛠️ Action 1: Force New Window (on the display where the context menu was triggered)
                            Button {
                                let mouseLocation = NSEvent.mouseLocation
                                let targetScreen = NSScreen.screens.first { $0.frame.contains(mouseLocation) } ?? NSScreen.main ?? NSScreen.screens[0]
                                let isPrimary = targetScreen == NSScreen.screens.first
                                if app.bundleIdentifier == "com.apple.finder" {
                                    let config = NSWorkspace.OpenConfiguration()
                                    NSWorkspace.shared.open(URL(fileURLWithPath: NSHomeDirectory()), configuration: config) { runningApp, _ in
                                        if !isPrimary { PinnedAppsTray.moveWindow(to: targetScreen, app: runningApp) }
                                    }
                                } else if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: app.bundleIdentifier) {
                                    let config = NSWorkspace.OpenConfiguration()
                                    config.createsNewApplicationInstance = true
                                    if app.bundleIdentifier == "com.google.Chrome" || app.bundleIdentifier == "com.microsoft.edgemac" {
                                        config.arguments = ["--new-window"]
                                    } else if app.bundleIdentifier == "org.mozilla.firefox" {
                                        config.arguments = ["-new-window"]
                                    }
                                    NSWorkspace.shared.openApplication(at: appURL, configuration: config) { runningApp, _ in
                                        if !isPrimary { PinnedAppsTray.moveWindow(to: targetScreen, app: runningApp) }
                                    }
                                }
                            } label: {
                                Label("Open New Window", systemImage: "macwindow.badge.plus")
                            }
                            
                            // 🕶️ Action 2: Incognito / Private Session
                            if app.bundleIdentifier != "com.apple.finder" && (app.bundleIdentifier == "com.google.Chrome" || app.bundleIdentifier == "com.apple.Safari" || app.bundleIdentifier == "com.microsoft.edgemac") {
                                Button {
                                    if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: app.bundleIdentifier) {
                                        let config = NSWorkspace.OpenConfiguration()
                                        config.createsNewApplicationInstance = true
                                        
                                        if app.bundleIdentifier == "com.google.Chrome" || app.bundleIdentifier == "com.microsoft.edgemac" {
                                            config.arguments = ["--incognito"]
                                        } else if app.bundleIdentifier == "com.apple.Safari" {
                                            config.arguments = ["-private"]
                                        }
                                        NSWorkspace.shared.openApplication(at: appURL, configuration: config, completionHandler: nil)
                                    }
                                } label: {
                                    Label("Open New Private Window", systemImage: "eyeglasses")
                                }
                            }
                            
                            // 📌 Unpin and Close Actions
                            Divider()
                            
                            if app.bundleIdentifier != "com.apple.finder" {
                                Button(role: .destructive) {
                                    onUnpin(app.bundleIdentifier)
                                } label: {
                                    Label("Unpin from Taskbar", systemImage: "pin.slash")
                                }
                            }
                            
                            if let runningInstance = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == app.bundleIdentifier }),
                               app.bundleIdentifier != "com.apple.finder" {
                                Button {
                                    runningInstance.terminate()
                                } label: {
                                    Label("Close App", systemImage: "minus.circle")
                                }
                            }
                        }
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }

    /// Moves the frontmost window of a running app to the target screen (AX-based, polls until ready).
    static func moveWindow(to screen: NSScreen, app: NSRunningApplication?) {
        guard let app = app else { return }
        let primaryH = NSScreen.screens[0].frame.height
        var attempts = 0
        func attempt() {
            let appRef = AXUIElementCreateApplication(app.processIdentifier)
            var ref: CFTypeRef?
            guard AXUIElementCopyAttributeValue(appRef, kAXWindowsAttribute as CFString, &ref) == .success,
                  let wins = ref as? [AXUIElement], let win = wins.first else {
                if attempts < 15 { attempts += 1; DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { attempt() } }
                return
            }
            var sRef: CFTypeRef?
            var sz = CGSize(width: 800, height: 600)
            if AXUIElementCopyAttributeValue(win, kAXSizeAttribute as CFString, &sRef) == .success,
               let sv = sRef as! AXValue? { AXValueGetValue(sv, .cgSize, &sz) }
            let cx = screen.frame.minX + (screen.frame.width - sz.width) / 2
            let cy = screen.frame.minY + 80
            let axY = primaryH - cy - sz.height
            var pt = CGPoint(x: cx, y: max(0, axY))
            if let pv = AXValueCreate(.cgPoint, &pt) { AXUIElementSetAttributeValue(win, kAXPositionAttribute as CFString, pv) }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { attempt() }
    }
}
