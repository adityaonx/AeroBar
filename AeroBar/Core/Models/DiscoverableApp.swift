// DiscoverableApp.swift — A local app found by Spotlight, shown in the Start Menu list.
// Owner: Core/Models
// Depends on: AppKit (NSImage)
// Tested by: Tests/DiscoverableAppTests.swift

import AppKit

struct DiscoverableApp: Identifiable, Equatable {
    var id: String { path }

    let appName: String
    let path: String
    let icon: NSImage
}

// Start-menu-only types. Kept here to avoid creating micro-files for two tiny structs.

struct LocalSystemApp: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let bundleID: String
    let pathURL: URL
    let icon: NSImage
}

struct RecentFinderItem: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let fileURL: URL
    let fileExtension: String
    let accessTimeDescription: String
}
