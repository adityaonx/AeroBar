// WindowArrangementDaemon.swift — 100ms polling loop that clamps windows above the bar.
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
//   windowStillCycleCount     — window must be still for 3 consecutive ticks (~300ms)
//                               before a resize is attempted.
//
// TAB STABILITY FIX:
//   activeTabs is updated via stable-merge: existing tabs keep their position,
//   new tabs are appended, gone tabs are removed. This prevents the constant
//   reordering that occurred because NSWorkspace.runningApplications returns apps
//   in arbitrary order on each poll tick.
//
// POLL INTERVAL: was 30ms (33Hz). Every tick fans out into an AX/XPC call per
// app, plus 6+ AX/XPC calls per window (role, subrole, title, minimized,
// position, size, plus the private window-ID resolver) — at 33Hz that's
// hundreds of Accessibility-daemon round-trips per second with even a modest
// number of windows open, which is what was flooding the system log enough to
// trip Xcode's "quarantined due to high logging volume" console guard.
// requiredStillCycles already gates actual AX *writes* behind 3 consecutive
// still ticks, so the per-tick interval was never load-bearing for snappiness —
// only for how fast a new/closed window appears in the tab bar and how fast a
// dragged-under-the-bar window gets clamped back. 100ms keeps both well within
// "feels instant" territory while cutting AX call volume to roughly a third.

import AppKit
import UniformTypeIdentifiers

// _AXUIElementGetWindow is a private, unheadered ApplicationServices function that maps an
// AXUIElement window to its real CGWindowID. There is no public AX API for this — it is not
// "kAXWindowIDAttribute" (that string is not a real attribute and AXUIElementCopyAttributeValue
// will never return .success for it). This symbol ships in every macOS version's
// ApplicationServices/HIServices and is the same private call used by Rectangle, AltTab,
// Amethyst, and similar window-management tools to resolve window IDs from AX elements.
@_silgen_name("_AXUIElementGetWindow")
@discardableResult
func _AXUIElementGetWindow(_ element: AXUIElement, _ outWindow: inout CGWindowID) -> AXError

final class WindowArrangementDaemon {
    static let shared = WindowArrangementDaemon()
    private init() {}

    var isPerformingManagedResize = false
    var isSuppressingFocusUpdates = false

    private var timer: Timer?
    private var previousFrames: [CGWindowID: CGRect] = [:]
    private var stillCounts:    [CGWindowID: Int]    = [:]
    private let requiredStillCycles = 3

    // MARK: - Lifecycle

    func start(barHeight: CGFloat) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.tick(barHeight: barHeight)
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func nudge() {
        start(barHeight: AeroBarSettings.shared.barHeight)
    }

    // MARK: - Pure clamping (no side-effects — safe to unit test)

    static func clampedFrame(
        axOrigin: CGPoint,
        axSize: CGSize,
        screen: NSScreen,
        barHeight: CGFloat
    ) -> (origin: CGPoint, size: CGSize)? {
        let primaryH = NSScreen.screens[0].frame.height

        let cocoaTop    = primaryH - axOrigin.y
        let cocoaBottom = cocoaTop - axSize.height

        let bottomBoundary = screen.frame.minY + barHeight - 0
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

                if !isMinimized && (axSize.width < 80 || axSize.height < 80) { continue }
                if !discoveredTabs.contains(where: { $0.windowID == tab.windowID }) {
                    discoveredTabs.append(tab)
                }
                if isMinimized { continue }

                applyClampIfNeeded(
                    window: window, windowID: windowID,
                    axOrigin: axOrigin, axSize: axSize,
                    settings: settings, mouseHeld: mouseHeld
                )
            }
        }

        // Prune state for windows that no longer exist. Without this,
        // previousFrames/stillCounts retain a CGRect + Int for every window ID
        // ever seen — including from apps that quit long ago — for as long as
        // AeroBar keeps running. At 10 ticks/sec that's a slow but real
        // unbounded leak over a multi-day uptime session.
        let discoveredIDs = Set(discoveredTabs.map { $0.windowID })
        previousFrames = previousFrames.filter { discoveredIDs.contains($0.key) }
        stillCounts    = stillCounts.filter    { discoveredIDs.contains($0.key) }

        // Fallback focus sync
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

        // STABLE MERGE — preserve existing tab order instead of replacing the whole array.
        // Without this, tabs shuffle every tick because NSWorkspace.runningApplications
        // returns apps in arbitrary order on each poll tick.
        DispatchQueue.main.async {
            let existing = settings.activeTabs
            let discoveredIDs = Set(discoveredTabs.map { $0.windowID })
            let existingIDs   = Set(existing.map { $0.windowID })

            // Short-circuit: if sets are identical and content unchanged, skip the write.
            let contentChanged = existing.count != discoveredTabs.count
                || existing.contains(where: { old in
                    guard let new = discoveredTabs.first(where: { $0.windowID == old.windowID })
                    else { return true }
                    return new != old  // WindowTab.== checks windowID + processID + windowTitle
                })

            guard contentChanged else { return }

            // Build merged list: keep existing order, update changed entries, append new ones.
            var merged: [WindowTab] = existing.compactMap { old in
                guard let updated = discoveredTabs.first(where: { $0.windowID == old.windowID })
                else { return nil }           // tab gone — drop it
                return updated                // tab still exists — update title/icon in-place
            }
            // Append brand-new tabs (not seen before) in the order the daemon found them.
            for tab in discoveredTabs where !existingIDs.contains(tab.windowID) {
                merged.append(tab)
            }
            // Remove tabs that disappeared.
            merged.removeAll { !discoveredIDs.contains($0.windowID) }

            settings.activeTabs = merged
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

        let correctedCocoa = CGRect(x: newOrigin.x,
                                    y: primaryH - newOrigin.y - newSize.height,
                                    width: newSize.width, height: newSize.height)
        guard hostScreen(for: correctedCocoa) == screen else { return }

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
        // "kAXWindowIDAttribute" was never a real AXUIElement attribute string — Apple
        // does not expose window IDs through AXUIElementCopyAttributeValue at all, public
        // or private. That call always failed .success, so every tab silently fell back to
        // a fabricated CFHash-based ID below — not a real CGWindowID. Real window IDs come
        // from the window-server attached, private function _AXUIElementGetWindow, declared
        // by AppKit/SkyLight and used ubiquitously by window-management tools (Rectangle,
        // AltTab, etc.) for exactly this purpose.
        var wid: CGWindowID = 0
        if _AXUIElementGetWindow(window, &wid) == .success, wid != 0 {
            return wid
        }
        // Fallback only if the private call is ever unavailable/fails (e.g. some
        // sandboxed system windows that don't have a window-server backing window).
        // CFHash on an AXUIElement is stable for the lifetime of the CF object — it does
        // NOT change with Z-order. idx is Z-order-dependent and causes tab shuffling
        // whenever a Chrome window is focused (kAXWindowsAttribute returns in Z-order).
        let stableHash = CFHash(window) ^ UInt(app.processIdentifier)
        return CGWindowID(truncatingIfNeeded: stableHash)
    }

    private func hostScreen(for cocoaRect: CGRect) -> NSScreen? {
        NSScreen.screens.max {
            $0.frame.intersection(cocoaRect).width * $0.frame.intersection(cocoaRect).height <
            $1.frame.intersection(cocoaRect).width * $1.frame.intersection(cocoaRect).height
        }
    }
}
