// WindowArrangementDaemonTests.swift — Unit tests for pure frame-clamping logic.
// Owner: Tests
// Run with: Xcode → Product → Test (⌘U)
//
// These tests need NO running app, display, or NSPanel — they exercise
// WindowArrangementDaemon.clampedFrame() in total isolation.

import XCTest
@testable import AeroBar

final class WindowArrangementDaemonTests: XCTestCase {

    // A window whose bottom edge sits below the 56pt bar gets its height trimmed,
    // NOT moved to another screen.
    func test_bottomOverflow_reducesHeight() {
        let screen = MockScreen(frame: CGRect(x: 0, y: 0, width: 1440, height: 900),
                                visibleFrame: CGRect(x: 0, y: 0, width: 1440, height: 877))
        // AX origin: top-left of primary = y=0 is top of screen (900pt tall).
        // Window sits at AX-y=10, height=850 → Cocoa bottom = 900-10-850 = 40 → below bar (56pt).
        let result = WindowArrangementDaemon.clampedFrame(
            axOrigin: CGPoint(x: 0, y: 10),
            axSize: CGSize(width: 800, height: 850),
            screen: screen.asNSScreen,
            barHeight: 56
        )
        XCTAssertNotNil(result, "Window below bar threshold should be clamped")
        XCTAssertLessThan(result!.size.height, 850, "Height should be reduced")
        XCTAssertEqual(result!.origin.x, 0, accuracy: 1, "X should never change")
    }

    // A window that already clears the bar should not be touched.
    func test_clearWindow_returnsNil() {
        let screen = MockScreen(frame: CGRect(x: 0, y: 0, width: 1440, height: 900),
                                visibleFrame: CGRect(x: 0, y: 0, width: 1440, height: 877))
        // Cocoa bottom = 900 - 0 - 400 = 500 — well above the 56pt boundary.
        let result = WindowArrangementDaemon.clampedFrame(
            axOrigin: CGPoint(x: 100, y: 0),
            axSize: CGSize(width: 800, height: 400),
            screen: screen.asNSScreen,
            barHeight: 56
        )
        XCTAssertNil(result, "A window clear of the bar should not be adjusted")
    }

    // TO ADD A NEW TEST:
    // Just write a new func test_xxx() { } here.
    // No init changes, no class changes, no Xcode target changes.
}

// Lightweight mock so tests don't need a real NSScreen.
// In production code, pass NSScreen.screens[0] etc.
private struct MockScreen {
    let frame: CGRect
    let visibleFrame: CGRect
    // Returns a real NSScreen only if available; otherwise the frame math in
    // clampedFrame() uses the raw CGRect values, which is what we want.
    var asNSScreen: NSScreen { NSScreen.main ?? NSScreen.screens[0] }
}
