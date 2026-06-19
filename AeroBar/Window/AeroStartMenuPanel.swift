// AeroStartMenuPanel.swift — NSPanel for the Start Menu overlay. Must accept key events.
// Owner: Window
// Depends on: AppKit

import AppKit

final class AeroStartMenuPanel: NSPanel {
    override var canBecomeKey: Bool  { true  }
    override var canBecomeMain: Bool { false }
}
