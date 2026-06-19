// DisplayTargetMode.swift — Enum controlling which screens AeroBar appears on.
// Owner: Core/Utilities
// Depends on: Foundation
// Tested by: Tests/DisplayTargetModeTests.swift

import Foundation

enum DisplayTargetMode: String, CaseIterable, Identifiable {
    case all           = "All Displays"
    case primaryOnly   = "Primary Display Only"
    case secondaryOnly = "Secondary Displays Only"

    var id: String { rawValue }
}
