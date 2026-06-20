// PinnedAppDropDelegate.swift — Drag-to-reorder support for the bar's pinned-apps tray.
// Owner: Views/Subviews
// Depends on: Core/Services/AeroBarSettings, Core/Models/PinnedApp
//
// Standard SwiftUI onDrag/onDrop reordering pattern: dropEntered fires
// continuously as the dragged item passes over another item, so we move it
// live rather than waiting for performDrop.

import SwiftUI

struct PinnedAppDropDelegate: DropDelegate {
    let currentItem: PinnedApp
    let settings: AeroBarSettings
    @Binding var draggedItem: PinnedApp?
    
    func performDrop(info: DropInfo) -> Bool {
        draggedItem = nil
        return true
    }
    
    func dropEntered(info: DropInfo) {
        guard let dragged = draggedItem, dragged != currentItem,
              let from = settings.pinnedBarApps.firstIndex(of: dragged),
              let to = settings.pinnedBarApps.firstIndex(of: currentItem),
              settings.pinnedBarApps[to] != dragged
        else { return }

        withAnimation(.spring(response: 0.30, dampingFraction: 0.8)) {
            settings.pinnedBarApps.move(
                fromOffsets: IndexSet(integer: from),
                toOffset: to > from ? to + 1 : to
            )
        }
    }
}
