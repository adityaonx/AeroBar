import Foundation
import AppKit

struct SystemDockConfigurator {
    static func enforceAeroDockDefaults() {
        DispatchQueue.global(qos: .userInitiated).async {
            print("Executing complete layout suite updates...")
            
            // 1. Core Layout Configuration Pass
            runDirectCommand(launchPath: "/usr/bin/defaults", arguments: ["write", "com.apple.dock", "orientation", "-string", "bottom"])
            runDirectCommand(launchPath: "/usr/bin/defaults", arguments: ["write", "com.apple.dock", "tilesize", "-int", "16"])
            runDirectCommand(launchPath: "/usr/bin/defaults", arguments: ["write", "com.apple.dock", "autohide", "-bool", "false"])
            runDirectCommand(launchPath: "/usr/bin/defaults", arguments: ["write", "com.apple.dock", "magnification", "-bool", "false"])
            runDirectCommand(launchPath: "/usr/bin/defaults", arguments: ["write", "com.apple.dock", "mineffect", "-string", "scale"])
            
            // 2. FIXED: Use Native AppKit API instead of AppleScript/killall
            // This safely cycles the Dock process without triggering legacy framework errors.
            let dockApps = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.dock")
            if let dockTarget = dockApps.first {
                // Command the Dock process to terminate cleanly via the workspace manager
                dockTarget.terminate()
                print("Native workspace signal sent to Dock process tree.")
            } else {
                // Failsafe fallback only if the workspace manager can't locate the bundle ID handle
                runDirectCommand(launchPath: "/usr/bin/killall", arguments: ["Dock"])
            }
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
