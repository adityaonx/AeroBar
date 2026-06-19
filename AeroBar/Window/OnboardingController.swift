// OnboardingController.swift — Status bar icon and permission popover shown before setup.
// Owner: Window
// Depends on: AppKit, SwiftUI

import AppKit
import SwiftUI

final class OnboardingController {

    private var statusItem: NSStatusItem?
    private let popover = NSPopover()
    private var permissionTimer: Timer?

    var onPermissionGranted: (() -> Void)?

    // MARK: - Setup

    func setUp() {
        guard statusItem == nil else { return }
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem?.button?.image = NSImage(
            systemSymbolName: "menubar.dock.rectangle.badge.record",
            accessibilityDescription: "AeroBar Setup"
        )
        statusItem?.button?.target = self
        statusItem?.button?.action = #selector(handleButtonClick)

        let view = AeroBarOnboardingPopoverView(
            onOpenSettings: { NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!) },
            onStartEngine: { [weak self] in self?.handleManualLaunch() }
        )
        popover.contentViewController = NSHostingController(rootView: view)
        popover.behavior = .applicationDefined

        startPermissionPolling()
    }

    func tearDown() {
        permissionTimer?.invalidate()
        permissionTimer = nil
        if let item = statusItem { NSStatusBar.system.removeStatusItem(item); statusItem = nil }
    }

    func presentPopover() {
        guard let button = statusItem?.button, !popover.isShown else { return }
        DispatchQueue.main.async { self.popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY) }
    }

    // MARK: - Private

    @objc private func handleButtonClick() {
        popover.isShown ? popover.performClose(nil) : presentPopover()
    }

    @objc private func handleManualLaunch() {
        guard AXIsProcessTrusted() else { return }
        popover.performClose(nil)
        tearDown()
        onPermissionGranted?()
    }

    private func startPermissionPolling() {
        permissionTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self else { return }
            let trusted = AXIsProcessTrusted()
            if trusted != AeroBarSettings.shared.isAccessibilityEnabled {
                AeroBarSettings.shared.isAccessibilityEnabled = trusted
                self.statusItem?.button?.image = NSImage(
                    systemSymbolName: trusted ? "menubar.dock.rectangle" : "menubar.dock.rectangle.badge.record",
                    accessibilityDescription: "AeroBar Status"
                )
                if !self.popover.isShown { self.presentPopover() }
            }
        }
    }
}
