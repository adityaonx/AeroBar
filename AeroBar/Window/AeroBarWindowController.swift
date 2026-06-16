import AppKit
import SwiftUI
import UniformTypeIdentifiers
import Combine
import ServiceManagement

// =======================================================
// 🖥️ DECOUPLED PANEL ARCHITECTURE
// =======================================================

final class AeroBarPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
    
    // 🎯 THE DEFINITIVE CAPSLOCK GHOST-CLICK FIX:
    // By overriding the native AppKit event router, we intercept standalone modifier
    // key presses (like CapsLock) at the root window level and destroy them.
    // SwiftUI never even knows the key was pressed.
    // (Note: This does not break Cmd+Click, because mouse clicks carry their own modifier payloads!)
    override func sendEvent(_ event: NSEvent) {
        if event.type == .flagsChanged {
            return // Silently drop the event
        }
        super.sendEvent(event)
    }
}
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
                    if let controllerPointer = refCon {
                        let myController = Unmanaged<AeroBarWindowController>.fromOpaque(controllerPointer).takeUnretainedValue()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                            myController.startWindowArrangementDaemon(barHeightThreshold: AeroBarSettings.shared.barHeight)
                        }
                    }
                }
            }
        }, &observerRef)
        
        guard createStatus == .success, let observer = observerRef else { return }
        
        let appRef = AXUIElementCreateApplication(pid)
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
        secondaryAeroPanels.forEach { $0.orderOut(nil); $0.contentView?.subviews.forEach { $0.removeFromSuperview() } }
        secondaryAeroPanels.removeAll()
        
        let screens = NSScreen.screens
        guard !screens.isEmpty else { return }
        
        guard let primaryPanel = window as? AeroBarPanel else { return }
        let currentMode = AeroBarSettings.shared.displayTargetMode
        
        DispatchQueue.main.async {
            let primaryScreen = screens[0]
            let primaryExpectedFrame = NSRect(x: primaryScreen.frame.minX, y: primaryScreen.frame.minY, width: primaryScreen.frame.width, height: 56)
            
            if currentMode == .all || currentMode == .primaryOnly {
                if primaryPanel.frame != primaryExpectedFrame {
                    primaryPanel.setFrame(primaryExpectedFrame, display: true, animate: false)
                }
                primaryPanel.orderFront(nil)
            } else {
                primaryPanel.orderOut(nil)
            }
            
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
        displayObserver = NotificationCenter.default.addObserver(forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main) { [weak self] _ in
            self?.recalibrateWindowGeometry()
        }
        spaceChangeObserver = NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.activeSpaceDidChangeNotification, object: nil, queue: .main) { [weak self] _ in
            self?.evaluateFullScreenVisibilityState()
        }
        appActivateObserver = NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.didActivateApplicationNotification, object: nil, queue: .main) { [weak self] notification in
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
        
        _ = NotificationCenter.default.addObserver(forName: Notification.Name("triggerAeroStartMenu"), object: nil, queue: .main) { [weak self] notification in
            self?.toggleModernStartMenuPopover(notification)
        }
        _ = NotificationCenter.default.addObserver(forName: Notification.Name("dismissStartMenuWindow"), object: nil, queue: .main) { [weak self] _ in
            self?.forceCloseStartMenuPopover()
        }
        _ = NotificationCenter.default.addObserver(forName: Notification.Name("AeroBarMultiDisplayChanged"), object: nil, queue: .main) { [weak self] _ in
            self?.recalibrateWindowGeometry()
        }
    }
    
    // 🎯 THE FIX: Issue 1, 4, and 5 - Target Topologies and Smart Child Monitor Gateways
    @objc private func toggleModernStartMenuPopover(_ notification: Notification) {
        if let existingWindow = modernStartWindow, existingWindow.isVisible {
            forceCloseStartMenuPopover()
            return
        }
        
        if NSDate().timeIntervalSince1970 - lastDismissalTime < 0.25 { return }
        
        guard let baseWindow = window as? AeroBarPanel else { return }
        
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
        overlayPanel.backgroundColor = NSColor.clear
        overlayPanel.hasShadow = true
        overlayPanel.ignoresMouseEvents = false
        
        overlayPanel.setFrame(startMenuRect, display: true, animate: false)
        overlayPanel.level = NSWindow.Level(Int(CGWindowLevelForKey(.dockWindow)) + 3)
        
        // 🎯 BUG 4 FIX: Dropped .canJoinAllSpaces so macOS respects explicit target space routing
        overlayPanel.collectionBehavior = [
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
        
        // 🎯 BUG 4 FIX: Inheriting target workspaces correctly via AppKit layout hierarchy instead of active OS space overrides
        if targetScreen != NSScreen.screens.first,
           let matchingSecondary = secondaryAeroPanels.first(where: { $0.frame.origin.x == targetScreen.frame.origin.x }) {
            matchingSecondary.addChildWindow(overlayPanel, ordered: .above)
            overlayPanel.makeKeyAndOrderFront(nil)
        } else {
            overlayPanel.makeKeyAndOrderFront(nil)
        }
        
        // 🎯 BUG 1 & 5 FIX: Whitelisting nested Settings Popovers inherently built off the primary layout
        self.localClickMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self = self, let activeMenuWindow = self.modernStartWindow else { return event }
            
            let isInsideMenu = event.windowNumber == activeMenuWindow.windowNumber
            let isInsideBase = event.windowNumber == baseWindow.windowNumber
            let isChildOfMenu = activeMenuWindow.childWindows?.contains(where: { $0.windowNumber == event.windowNumber }) ?? false
            let isSecondaryPanel = self.secondaryAeroPanels.contains(where: { $0.windowNumber == event.windowNumber })

            if isInsideMenu || isInsideBase || isChildOfMenu || isSecondaryPanel {
                return event
            }
            
            DispatchQueue.main.async { self.forceCloseStartMenuPopover() }
            return event
        }
        
        self.globalClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self = self, let activeMenuWindow = self.modernStartWindow else { return }
            
            let isInsideMenu = event.windowNumber == activeMenuWindow.windowNumber
            let isInsideBase = event.windowNumber == baseWindow.windowNumber
            let isChildOfMenu = activeMenuWindow.childWindows?.contains(where: { $0.windowNumber == event.windowNumber }) ?? false
            let isSecondaryPanel = self.secondaryAeroPanels.contains(where: { $0.windowNumber == event.windowNumber })

            if !isInsideMenu && !isInsideBase && !isChildOfMenu && !isSecondaryPanel {
                DispatchQueue.main.async { self.forceCloseStartMenuPopover() }
            }
        }
    }
    
    @objc private func forceCloseStartMenuPopover() {
        lastDismissalTime = NSDate().timeIntervalSince1970
        if let monitor = localClickMonitor { NSEvent.removeMonitor(monitor); self.localClickMonitor = nil }
        if let monitor = globalClickMonitor { NSEvent.removeMonitor(monitor); self.globalClickMonitor = nil }
        
        if let activeWindow = modernStartWindow {
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
                    DispatchQueue.main.async { AeroBarSettings.shared.currentSystemFocusedElement = activeWindowElement }
                }
            }
            
            if let targetElement = activeWindowElement {
                var isFullScreenRef: CFTypeRef?
                if AXUIElementCopyAttributeValue(targetElement, "AXFullScreen" as CFString, &isFullScreenRef) == .success,
                   let isFullScreenValue = isFullScreenRef as? Bool {
                    if isFullScreenValue { shouldHideForFullScreen = true }
                }
                
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
    
    private func startWindowArrangementDaemon(barHeightThreshold: CGFloat) {
        arrangementTimer?.invalidate()
        arrangementTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { [weak self] _ in
            guard let self = self, let baseWindow = self.window, baseWindow.isVisible else { return }
            var discoveredTabs: [WindowTab] = []
            let currentSettings = AeroBarSettings.shared

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
                                        
                                        let isMinimized = minimizedRef as? Bool ?? false
                                        
                                        // 🎯 THE CAPSLOCK GHOST-TAB FIX:
                                        // macOS Sonoma injects the inline CapsLock indicator as a tiny physical window into Chromium apps.
                                        // We MUST filter out these micro-windows (less than 80x80) BEFORE they get appended to the active tabs list.
                                        if !isMinimized && (size.width < 80 || size.height < 80) { continue }
                                        
                                        if !discoveredTabs.contains(where: { $0.id == newTab.id }) { discoveredTabs.append(newTab) }
                                        if isMinimized { continue }

                    let primaryH = NSScreen.screens[0].frame.height
                    let cocoaTop    = primaryH - point.y
                    let cocoaBottom = cocoaTop - size.height
                    let cocoaRect = CGRect(x: point.x, y: cocoaBottom, width: size.width, height: size.height)

                    let axFrame = CGRect(x: point.x, y: point.y, width: size.width, height: size.height)
                    let lastAXFrame = self.previousWindowFrames[resolvedWindowID]
                    self.previousWindowFrames[resolvedWindowID] = axFrame

                    if isMouseButtonHeld || lastAXFrame != axFrame {
                        self.windowStillCycleCount[resolvedWindowID] = 0
                        continue
                    }

                    let stillCount = (self.windowStillCycleCount[resolvedWindowID] ?? 0) + 1
                    self.windowStillCycleCount[resolvedWindowID] = stillCount
                    guard stillCount >= self.requiredStillCyclesBeforeResize else { continue }

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

                    let bottomForbiddenY = screenFrame.minY + barHeightThreshold
                    let bottomOverflow   = bottomForbiddenY - cocoaBottom

                    let topForbiddenY  = screenFrame.maxY
                    let topOverflow    = cocoaTop - topForbiddenY

                    let needsBottomFix = bottomOverflow > 0
                    let needsTopFix    = topOverflow > 0

                    guard needsBottomFix || needsTopFix else { continue }

                    var newHeight  = size.height
                    var newAXOriginY = point.y

                    if needsTopFix {
                        newAXOriginY = point.y + topOverflow
                        let newCocoaBottom = cocoaBottom - topOverflow
                        let newBottomOverflow = bottomForbiddenY - newCocoaBottom
                        if newBottomOverflow > 0 {
                            newHeight = size.height - newBottomOverflow
                        }
                    } else if needsBottomFix {
                        newHeight = size.height - bottomOverflow
                    }

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
