# AeroBar — Release Notes

## Internal cleanup pass (unreleased)

This is a maintenance/refactor pass — no user-facing features were added or
removed. Safe to ship as a patch update once built and tested.

### Fixed
- Update-check throttle was silently disabled (dead code left the daily/weekly
  guard unreachable), so AeroBar was pinging GitHub for a new release on
  *every* launch instead of once per day/week as configured. The guard is
  restored.

### Changed
- Removed 3 dead files that were never instantiated anywhere in the project:
  `OnboardingWizardView.swift`, `AeroAppearanceWrappers.swift`,
  `SpriteLayerView.swift`.
- Split `AeroBarUpdateEngine.swift` (previously one file holding a model, an
  `NSPanel`, a SwiftUI view, and the update logic) into four files matching
  the project's existing folder conventions: `Core/Models/GitHubRelease.swift`,
  `Window/AeroBarUpdateAlertPanel.swift`, `Views/Settings/AeroBarUpdateAlertView.swift`,
  and a slimmed-down `Core/Services/AeroBarUpdateEngine.swift`.
- Extracted the Start Menu's inline drag-and-drop delegate into its own file,
  `Views/StartMenu/StartMenuPinnedDropDelegate.swift`, mirroring the existing
  `PinnedAppDropDelegate.swift` pattern used by the bar's pinned tray.
- Renamed a misleadingly-named hex decoder (`fromTelemetryHexString` →
  `Data(hexEncoded:)`) — it just decodes a hex string, no telemetry involved.
- Rewrote `AeroVistaOrbButton.swift`'s internal comments and structure; logic
  and visuals are unchanged.
- General comment cleanup across the codebase: removed leftover debug-session
  artifacts (emoji markers, "THE FIX" labels, bare `BUG N` references with no
  tracker context) and replaced them with plain descriptive comments.
- Added `docs/ARCHITECTURE.md` — class diagram, data-flow diagram, and launch /
  window-switch sequence diagrams for anyone new to the codebase.
- Tidied the README's formatting (removed redundant emoji clutter in headers,
  added a link to the new architecture doc).

### Notes for reviewers
- No public API, UI behavior, or settings keys changed.
- The update-check throttle fix is the only behavior change — worth a explicit
  mention in your changelog since it affects network calls on every launch
  for existing installs until they pick up this build.
