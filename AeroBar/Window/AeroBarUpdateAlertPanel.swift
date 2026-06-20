// AeroBarUpdateAlertPanel.swift — Floating panel that hosts AeroBarUpdateAlertView.
// Owner: Window
// Depends on: AppKit, SwiftUI, Views/Settings/AeroBarUpdateAlertView
//
// A regular (key-accepting) NSPanel, unlike AeroBarPanel/AeroPreviewPanel — this
// is a genuine modal-style prompt the user reads and clicks a button on, so it's
// fine for it to take key status normally.

import AppKit
import SwiftUI

final class AeroBarUpdateAlertPanel: NSPanel {

    static func show(version: String, changelog: String, onUpdateNow: @escaping () -> Void) {
        let panel = AeroBarUpdateAlertPanel(
            contentRect: NSRect(x: 0, y: 0, width: 460, height: 480),
            styleMask: [.titled, .closable, .fullSizeContentView, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.titlebarAppearsTransparent = true
        panel.title = ""
        panel.isMovableByWindowBackground = true
        panel.level = .statusBar + 1
        panel.isReleasedWhenClosed = false
        panel.center()

        let rootView = AeroBarUpdateAlertView(
            version: version,
            changelog: changelog,
            onUpdateNow: {
                panel.close()
                onUpdateNow()
            },
            onLater: {
                panel.close()
            }
        )
        panel.contentView = NSHostingView(rootView: rootView)

        // AeroBar runs as .accessory (no Dock icon), so makeKeyAndOrderFront silently
        // fails when no window currently has focus (e.g. during an automatic
        // launch-time check). Briefly activate the app so the panel actually surfaces.
        NSApp.activate(ignoringOtherApps: true)
        panel.orderFrontRegardless()
    }
}
