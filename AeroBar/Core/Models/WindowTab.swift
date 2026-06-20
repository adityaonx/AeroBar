// WindowTab.swift — One live or minimized window shown as a taskbar chip.
// Owner: Core/Models
// Depends on: AppKit (NSImage, AXUIElement)
// Tested by: Tests/WindowTabTests.swift

import AppKit

struct WindowTab: Identifiable, Equatable {
    var id: String { "\(processID)-\(windowID)" }

    let windowID: CGWindowID
    let processID: pid_t
    let appName: String
    let windowTitle: String
    let axElement: AXUIElement
    let appIcon: NSImage

    static func == (lhs: WindowTab, rhs: WindowTab) -> Bool {
        // windowTitle is part of equality so that in-process title changes
        // (e.g. Chrome switching inner tabs from "YouTube" to "Google Search")
        // are detected by the daemon's `activeTabs != discoveredTabs` guard
        // and pushed to the UI immediately, instead of being silently ignored.
        lhs.windowID == rhs.windowID
            && lhs.processID == rhs.processID
            && lhs.windowTitle == rhs.windowTitle
    }
}
