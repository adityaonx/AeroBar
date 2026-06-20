// StartMenuPinnedDropDelegate.swift — Drag-to-reorder support for the Start Menu's
// pinned-apps grid.
// Owner: Views/StartMenu
// Depends on: Core/Services/AeroBarSettings, Core/Models/PinnedApp
//
// Mirrors Views/Subviews/PinnedAppDropDelegate.swift, but reorders
// AeroBarSettings.pinnedStartApps (the Start Menu grid) instead of
// pinnedBarApps (the bar tray) — the two pinned lists are independent.

import SwiftUI

struct StartMenuPinnedDropDelegate: DropDelegate {
    let item: PinnedApp
    let settings: AeroBarSettings
    @Binding var dragged: PinnedApp?

    func performDrop(info: DropInfo) -> Bool {
        dragged = nil
        return true
    }

    func dropEntered(info: DropInfo) {
        guard let draggedItem = dragged, draggedItem != item,
              let from = settings.pinnedStartApps.firstIndex(of: draggedItem),
              let to = settings.pinnedStartApps.firstIndex(of: item)
        else { return }

        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            settings.pinnedStartApps.move(fromOffsets: IndexSet(integer: from), toOffset: to > from ? to + 1 : to)
        }
    }
}
