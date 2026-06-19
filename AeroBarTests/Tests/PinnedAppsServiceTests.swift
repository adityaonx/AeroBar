// PinnedAppsServiceTests.swift — Tests for pinned-app persistence.
// Owner: Tests
//
// Uses a temporary UserDefaults suite so tests don't touch real app data.

import XCTest
@testable import AeroBar

final class PinnedAppsServiceTests: XCTestCase {

    func test_ensureFinderPinned_insertsFinder() {
        var start: [PinnedApp] = []
        var bar:   [PinnedApp] = []
        PinnedAppsService.shared.ensureFinderPinned(start: &start, bar: &bar)
        XCTAssertTrue(start.contains { $0.bundleIdentifier == "com.apple.finder" })
        XCTAssertTrue(bar.contains   { $0.bundleIdentifier == "com.apple.finder" })
    }

    func test_ensureFinderPinned_doesNotDuplicate() {
        let finder = PinnedApp(bundleIdentifier: "com.apple.finder", appName: "Finder")
        var start: [PinnedApp] = [finder]
        var bar:   [PinnedApp] = [finder]
        PinnedAppsService.shared.ensureFinderPinned(start: &start, bar: &bar)
        XCTAssertEqual(start.filter { $0.bundleIdentifier == "com.apple.finder" }.count, 1)
        XCTAssertEqual(bar.filter   { $0.bundleIdentifier == "com.apple.finder" }.count, 1)
    }
}
