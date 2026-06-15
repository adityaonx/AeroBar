import AppKit
import SwiftUI
import UniformTypeIdentifiers
import Combine
import ServiceManagement

// =======================================================
// 🖥️ DECOUPLED PANEL ARCHITECTURE
// =======================================================

// 1. The Main Background Taskbar Rail Panel Container
final class AeroBarPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

// 2. 🎯 Dedicated Start Menu Panel Container
// Inherits standard key status capability so child text views are interactive!
final class AeroStartMenuPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
final class AeroBarWindowController: NSWindowController, NSPopoverDelegate {
    private var systemAXObserver: AXObserver?
    private var secondaryAeroPanels: [AeroBarPanel] = []
    private var registeredPIDObserver: pid_t?
    private var arrangementTimer: Timer?
    private var permissionPollTimer: Timer?
    private var displayObserver: NSObjectProtocol?
    private var spaceChangeObserver: NSObjectProtocol?
    private var appActivateObserver: NSObjectProtocol?
    private var previousWindowFrames: [CGWindowID: CGRect] = [:]
    // 🛡️ CROSS-DISPLAY DRAG COOLDOWN: tracks how many consecutive still cycles
    // have elapsed since a window last moved. We require at least 3 stable cycles
    // (~0.45s) before we apply any resize — this prevents the "snap-resize on drop"
    // that happens when a window is dragged from display 1 → display 2 and the
    // daemon fires on the very first stationary frame, and also prevents the
    // "sticky barrier" when dragging from display 2 → display 1 (the resize was
    // fighting the drag because the window settled into the forbidden zone for just
    // one tick before crossing the boundary).
    private var windowStillCycleCount: [CGWindowID: Int] = [:]
    private let requiredStillCyclesBeforeResize = 3
    private var localClickMonitor: Any?
    private var globalClickMonitor: Any?
    private var lastDismissalTime: TimeInterval = 0
    
    private var statusItem: NSStatusItem?
    private let interfacePopover = NSPopover()
    private let appearancePopover = NSPopover()
    
    private var modernStartWindow: NSPanel?
    
    init() {
        AeroBarUpdateEngine.shared.checkForUpdatesSilently()
        let screen = NSScreen.main ?? NSScreen.screens[0]
        let panel = AeroBarPanel(
            contentRect: NSRect(x: screen.frame.minX, y: screen.frame.minY, width: screen.frame.width, height: 56),
            styleMask: [NSWindow.StyleMask.borderless, NSWindow.StyleMask.nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        super.init(window: panel)
        
        panel.minSize = NSSize(width: screen.frame.width, height: 56)
        panel.maxSize = NSSize(width: screen.frame.width, height: 56)
        panel.isOpaque = false
        panel.backgroundColor = NSColor.clear
        panel.hasShadow = false
        panel.isMovable = false
        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = NSWindow.TitleVisibility.hidden
        
        // ⚙️ PERMANENT LAYERING PARAMS:
        panel.level = NSWindow.Level.statusBar
        panel.collectionBehavior = [
            NSWindow.CollectionBehavior.canJoinAllSpaces,
            NSWindow.CollectionBehavior.ignoresCycle,
            NSWindow.CollectionBehavior.stationary,
            NSWindow.CollectionBehavior.fullScreenAuxiliary,
            NSWindow.CollectionBehavior.managed
        ]
        
        panel.setIsVisible(false)
        
        configureStartOnBootDaemon()
        evaluateLaunchLifecycleState()
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    private func registerActiveApplicationAXObserver(for pid: pid_t) {
        if registeredPIDObserver == pid && systemAXObserver != nil { return }
        
        if let oldObserver = systemAXObserver, let oldPID = registeredPIDObserver {
            let oldAppRef = AXUIElementCreateApplication(oldPID)
            AXObserverRemoveNotification(oldObserver, oldAppRef, kAXFocusedWindowChangedNotification as CFString)
            AXObserverRemoveNotification(oldObserver, oldAppRef, kAXTitleChangedNotification as CFString)
            self.systemAXObserver = nil
            self.registeredPIDObserver = nil
        }
        
        var observerRef: AXObserver?
        let createStatus = AXObserverCreate(pid, { (observer, element, notification, refCon) in
            DispatchQueue.main.async {
                let notificationType = notification as String
                
                if notificationType == kAXFocusedWindowChangedNotification {
                    AeroBarSettings.shared.currentSystemFocusedElement = element
                } else if notificationType == kAXTitleChangedNotification {
                    // 🎯 THE LIVE TRACKING FIX:
                    // Instead of just cycling the focused tracking token element,
                    // we pull the current window controller reference pointer from the context block
                    // and force an immediate layout update across our active taskbar tab arrays!
                    if let controllerPointer = refCon {
                        let myController = Unmanaged<AeroBarWindowController>.fromOpaque(controllerPointer).takeUnretainedValue()
                        
                        // We give the system a tiny 0.05s buffer to finish writing its layout string,
                        // then explicitly execute the tab array parsing engine instantly.
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                            myController.startWindowArrangementDaemon(barHeightThreshold: AeroBarSettings.shared.barHeight)
                        }
                    }
                }
            }
        }, &observerRef)
        
        guard createStatus == .success, let observer = observerRef else { return }
        
        let appRef = AXUIElementCreateApplication(pid)
        
        // 🎯 THE MEMORY CONTEXT FIX:
        // We pass an unretained self pointer context reference into the AXObserver notification engine.
        // This allows our static observer callback block above to securely invoke our instance functions.
        let selfContextPointer = Unmanaged.passUnretained(self).toOpaque()
        
        _ = AXObserverAddNotification(observer, appRef, kAXFocusedWindowChangedNotification as CFString, selfContextPointer)
        _ = AXObserverAddNotification(observer, appRef, kAXTitleChangedNotification as CFString, selfContextPointer)
        
        self.systemAXObserver = observer
        self.registeredPIDObserver = pid
        
        var focusedWindowRef: CFTypeRef?
        if AXUIElementCopyAttributeValue(appRef, kAXFocusedWindowAttribute as CFString, &focusedWindowRef) == .success {
            AeroBarSettings.shared.currentSystemFocusedElement = (focusedWindowRef as! AXUIElement)
        }
        
        CFRunLoopAddSource(CFRunLoopGetCurrent(), AXObserverGetRunLoopSource(observer), .commonModes)
    }
    private func configureStartOnBootDaemon() {
        if #available(macOS 13.0, *) {
            let mainService = SMAppService.mainApp
            do {
                if mainService.status != .enabled { try mainService.register() }
            } catch { print("SMAppService error: \(error.localizedDescription)") }
        } else {
            let helperBundleIdentifier = "com.aerobar.LauncherHelper" as CFString
            SMLoginItemSetEnabled(helperBundleIdentifier, true)
        }
    }
    
    private func evaluateLaunchLifecycleState() {
        let isTrusted = AXIsProcessTrusted()
        AeroBarSettings.shared.isAccessibilityEnabled = isTrusted
        
        if isTrusted {
            tearDownStatusBarOnboardingMenu()
            launchMainAeroBarEnvironment()
        } else {
            setupStatusBarOnboardingMenu()
            startPermissionMonitoringHeartbeat()
            Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
                guard let self = self, let button = self.statusItem?.button else { return }
                if button.window != nil {
                    timer.invalidate()
                    DispatchQueue.main.async { self.presentOnboardingPopoverLayout() }
                }
            }
        }
    }
    
    private func setupStatusBarOnboardingMenu() {
        guard statusItem == nil else { return }
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "menubar.dock.rectangle.badge.record", accessibilityDescription: "AeroBar Setup")
            button.target = self
            button.action = #selector(handleStatusItemButtonClick)
        }
        
        let swiftUiOnboardingView = AeroBarOnboardingPopoverView(
            onOpenSettings: { [weak self] in self?.routeToSystemAccessibilityPanel() },
            onStartEngine: { [weak self] in self?.handleManualLaunchTrigger() }
        )
        interfacePopover.contentViewController = NSHostingController(rootView: swiftUiOnboardingView)
        interfacePopover.behavior = .applicationDefined
    }
    
    @objc private func handleStatusItemButtonClick(_ sender: Any?) {
        if interfacePopover.isShown { interfacePopover.performClose(nil) }
        else { presentOnboardingPopoverLayout() }
    }
    
    private func presentOnboardingPopoverLayout() {
        guard let button = statusItem?.button, !interfacePopover.isShown else { return }
        DispatchQueue.main.async { self.interfacePopover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY) }
    }
    
    private func startPermissionMonitoringHeartbeat() {
        permissionPollTimer?.invalidate()
        permissionPollTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let trackingTrustStatus = AXIsProcessTrusted()
            if trackingTrustStatus != AeroBarSettings.shared.isAccessibilityEnabled {
                AeroBarSettings.shared.isAccessibilityEnabled = trackingTrustStatus
                if let button = self.statusItem?.button {
                    button.image = NSImage(systemSymbolName: trackingTrustStatus ? "menubar.dock.rectangle" : "menubar.dock.rectangle.badge.record", accessibilityDescription: "AeroBar Status")
                }
                if !self.interfacePopover.isShown { self.presentOnboardingPopoverLayout() }
            }
        }
    }
    
    @objc private func routeToSystemAccessibilityPanel() {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
    }
    
    @objc private func handleManualLaunchTrigger() {
        guard AXIsProcessTrusted() else { return }
        interfacePopover.performClose(nil)
        tearDownStatusBarOnboardingMenu()
        launchMainAeroBarEnvironment()
    }
    
    private func tearDownStatusBarOnboardingMenu() {
        permissionPollTimer?.invalidate()
        permissionPollTimer = nil
        if let item = statusItem {
            NSStatusBar.system.removeStatusItem(item)
            statusItem = nil
        }
    }
    
    private func launchMainAeroBarEnvironment() {
        guard let panel = window as? AeroBarPanel, let contentView = panel.contentView else { return }
        let hostingView = NSHostingView(rootView: AeroBarMainContainerView())
        hostingView.frame = contentView.bounds
        hostingView.autoresizingMask = [.width, .height]
        
        contentView.subviews.forEach { $0.removeFromSuperview() }
        contentView.wantsLayer = true
        contentView.layer?.masksToBounds = true
        contentView.layer?.cornerRadius = 12.0
        contentView.layer?.backgroundColor = .clear
        contentView.layer?.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        contentView.addSubview(hostingView)
        
        panel.styleMask = [.borderless]
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hidesOnDeactivate = false
        
        panel.level = .statusBar
        
        panel.collectionBehavior = [
            .canJoinAllSpaces,
            .ignoresCycle,
            .stationary,
            .fullScreenAuxiliary,
            .managed
        ]
        
        recalibrateWindowGeometry()
        setupNotificationObservers()
        startWindowArrangementDaemon(barHeightThreshold: AeroBarSettings.shared.barHeight)
        panel.alphaValue = 1.0
        panel.ignoresMouseEvents = false
        panel.setIsVisible(true)
        panel.orderFront(nil)
    }
    
    private func recalibrateWindowGeometry() {
        // 1. Clear out all existing secondary taskbar panels to prevent frame layout leakage
        secondaryAeroPanels.forEach { $0.orderOut(nil); $0.contentView?.subviews.forEach { $0.removeFromSuperview() } }
        secondaryAeroPanels.removeAll()
        
        let screens = NSScreen.screens
        guard !screens.isEmpty else { return }
        
        guard let primaryPanel = window as? AeroBarPanel else { return }
        let currentMode = AeroBarSettings.shared.displayTargetMode
        
        DispatchQueue.main.async {
            // 2. CALIBRATE PRIMARY BUILT-IN DISPLAY
            let primaryScreen = screens[0]
            let primaryExpectedFrame = NSRect(x: primaryScreen.frame.minX, y: primaryScreen.frame.minY, width: primaryScreen.frame.width, height: 56)
            
            if currentMode == .all || currentMode == .primaryOnly {
                if primaryPanel.frame != primaryExpectedFrame {
                    primaryPanel.setFrame(primaryExpectedFrame, display: true, animate: false)
                }
                primaryPanel.orderFront(nil)
            } else {
                // If External Only is active, dismiss the main panel window frame node completely
                primaryPanel.orderOut(nil)
            }
            
            // 3. CALIBRATE SECONDARY EXTERNAL WORKSPACES
            if (currentMode == .all || currentMode == .secondaryOnly) && screens.count > 1 {
                for index in 1..<screens.count {
                    let externalScreen = screens[index]
                    
                    let secondaryPanel = AeroBarPanel(
                        contentRect: NSRect(x: externalScreen.frame.minX, y: externalScreen.frame.minY, width: externalScreen.frame.width, height: 56),
                        styleMask: [.borderless, .nonactivatingPanel],
                        backing: .buffered,
                        defer: false
                    )
                    
                    secondaryPanel.minSize = NSSize(width: externalScreen.frame.width, height: 56)
                    secondaryPanel.maxSize = NSSize(width: externalScreen.frame.width, height: 56)
                    secondaryPanel.isOpaque = false
                    secondaryPanel.backgroundColor = .clear
                    secondaryPanel.hasShadow = false
                    secondaryPanel.level = .statusBar
                    secondaryPanel.ignoresMouseEvents = false
                    secondaryPanel.collectionBehavior = primaryPanel.collectionBehavior
                    
                    let secondaryHostingView = NSHostingView(rootView: AeroBarMainContainerView())
                    if let contentView = secondaryPanel.contentView {
                        secondaryHostingView.frame = contentView.bounds
                        secondaryHostingView.autoresizingMask = [.width, .height]
                        
                        contentView.wantsLayer = true
                        contentView.layer?.masksToBounds = true
                        contentView.layer?.cornerRadius = 12.0
                        contentView.layer?.backgroundColor = .clear
                        contentView.layer?.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
                        contentView.addSubview(secondaryHostingView)
                    }
                    
                    self.secondaryAeroPanels.append(secondaryPanel)
                    secondaryPanel.orderFront(nil)
                }
            }
        }
    }
    
    private func setupNotificationObservers() {
        
        displayObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.recalibrateWindowGeometry()
        }
        
        spaceChangeObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.evaluateFullScreenVisibilityState()
        }
        
        appActivateObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication {
                self?.registerActiveApplicationAXObserver(for: app.processIdentifier)
            }
            self?.evaluateFullScreenVisibilityState()
        }
        
        _ = NotificationCenter.default.addObserver(forName: NSWindow.didEnterFullScreenNotification, object: nil, queue: .main) { [weak self] _ in
            self?.evaluateFullScreenVisibilityState()
        }
        _ = NotificationCenter.default.addObserver(forName: NSWindow.didExitFullScreenNotification, object: nil, queue: .main) { [weak self] _ in
            self?.evaluateFullScreenVisibilityState()
        }
        
        _ = NotificationCenter.default.addObserver(
                    forName: Notification.Name("triggerAeroStartMenu"),
                    object: nil,
                    queue: .main
                ) { [weak self] notification in
                    self?.toggleModernStartMenuPopover(notification)
                }
        _ = NotificationCenter.default.addObserver(
            forName: Notification.Name("dismissStartMenuWindow"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.forceCloseStartMenuPopover()
        }
        
        _ = NotificationCenter.default.addObserver(
            forName: Notification.Name("triggerAeroAppearanceLab"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.presentOrbCustomizerPopover()
        }
        // 🎯 THE LIVE MULTI-MONITOR WORKSPACE OBSERVER:
        // Listens to our custom notification pass and recalibrates multi-screen panels instantly!
        _ = NotificationCenter.default.addObserver(
            forName: Notification.Name("AeroBarMultiDisplayChanged"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.recalibrateWindowGeometry()
        }
    }
    
    @objc private func toggleModernStartMenuPopover(_ notification: Notification) {
            if let existingWindow = modernStartWindow, existingWindow.isVisible {
                forceCloseStartMenuPopover()
                return
            }
            
            if NSDate().timeIntervalSince1970 - lastDismissalTime < 0.25 { return }
            
            guard let baseWindow = window as? AeroBarPanel else { return }
            
            // 🎯 FIX: Safely unpack target display notification parameters
            let targetScreen = notification.userInfo?["targetScreen"] as? NSScreen ?? NSScreen.main ?? NSScreen.screens[0]
            let isRecsEnabled = AeroBarSettings.shared.showRecommendations
            let menuWidth: CGFloat = isRecsEnabled ? 980 : 740
            let menuHeight: CGFloat = 520
            
            let screenFrame = targetScreen.frame
            let startMenuRect = NSRect(
                x: screenFrame.origin.x + 16,
                y: screenFrame.origin.y + 62,
                width: menuWidth,
                height: menuHeight
            )
            
            let overlayPanel = AeroStartMenuPanel(
                contentRect: startMenuRect,
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            
            overlayPanel.isOpaque = false
            // 🎯 FIX: Use explicit NSColor type matching
            overlayPanel.backgroundColor = NSColor.clear
            overlayPanel.hasShadow = true
            overlayPanel.ignoresMouseEvents = false
            
            // Assign explicit display space frames
            overlayPanel.setFrame(startMenuRect, display: true, animate: false)
            overlayPanel.level = NSWindow.Level(Int(CGWindowLevelForKey(.dockWindow)) + 3)
            
            // 🎯 FIX: Provide full explicit option set types
            overlayPanel.collectionBehavior = [
                NSWindow.CollectionBehavior.canJoinAllSpaces,
                NSWindow.CollectionBehavior.ignoresCycle,
                NSWindow.CollectionBehavior.stationary,
                NSWindow.CollectionBehavior.fullScreenAuxiliary
            ]
            
            let hostingView = NSHostingView(rootView: AeroStartMenuView())
            hostingView.frame = NSRect(x: 0, y: 0, width: menuWidth, height: menuHeight)
            hostingView.autoresizingMask = [.width, .height]
            overlayPanel.contentView?.addSubview(hostingView)
            
            overlayPanel.contentView?.wantsLayer = true
            overlayPanel.contentView?.layer?.cornerRadius = 18
            overlayPanel.contentView?.layer?.masksToBounds = true
            
            self.modernStartWindow = overlayPanel
            
            // 🎯 FIX: Use self as typed sender instead of uncontextual nil
            overlayPanel.orderFront(self)
            
            NSApp.activate(ignoringOtherApps: true)
            
            self.localClickMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
                guard let self = self, let activeMenuWindow = self.modernStartWindow else { return event }
                if event.windowNumber == activeMenuWindow.windowNumber || event.windowNumber == baseWindow.windowNumber {
                    return event
                }
                DispatchQueue.main.async { self.forceCloseStartMenuPopover() }
                return event
            }
            
            self.globalClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
                guard let self = self, let activeMenuWindow = self.modernStartWindow else { return }
                if event.windowNumber != activeMenuWindow.windowNumber && event.windowNumber != baseWindow.windowNumber {
                    DispatchQueue.main.async { self.forceCloseStartMenuPopover() }
                }
            }
        }
    @objc private func forceCloseStartMenuPopover() {
        lastDismissalTime = NSDate().timeIntervalSince1970
        if let monitor = localClickMonitor { NSEvent.removeMonitor(monitor); self.localClickMonitor = nil }
        if let monitor = globalClickMonitor { NSEvent.removeMonitor(monitor); self.globalClickMonitor = nil }
        
        if let activeWindow = modernStartWindow {
            // 🎯 THE FIX: Resign key status cleanly before walking away
            activeWindow.resignKey()
            activeWindow.orderOut(nil)
            self.modernStartWindow = nil
        }
    }
    
    private func enqueueSafeVisibilityEvaluation() {
        DispatchQueue.main.async { [weak self] in self?.evaluateFullScreenVisibilityState() }
    }
    
    private func evaluateFullScreenVisibilityState() {
        guard let baseWindow = self.window, let currentScreen = NSScreen.main else { return }
        
        var shouldHideForFullScreen = false
        
        if let frontmostApp = NSWorkspace.shared.frontmostApplication,
           frontmostApp.bundleIdentifier != Bundle.main.bundleIdentifier {
            
            let bundleID = frontmostApp.bundleIdentifier?.lowercased() ?? ""
            
            if bundleID.contains("screencapture") || bundleID.contains("controlcenter") || bundleID.contains("siri") {
                if baseWindow.alphaValue < 1.0 {
                    baseWindow.alphaValue = 1.0
                    baseWindow.ignoresMouseEvents = false
                    baseWindow.orderFrontRegardless()
                }
                return
            }
            
            var activeWindowElement: AXUIElement? = AeroBarSettings.shared.currentSystemFocusedElement
            
            if activeWindowElement == nil {
                let appRef = AXUIElementCreateApplication(frontmostApp.processIdentifier)
                var focusedWindowRef: CFTypeRef?
                if AXUIElementCopyAttributeValue(appRef, kAXFocusedWindowAttribute as CFString, &focusedWindowRef) == .success {
                    activeWindowElement = (focusedWindowRef as! AXUIElement)
                    
                    DispatchQueue.main.async {
                        AeroBarSettings.shared.currentSystemFocusedElement = activeWindowElement
                    }
                }
            }
            
            if let targetElement = activeWindowElement {
                var isFullScreenRef: CFTypeRef?
                if AXUIElementCopyAttributeValue(targetElement, "AXFullScreen" as CFString, &isFullScreenRef) == .success,
                   let isFullScreenValue = isFullScreenRef as? Bool {
                    if isFullScreenValue {
                        shouldHideForFullScreen = true
                    }
                }
                
                // 🎯 FIXED BOUNDING BOX CHECK: Exclude common browser bundles along with Finder
                // to prevent expanded solo browser windows from mimicking full-screen modes.
                let isBrowserOrShell = bundleID.contains("com.apple.finder") ||
                bundleID.contains("google.chrome") ||
                bundleID.contains("safari") ||
                bundleID.contains("company.thebrowser.arc") ||
                bundleID.contains("firefox") ||
                bundleID.contains("microsoft.edgemac")
                
                if !shouldHideForFullScreen && !isBrowserOrShell {
                    var sizeRef: CFTypeRef?
                    if AXUIElementCopyAttributeValue(targetElement, kAXSizeAttribute as CFString, &sizeRef) == .success {
                        var windowSize = CGSize.zero
                        if AXValueGetValue(sizeRef as! AXValue, .cgSize, &windowSize) {
                            let screenWidth = currentScreen.frame.size.width
                            let screenHeight = currentScreen.frame.size.height
                            
                            if abs(windowSize.width - screenWidth) < 15 && abs(windowSize.height - screenHeight) < 15 {
                                shouldHideForFullScreen = true
                            }
                        }
                    }
                }
            }
        }
        
        if shouldHideForFullScreen {
            if baseWindow.alphaValue > 0 {
                baseWindow.alphaValue = 0.0
                baseWindow.ignoresMouseEvents = true
            }
        } else {
            if baseWindow.alphaValue < 1.0 {
                baseWindow.alphaValue = 1.0
                baseWindow.ignoresMouseEvents = false
                baseWindow.orderFrontRegardless()
                self.recalibrateWindowGeometry()
            } else {
                baseWindow.orderFrontRegardless()
            }
        }
    }
    
    @objc private func presentOrbCustomizerPopover() {
        guard let panel = window as? AeroBarPanel, let viewModel = panel.contentView else { return }
        if appearancePopover.isShown { appearancePopover.performClose(nil); return }
        appearancePopover.contentViewController = NSHostingController(rootView: AeroBarAppearanceCustomizerView())
        appearancePopover.behavior = .transient
        appearancePopover.show(relativeTo: NSRect(x: 12, y: 0, width: 54, height: 54), of: viewModel, preferredEdge: .maxY)
    }
    
    private func startWindowArrangementDaemon(barHeightThreshold: CGFloat) {
        arrangementTimer?.invalidate()
        arrangementTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { [weak self] _ in
            guard let self = self, let baseWindow = self.window, baseWindow.isVisible else { return }
            var discoveredTabs: [WindowTab] = []
            let currentSettings = AeroBarSettings.shared

            // ═══════════════════════════════════════════════════════════
            // 🖱️ GLOBAL MOUSE-BUTTON GATE
            // ═══════════════════════════════════════════════════════════
            // If ANY mouse button is currently held down the user is
            // dragging or resizing a window right now. We must not touch
            // ANY window geometry during this time — doing so causes:
            //   • Drag resistance / sticky barrier between displays
            //   • Instant resize the moment a window crosses a display edge
            //   • Window-server jitter / cursor desync
            //
            // This single check is the most reliable drag-detection
            // available without AXUIElement polling per-window, and it
            // is evaluated once per timer tick for zero per-window cost.
            let isMouseButtonHeld = NSEvent.pressedMouseButtons != 0
            
            for app in NSWorkspace.shared.runningApplications where app.activationPolicy == .regular && app.bundleIdentifier != Bundle.main.bundleIdentifier {
                let appRef = AXUIElementCreateApplication(app.processIdentifier)
                var windowListRef: CFTypeRef?
                guard AXUIElementCopyAttributeValue(appRef, kAXWindowsAttribute as CFString, &windowListRef) == .success, let windows = windowListRef as? [AXUIElement] else { continue }
                
                for (idx, window) in windows.enumerated() {
                    var roleRef: CFTypeRef?, subroleRef: CFTypeRef?, titleRef: CFTypeRef?, minimizedRef: CFTypeRef?
                    AXUIElementCopyAttributeValue(window, kAXRoleAttribute as CFString, &roleRef)
                    AXUIElementCopyAttributeValue(window, kAXSubroleAttribute as CFString, &subroleRef)
                    AXUIElementCopyAttributeValue(window, kAXTitleAttribute as CFString, &titleRef)
                    AXUIElementCopyAttributeValue(window, kAXMinimizedAttribute as CFString, &minimizedRef)
                    if (roleRef as? String) != kAXWindowRole || (subroleRef as? String) == "AXUnknown" { continue }
                    
                    var windowIDRef: CFTypeRef?
                    var resolvedWindowID: CGWindowID = 0
                    
                    if AXUIElementCopyAttributeValue(window, "kAXWindowIDAttribute" as CFString, &windowIDRef) == .success,
                       let idNum = windowIDRef as? NSNumber {
                        resolvedWindowID = CGWindowID(idNum.uint32Value)
                    } else {
                        resolvedWindowID = CGWindowID(app.processIdentifier + Int32(idx))
                    }
                    
                    var positionRef: CFTypeRef?, sizeRef: CFTypeRef?
                    AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &positionRef)
                    AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &sizeRef)
                    var point = CGPoint.zero, size = CGSize.zero
                    if let posVal = positionRef as! AXValue?, let sizeVal = sizeRef as! AXValue? {
                        AXValueGetValue(posVal, .cgPoint, &point)
                        AXValueGetValue(sizeVal, .cgSize, &size)
                    }
                    
                    let displayTitle = (titleRef as? String)?.isEmpty == false ? (titleRef as? String)! : (app.localizedName ?? "Window")
                    
                    let newTab = WindowTab(
                        windowID: resolvedWindowID,
                        processID: app.processIdentifier,
                        appName: app.localizedName ?? "App",
                        windowTitle: displayTitle,
                        axElement: window,
                        appIcon: app.icon ?? NSWorkspace.shared.icon(for: UTType.application)
                    )
                    
                    if !discoveredTabs.contains(where: { $0.id == newTab.id }) { discoveredTabs.append(newTab) }
                    if (minimizedRef as? Bool ?? false) || size.width <= 0 || size.height <= 0 { continue }

                    // ── COORDINATE SYSTEM NOTE ─────────────────────────────────
                    // AX position (point.x / point.y): FLIPPED global space.
                    //   Origin = top-left of primary screen. Y grows DOWN.
                    // NSScreen.frame: COCOA global space.
                    //   Origin = bottom-left of primary screen. Y grows UP.
                    //
                    // We convert AX → Cocoa once, then use Cocoa everywhere.
                    let primaryH = NSScreen.screens[0].frame.height
                    // Cocoa Y of the window's TOP edge (higher value = higher on screen)
                    let cocoaTop    = primaryH - point.y
                    // Cocoa Y of the window's BOTTOM edge
                    let cocoaBottom = cocoaTop - size.height
                    // Full window rect in Cocoa space (matches NSScreen.frame space)
                    let cocoaRect = CGRect(x: point.x, y: cocoaBottom, width: size.width, height: size.height)

                    // ── MOTION / DRAG DETECTION ────────────────────────────────
                    // Track AX frame changes for the cooldown counter.
                    // But the PRIMARY drag gate is the mouse-button check above —
                    // frame-delta alone can miss micro-pauses mid-drag.
                    let axFrame = CGRect(x: point.x, y: point.y, width: size.width, height: size.height)
                    let lastAXFrame = self.previousWindowFrames[resolvedWindowID]
                    self.previousWindowFrames[resolvedWindowID] = axFrame

                    if isMouseButtonHeld || lastAXFrame != axFrame {
                        // User is actively dragging — reset cooldown, never resize
                        self.windowStillCycleCount[resolvedWindowID] = 0
                        continue
                    }

                    // ── POST-DROP SETTLING COOLDOWN ────────────────────────────
                    // After the mouse is released the window needs a few ticks to
                    // finish animating to its resting position before we measure it.
                    // This prevents a false resize on the very first stationary frame.
                    let stillCount = (self.windowStillCycleCount[resolvedWindowID] ?? 0) + 1
                    self.windowStillCycleCount[resolvedWindowID] = stillCount
                    guard stillCount >= self.requiredStillCyclesBeforeResize else { continue }

                    // ── WHICH SCREEN OWNS THIS WINDOW? ─────────────────────────
                    // Largest-area intersection, all in Cocoa space.
                    let windowHostingScreen = NSScreen.screens.max(by: { a, b in
                        let aA = a.frame.intersection(cocoaRect).width * a.frame.intersection(cocoaRect).height
                        let aB = b.frame.intersection(cocoaRect).width * b.frame.intersection(cocoaRect).height
                        return aA < aB
                    }) ?? NSScreen.main ?? NSScreen.screens[0]

                    let isPrimaryScreen = (windowHostingScreen == NSScreen.screens.first)
                    let targetMode = currentSettings.displayTargetMode

                    let isBarActiveOnThisScreen: Bool
                    switch targetMode {
                    case .all:           isBarActiveOnThisScreen = true
                    case .primaryOnly:   isBarActiveOnThisScreen = isPrimaryScreen
                    case .secondaryOnly: isBarActiveOnThisScreen = !isPrimaryScreen
                    }
                    guard isBarActiveOnThisScreen else { continue }

                    let screenFrame = windowHostingScreen.frame

                    // ── MAXIMIZATION / FULLSCREEN GUARD ───────────────────────
                    var subroleCheckRef: CFTypeRef?
                    if AXUIElementCopyAttributeValue(window, kAXSubroleAttribute as CFString, &subroleCheckRef) == .success,
                       (subroleCheckRef as? String) == "AXUnknown" { continue }

                    let isWidthMaximized  = abs(size.width  - screenFrame.size.width)  <= 24
                    let isHeightMaximized = abs(size.height - screenFrame.size.height) <= 75

                    var fullScreenRef: CFTypeRef?
                    var isNativelyFullScreen = false
                    if AXUIElementCopyAttributeValue(window, "AXFullScreen" as CFString, &fullScreenRef) == .success,
                       let fsBool = fullScreenRef as? Bool { isNativelyFullScreen = fsBool }

                    guard !(isWidthMaximized && isHeightMaximized) && !isNativelyFullScreen else { continue }

                    // ── BOTTOM FORBIDDEN ZONE ──────────────────────────────────
                    // The AeroBar taskbar occupies the bottom `barHeightThreshold`
                    // points of the hosting screen (in Cocoa space):
                    //   forbidden zone: screenFrame.minY  →  screenFrame.minY + barHeightThreshold
                    //
                    // If the window's bottom edge dips below that line, trim it.
                    let bottomForbiddenY = screenFrame.minY + barHeightThreshold
                    let bottomOverflow   = bottomForbiddenY - cocoaBottom   // > 0 means infringement

                    // ── TOP EDGE GUARD (NEW — fixes "title bar hidden behind display 1 taskbar") ──
                    // When a window is dragged from display 1 DOWN to display 2, its
                    // top edge can end up above screenFrame.maxY — i.e. still sitting
                    // inside display 1's taskbar area. The user can't grab the title
                    // bar to reposition it.
                    //
                    // The top of the hosting screen in Cocoa space is screenFrame.maxY.
                    // If the window's top edge exceeds that, we must push the window
                    // downward so its top lands just inside the screen.
                    // (We leave a 1-pt margin so the title bar is always grabbable.)
                    let topForbiddenY  = screenFrame.maxY          // Cocoa top of this screen
                    let topOverflow    = cocoaTop - topForbiddenY  // > 0 means title bar is above the screen

                    let needsBottomFix = bottomOverflow > 0
                    let needsTopFix    = topOverflow > 0

                    guard needsBottomFix || needsTopFix else { continue }

                    // Start from current values and apply whichever corrections are needed.
                    var newHeight  = size.height
                    var newAXOriginY = point.y   // AX Y of top-left (flipped, grows down)

                    if needsTopFix {
                        // Push the window DOWN in AX space (increase point.y) so its
                        // top edge lands exactly at the screen's top boundary.
                        // In AX space: higher point.y = lower on screen.
                        // cocoaTop - topForbiddenY = topOverflow → add that to point.y.
                        newAXOriginY = point.y + topOverflow

                        // The window moved down, so its effective cocoaBottom also moved
                        // down by the same amount. Recompute for the bottom check below.
                        let newCocoaBottom = cocoaBottom - topOverflow
                        let newBottomOverflow = bottomForbiddenY - newCocoaBottom
                        if newBottomOverflow > 0 {
                            // After the position shift the window is still too tall — trim height too.
                            newHeight = size.height - newBottomOverflow
                        }
                    } else if needsBottomFix {
                        // Only the bottom needs trimming — don't move the window, just shrink it.
                        newHeight = size.height - bottomOverflow
                    }

                    // Write position first (if changed), then size.
                    if newAXOriginY != point.y {
                        var newOrigin = CGPoint(x: point.x, y: newAXOriginY)
                        if let posValue = AXValueCreate(.cgPoint, &newOrigin) {
                            AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, posValue)
                        }
                    }
                    if newHeight != size.height && newHeight > 50 {
                        var finalSize = CGSize(width: size.width, height: newHeight)
                        if let sizeValue = AXValueCreate(.cgSize, &finalSize) {
                            AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, sizeValue)
                        }
                    }
                }
            }
            
            if let frontmostApp = NSWorkspace.shared.frontmostApplication {
                let activeAppRef = AXUIElementCreateApplication(frontmostApp.processIdentifier)
                var liveFocusedWindowRef: CFTypeRef?
                
                if AXUIElementCopyAttributeValue(activeAppRef, kAXFocusedWindowAttribute as CFString, &liveFocusedWindowRef) == .success {
                    if let freshFocusedElement = liveFocusedWindowRef as! AXUIElement? {
                        DispatchQueue.main.async {
                            if currentSettings.currentSystemFocusedElement == nil || !CFEqual(currentSettings.currentSystemFocusedElement!, freshFocusedElement) {
                                currentSettings.currentSystemFocusedElement = freshFocusedElement
                            }
                        }
                    }
                }
            }
            
            DispatchQueue.main.async {
                if currentSettings.activeTabs != discoveredTabs {
                    currentSettings.activeTabs = discoveredTabs
                }
            }
        }
    }
}
