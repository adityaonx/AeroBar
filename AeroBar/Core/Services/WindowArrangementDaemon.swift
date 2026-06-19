// WindowArrangementDaemon.swift — 30ms polling loop that clamps windows above the bar.
// Owner: Core/Services
// Depends on: AppKit, AccessibilityService
//
// KEY DESIGN:
//   clampedFrame(axOrigin:axSize:screen:barHeight:) is a PURE STATIC FUNCTION — no AppKit
//   side-effects, fully unit-testable without a running app or display.
//   The timer loop calls it and then applies the result via AX writes.
//
// JITTER GUARDS:
//   isPerformingManagedResize — set before any AX write, cleared after 350ms.
//   windowStillCycleCount     — window must be still for 3 consecutive ticks (~90ms)
//                               before a resize is attempted.

import AppKit
import UniformTypeIdentifiers

final class WindowArrangementDaemon {
    static let shared = WindowArrangementDaemon()
    private init() {}

    // Exposed so ZoomInterceptService and AeroBarWindowController can flip these flags.
    var isPerformingManagedResize = false
    var isSuppressingFocusUpdates = false

    private var timer: Timer?
    private var previousFrames: [CGWindowID: CGRect] = [:]
    private var stillCounts:    [CGWindowID: Int]    = [:]
    private let requiredStillCycles = 3   // ~90ms settle time before applying a correction

    // MARK: - Lifecycle

    func start(barHeight: CGFloat) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { [weak self] _ in
            self?.tick(barHeight: barHeight)
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    // Called by AccessibilityService when kAXResizedNotification / kAXMovedNotification fires.
    // Restarts the timer so the daemon re-evaluates sooner than the next scheduled tick.
    func nudge() {
        start(barHeight: AeroBarSettings.shared.barHeight)
    }

    // MARK: - Pure clamping (no side-effects — safe to unit test)

    /// Returns corrected AX-space origin and size for a window that overlaps the bar,
    /// or nil if no correction is needed. All coordinates are in AX space (top-left origin).
    static func clampedFrame(
        axOrigin: CGPoint,
        axSize: CGSize,
        screen: NSScreen,
        barHeight: CGFloat
    ) -> (origin: CGPoint, size: CGSize)? {
        let primaryH = NSScreen.screens[0].frame.height

        let cocoaTop    = primaryH - axOrigin.y
        let cocoaBottom = cocoaTop - axSize.height

        let bottomBoundary = screen.frame.minY + barHeight - 0  // 41pt at default 56pt bar
        let bottomOverflow = bottomBoundary - cocoaBottom
        let topOverflow    = cocoaTop - screen.frame.maxY

        guard bottomOverflow > 0 || topOverflow > 0 else { return nil }

        var newHeight    = axSize.height
        var newAXOriginY = axOrigin.y

        if topOverflow > 0 {
            newAXOriginY = axOrigin.y + topOverflow
            let newCocoaBottom = cocoaBottom - topOverflow
            let newBottomOverflow = bottomBoundary - newCocoaBottom
            if newBottomOverflow > 0 { newHeight = axSize.height - newBottomOverflow }
        } else {
            newHeight = axSize.height - bottomOverflow
        }

        return (CGPoint(x: axOrigin.x, y: newAXOriginY), CGSize(width: axSize.width, height: newHeight))
    }

    // MARK: - Timer tick

    private func tick(barHeight: CGFloat) {
        guard let baseWindow = NSApp.windows.first(where: { $0 is AeroBarPanel }),
              baseWindow.isVisible else { return }

        var discoveredTabs: [WindowTab] = []
        let settings = AeroBarSettings.shared
        let mouseHeld = NSEvent.pressedMouseButtons != 0

        for app in NSWorkspace.shared.runningApplications
            where app.activationPolicy == .regular
               && app.bundleIdentifier != Bundle.main.bundleIdentifier
        {
            let appRef = AXUIElementCreateApplication(app.processIdentifier)
            var listRef: CFTypeRef?
            guard AXUIElementCopyAttributeValue(appRef, kAXWindowsAttribute as CFString, &listRef) == .success,
                  let windows = listRef as? [AXUIElement]
            else { continue }

            for (idx, window) in windows.enumerated() {
                var roleRef: CFTypeRef?, subroleRef: CFTypeRef?, titleRef: CFTypeRef?, minRef: CFTypeRef?
                AXUIElementCopyAttributeValue(window, kAXRoleAttribute as CFString, &roleRef)
                AXUIElementCopyAttributeValue(window, kAXSubroleAttribute as CFString, &subroleRef)
                AXUIElementCopyAttributeValue(window, kAXTitleAttribute as CFString, &titleRef)
                AXUIElementCopyAttributeValue(window, kAXMinimizedAttribute as CFString, &minRef)

                guard (roleRef as? String) == kAXWindowRole,
                      (subroleRef as? String) != "AXUnknown"
                else { continue }

                let windowID  = resolvedWindowID(window: window, app: app, idx: idx)
                let isMinimized = (minRef as? Bool) ?? false

                var posRef: CFTypeRef?, sizeRef: CFTypeRef?
                AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &posRef)
                AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &sizeRef)
                var axOrigin = CGPoint.zero, axSize = CGSize.zero
                if let p = posRef as! AXValue?, let s = sizeRef as! AXValue? {
                    AXValueGetValue(p, .cgPoint, &axOrigin)
                    AXValueGetValue(s, .cgSize, &axSize)
                }

                let title = (titleRef as? String).flatMap { $0.isEmpty ? nil : $0 }
                          ?? app.localizedName ?? "Window"

                let tab = WindowTab(
                    windowID: windowID,
                    processID: app.processIdentifier,
                    appName: app.localizedName ?? "App",
                    windowTitle: title,
                    axElement: window,
                    appIcon: app.icon ?? NSWorkspace.shared.icon(for: UTType.application)
                )

                // Filter macOS Sonoma CapsLock indicator micro-windows (< 80×80)
                if !isMinimized && (axSize.width < 80 || axSize.height < 80) { continue }
                if !discoveredTabs.contains(where: { $0.id == tab.id }) { discoveredTabs.append(tab) }
                if isMinimized { continue }

                applyClampIfNeeded(
                    window: window, windowID: windowID,
                    axOrigin: axOrigin, axSize: axSize,
                    settings: settings, mouseHeld: mouseHeld
                )
            }
        }

        // Fallback focus sync — keeps the active-tab highlight correct even if the
        // AXObserver misses a notification (e.g. just after permission is granted).
        if let frontApp = NSWorkspace.shared.frontmostApplication {
            let appRef = AXUIElementCreateApplication(frontApp.processIdentifier)
            var focusedRef: CFTypeRef?
            if AXUIElementCopyAttributeValue(appRef, kAXFocusedWindowAttribute as CFString, &focusedRef) == .success,
               let elem = focusedRef as! AXUIElement? {
                DispatchQueue.main.async {
                    if settings.currentSystemFocusedElement == nil ||
                       !CFEqual(settings.currentSystemFocusedElement!, elem) {
                        settings.currentSystemFocusedElement = elem
                    }
                }
            }
        }

        DispatchQueue.main.async {
            if settings.activeTabs != discoveredTabs { settings.activeTabs = discoveredTabs }
        }
    }

    // MARK: - Clamp application

    private func applyClampIfNeeded(
        window: AXUIElement, windowID: CGWindowID,
        axOrigin: CGPoint, axSize: CGSize,
        settings: AeroBarSettings, mouseHeld: Bool
    ) {
        let axFrame = CGRect(x: axOrigin.x, y: axOrigin.y, width: axSize.width, height: axSize.height)
        let wasStill = previousFrames[windowID] == axFrame
        previousFrames[windowID] = axFrame

        if mouseHeld || !wasStill { stillCounts[windowID] = 0; return }

        let count = (stillCounts[windowID] ?? 0) + 1
        stillCounts[windowID] = count
        guard count >= requiredStillCycles else { return }

        let primaryH = NSScreen.screens[0].frame.height
        let cocoaRect = CGRect(x: axOrigin.x, y: primaryH - axOrigin.y - axSize.height,
                               width: axSize.width, height: axSize.height)
        guard let screen = hostScreen(for: cocoaRect) else { return }

        let isPrimary = screen == NSScreen.screens.first
        switch settings.displayTargetMode {
        case .primaryOnly   where !isPrimary: return
        case .secondaryOnly where isPrimary:  return
        default: break
        }

        var fsRef: CFTypeRef?
        if AXUIElementCopyAttributeValue(window, "AXFullScreen" as CFString, &fsRef) == .success,
           (fsRef as? Bool) == true { return }

        guard let (newOrigin, newSize) = Self.clampedFrame(
            axOrigin: axOrigin, axSize: axSize,
            screen: screen, barHeight: settings.barHeight
        ) else { return }

        // Same-display guard — the corrected rect must stay on the same screen.
        let correctedCocoa = CGRect(x: newOrigin.x,
                                    y: primaryH - newOrigin.y - newSize.height,
                                    width: newSize.width, height: newSize.height)
        guard hostScreen(for: correctedCocoa) == screen else { return }

        // Set the flag BEFORE the AX write so the observer callback ignores the
        // kAXResizedNotification macOS fires back at us — avoids bounce loops.
        isPerformingManagedResize = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            self?.isPerformingManagedResize = false
        }

        if newOrigin.y != axOrigin.y {
            var mutableOrigin = newOrigin
            if let val = AXValueCreate(.cgPoint, &mutableOrigin) {
                AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, val)
            }
        }
        if newSize.height != axSize.height && newSize.height > 50 {
            var mutableSize = newSize
            if let val = AXValueCreate(.cgSize, &mutableSize) {
                AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, val)
            }
        }
    }

    // MARK: - Helpers

    private func resolvedWindowID(window: AXUIElement, app: NSRunningApplication, idx: Int) -> CGWindowID {
        var ref: CFTypeRef?
        if AXUIElementCopyAttributeValue(window, "kAXWindowIDAttribute" as CFString, &ref) == .success,
           let num = ref as? NSNumber { return CGWindowID(num.uint32Value) }
        return CGWindowID(app.processIdentifier + Int32(idx))
    }

    private func hostScreen(for cocoaRect: CGRect) -> NSScreen? {
        NSScreen.screens.max {
            $0.frame.intersection(cocoaRect).width * $0.frame.intersection(cocoaRect).height <
            $1.frame.intersection(cocoaRect).width * $1.frame.intersection(cocoaRect).height
        }
    }
}
