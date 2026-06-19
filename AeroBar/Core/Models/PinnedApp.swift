// PinnedApp.swift — A user-pinned application entry (bar or start menu).
// Owner: Core/Models
// Depends on: AppKit (NSWorkspace, NSImage), UniformTypeIdentifiers
// Tested by: Tests/PinnedAppTests.swift

import AppKit
import UniformTypeIdentifiers

struct PinnedApp: Identifiable, Equatable, Codable {
    var id: String { bundleIdentifier }

    let bundleIdentifier: String
    let appName: String

    // Icon is resolved at display time — not stored — so it always reflects the
    // current installed version of the app.
    var appIcon: NSImage {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) {
            return NSWorkspace.shared.icon(forFile: url.path)
        }
        return NSWorkspace.shared.icon(for: UTType.application)
    }
}
