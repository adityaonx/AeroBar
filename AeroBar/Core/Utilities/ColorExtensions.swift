// ColorExtensions.swift — Hex-string initialiser for SwiftUI Color and hue utilities.
// Owner: Core/Utilities
// Depends on: SwiftUI, AppKit

import SwiftUI
import AppKit

extension Color {
    init(_ hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 255, 255, 255)
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255, opacity: Double(a)/255)
    }
}

// Converts a hex colour string to its HSB hue (0–360). Used by colour sliders.
func hueFromHex(_ hex: String) -> Double {
    let clean = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
    var int: UInt64 = 0
    guard Scanner(string: clean).scanHexInt64(&int) else { return 0 }
    let r, g, b: UInt64
    switch clean.count {
    case 3: (r, g, b) = ((int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
    case 6: (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
    default: return 0
    }
    let color = NSColor(red: CGFloat(r)/255, green: CGFloat(g)/255, blue: CGFloat(b)/255, alpha: 1)
    return Double((color.usingColorSpace(.deviceRGB)?.hueComponent ?? 0) * 360)
}

extension Data {
    // Decodes a hex-encoded string (e.g. "48656C6C6F") into raw bytes.
    // Returns nil if the string has an odd length or contains non-hex characters.
    init?(hexEncoded hexString: String) {
        let len = hexString.count / 2
        var buffer = Data(capacity: len)
        var index = hexString.startIndex
        for _ in 0..<len {
            let end = hexString.index(index, offsetBy: 2)
            guard let byte = UInt8(hexString[index..<end], radix: 16) else { return nil }
            buffer.append(byte)
            index = end
        }
        self = buffer
    }
}
