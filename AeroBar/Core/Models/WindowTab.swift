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
        lhs.windowID == rhs.windowID && lhs.processID == rhs.processID
    }
}
