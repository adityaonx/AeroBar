import SwiftUI

struct PinnedAppDropDelegate: DropDelegate {
    let currentItem: PinnedApp
    let settings: AeroBarSettings
    @Binding var draggedItem: PinnedApp?
    
    func performDrop(info: DropInfo) -> Bool {
        self.draggedItem = nil
        return true
    }
    
    func dropEntered(info: DropInfo) {
        guard let dragged = draggedItem, dragged != currentItem else { return }
        
        // FIXED: Pointing directly to the decoupled bar tray array block
        let fromIndex = settings.pinnedBarApps.firstIndex(of: dragged)
        let toIndex = settings.pinnedBarApps.firstIndex(of: currentItem)
        
        if let from = fromIndex, let to = toIndex {
            if settings.pinnedBarApps[to] != dragged {
                withAnimation(.spring(response: 0.30, dampingFraction: 0.8)) {
                    // FIXED: Reordering items smoothly inside the taskbar specific collection
                    settings.pinnedBarApps.move(
                        fromOffsets: IndexSet(integer: from),
                        toOffset: to > from ? to + 1 : to
                    )
                }
            }
        }
    }
}
