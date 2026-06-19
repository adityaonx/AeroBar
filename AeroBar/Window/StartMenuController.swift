// StartMenuController.swift — Opens, positions, and closes the Start Menu panel.
// Owner: Window
// Depends on: AppKit, SwiftUI, Window/AeroStartMenuPanel

import AppKit
import SwiftUI

final class StartMenuController {

    private var menuPanel: AeroStartMenuPanel?
    private var localClickMonitor: Any?
    private var globalClickMonitor: Any?
    private var lastDismissalTime: TimeInterval = 0

    // The primary bar panel is needed to whitelist its click events so the menu
    // doesn't dismiss when the user clicks the bar itself.
    weak var primaryPanel: NSPanel?
    var secondaryPanels: [AeroBarPanel] = []

    // MARK: - Toggle

    func toggle(_ notification: Notification) {
        if let existing = menuPanel, existing.isVisible {
            close()
            return
        }
        // Debounce: ignore a toggle fired within 250ms of the last close.
        guard Date().timeIntervalSince1970 - lastDismissalTime >= 0.25 else { return }
        open(notification)
    }

    // MARK: - Open

    private func open(_ notification: Notification) {
        let settings = AeroBarSettings.shared
        let targetScreen = notification.userInfo?["targetScreen"] as? NSScreen
                        ?? NSScreen.main ?? NSScreen.screens[0]
        let menuWidth: CGFloat  = settings.showRecommendations ? 980 : 740
        let menuHeight: CGFloat = 520
        let screenFrame = targetScreen.frame

        let rect = NSRect(x: screenFrame.origin.x + 16,
                          y: screenFrame.origin.y + 62,
                          width: menuWidth, height: menuHeight)

        let panel = AeroStartMenuPanel(
            contentRect: rect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.ignoresMouseEvents = false
        panel.setFrame(rect, display: true, animate: false)
        panel.level = NSWindow.Level(Int(CGWindowLevelForKey(.screenSaverWindow)) + 2)
        panel.collectionBehavior = [.ignoresCycle, .stationary, .fullScreenAuxiliary]

        let host = NSHostingView(rootView: AeroStartMenuView())
        host.frame = NSRect(origin: .zero, size: CGSize(width: menuWidth, height: menuHeight))
        host.autoresizingMask = [.width, .height]
        panel.contentView?.addSubview(host)
        panel.contentView?.wantsLayer = true
        panel.contentView?.layer?.cornerRadius = 18
        panel.contentView?.layer?.masksToBounds = true

        menuPanel = panel

        // DISPLAY FIX: orderFront first (respects frame origin = correct display),
        // then makeKey separately. makeKeyAndOrderFront in one shot pulls the panel to
        // the active space rather than the display defined by the frame origin.
        panel.orderFront(nil)
        panel.makeKey()

        installClickMonitors(activeMenu: panel)
    }

    // MARK: - Close

    func close() {
        lastDismissalTime = Date().timeIntervalSince1970
        removeClickMonitors()
        menuPanel?.resignKey()
        menuPanel?.orderOut(nil)
        menuPanel = nil
    }

    // MARK: - Click monitors

    private func installClickMonitors(activeMenu: NSPanel) {
        localClickMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self, let menu = self.menuPanel else { return event }
            if self.isInsideAllowedWindow(event: event, menu: menu) { return event }
            DispatchQueue.main.async { self.close() }
            return event
        }
        globalClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self, let menu = self.menuPanel else { return }
            if !self.isInsideAllowedWindow(event: event, menu: menu) {
                DispatchQueue.main.async { self.close() }
            }
        }
    }

    private func removeClickMonitors() {
        if let m = localClickMonitor  { NSEvent.removeMonitor(m); localClickMonitor  = nil }
        if let m = globalClickMonitor { NSEvent.removeMonitor(m); globalClickMonitor = nil }
    }

    private func isInsideAllowedWindow(event: NSEvent, menu: NSPanel) -> Bool {
        let num = event.windowNumber
        if num == menu.windowNumber { return true }
        if let primary = primaryPanel, num == primary.windowNumber { return true }
        if menu.childWindows?.contains(where: { $0.windowNumber == num }) == true { return true }
        if secondaryPanels.contains(where: { $0.windowNumber == num }) { return true }
        return false
    }
}
