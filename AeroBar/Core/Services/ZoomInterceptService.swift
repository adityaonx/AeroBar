// ZoomInterceptService.swift — CGEvent tap that pre-clamps windows before zoom animations.
// Owner: Core/Services
// Depends on: AppKit, Core/Services/WindowArrangementDaemon
//
// PROBLEM: Clicking the green zoom button triggers a ~0.5–1s OS animation. Our AX daemon
// can only clamp the window AFTER the animation finishes, causing a visible snap.
//
// SOLUTION: Install a CGEvent tap at .cghidEventTap (before AppKit sees the click).
// On every leftMouseDown, hit-test against the frontmost window's AX zoom button.
// If it's a zoom click, pre-set the window frame to the clamped rect so the animation
// starts from and lands on the correct bounded position.

import AppKit

final class ZoomInterceptService {
    static let shared = ZoomInterceptService()
    private init() {}

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    // MARK: - Lifecycle

    func install() {
        remove()

        let selfPtr = Unmanaged.passRetained(self).toOpaque()
        guard let tap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(1 << CGEventType.leftMouseDown.rawValue),
            callback: zoomTapCallback,
            userInfo: selfPtr
        ) else {
            Unmanaged<ZoomInterceptService>.fromOpaque(selfPtr).release()
            print("AeroBar ZoomInterceptService: CGEvent tap requires Accessibility permission.")
            return
        }

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        eventTap = tap
        runLoopSource = source
    }

    func remove() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            if let src = runLoopSource {
                CFRunLoopRemoveSource(CFRunLoopGetCurrent(), src, .commonModes)
            }
        }
        eventTap = nil
        runLoopSource = nil
    }

    // MARK: - Hit-testing

    // Returns the focused window's AXUIElement and its hosting NSScreen if the
    // click landed on the zoom button, otherwise nil.
    func zoomButtonHitTest(at screenPoint: CGPoint) -> (AXUIElement, NSScreen)? {
        guard let frontApp = NSWorkspace.shared.frontmostApplication,
              frontApp.bundleIdentifier != Bundle.main.bundleIdentifier
        else { return nil }

        let appRef = AXUIElementCreateApplication(frontApp.processIdentifier)
        var windowRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(appRef, kAXFocusedWindowAttribute as CFString, &windowRef) == .success,
              let window = windowRef as! AXUIElement?
        else { return nil }

        var btnRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(window, kAXZoomButtonAttribute as CFString, &btnRef) == .success,
              let btn = btnRef as! AXUIElement?
        else { return nil }

        var posRef: CFTypeRef?, sizeRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(btn, kAXPositionAttribute as CFString, &posRef) == .success,
              AXUIElementCopyAttributeValue(btn, kAXSizeAttribute as CFString, &sizeRef) == .success,
              let posVal = posRef as! AXValue?,
              let sizeVal = sizeRef as! AXValue?
        else { return nil }

        var btnOrigin = CGPoint.zero, btnSize = CGSize.zero
        AXValueGetValue(posVal, .cgPoint, &btnOrigin)
        AXValueGetValue(sizeVal, .cgSize, &btnSize)

        // AX and CGEvent both use top-left origin — compare directly.
        let hitTarget = CGRect(origin: btnOrigin, size: btnSize).insetBy(dx: -4, dy: -4)
        guard hitTarget.contains(screenPoint) else { return nil }

        return (window, hostScreen(for: window) ?? NSScreen.main ?? NSScreen.screens[0])
    }

    func preClampWindowForZoom(windowElement: AXUIElement, on screen: NSScreen) {
        let barHeight: CGFloat = AeroBarSettings.shared.barHeight
        let menuBarH = screen.frame.height - screen.visibleFrame.height
                     - screen.visibleFrame.origin.y + screen.frame.origin.y

        let targetCocoaRect = CGRect(
            x: screen.frame.minX,
            y: screen.frame.minY + barHeight,
            width: screen.frame.width,
            height: screen.frame.height - barHeight - menuBarH
        )

        let primaryH  = NSScreen.screens[0].frame.height
        let axOriginY = primaryH - targetCocoaRect.maxY

        // Block the daemon from reacting to the resize we're about to trigger.
        WindowArrangementDaemon.shared.isPerformingManagedResize = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            WindowArrangementDaemon.shared.isPerformingManagedResize = false
        }

        var newOrigin = CGPoint(x: targetCocoaRect.minX, y: axOriginY)
        var newSize   = CGSize(width: targetCocoaRect.width, height: targetCocoaRect.height)
        if let posVal = AXValueCreate(.cgPoint, &newOrigin) {
            AXUIElementSetAttributeValue(windowElement, kAXPositionAttribute as CFString, posVal)
        }
        if let sizeVal = AXValueCreate(.cgSize, &newSize) {
            AXUIElementSetAttributeValue(windowElement, kAXSizeAttribute as CFString, sizeVal)
        }
    }

    // MARK: - Private

    private func hostScreen(for window: AXUIElement) -> NSScreen? {
        var posRef: CFTypeRef?, sizeRef: CFTypeRef?
        AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &posRef)
        AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &sizeRef)
        var origin = CGPoint.zero, size = CGSize.zero
        if let p = posRef as! AXValue?, let s = sizeRef as! AXValue? {
            AXValueGetValue(p, .cgPoint, &origin)
            AXValueGetValue(s, .cgSize, &size)
        }
        let primaryH = NSScreen.screens[0].frame.height
        let cocoaRect = CGRect(x: origin.x, y: primaryH - origin.y - size.height,
                                width: size.width, height: size.height)
        return NSScreen.screens.max {
            $0.frame.intersection(cocoaRect).width * $0.frame.intersection(cocoaRect).height <
            $1.frame.intersection(cocoaRect).width * $1.frame.intersection(cocoaRect).height
        }
    }
}

// Allow ZoomInterceptService to flip the daemon's managed-resize guard without
// creating a circular dependency between the two services.

// C-compatible CGEvent tap callback.
private let zoomTapCallback: CGEventTapCallBack = { _, _, event, refcon in
    guard let refcon = refcon else { return Unmanaged.passRetained(event) }
    let service = Unmanaged<ZoomInterceptService>.fromOpaque(refcon).takeUnretainedValue()
    let clickPoint = event.location
    if let (windowElement, screen) = service.zoomButtonHitTest(at: clickPoint) {
        service.preClampWindowForZoom(windowElement: windowElement, on: screen)
    }
    return Unmanaged.passRetained(event)
}
