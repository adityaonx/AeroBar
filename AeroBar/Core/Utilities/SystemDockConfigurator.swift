// SystemDockConfigurator.swift — Temporarily reconfigures the system Dock so it
// doesn't visually clash with AeroBar, and restores it on quit.
// Owner: Core/Utilities
// Depends on: AppKit, Foundation
//
// AeroBar lives at the bottom of the screen, the same place the Dock wants to
// be. Rather than trying to coexist with it, we push the real Dock out of the
// way for the duration of the session:
//   - orientation is forced to "bottom" (in case the user had it on a side)
//   - autohide is enabled with a very long reveal delay, so it effectively
//     never pops back up over AeroBar
// Both settings are written via `defaults` and applied by restarting the Dock
// process. They're restored to normal in restoreSystemDockDefaults(), called
// from AppDelegate.applicationWillTerminate.

import Foundation
import AppKit

struct SystemDockConfigurator {

    static func enforceAeroDockDefaults() {
        DispatchQueue.global(qos: .userInitiated).async {
            runDirectCommand(launchPath: "/usr/bin/defaults",
                              arguments: ["write", "com.apple.dock", "orientation", "-string", "bottom"])

            // Autohide stays on, but with a 1000-second reveal delay — long enough
            // that the Dock effectively never reappears on hover for a normal session.
            runDirectCommand(launchPath: "/usr/bin/defaults",
                              arguments: ["write", "com.apple.dock", "autohide", "-bool", "true"])
            runDirectCommand(launchPath: "/usr/bin/defaults",
                              arguments: ["write", "com.apple.dock", "autohide-delay", "-float", "1000"])

            // Clear out any leftover magnification settings so the Dock comes back
            // clean once it's restored.
            runDirectCommand(launchPath: "/usr/bin/defaults",
                              arguments: ["delete", "com.apple.dock", "magnification"])
            runDirectCommand(launchPath: "/usr/bin/defaults",
                              arguments: ["delete", "com.apple.dock", "largesize"])

            restartDockProcess()
        }
    }

    static func restoreSystemDockDefaults() {
        // Removing the override key lets the Dock fall back to its normal,
        // system-default reveal delay.
        runDirectCommand(launchPath: "/usr/bin/defaults",
                          arguments: ["delete", "com.apple.dock", "autohide-delay"])
        restartDockProcess()
    }

    // MARK: - Private

    private static func restartDockProcess() {
        let dockApps = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.dock")
        if let dockProcess = dockApps.first {
            dockProcess.terminate()
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
            print("AeroBar SystemDockConfigurator: \(error.localizedDescription)")
        }
    }
}
