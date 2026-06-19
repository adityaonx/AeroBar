// WindowTabTests.swift — Tests for WindowTab equality and identity.
// Owner: Tests

import XCTest
@testable import AeroBar

final class WindowTabTests: XCTestCase {

    func test_equality_basedOnWindowAndProcessID() {
        let app = AXUIElementCreateApplication(1)
        let a = WindowTab(windowID: 100, processID: 1, appName: "Safari", windowTitle: "A", axElement: app, appIcon: .init())
        let b = WindowTab(windowID: 100, processID: 1, appName: "Safari", windowTitle: "B", axElement: app, appIcon: .init())
        let c = WindowTab(windowID: 999, processID: 1, appName: "Safari", windowTitle: "A", axElement: app, appIcon: .init())
        XCTAssertEqual(a, b, "Same windowID+processID should be equal regardless of title")
        XCTAssertNotEqual(a, c, "Different windowID should not be equal")
    }

    func test_id_isCombinedString() {
        let app = AXUIElementCreateApplication(1)
        let tab = WindowTab(windowID: 42, processID: 7, appName: "X", windowTitle: "Y", axElement: app, appIcon: .init())
        XCTAssertEqual(tab.id, "7-42")
    }
}
