// MultiDisplayManager.swift — Creates and positions AeroBar panels on every screen.
// Owner: Window
// Depends on: AppKit, Core/Services/AeroBarSettings, Window/AeroBarPanel

import AppKit
import SwiftUI

final class MultiDisplayManager {

    private(set) var secondaryPanels: [AeroBarPanel] = []

    // Recalculates which screens should show AeroBar and creates/removes secondary panels.
    // Always called on the main thread.
    func recalibrate(primaryPanel: AeroBarPanel) {
        secondaryPanels.forEach { $0.orderOut(nil) }
        secondaryPanels.removeAll()

        let screens = NSScreen.screens
        guard !screens.isEmpty else { return }

        let mode = AeroBarSettings.shared.displayTargetMode

        let primaryFrame = NSRect(x: screens[0].frame.minX, y: screens[0].frame.minY,
                                  width: screens[0].frame.width, height: 56)
        if mode == .all || mode == .primaryOnly {
            if primaryPanel.frame != primaryFrame {
                primaryPanel.setFrame(primaryFrame, display: true, animate: false)
            }
            primaryPanel.orderFront(nil)
        } else {
            primaryPanel.orderOut(nil)
        }

        guard (mode == .all || mode == .secondaryOnly) && screens.count > 1 else { return }

        for screen in screens.dropFirst() {
            let panel = makePanel(for: screen, inheriting: primaryPanel)
            secondaryPanels.append(panel)
            panel.orderFront(nil)
        }
    }

    // MARK: - Private

    private func makePanel(for screen: NSScreen, inheriting primary: AeroBarPanel) -> AeroBarPanel {
        let panel = AeroBarPanel(
            contentRect: NSRect(x: screen.frame.minX, y: screen.frame.minY,
                                width: screen.frame.width, height: 56),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.minSize = NSSize(width: screen.frame.width, height: 56)
        panel.maxSize = NSSize(width: screen.frame.width, height: 56)
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = NSWindow.Level(Int(CGWindowLevelForKey(.screenSaverWindow)) + 1)
        panel.ignoresMouseEvents = false
        panel.collectionBehavior = primary.collectionBehavior

        embedBarView(in: panel)
        return panel
    }

    private func embedBarView(in panel: AeroBarPanel) {
        guard let contentView = panel.contentView else { return }
        let host = NSHostingView(rootView: AeroBarMainContainerView())
        host.frame = contentView.bounds
        host.autoresizingMask = [.width, .height]
        contentView.wantsLayer = true
        contentView.layer?.masksToBounds = true
        contentView.layer?.cornerRadius = 12
        contentView.layer?.backgroundColor = .clear
        contentView.layer?.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        contentView.addSubview(host)
    }
}
