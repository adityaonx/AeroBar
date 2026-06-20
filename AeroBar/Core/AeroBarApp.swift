import SwiftUI
import AppKit

@main
struct AeroBarApp: App {
    // Routes the SwiftUI App lifecycle through our own AppDelegate so we can
    // control launch order: Dock configuration, then the AeroBar panel itself.
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // AeroBar draws its own NSPanel (see AeroBarWindowController) rather than
        // a SwiftUI window, so the only scene we declare is an empty Settings
        // scene — just enough to satisfy the App protocol without macOS creating
        // a default window for us.
        Settings {
            EmptyView()
        }
    }
}
