import SwiftUI
import AppKit

@main
struct AeroBarApp: App {
    // Bridges our custom AppDelegate coordinator straight into the SwiftUI App lifecycle loop
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        // Disables default window creation since AeroBarWindowController draws its own panel
        Settings {
            EmptyView()
        }
    }
}
