// AeroBarPanel.swift — Primary NSPanel subclass. Floats above all windows, never activates.
// Owner: Window
// Depends on: AppKit

import AppKit

final class AeroBarPanel: NSPanel {
    override var canBecomeKey: Bool  { false }
    override var canBecomeMain: Bool { false }

    // CAPSLOCK GHOST-CLICK FIX:
    // macOS Sonoma fires a standalone .flagsChanged event for CapsLock presses, which
    // SwiftUI interprets as a click and creates ghost tabs. Dropping it here at the
    // root window level means SwiftUI never sees the event. This doesn't break
    // Cmd+Click because mouse events carry their modifier payload separately.
    override func sendEvent(_ event: NSEvent) {
        if event.type == .flagsChanged { return }
        super.sendEvent(event)
    }
}
