// ColorExtensionsTests.swift — Tests for hex colour utilities.
// Owner: Tests

import XCTest
@testable import AeroBar

final class ColorExtensionsTests: XCTestCase {

    func test_hueFromHex_red() {
        // Pure red (#FF0000) should give hue ≈ 0
        let hue = hueFromHex("#FF0000")
        XCTAssertEqual(hue, 0, accuracy: 5)
    }

    func test_hueFromHex_green() {
        let hue = hueFromHex("#00FF00")
        XCTAssertEqual(hue, 120, accuracy: 5)
    }

    func test_hueFromHex_blue() {
        let hue = hueFromHex("#0000FF")
        XCTAssertEqual(hue, 240, accuracy: 5)
    }

    func test_dataFromHexString_roundtrip() {
        let hex = "48656C6C6F"  // "Hello"
        let data = Data(hexEncoded: hex)
        XCTAssertNotNil(data)
        XCTAssertEqual(String(data: data!, encoding: .utf8), "Hello")
    }

    func test_dataFromHexString_invalidReturnsNil() {
        XCTAssertNil(Data(hexEncoded: "ZZZZ"))
    }
}
