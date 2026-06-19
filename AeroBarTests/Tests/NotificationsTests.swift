// NotificationsTests.swift — Verifies typed Notification.Name constants are stable.
// Owner: Tests
//
// These look trivial but they catch regressions where a name string changes
// and breaks inter-component communication silently at runtime.

import XCTest
@testable import AeroBar

final class NotificationsTests: XCTestCase {

    func test_notificationNames_areStable() {
        XCTAssertEqual(Notification.Name.triggerAeroStartMenu.rawValue,    "triggerAeroStartMenu")
        XCTAssertEqual(Notification.Name.dismissStartMenuWindow.rawValue,  "dismissStartMenuWindow")
        XCTAssertEqual(Notification.Name.aeroBarMultiDisplayChanged.rawValue, "AeroBarMultiDisplayChanged")
        XCTAssertEqual(Notification.Name.suppressFocusUpdates.rawValue,    "suppressFocusUpdates")
        XCTAssertEqual(Notification.Name.resumeFocusUpdates.rawValue,      "resumeFocusUpdates")
    }
}
