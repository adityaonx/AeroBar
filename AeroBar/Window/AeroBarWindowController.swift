// AeroBarWindowController.swift — Thin orchestrator. Owns the primary panel and wires services.
// Owner: Window
// Depends on: All services and sub-controllers.
//
// RULE: If you're adding more than ~20 lines here, the logic belongs in a Service or Controller.
// This file should read like a startup checklist, not an implementation.

import AppKit
import SwiftUI

final class AeroBarWindowController: NSWindowController {

    // MARK: - Sub-controllers (each owns one responsibility)
    private let displayManager   = MultiDisplayManager()
    private let startMenuCtrl    = StartMenuController()
    private let onboardingCtrl   = OnboardingController()

    // MARK: - Focus suppression flag (read by AccessibilityService via JitterGuardProtocol)
    var isSuppressingFocusUpdates: Bool {
        get { WindowArrangementDaemon.shared.isSuppressingFocusUpdates }
        set { WindowArrangementDaemon.shared.isSuppressingFocusUpdates = newValue }
    }
    var isPerformingManagedResize: Bool {
        get { WindowArrangementDaemon.shared.isPerformingManagedResize }
        set { WindowArrangementDaemon.shared.isPerformingManagedResize = newValue }
    }

    // MARK: - Init

    init() {
        let screen = NSScreen.main ?? NSScreen.screens[0]
        let panel = AeroBarPanel(
            contentRect: NSRect(x: screen.frame.minX, y: screen.frame.minY,
                                width: screen.frame.width, height: 56),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        super.init(window: panel)
        configurePrimaryPanel(panel, screen: screen)
        scheduleUpdateCheckIfNeeded()
        evaluateLaunchState()
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Launch routing

    private func evaluateLaunchState() {
        if AXIsProcessTrusted() {
            launchMainEnvironment()
        } else {
            onboardingCtrl.onPermissionGranted = { [weak self] in self?.launchMainEnvironment() }
            onboardingCtrl.setUp()
            onboardingCtrl.presentPopover()
        }
    }

    private func launchMainEnvironment() {
        guard let panel = window as? AeroBarPanel else { return }
        embedBarView(in: panel)
        displayManager.recalibrate(primaryPanel: panel)
        startMenuCtrl.primaryPanel = panel
        AccessibilityService.shared.jitterGuard = self
        WindowArrangementDaemon.shared.start(barHeight: AeroBarSettings.shared.barHeight)
        ZoomInterceptService.shared.install()
        LoginItemService.shared.setEnabled(true)
        registerNotificationObservers()
        panel.setIsVisible(true)
        panel.orderFront(nil)
    }

    // MARK: - Panel setup helpers

    private func configurePrimaryPanel(_ panel: AeroBarPanel, screen: NSScreen) {
        panel.minSize = NSSize(width: screen.frame.width, height: 56)
        panel.maxSize = NSSize(width: screen.frame.width, height: 56)
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.isMovable = false
        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = .hidden
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .ignoresCycle, .stationary,
                                    .fullScreenAuxiliary, .managed]
        panel.setIsVisible(false)
    }

    private func embedBarView(in panel: AeroBarPanel) {
        guard let contentView = panel.contentView else { return }
        let host = NSHostingView(rootView: AeroBarMainContainerView())
        host.frame = contentView.bounds
        host.autoresizingMask = [.width, .height]
        contentView.subviews.forEach { $0.removeFromSuperview() }
        contentView.wantsLayer = true
        contentView.layer?.masksToBounds = true
        contentView.layer?.cornerRadius = 12
        contentView.layer?.backgroundColor = .clear
        contentView.layer?.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        contentView.addSubview(host)
        panel.styleMask = [.borderless]
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hidesOnDeactivate = false
    }

    // MARK: - Notification observers

    private func registerNotificationObservers() {
        let nc  = NotificationCenter.default
        let wnc = NSWorkspace.shared.notificationCenter

        nc.addObserver(forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main) { [weak self] _ in
            guard let self, let panel = self.window as? AeroBarPanel else { return }
            self.displayManager.recalibrate(primaryPanel: panel)
        }
        wnc.addObserver(forName: NSWorkspace.activeSpaceDidChangeNotification, object: nil, queue: .main) { [weak self] _ in
            self?.evaluateFullScreenVisibility()
        }
        wnc.addObserver(forName: NSWorkspace.didActivateApplicationNotification, object: nil, queue: .main) { [weak self] note in
            if let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication {
                AccessibilityService.shared.register(for: app.processIdentifier)
            }
            self?.evaluateFullScreenVisibility()
        }
        nc.addObserver(forName: NSWindow.didEnterFullScreenNotification, object: nil, queue: .main) { [weak self] _ in self?.evaluateFullScreenVisibility() }
        nc.addObserver(forName: NSWindow.didExitFullScreenNotification,  object: nil, queue: .main) { [weak self] _ in self?.evaluateFullScreenVisibility() }
        nc.addObserver(forName: .suppressFocusUpdates, object: nil, queue: .main) { [weak self] _ in self?.isSuppressingFocusUpdates = true  }
        nc.addObserver(forName: .resumeFocusUpdates,   object: nil, queue: .main) { [weak self] _ in self?.isSuppressingFocusUpdates = false }
        nc.addObserver(forName: .triggerAeroStartMenu, object: nil, queue: .main) { [weak self] note in self?.startMenuCtrl.toggle(note) }
        nc.addObserver(forName: .dismissStartMenuWindow, object: nil, queue: .main) { [weak self] _ in self?.startMenuCtrl.close() }
        nc.addObserver(forName: .aeroBarMultiDisplayChanged, object: nil, queue: .main) { [weak self] _ in
            guard let self, let panel = self.window as? AeroBarPanel else { return }
            self.displayManager.recalibrate(primaryPanel: panel)
            self.startMenuCtrl.secondaryPanels = self.displayManager.secondaryPanels
        }
    }

    // MARK: - Full-screen visibility

    private func evaluateFullScreenVisibility() {
        guard let baseWindow = window, let screen = NSScreen.main else { return }
        var shouldHide = false

        if let frontApp = NSWorkspace.shared.frontmostApplication,
           frontApp.bundleIdentifier != Bundle.main.bundleIdentifier {
            let bundleID = frontApp.bundleIdentifier?.lowercased() ?? ""
            let isSystemUI = bundleID.contains("screencapture") || bundleID.contains("controlcenter") || bundleID.contains("siri")
            if isSystemUI { return } // These apps should never hide the bar.

            if let axElement = AeroBarSettings.shared.currentSystemFocusedElement {
                var fsRef: CFTypeRef?
                if AXUIElementCopyAttributeValue(axElement, "AXFullScreen" as CFString, &fsRef) == .success,
                   (fsRef as? Bool) == true { shouldHide = true }

                // Also hide for windows that fill the screen but aren't in a native Full-Screen Space.
                if !shouldHide {
                    let isBrowser = ["com.apple.finder","google.chrome","safari","company.thebrowser.arc","firefox","microsoft.edgemac"]
                        .contains(where: { bundleID.contains($0) })
                    if !isBrowser {
                        var sizeRef: CFTypeRef?
                        if AXUIElementCopyAttributeValue(axElement, kAXSizeAttribute as CFString, &sizeRef) == .success {
                            var size = CGSize.zero
                            AXValueGetValue(sizeRef as! AXValue, .cgSize, &size)
                            if abs(size.width - screen.frame.width) < 15 && abs(size.height - screen.frame.height) < 15 {
                                shouldHide = true
                            }
                        }
                    }
                }
            }
        }

        if shouldHide {
            if baseWindow.alphaValue > 0 { baseWindow.alphaValue = 0; baseWindow.ignoresMouseEvents = true }
        } else {
            if baseWindow.alphaValue < 1 {
                baseWindow.alphaValue = 1
                baseWindow.ignoresMouseEvents = false
                baseWindow.orderFrontRegardless()
                if let panel = baseWindow as? AeroBarPanel { displayManager.recalibrate(primaryPanel: panel) }
            } else {
                baseWindow.orderFrontRegardless()
            }
        }
    }

    // MARK: - Update check

    private func scheduleUpdateCheckIfNeeded() {
        let settings = AeroBarSettings.shared
        guard settings.checkUpdatesOnLaunch else { return }
        let key = "com.aerobar.lastUpdateCheckTimestamp"
        let now = Date().timeIntervalSince1970
        let last = UserDefaults.standard.double(forKey: key)
        let interval: TimeInterval = settings.updateFrequency == 1 ? 604_800 : 86_400
        guard now - last >= interval else { return }
        UserDefaults.standard.set(now, forKey: key)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            AeroBarUpdateEngine.shared.checkForUpdatesSilently()
        }
    }
}

// MARK: - JitterGuardProtocol conformance
extension AeroBarWindowController: JitterGuardProtocol {}
