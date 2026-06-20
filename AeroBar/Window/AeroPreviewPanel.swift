// AeroPreviewPanel.swift — Non-activating NSPanel for window/app preview popovers.
// Owner: Window
// Depends on: AppKit
//
// WHY THIS EXISTS:
//   SwiftUI's built-in `.popover(isPresented:)` always backs its content with an
//   NSWindow that becomes key when shown. For a normal app that's fine — key status
//   returns to the previous window when the popover closes.
//
//   AeroBar is different: it runs with NSApp.setActivationPolicy(.accessory), and
//   its host window (AeroBarPanel) is hardcoded `canBecomeKey = false` by design —
//   the whole point is that clicking the bar must never steal focus from whatever
//   app the user is actually working in.
//
//   That combination breaks `.popover`: when the popover (which DOES take key
//   status) closes, there is no key-capable AeroBar window for the OS to hand key
//   status back to. Key status instead falls through to general window-server
//   activation handling, and the user's VERY NEXT click anywhere in AeroBar gets
//   consumed by the OS re-establishing input focus on the process — not delivered
//   to any SwiftUI gesture recognizer. That's the "first click just (re)focuses,
//   second click actually acts" symptom on every popover-adjacent control: the tab
//   itself, the chip's hover-to-preview, and the chip's tap-to-focus, since all
//   three sit behind the same `.popover` mechanism.
//
//   Fix: never let preview content take key status in the first place. This panel
//   mirrors AeroBarPanel's `canBecomeKey = false` so showing/hiding a preview is a
//   pure visual operation that never touches the window-server's key/activation
//   chain — eliminating the whole class of bug instead of routing around its
//   symptoms with click monitors.

import AppKit

final class AeroPreviewPanel: NSPanel {
    override var canBecomeKey: Bool  { false }
    override var canBecomeMain: Bool { false }

    convenience init() {
        self.init(
            contentRect: .zero,
            styleMask: [.nonactivatingPanel, .borderless, .utilityWindow],
            backing: .buffered,
            defer: false
        )
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        hidesOnDeactivate = false
        isReleasedWhenClosed = false
        // Resize/move must be instantaneous — any implicit animation (utility
        // panels default to fade/resize animation) lets the bad top-left-anchored
        // intermediate frame from setContentSize() paint for a frame, which is
        // what was visible as the panel dipping into the bar at 10–25% scale.
        animationBehavior = .none
    }
}
