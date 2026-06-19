// AccessibilityService.swift — AXObserver setup and frontmost-app tracking.
// Owner: Core/Services
// Depends on: AppKit, Accessibility framework
//
// One AXObserver is active at a time, watching the frontmost app.
// When the app switches, the old observer is torn down and a new one registered.
// All callbacks dispatch to main so callers never need to think about threads.

import AppKit

final class AccessibilityService {
    static let shared = AccessibilityService()
    private init() {}

    // Set by AeroBarWindowController so the observer can call back into it.
    weak var jitterGuard: JitterGuardProtocol?

    private var observer: AXObserver?
    private var registeredPID: pid_t?

    func register(for pid: pid_t) {
        guard registeredPID != pid || observer == nil else { return }
        tearDown()

        var observerRef: AXObserver?
        guard AXObserverCreate(pid, axCallback, &observerRef) == .success,
              let obs = observerRef
        else { return }

        let appRef = AXUIElementCreateApplication(pid)
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        AXObserverAddNotification(obs, appRef, kAXFocusedWindowChangedNotification as CFString, selfPtr)
        AXObserverAddNotification(obs, appRef, kAXTitleChangedNotification as CFString, selfPtr)
        AXObserverAddNotification(obs, appRef, kAXResizedNotification as CFString, selfPtr)
        AXObserverAddNotification(obs, appRef, kAXMovedNotification as CFString, selfPtr)

        CFRunLoopAddSource(CFRunLoopGetCurrent(), AXObserverGetRunLoopSource(obs), .commonModes)

        observer = obs
        registeredPID = pid

        // Seed the current focused window immediately on registration.
        var windowRef: CFTypeRef?
        if AXUIElementCopyAttributeValue(appRef, kAXFocusedWindowAttribute as CFString, &windowRef) == .success,
           let window = windowRef as! AXUIElement? {
            AeroBarSettings.shared.currentSystemFocusedElement = window
        }
    }

    func tearDown() {
        guard let obs = observer, let pid = registeredPID else { return }
        let appRef = AXUIElementCreateApplication(pid)
        AXObserverRemoveNotification(obs, appRef, kAXFocusedWindowChangedNotification as CFString)
        AXObserverRemoveNotification(obs, appRef, kAXTitleChangedNotification as CFString)
        AXObserverRemoveNotification(obs, appRef, kAXResizedNotification as CFString)
        AXObserverRemoveNotification(obs, appRef, kAXMovedNotification as CFString)
        observer = nil
        registeredPID = nil
    }
}

// MARK: - AX Callback (C closure — must be a free function or static)

private let axCallback: AXObserverCallback = { _, element, notification, refcon in
    DispatchQueue.main.async {
        let type = notification as String
        guard let ptr = refcon else { return }
        let service = Unmanaged<AccessibilityService>.fromOpaque(ptr).takeUnretainedValue()

        if type == kAXFocusedWindowChangedNotification {
            guard !(service.jitterGuard?.isSuppressingFocusUpdates ?? false) else { return }
            AeroBarSettings.shared.currentSystemFocusedElement = element

        } else if type == kAXTitleChangedNotification
               || type == kAXResizedNotification
               || type == kAXMovedNotification {
            // Skip if AeroBar itself caused this resize — avoids bounce loops.
            guard !(service.jitterGuard?.isPerformingManagedResize ?? false) else { return }
            WindowArrangementDaemon.shared.nudge()
        }
    }
}

// Protocol so WindowArrangementDaemon and AeroBarWindowController can expose their
// guard flags without creating a circular import.
protocol JitterGuardProtocol: AnyObject {
    var isSuppressingFocusUpdates: Bool { get }
    var isPerformingManagedResize: Bool { get }
}
