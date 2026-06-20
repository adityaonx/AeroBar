// AppDelegate.swift — App lifecycle entry point.
// Owner: Core
// Depends on: Window/AeroBarWindowController, Core/Utilities/SystemDockConfigurator
//
// Kept intentionally thin: startup just configures the Dock and hands off to
// AeroBarWindowController, which owns the actual launch/onboarding sequence.

import AppKit
import Collaboration

final class AppDelegate: NSObject, NSApplicationDelegate {
    var windowController: AeroBarWindowController?

    @MainActor func applicationDidFinishLaunching(_ notification: Notification) {
        // AeroBar is a background utility, not a regular app — hide it from the
        // Dock and Cmd+Tab switcher immediately on launch.
        NSApp.setActivationPolicy(.accessory)

        // Reconfigure the system Dock (bottom position, autohide) so it stays
        // out of AeroBar's way. Restored on quit in applicationWillTerminate.
        SystemDockConfigurator.enforceAeroDockDefaults()

        // AeroBarWindowController owns everything from here: it checks the
        // Accessibility permission, runs onboarding if needed, and only then
        // builds and shows the actual taskbar panel.
        windowController = AeroBarWindowController()

        prefetchUserAvatar()
    }

    func applicationWillTerminate(_ notification: Notification) {
        SystemDockConfigurator.restoreSystemDockDefaults()
    }

    // MARK: - User avatar prefetch

    // The Start Menu shows the macOS account avatar in its header. Resolving it
    // via the Collaboration framework involves a directory lookup, so we kick
    // it off once at launch (off the main thread) and cache the result, rather
    // than paying that cost the first time the user opens the Start Menu.
    private func prefetchUserAvatar() {
        DispatchQueue.global(qos: .utility).async {
            guard let identity = CBIdentity(name: NSUserName(), authority: .local()),
                  let avatarImage = identity.image
            else { return }

            var proposedRect = CGRect(origin: .zero, size: avatarImage.size)
            guard let cgImage = avatarImage.cgImage(forProposedRect: &proposedRect, context: nil, hints: nil)
            else { return }

            DispatchQueue.main.async {
                AeroBarSettings.shared.cachedUserAvatar = cgImage
            }
        }
    }
}
