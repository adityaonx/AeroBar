# Release Notes

### v9.4-beta5 - September 2026
- **App Tint Overrides**: Fixed a bug where opening the Customizer would automatically overwrite custom app tint rules for Chromium browsers with their auto-extracted colors due to an unprompted state update.
- **Update Engine**: Significantly reduced the app restart delay during an update by pre-mounting the update disk image in the background before waiting for the app to quit.
- **Focus Mode UI**: Fixed an issue in Light Mode where the sharp white dividers would remain intensely bright even when Focus Mode dimmed the bar to an opaque dark state, blending them smoothly instead.

### v9.4-beta4 - September 2026
- **Custom Color Overrides**: Fixed a bug where AeroBar could accidentally target itself or Finder when assigning Active App Colors, overriding default system themes.
- **Auto-Repair**: Added a startup check that automatically removes any accidentally saved color overrides for AeroBar or Finder to instantly repair stuck theming.
- **Menu Bar Interaction**: Fixed an issue where the native menu bar could become permanently unclickable due to an invisible focus tracking panel swallowing mouse clicks while AuraBar was disabled.

### v9.4-beta3 - September 2026
- **Window Tabs**: Fixed an issue where window tabs could randomly flicker or redraw themselves if an application momentarily stopped responding to accessibility checks.
- **PWA Support**: Expanded YouTube Music integration to correctly load track names and album art for Progressive Web Apps installed via Google Chrome or Microsoft Edge.
- **Start Menu**: Added a hardcoded fallback to ensure Finder always appears in the "All Apps" list, even if macOS indexing temporarily loses track of it.
- **Stability**: Fixed a hard crash (Swift Exclusivity Violation) that occurred when rapidly dragging the "Surface Tint Density" slider in the Customizer.
- **Welcome Panel**: Fixed a layout bug where the Post-Update welcome notes panel could erroneously anchor itself to the top-right corner of the screen instead of properly centering.
### v9.4-beta2 - September 2026

- **Website UI**: Redesigned index.html buttons with a modern Liquid Glass aesthetic using backdrop-filter blurring and inset shadows.
- **Documentation Alignment**: Re-anchored README headers and replaced external Shields.io badges with unified vector SVG buttons.
- **Static Download Links**: Replaced dynamic GitHub API fetch operations with static URLs for release assets to improve load reliability.
- **Drag-and-Drop Shortcuts**: Dragging an app from the Aero-Menu onto your Desktop or Finder now correctly generates a lightweight native macOS shortcut (alias), rather than incorrectly copying the entire application bundle.
- **Drag-and-Drop Reliability**: Fixed an issue where dragging an app from the "All Apps" list and dropping it into the "Pinned Shortcuts" section would fail to register.
- **Performance & Stability**: Fixed a severe bug where dragging certain system apps out of the Aero-Menu could cause AeroBar to hang and crash due to macOS sandbox restrictions on drag thumbnail generation.
- **Under the Hood**: Resolved Xcode build warnings and excessive runtime console spam by migrating internal drag-and-drop payloads to standard string identifiers.
- **Hover Consistency**: Fixed an issue where hovering over icons in Dock Mode failed to highlight or un-dim them when Display Dimmer or Focus Mode was enabled.
- **UI Consistency**: Updated all remaining guide popups (such as the Top Placement and Native Menu Bar guides) to correctly use the new Liquid Glass design language, matching the main onboarding flow.
- **Customizer**: The "Liquid Glass" bar material option is now unlocked and available for selection on all macOS versions (previously restricted to macOS Tahoe 26.0+). On older OSes, it will gracefully degrade to a high-quality ultra-thin material fallback.


### v9.3-beta9 - September 2026
- **Post-Update Experience**: Added a brand new "Update Successful" floating panel that automatically greets you with the release notes right after AeroBar completes an update and relaunches.
- **Intelligent Updater UI**: The updater popup now renders GitHub release notes natively with Markdown, properly displaying clickable hyperlinks, bold text, and lists.
- **Unified Liquid Glass Styling**: The updater popup now perfectly matches the OS-conditional Liquid Glass and Static Bar materials used in the onboarding UI.
- **Simplified Update Settings**: Removed the confusing Release Channel selectors (Beta, Testing, Final) from Settings. The updater now strictly fetches the single latest release from GitHub to reduce complexity.
- **Customizer Enhancements**: The Customizer's sidebar now automatically snaps back and expands the Layout section every time you open the panel.

### v9.3-beta8 - September 2026
- **Clipboard Security & Permissions**: Redesigned the "Save To" feature for copied file pointers in the Clipboard History panel. To strictly adhere to the Principle of Least Privilege, file pointers can now only be "Revealed in Finder" rather than duplicated. This completely removes the reliance on `FileManager` and Apple Events, preventing macOS from falsely flagging AeroBar for Full Disk Access.

### v9.3-beta7 - September 2026
- **Chromium UI Overlay Fix**: Fixed an issue introduced in beta6 where AeroBar would incorrectly clamp and shift Chromium-based browser (Google Chrome, Arc, Brave) search dropdowns, autocomplete menus, and focus rings.

### v9.3-beta6 - September 2026
- **Focus Mode Rendering**: Replaced opacity-based dimming on pinned and unpinned application icons with saturation and color-multiply filters. This prevents wallpaper bleed-through and ensures visual consistency with utility icons when the taskbar is translucent.
- **macOS 15/16 Clipboard Compatibility**: Fixed an issue where the system clipboard would fail to record copied items while AeroBar was active. Added a 150ms read debounce and strict type validation to prevent AeroBar from interrupting background write transactions in macOS Sequoia and Tahoe.
- **Divider Alignment**: Fixed an issue where section dividers would incorrectly render adjacent to empty space on vertical or top-placed taskbars when application lists did not fully fill the available screen area.
- **Cross-Platform App Compatibility**: Relaxed macOS Accessibility (AX) window role restrictions. AeroBar now natively recognizes and manages custom-drawn windows from cross-platform frameworks (e.g. Qt-based apps like DaVinci Resolve) that omit standard macOS window subroles.
- **Advanced Mode Deprecation**: Removed the "Advanced" toggle button from the Customizer. All advanced appearance and layout settings are now universally unlocked and visible by default for all users.

### v9.3-beta5 - September 2026
- **Light Mode Onboarding UI**: Fixed text visibility during first-time setup on Macs running Light Mode by enforcing a dark appearance globally.
- **EULA Checkbox**: Added accent-colored border and a "Please check mark to continue" prompt to the EULA checkbox.

### v9.3-beta4 - September 2026
- **Gatekeeper Validation**: Replaced dummy app symlinks with shell scripts and ad-hoc signatures to prevent ZIP extraction corruption and bypass Gatekeeper false-positives.

### v9.3-beta2 - September 2026
- **Window Preview Focus**: Fixed issue where clicking a live window preview thumbnail would incorrectly restore focus to the previous application upon closing.
- **Preview Animations**: Removed redundant window-raise commands when clicking window previews to prevent visual flashing.

### v9.3-beta1 - September 2026
- **Flicker Fixes**: Fixed flickering of pinned apps, unpinned apps, and window tabs when Screen Recording permission is denied.

### v9.2-beta9 - September 2026
- **Chromium Hover Cursor**: Added a 2px visual gap to the taskbar edge to guarantee `mouseExited` events register correctly for maximized Chromium-based apps.
- **Focus Mode Fullscreen**: Configured the dimming panel to automatically hide on monitors displaying a fullscreen application.

### v9.2-beta8 - September 2026
- **Window Clamping**: Updated clamping behavior to allow manual window placement behind or over the AeroBar, while retaining intelligent clamping for maximized or edge-snapped windows.
- **Maximize Clamping Delay**: Fixed delay where maximizing windows would overlap the AeroBar before being clamped.
- **Horizontal Clamping**: Fixed horizontal magnetic snapping and manual overlap overrides for left/right edge placements.
- **Auto-Updater**: Migrated the update installation process to a detached background script to prevent failure from extended-attribute copy errors or app crashes.
- **Crash Fixes**: Resolved thread deadlock (`EXC_BREAKPOINT`) in the window arrangement coordinator.
- **Taskbar Mode Flicker**: Fixed visual flickering of window tab chips during active window changes or bar height adjustments.

### v9.2-beta7 - September 2026
- **App Hangs**: Moved dynamic icon color extraction (`AuraBar`) to detached background tasks, removing synchronous `IconServices` caching loops.
- **AppleScript Stability**: Routed internal AppleScript executions through a dedicated serial queue to prevent `EXC_BAD_ACCESS` memory corruption crashes.
- **Shelf Hub Icon**: Replaced Shelf Hub icon with a native Asset Catalog (`Assets.car`) implementation to support real-time macOS dark mode and custom icon tints.
- **Auto-Updater**: Updated backup logic to use unique UUIDs, preventing "item with same name already exists" errors during installation.

### v9.2-beta6 - September 2026
- **AuraBar Flickering**: Fixed issue where the top menu bar would disappear during rapid app switches or focus changes.
- **App Badges**: Fixed macOS Accessibility API parsing errors causing missing red badges and attention animations for certain apps.
- **Efficiency Mode Dialogs**: Fixed issue in Customizer where Efficiency Mode and Power Save warning dialogs would instantly close without applying changes.
- **Telemetry Identifiers**: Migrated Cloudflare and Sentry telemetry to use a stable hardware ID (via IOKit) instead of random UUIDs.
- **Developer Options**: Added toggles to disable Sentry and Cloudflare reporting during local development.
- **Dashboard Telemetry**: Added manual cleanup tools and update deferral tracking metrics to the dashboard.

### v9.2-beta5 - September 2026
- **Focus Mode Opaque Bar**: Added toggle under Display Background Dimmer to disable the opaque dark bar effect when active.
- **Panel Depth Toggle**: Added toggle to switch popup panels from native WindowServer focus to emulated glass using `orderFrontRegardless`.

### v8.5-beta6 - July 2026
- Code decoupling and minor layout improvements.

### v8.4-beta9 - July 2026
- **Multi-Display Window Previews**: Fixed incorrect tab highlighting and incorrect screen placement for window previews on secondary displays.
- **Preview Stability**: Fixed infinite retry loop and flickering caused by truncated display crops for edge-aligned or maximized apps.

### v8.4-beta3 - July 2026
- **Scroll View Sizing**: Fixed issue where adding new windows from pinned tabs failed to resize the tab scroll view.
- **Pinned App Window Launch**: Fixed "Open New Window" context menu action failing when the application is already running.
- **Preview Reliability**: Resolved race condition causing blank window previews during rapid mouse hovers.
- **Performance**: Optimized main-thread IPC calls during pinned app hovers and context menu rendering.

### v8.3-beta8 - July 2026
- **Sentry Integration**: Integrated Sentry SDK for crash and performance metric tracking.
- **Hang Detection**: Updated Watchdog Service to spawn an independent AppleScript process for reliable crash reporting during main thread deadlocks.
- **Watchdog Threshold**: Reduced kill threshold from 15s to 10s.

### v8.3-beta6 - July 2026
- **Sleep Crashes**: Fixed watchdog timer timeouts when waking the Mac from sleep.
- **System Freezes**: Resolved deadlock with macOS WindowServer during Cmd+Tab or gesture switching when interacting with settings.

### v8.3-beta4 - July 2026
- **Native Crash Reporter**: Replaced background script crash popup with a native launch window.
- **Log Formatting**: Truncated crash logs to comply with GitHub issue size limits.
- **Event Tap Failsafe**: Added circuit breakers to prevent global OS freezes during event tap timeouts.
- **Developer Settings**: Moved testing tools to a dedicated Developer tab.
- **App Menu**: Fixed missing system apps and user-specific apps in the Start Menu app list.

### v8.3-beta3 - July 2026
- Under-the-hood performance optimizations.

### v8.3-beta2 - July 2026
- **Hover Animations**: Fixed hover lag and sticky button states during Focus Mode.

### v8.3-beta1 - July 2026
- **OS Support**: Added experimental support for macOS Sonoma and macOS Sequoia.

### v8.2-beta10 - July 2026
- **Memory Leaks**: Fixed memory leaks and CPU usage spikes related to window tracking and clipboard thumbnail generation.

### v8.2-beta8 - July 2026
- **Display Background Dimmer**: Added toggle to dim wallpaper on secondary or inactive displays lacking active windows.
- **Multi-Display Focus Mode**: Fixed dimming panel coordinates on external displays.
- **Codebase Modernization**: Addressed deprecated property warnings and updated dictionary initializers.

### v8.2-beta6 - July 2026
- **Settings UI**: Restructured "Surface Tint Density" grouping.
- **Focus Mode**: Corrected shading for Search and Trash buttons, applied dim tint instantly upon resize, and disabled bevel edges while active.
- **Flickering**: Fixed flickering during pinned app hovers.

### v8.2-beta4 - July 2026
- **Daemon Optimization**: Cached Space IPC calls and short-circuited phantom windows to reduce CPU usage.
- **Memory Leaks**: Addressed leaks from undocumented CGS WindowServer APIs.
- **Screen Recording Lifecycle**: Fixed issue where screen recording sessions remained active after popover closure.
- **Window Tab Previews**: Resolved state synchronization race condition causing blank hover previews.
- **Chromium Live Previews**: Fixed ScreenCaptureKit bug causing live previews to fallback to static thumbnails.
- **AeroBar Ghost Previews**: Excluded AeroBar's invisible tracking overlays from live preview captures.

### v8.2-beta3 - July 2026
- **Performance**: Shifted glass masking to native AppKit CoreAnimation layers to reduce CPU overhead.
- **Responsiveness**: Moved AX accessibility hit-testing off the main thread.
- **Stability**: Fixed `Invalid frame dimension` layout crash during initial Cmd+Tab panel display.

### v8.2-beta2 - July 2026
- **Trackpad Gestures**: Migrated multidirectional app cycling from 4-finger to 3-finger swipes.
- **Update Dialogs**: Suppressed update check popups when a display is in true fullscreen mode.
- **Window Positioning**: Fixed layout coordinate bugs causing windows to shift downward when pulled cross-screen.
- **Customization Button**: Expanded the Customization button click target to match its hover area.
- **Pinned App Icons**: Adjusted corner radii and masks to match macOS squircle aesthetics.
- **Hover Jitter**: Filtered physical trackpad cursor drift during 3-finger swipe gesture cycle highlights.

### v8.1-beta2 - July 2026
- Memory, battery, and performance optimizations.

### v8.1-beta - July 2026
- **Cmd+Tab & Gesture Switching**: Fixed 3/4 finger swipe gestures and window preview size clipping.
- **Aesthetics**: Added glass vibrancy, split accent colors, and 0.5pt bevel highlights.
- **Memory Optimization**: Fixed memory leaks causing instability.
- **Workspace**: Resolved fullscreen Space flickering and VLC rendering compatibility bugs.
- **UI Settings**: Added a slider for selection highlight color intensity and an Active Tab Dimmer for inactive window states.
- **Layout**: Fixed icon padding, welcome screen gaps, and EULA layout.
- **Threading**: Moved window tracking updates to background threads.
- **Clipboard History**: Added a delete confirmation prompt.
- **Context Menus**: Fixed bugs causing Context Menu freezes.
