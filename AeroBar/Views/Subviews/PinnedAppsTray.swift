import SwiftUI
import AppKit

struct PinnedAppsTray: View {
    @ObservedObject var settings = AeroBarSettings.shared
    @Binding var draggedPinnedItem: PinnedApp?
    let onLaunch: (String) -> Void
    let onUnpin: (String) -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(settings.pinnedBarApps) { app in
                Button(action: {
                    onLaunch(app.bundleIdentifier)
                }) {
                    Image(nsImage: app.appIcon)
                        .resizable()
                        .frame(width: 24, height: 24)
                        .contextMenu {
                            // 🛠️ Action 1: Force New Window (on the display where the context menu was triggered)
                            Button {
                                let mouseLocation = NSEvent.mouseLocation
                                let targetScreen = NSScreen.screens.first { $0.frame.contains(mouseLocation) } ?? NSScreen.main ?? NSScreen.screens[0]
                                let bundleID = app.bundleIdentifier
                                // Snapshot existing window AXUIElements (not just a count) so the new
                                // window can be identified by diffing afterwards — robust to AX list
                                // ordering, which is NOT reliably "newest first" for every app (Chrome
                                // included). A count/index-based guess can silently grab the wrong window.
                                var preLaunchWindows: [AXUIElement] = []
                                if let running = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == bundleID }) {
                                    let aRef = AXUIElementCreateApplication(running.processIdentifier)
                                    var wRef: CFTypeRef?
                                    if AXUIElementCopyAttributeValue(aRef, kAXWindowsAttribute as CFString, &wRef) == .success,
                                       let wins = wRef as? [AXUIElement] { preLaunchWindows = wins }
                                }
                                if bundleID == "com.apple.finder" {
                                    let config = NSWorkspace.OpenConfiguration()
                                    NSWorkspace.shared.open(URL(fileURLWithPath: NSHomeDirectory()), configuration: config) { _, _ in
                                        PinnedAppsTray.moveAndResizeNewWindow(to: targetScreen, bundleIdentifier: bundleID, existingWindows: preLaunchWindows)
                                    }
                                } else if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
                                    let config = NSWorkspace.OpenConfiguration()
                                    config.createsNewApplicationInstance = true
                                    if bundleID == "com.google.Chrome" || bundleID == "com.microsoft.edgemac" {
                                        config.arguments = ["--new-window"]
                                    } else if bundleID == "org.mozilla.firefox" {
                                        config.arguments = ["-new-window"]
                                    }
                                    NSWorkspace.shared.openApplication(at: appURL, configuration: config) { _, _ in
                                        // Deliberately ignore the `runningApp` passed here: for single-instance
                                        // apps (Chrome/Edge/Firefox) this can be a short-lived launch-helper
                                        // process that just forwards "--new-window" via Apple Events to the
                                        // already-running app and then exits. Using its pid means AX queries
                                        // target a dead process and silently never find the new window — which
                                        // is exactly why the new window was being left on the main display.
                                        // We re-resolve the real, long-lived process by bundle ID instead.
                                        PinnedAppsTray.moveAndResizeNewWindow(to: targetScreen, bundleIdentifier: bundleID, existingWindows: preLaunchWindows)
                                    }
                                }
                            } label: {
                                Label("Open New Window", systemImage: "macwindow.badge.plus")
                            }
                            
                            // 🕶️ Action 2: Incognito / Private Session
                            if app.bundleIdentifier != "com.apple.finder" && (app.bundleIdentifier == "com.google.Chrome" || app.bundleIdentifier == "com.apple.Safari" || app.bundleIdentifier == "com.microsoft.edgemac") {
                                Button {
                                    if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: app.bundleIdentifier) {
                                        let config = NSWorkspace.OpenConfiguration()
                                        config.createsNewApplicationInstance = true
                                        
                                        if app.bundleIdentifier == "com.google.Chrome" || app.bundleIdentifier == "com.microsoft.edgemac" {
                                            config.arguments = ["--incognito"]
                                        } else if app.bundleIdentifier == "com.apple.Safari" {
                                            config.arguments = ["-private"]
                                        }
                                        NSWorkspace.shared.openApplication(at: appURL, configuration: config, completionHandler: nil)
                                    }
                                } label: {
                                    Label("Open New Private Window", systemImage: "eyeglasses")
                                }
                            }
                            
                            // 📌 Unpin and Close Actions
                            Divider()
                            
                            if app.bundleIdentifier != "com.apple.finder" {
                                Button(role: .destructive) {
                                    onUnpin(app.bundleIdentifier)
                                } label: {
                                    Label("Unpin from Taskbar", systemImage: "pin.slash")
                                }
                            }
                            
                            if let runningInstance = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == app.bundleIdentifier }),
                               app.bundleIdentifier != "com.apple.finder" {
                                Button {
                                    runningInstance.terminate()
                                } label: {
                                    Label("Close App", systemImage: "minus.circle")
                                }
                            }
                        }
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }

    // Keeps per-launch placement state alive for the duration of the AX observation. The AX
    // callback only carries an *unretained* pointer (see AXObserverAddNotification's refcon),
    // so something else must hold a strong reference or this would be freed before the
    // notification ever fires.
    private static var pendingWindowPlacements: [ObjectIdentifier: PinnedAppNewWindowPlacementContext] = [:]

    // Kept alive the same way, for the post-placement settle guard (see `installSettleGuard`).
    private static var activeSettleGuards: [ObjectIdentifier: SettleGuardContext] = [:]

    /// Finds and places the newly opened window on `screen`.
    ///
    /// Primary path: watches for `kAXWindowCreatedNotification` on the app and positions the
    /// window the instant it's created — before the user ever sees it at its default frame.
    /// This is what actually fixes the "shows up on main display / at full size, THEN jumps /
    /// shrinks" flash: the previous approach only ever acted after a fixed delay, by which point
    /// the window had already been shown to the user at the wrong place and size.
    ///
    /// Fallback path: if the app isn't resolvable yet (cold launch — no pid to attach an
    /// observer to) or the notification doesn't fire within 3s for some reason, falls back to
    /// the old diff-and-poll approach. Slower and still has a small visible jump, but keeps
    /// things working rather than stranding the window.
    static func moveAndResizeNewWindow(to screen: NSScreen, bundleIdentifier: String, existingWindows: [AXUIElement]) {
        guard let running = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == bundleIdentifier }) else {
            pollForNewWindow(screen: screen, bundleIdentifier: bundleIdentifier, existingWindows: existingWindows)
            return
        }
        attachCreationObserver(screen: screen, bundleIdentifier: bundleIdentifier, existingWindows: existingWindows, pid: running.processIdentifier)
    }

    private static func attachCreationObserver(screen: NSScreen, bundleIdentifier: String, existingWindows: [AXUIElement], pid: pid_t) {
        let appRef = AXUIElementCreateApplication(pid)
        let context = PinnedAppNewWindowPlacementContext(screen: screen, bundleIdentifier: bundleIdentifier, existingWindows: existingWindows, pid: pid, appRef: appRef)
        let key = ObjectIdentifier(context)
        pendingWindowPlacements[key] = context

        var observerRef: AXObserver?
        let createStatus = AXObserverCreate(pid, { (_, element, notification, refCon) in
            guard let refCon = refCon else { return }
            let ctx = Unmanaged<PinnedAppNewWindowPlacementContext>.fromOpaque(refCon).takeUnretainedValue()
            guard notification as String == kAXWindowCreatedNotification else { return }
            // Defensive: kAXWindowCreatedNotification should only fire for genuinely new
            // windows, but skip it anyway if it somehow matches something we already had.
            guard !ctx.existingWindows.contains(where: { CFEqual($0, element) }) else { return }
            DispatchQueue.main.async {
                PinnedAppsTray.finishPlacement(context: ctx, window: element)
            }
        }, &observerRef)

        guard createStatus == .success, let observer = observerRef else {
            pendingWindowPlacements.removeValue(forKey: key)
            pollForNewWindow(screen: screen, bundleIdentifier: bundleIdentifier, existingWindows: existingWindows)
            return
        }
        context.observer = observer

        let contextPointer = Unmanaged.passUnretained(context).toOpaque()
        _ = AXObserverAddNotification(observer, appRef, kAXWindowCreatedNotification as CFString, contextPointer)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), AXObserverGetRunLoopSource(observer), .commonModes)

        // Safety net — don't strand the window forever if the notification never arrives.
        let timeoutItem = DispatchWorkItem {
            guard pendingWindowPlacements[key] != nil else { return } // already handled
            detachObserver(context: context)
            pendingWindowPlacements.removeValue(forKey: key)
            pollForNewWindow(screen: screen, bundleIdentifier: bundleIdentifier, existingWindows: existingWindows)
        }
        context.timeoutWorkItem = timeoutItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0, execute: timeoutItem)
    }

    private static func finishPlacement(context: PinnedAppNewWindowPlacementContext, window: AXUIElement) {
        let key = ObjectIdentifier(context)
        guard pendingWindowPlacements[key] != nil else { return } // timeout already fired first
        context.timeoutWorkItem?.cancel()
        detachObserver(context: context)
        pendingWindowPlacements.removeValue(forKey: key)
        if let running = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == context.bundleIdentifier }) {
            running.activate()
        }
        place(window, on: context.screen, appRef: context.appRef, pid: context.pid)
    }

    private static func detachObserver(context: PinnedAppNewWindowPlacementContext) {
        guard let observer = context.observer else { return }
        AXObserverRemoveNotification(observer, context.appRef, kAXWindowCreatedNotification as CFString)
        CFRunLoopRemoveSource(CFRunLoopGetCurrent(), AXObserverGetRunLoopSource(observer), .commonModes)
    }

    /// Computes the clamped target frame (AX coordinate space) for a window placed on `screen`.
    private static func clampedTargetFrame(for screen: NSScreen) -> (origin: CGPoint, size: CGSize) {
        let primaryH = NSScreen.screens[0].frame.height
        let targetW = min(screen.frame.width * 0.85, 1400)
        let targetH = min(screen.frame.height * 0.80, screen.frame.height - 56 - 60)
        let cocoaX = screen.frame.minX + (screen.frame.width - targetW) / 2
        let cocoaY = screen.frame.minY + 56 + 30  // above aerobar
        let axY = primaryH - cocoaY - targetH
        return (CGPoint(x: cocoaX, y: max(0, axY)), CGSize(width: targetW, height: targetH))
    }

    /// Sets position + size to the clamped target, then installs a short-lived settle guard
    /// (see below) instead of blindly polling on a fixed interval. Some apps (Chrome notably,
    /// and other Chromium/Electron apps generally) re-assert their own remembered bounds a beat
    /// after creation, silently undoing a single AX write.
    private static func place(_ win: AXUIElement, on screen: NSScreen, appRef: AXUIElement, pid: pid_t) {
        let (origin, size) = clampedTargetFrame(for: screen)
        var writeOrigin = origin
        var writeSize = size
        if let pv = AXValueCreate(.cgPoint, &writeOrigin) { AXUIElementSetAttributeValue(win, kAXPositionAttribute as CFString, pv) }
        if let sv = AXValueCreate(.cgSize, &writeSize) { AXUIElementSetAttributeValue(win, kAXSizeAttribute as CFString, sv) }
        AXUIElementPerformAction(win, kAXRaiseAction as CFString)
        installSettleGuard(on: win, appRef: appRef, pid: pid, targetOrigin: origin, targetSize: size)
    }

    // =======================================================
    // 🎯 SETTLE GUARD
    // =======================================================
    // 🎯 THE FLICKER FIX: the old approach re-checked position only, on a fixed 0.15s timer, for
    // up to 4 attempts — so if an app reasserted its own bounds, the wrong frame could sit
    // visibly on screen for up to 150ms before we even looked, and a size-only reassertion
    // (no position change) was never caught at all. Watching the AX move/resize notifications
    // instead reacts the instant the app's own write happens — the correction lands before the
    // next paint in practice, so there's nothing to see. We watch for ~4s, comfortably covering
    // the "beat after creation" Chrome/Electron apps are prone to. If the user starts actually
    // dragging or resizing during that window (mouse button down), that's a deliberate action,
    // not the app reasserting itself — we back off for good rather than fighting them.
    private static func installSettleGuard(on window: AXUIElement, appRef: AXUIElement, pid: pid_t, targetOrigin: CGPoint, targetSize: CGSize) {
        let context = SettleGuardContext(window: window, appRef: appRef, targetOrigin: targetOrigin, targetSize: targetSize)
        let key = ObjectIdentifier(context)
        activeSettleGuards[key] = context

        var observerRef: AXObserver?
        let status = AXObserverCreate(pid, { (_, element, _, refCon) in
            guard let refCon = refCon else { return }
            let ctx = Unmanaged<SettleGuardContext>.fromOpaque(refCon).takeUnretainedValue()
            guard CFEqual(element, ctx.window) else { return }
            DispatchQueue.main.async { PinnedAppsTray.handleSettleGuardNotification(context: ctx) }
        }, &observerRef)

        guard status == .success, let observer = observerRef else {
            activeSettleGuards.removeValue(forKey: key)
            return
        }
        context.observer = observer
        let ptr = Unmanaged.passUnretained(context).toOpaque()
        _ = AXObserverAddNotification(observer, appRef, kAXMovedNotification as CFString, ptr)
        _ = AXObserverAddNotification(observer, appRef, kAXResizedNotification as CFString, ptr)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), AXObserverGetRunLoopSource(observer), .commonModes)

        let timeout = DispatchWorkItem {
            guard activeSettleGuards[key] != nil else { return }
            teardownSettleGuard(context: context)
            activeSettleGuards.removeValue(forKey: key)
        }
        context.timeoutWorkItem = timeout
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0, execute: timeout)
    }

    private static func handleSettleGuardNotification(context: SettleGuardContext) {
        let key = ObjectIdentifier(context)
        guard activeSettleGuards[key] != nil, !context.isWriting else { return }

        if NSEvent.pressedMouseButtons != 0 {
            teardownSettleGuard(context: context)
            activeSettleGuards.removeValue(forKey: key)
            return
        }

        var posRef: CFTypeRef?, sizeRef: CFTypeRef?
        AXUIElementCopyAttributeValue(context.window, kAXPositionAttribute as CFString, &posRef)
        AXUIElementCopyAttributeValue(context.window, kAXSizeAttribute as CFString, &sizeRef)
        var actualOrigin = CGPoint.zero, actualSize = CGSize.zero
        if let pv = posRef as! AXValue? { AXValueGetValue(pv, .cgPoint, &actualOrigin) }
        if let sv = sizeRef as! AXValue? { AXValueGetValue(sv, .cgSize, &actualSize) }

        let drifted = abs(actualOrigin.x - context.targetOrigin.x) > 4 || abs(actualOrigin.y - context.targetOrigin.y) > 4
                   || abs(actualSize.width - context.targetSize.width) > 4 || abs(actualSize.height - context.targetSize.height) > 4
        guard drifted else { return }

        context.isWriting = true
        var origin = context.targetOrigin
        var size = context.targetSize
        if let pv = AXValueCreate(.cgPoint, &origin) { AXUIElementSetAttributeValue(context.window, kAXPositionAttribute as CFString, pv) }
        if let sv = AXValueCreate(.cgSize, &size) { AXUIElementSetAttributeValue(context.window, kAXSizeAttribute as CFString, sv) }
        AXUIElementPerformAction(context.window, kAXRaiseAction as CFString)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { context.isWriting = false }
    }

    private static func teardownSettleGuard(context: SettleGuardContext) {
        context.timeoutWorkItem?.cancel()
        guard let observer = context.observer else { return }
        AXObserverRemoveNotification(observer, context.appRef, kAXMovedNotification as CFString)
        AXObserverRemoveNotification(observer, context.appRef, kAXResizedNotification as CFString)
        CFRunLoopRemoveSource(CFRunLoopGetCurrent(), AXObserverGetRunLoopSource(observer), .commonModes)
    }

    /// Legacy fallback: diff window refs (not counts/order) via polling. Only used when the
    /// fast observer-based path above couldn't be used or timed out.
    private static func pollForNewWindow(screen: NSScreen, bundleIdentifier: String, existingWindows: [AXUIElement]) {
        var findAttempts = 0
        func isNewWindow(_ win: AXUIElement) -> Bool {
            !existingWindows.contains { CFEqual($0, win) }
        }
        func attempt() {
            guard let running = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == bundleIdentifier }) else {
                if findAttempts < 20 { findAttempts += 1; DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { attempt() } }
                return
            }
            let appRef = AXUIElementCreateApplication(running.processIdentifier)
            var ref: CFTypeRef?
            guard AXUIElementCopyAttributeValue(appRef, kAXWindowsAttribute as CFString, &ref) == .success,
                  let wins = ref as? [AXUIElement],
                  let newWin = wins.first(where: isNewWindow) else {
                if findAttempts < 20 { findAttempts += 1; DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { attempt() } }
                return
            }
            running.activate()
            place(newWin, on: screen, appRef: appRef, pid: running.processIdentifier)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { attempt() }
    }
}

/// Per-launch state for `PinnedAppsTray`'s window-creation observer. Kept alive externally via
/// `pendingWindowPlacements` since the AX callback only receives an unretained pointer.
private final class PinnedAppNewWindowPlacementContext {
    let screen: NSScreen
    let bundleIdentifier: String
    let existingWindows: [AXUIElement]
    let pid: pid_t
    let appRef: AXUIElement
    var observer: AXObserver?
    var timeoutWorkItem: DispatchWorkItem?

    init(screen: NSScreen, bundleIdentifier: String, existingWindows: [AXUIElement], pid: pid_t, appRef: AXUIElement) {
        self.screen = screen
        self.bundleIdentifier = bundleIdentifier
        self.existingWindows = existingWindows
        self.pid = pid
        self.appRef = appRef
    }
}

/// Per-placement state for `PinnedAppsTray`'s settle guard. Kept alive externally via
/// `activeSettleGuards` since the AX callback only receives an unretained pointer.
private final class SettleGuardContext {
    let window: AXUIElement
    let appRef: AXUIElement
    let targetOrigin: CGPoint
    let targetSize: CGSize
    var observer: AXObserver?
    var isWriting = false
    var timeoutWorkItem: DispatchWorkItem?

    init(window: AXUIElement, appRef: AXUIElement, targetOrigin: CGPoint, targetSize: CGSize) {
        self.window = window
        self.appRef = appRef
        self.targetOrigin = targetOrigin
        self.targetSize = targetSize
    }
}
