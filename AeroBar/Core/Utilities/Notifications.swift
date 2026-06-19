// Notifications.swift — Typed Notification.Name constants for the whole app.
// Owner: Core/Utilities
// Depends on: Foundation
//
// ADDING A NEW NOTIFICATION:
//   1. Add a static let here.
//   2. Post it with NotificationCenter.default.post(name: .aeroBarXxx, object: nil)
//   3. Observe it the same way — no stringly-typed strings anywhere else.

import Foundation

extension Notification.Name {
    // Start menu
    static let triggerAeroStartMenu    = Notification.Name("triggerAeroStartMenu")
    static let dismissStartMenuWindow  = Notification.Name("dismissStartMenuWindow")

    // Display topology
    static let aeroBarMultiDisplayChanged = Notification.Name("AeroBarMultiDisplayChanged")

    // Focus suppression during window restore animations
    static let suppressFocusUpdates = Notification.Name("suppressFocusUpdates")
    static let resumeFocusUpdates   = Notification.Name("resumeFocusUpdates")
}
