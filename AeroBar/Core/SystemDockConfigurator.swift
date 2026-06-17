import Foundation
import AppKit

struct SystemDockConfigurator {
    static func enforceAeroDockDefaults() {
            DispatchQueue.global(qos: .userInitiated).async {
                print("Executing complete layout suite updates...")
                
                // 1. Core Layout Configuration Pass
                runDirectCommand(launchPath: "/usr/bin/defaults", arguments: ["write", "com.apple.dock", "orientation", "-string", "bottom"])
                
                // 🎯 THE NUCLEAR FIX: Banish the Dock off-screen permanently
                // We turn autohide ON, but set the hover trigger delay to 1000 seconds.
                // The Dock will sink below the screen and refuse to ever pop back up.
                runDirectCommand(launchPath: "/usr/bin/defaults", arguments: ["write", "com.apple.dock", "autohide", "-bool", "true"])
                runDirectCommand(launchPath: "/usr/bin/defaults", arguments: ["write", "com.apple.dock", "autohide-delay", "-float", "1000"])
                
                // Clean up any old magnification hacks to keep the defaults clean
                runDirectCommand(launchPath: "/usr/bin/defaults", arguments: ["delete", "com.apple.dock", "magnification"])
                runDirectCommand(launchPath: "/usr/bin/defaults", arguments: ["delete", "com.apple.dock", "largesize"])
                
                // 2. Safely cycle the Dock process
                let dockApps = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.dock")
                if let dockTarget = dockApps.first {
                    dockTarget.terminate()
                } else {
                    runDirectCommand(launchPath: "/usr/bin/killall", arguments: ["Dock"])
                }
            }
        }
    static func restoreSystemDockDefaults() {
            print("Restoring native macOS Dock defaults...")
            
            // 🎯 THE FIX: Delete the artificial delay key so the Dock returns to its normal speed
            runDirectCommand(launchPath: "/usr/bin/defaults", arguments: ["delete", "com.apple.dock", "autohide-delay"])
            
            // Restart the Dock one last time to apply the restoration
            let dockApps = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.dock")
            if let dockTarget = dockApps.first {
                dockTarget.terminate()
            } else {
                runDirectCommand(launchPath: "/usr/bin/killall", arguments: ["Dock"])
            }
        }
    private static func runDirectCommand(launchPath: String, arguments: [String]) {
        let task = Process()
        task.launchPath = launchPath
        task.arguments = arguments
        task.standardOutput = Pipe()
        task.standardError = Pipe()
        
        do {
            try task.run()
            task.waitUntilExit()
        } catch {
            print("AeroBar Core Automation Error: \(error.localizedDescription)")
        }
    }
}
