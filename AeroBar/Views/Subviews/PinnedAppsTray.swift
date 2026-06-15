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
                    // Left-click activates smart switching or initial instantiation
                    onLaunch(app.bundleIdentifier)
                }) {
                    Image(nsImage: app.appIcon)
                        .resizable()
                        .frame(width: 24, height: 24)
                        .contextMenu {
                            // 🛠️ Action 1: Force New Window (With a safe structural exception for Finder)
                            Button {
                                if app.bundleIdentifier == "com.apple.finder" {
                                    NSWorkspace.shared.open(URL(fileURLWithPath: NSHomeDirectory()), configuration: NSWorkspace.OpenConfiguration(), completionHandler: nil)
                                } else if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: app.bundleIdentifier) {
                                    let config = NSWorkspace.OpenConfiguration()
                                    config.createsNewApplicationInstance = true
                                    
                                    if app.bundleIdentifier == "com.google.Chrome" || app.bundleIdentifier == "com.microsoft.edgemac" {
                                        config.arguments = ["--new-window"]
                                    } else if app.bundleIdentifier == "org.mozilla.firefox" {
                                        config.arguments = ["-new-window"]
                                    }
                                    NSWorkspace.shared.openApplication(at: appURL, configuration: config, completionHandler: nil)
                                }
                            } label: {
                                Label("Open New Window", systemImage: "macwindow.badge.plus")
                            }
                            
                            // 🕶️ Action 2: Incognito / Private Session Matrix (Hidden for Finder)
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
                            
                            // =======================================================
                            // 📥 DESTRUCTIVE / CLOSING ACTIONS (ORDER REARRANGED)
                            // =======================================================
                            Divider()
                            
                            // 📌 Second to Last: Unpin Action (Hidden for Finder)
                            if app.bundleIdentifier != "com.apple.finder" {
                                Button(role: .destructive) {
                                    onUnpin(app.bundleIdentifier)
                                } label: {
                                    Label("Unpin from Taskbar", systemImage: "pin.slash")
                                }
                            }
                            
                            // 🛑 Very Bottom: Close App Utility (Hidden for Finder)
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
}
