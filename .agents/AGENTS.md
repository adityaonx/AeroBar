# AeroBar Architecture & Safety Rules

## 1. Event Tap Safety (CRITICAL)
- **NO SYNCHRONOUS IPC**: Never perform synchronous cross-process calls (like `CGWindowListCopyWindowInfo` or synchronous `AXUIElement` attribute reads) directly inside a `CGEventTapCallBack`. Doing so can exceed the macOS ~1.0s callback budget under load.
- **NO INFINITE TIMEOUT LOOPS**: If macOS kills an event tap (`.tapDisabledByTimeout`), you must ensure a Circuit Breaker is used if you auto-reenable it (e.g., `CGEvent.tapEnable`). Blindly re-enabling an event tap that is timing out will result in a global WindowServer deadlock, permanently freezing the user's Mac until a hard reset.

## 2. Main Thread Blocking
- Be extraordinarily careful reading `@Published` variables or any `AeroBarSettings.shared` state from background event tap threads if those variables might be locked by the main thread. A hung main thread will cascade to hang the event tap thread.

## 3. Version Upgrades
- **ALWAYS UPDATE CASK**: When upgrading to a new version (e.g., v8.3-beta6), always update the version string in `Casks/aerobar.rb`. The GitHub Actions CI/CD pipeline (yml) will fail if this is not updated.
