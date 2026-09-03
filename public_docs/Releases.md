# Release Notes

### v9.1-beta9 - September 2026
- **New: Accessibility/Quarantine Troubleshooter**: Added a guided fix in Settings → Troubleshoot for the case where AeroBar won't show up under Accessibility and windows or pinned apps never populate — it detects where AeroBar is installed and gives you ready-to-copy Terminal commands for your exact setup.
- **Clipboard Priority-Inversion / Hang Risk Fixed**: Fixed a background thumbnail-generation process that could occasionally starve the Clipboard's foreground work of a thread, showing up as a brief hang risk when browsing Clipboard history.

### v9.1-beta8 - September 2026
- **Clipboard Screenshot Capture Fixed**: Fixed a bug where the Clipboard was sometimes missing screenshots you just took — they wouldn't show up in the Clipboard history even though the capture succeeded.
- **Pinned/Unpinned Apps Not Populating Fixed**: Fixed an issue where pinned and unpinned apps could fail to populate in the taskbar, leaving your pinned app list looking empty or out of date.
- **Menu Bar Permission Prompt No Longer Overlaps Customizer**: Fixed the menu bar permission overlay drawing on top of the Appearance Customizer panel; it's now dismissed automatically when you change AeroBar's size from the Customizer.
- **Divider Drawing Fix**: Fixed an issue with how dividers were drawn between taskbar items.

### v9.1-beta7 - September 2026
- **Fixed: Placement Screen Showing "Bottom" as Already Chosen**: On the setup screen where you pick where AeroBar sits (Top, Bottom, Left, or Right), the "Bottom" option was incorrectly shown as already selected before you'd tapped anything, and AeroBar wouldn't actually appear until you clicked something. Now no option is pre-selected, and the Continue button stays disabled until you've picked one.

### v9.1-beta6 - September 2026
- **Snappy, Reliable Window Clamping**: Maximized/tiled windows that got shoved out of place (a title-bar click, another app fighting for the frame, etc.) now snap back to where they belong noticeably faster — the recovery delay is roughly 4x shorter than before. And it no longer ever gives up: previously, a window could occasionally get "stuck" out of position for good after enough rapid changes; now AeroBar just keeps quietly correcting it until it settles, with the same tear-free protection as always.

### v9.1-beta5 - September 2026
- **Big Memory Fix — Start Menu**: The Start Menu was loading every single app icon at full resolution the instant you opened it, which could spike memory by 400-650MB on machines with a lot of installed apps. Icons are now cached and loaded lazily, so opening the Start Menu is lighter and noticeably snappier, especially on first launch.
- **Customizer No Longer Leaks Memory**: Closing the Appearance Customizer wasn't fully releasing it from memory — repeated open/close cycles could quietly pile up. It's now properly torn down every time, so RAM usage stays flat no matter how many times you pop it open.
- **Customizer Restructured Like macOS Settings**: The Customizer now uses a sidebar layout in the style of the macOS Tahoe Settings app, making it faster to jump between categories. It also gained a real search bar — start typing a setting's name (like "badge" or "cmd+tab") and jump straight to it.
- **New "Options" Tab**: Cmd+Tab switcher and trackpad gesture-switching settings now have a proper home of their own in the Customizer, instead of being buried elsewhere.
- **Fewer Background Timers**: Cleaned up a bug where rapidly toggling the Start Menu or Customizer could leave several redundant cleanup timers running at once. Everything now cancels properly, trimming background CPU/memory churn.
- **Stability**: Fixed a rare crash tied to computing tint colors (e.g. on light/dark mode switches) under heavy load.

### v9.1-beta4 - September 2026
- **Customizer Popup Z-Order Fixed**: Fixed the "Show menu bar background" and "Menu bar auto-hide" guide popups drawing behind the Appearance Customizer and Start Menu when triggered from the Position control, so they now always appear on top where you can see and use them.
- **No More Mid-Flow Customizer Dismissal**: Fixed the Customizer panel (and Start Menu) closing unexpectedly when interacting with those same guide popups — e.g. clicking "Open Control Center Settings" — so changing your Bar Placement no longer gets interrupted.

### v9.1-beta3 - August 2026
- **Redesigned Settings – 7-Category Customizer**: Rebuilt the Appearance Customizer around a clean, progressive-disclosure layout split into 7 focused categories, replacing the old dense single-page view so options are far easier to find.
- **Solid Background Override**: Added a dedicated "Solid Background Override" toggle for anyone who prefers a fully opaque bar over glass — consolidating and fixing the previous "Disable Glass Material" toggle, which wasn't reliably applying to AeroBar and AuraBar.
- **Decoupled Focus Mode**: Fixed an issue where the Focus Mode menu bar dimming would break if you disabled the AuraBar. It now works flawlessly on its own, utilizing an invisible hover tracker.
- **Extension Button Drag-to-Reorder Fixed**: Fixed drag-to-reorder for extension/utility buttons (Clipboard, File Shelf, Quick Links, Recycle Bin, Show Desktop, and more), which had silently stopped working for most buttons, and extended support to Left/Right vertical bar placements.
- **Pinned Apps Tray Reliability**: Fixed the Pinned Apps popup getting stuck open — or dismissing unexpectedly — when switching bar placement mid-session, and restored a missing hover highlight on the Pinned Apps Grid button.
- **Polish**: Reordered "Top" above "Bottom" in the Bar Placement settings list, and tightened the timing of the window-reveal focus handoff to eliminate a rare WindowServer race condition.

### v9.1-beta2 - August 2026
- **Flawless Light Mode Aesthetics**: Completely overhauled the default Light Mode experience. Fresh installs and factory resets now default to a stunning 'Frosted Ice' Aero Blur with 100% brightness and 100% surface density for a pristine, premium glass aesthetic.
- **Smart Brightness Clamping**: Increasing the Tint Brightness slider in Light Mode now intelligently boosts only the floating menus and panels, while protecting the main top/bottom bars from washing out and blinding you.
- **High-Contrast Legibility Engine**: Added a smart dark-grey stroke that automatically outlines pure-white window tabs, section dividers, and Music Widget controls in Light Mode. This guarantees perfect legibility whether the translucent bar is floating over a pitch-black terminal or a glaring white webpage.
- **Liquid Glass Deprecated in Light Mode**: Due to unpatchable CoreAnimation tearing bugs in macOS that caused Liquid Glass to become cloudy-white on theme changes, we've disabled it entirely for Light Mode to ensure a rock-solid, bug-free experience.

### v9.1-beta1 - August 2026
- **Pixel-Perfect Layouts**: Fixed inconsistent horizontal gaps between utility extension buttons and the Mission Control divider caused by invisible ghost layout elements. The bar now maintains flawless symmetry.
- **Sleek New Design Language**: Replaced custom-drawn UI shapes with gorgeous, native macOS-style dummy app icons. The entire bar feels completely at home on macOS while retaining that nostalgic Windows taskbar vibe.
- **The "Shelf Hub"**: We've streamlined the extensions! The previously separate utilities have been merged into a single, unified "Shelf Hub" button, decluttering your taskbar while keeping all your power tools just a click away.
- **Precision Focus Mode**: Focus Mode is now smarter than ever. Instead of the entire bar brightening up when you move your mouse, the bar stays beautifully dimmed in the shadows, and *only* the specific icon or tab you hover over gently illuminates. 
- **Utility Tray Deprecated**: We removed the complex separate "Utility Tray" mode to focus on delivering a single, incredibly stable, and highly polished Unified Bar experience. 
- **Lightweight & Fast**: By stripping out legacy equalizer animations and obsolete icon coloring engines, we've trimmed the fat and made AeroBar snappier and less resource-intensive.

### v9.0-beta9 - August 2026
- **Antivirus False Positive Fix**: 
  - Rewrote the background Dock watchdog to execute shell commands entirely in-memory instead of writing and executing hidden bash scripts to the system Temp folder. 
  - Removed aggressive LaunchAgent polling and global keyboard hotkey hooks. 
  - These changes completely eliminate the 'Trojan:Script/Wacatac.C!ml' false positive triggered by aggressive machine-learning antivirus scanners like Microsoft Defender.
- **Clipboard History Overhaul**:
  - **Native Quick Look & Live Text**: Replaced the custom oversized OCR panel with native macOS Quick Look. Previewing images now provides a seamless, perfectly scaled Finder-style experience with Apple's Live Text built right in.
  - **Crisp Retina Thumbnails**: Fixed a bug where copied image thumbnails looked blurry on Retina displays. Thumbnails are now rendered at 1000px resolution with expanded memory caching for buttery smooth scrolling.
  - **New Pinned Tab**: Added a dedicated "Pinned" tab to the clipboard filter bar so you can instantly access your saved items.
  - **Layout Fixes**: Increased the panel width to 500pt and fixed an issue where the "Files" tab label was clipped off the screen.
  - **Code Cleanup**: Removed hundreds of lines of deprecated custom OCR code, keeping the app lightweight and fast.

### v9.0-beta7 - August 2026
- **Layout Hotfix**: Fixed a visual overlap bug where the taskbar expanded beyond its physical bounding box and bled behind windows due to mismatched icon scaling parameters from beta5.
- **Critical Hotfix**: Taskbar auto-scaling layout logic introduced in beta5 has been completely reverted to prevent WindowServer crashes and macOS window sync failures, returning to the stable layout of beta4.
- **Massive Memory Optimization**:
  - Automatically destroys the AeroBar Start Menu and Customizer UI off-screen 60 seconds after closing them, freeing up roughly ~200MB of pure WindowServer graphical memory.
  - Re-engineered icon retrieval for Search and Start Menu, utilizing ephemeral caches to starve the `iconservicesagent` memory bloat, recovering up to 800MB of RAM during intense searches.
  - Terminated runaway background daemon processes left alive by native Spotlight metadata queries, freeing up idle CPU time.
- **Dynamic Icon Rasterization**: Changing the `pt` size in settings now triggers a perfect mathematical redraw of all icons at their new scale without app restart.


### v9.0-beta4 - August 2026
- **Performance & Stability Enhancements**:
  - **WindowServer Crash Fix**: Drastically reduced CPU usage and completely eliminated WindowServer deadlocks/UI freezes that occurred when rapidly moving the mouse across multiple taskbar icons.
  - **No More Dropped Keystrokes**: Fixed an issue where accidentally brushing your mouse past the taskbar would momentarily steal keyboard focus and cause you to drop keystrokes in your active application.
  - **Smoother Liquid Glass**: The immediate "depth" effect of Liquid Glass when hovering taskbar icons has been optimized for macOS 16.0 Tahoe.

### v9.0-beta3 - August 2026
- **Diagnostics HUD**: Added an intuitive, in-app draggable floating panel when clicking "Submit Issues" to seamlessly drag-and-drop diagnostic logs directly into GitHub, bypassing Safari sandboxing restrictions.
- **Troubleshooting Menu**: Moved diagnostics export tools from the hidden Developer section directly to the Troubleshooting tab.
- **System State Snapshot**: Diagnostic logs will now dynamically append the exact macOS version and AeroBar build state even if there are zero crash events recorded, saving diagnostic time.
- **Focus & Activation Reliability**:
  - Fixed a major bug where rapid hovering across pinned apps would permanently steal focus from your active application by safely canceling overlapping activation requests.
- **Hover Engine Recovery**:
  - Fixed an issue where hovering would permanently die after the Mac was put to sleep multiple times by removing an overly aggressive safety tripwire.
- **Preview Hit-Testing & Dead Zones**:
  - Fixed overlapping "ghost" hover zones from scrolled window tabs preventing hovers from registering correctly.
- **Customizer & Settings Theming Fixes**:
  - Fixed a missing color overlay on macOS 26.0 Tahoe's native `.glassEffect` that prevented custom Liquid Glass tint colors from applying to the Aero Menu and Customizer panels.
  - Re-enabled the volumetric cursor glow for native Tahoe glass.
  - Fixed a bug where the "Reset Section" button applied outdated solid background defaults instead of the true Liquid Glass factory defaults.
- **Customizer Performance Lag**:
  - Fixed massive cursor and menu lag in the Appearance Customizer caused by continuous 60Hz mouse updates triggering redundant 200ms Core Animation interpolations.
### v9.0-beta2 - August 2026
- **Reset Options Fixed**:
  - Fixed Total Factory Reset, Dry Wipe, and Reset Settings & Cache all quitting AeroBar without relaunching it afterward.
  - Fixed a rare crash that could occur specifically during Total Factory Reset, caused by a settings-save reentrancy issue.
- **In-App Update Reliability Fixed**:
  - Fixed a bug where the in-app updater could quit and relaunch from the same old build if mounting the update disk image or swapping in the new app silently failed.
  - The updater now verifies each step succeeded, automatically restores the previous build if a swap fails partway through, and shows a real error instead of failing silently.
- **Panel Close Crash Fixed**:
  - Fixed a crash ("NSWindow geometry should only be modified on the main thread!") that could occur when a panel (Start Menu, alert panels, etc.) closed.
  - Panel teardown code is now guaranteed to always run on the main thread instead of occasionally landing on a background thread.

### v9.0-beta1 - August 2026
- **Memory Usage Nearly Halved**:
  - Continued the memory work from v8.9-beta9 with a deeper pass across the app. Typical memory usage is now nearly 50% lower than v8.9-beta9.
  - AeroBar should feel noticeably lighter, especially if you keep it running for long stretches or leave your Mac on for days at a time.
- **General Stability Improvements**:
  - Small fixes and polish throughout the app based on beta feedback.

### v8.9-beta9 - August 2026
- **Memory Leaks Fixed (Part 1 — WindowServer & UI Panels)**:
  - Fixed multiple memory leaks that were causing AeroBar to accumulate hundreds of megabytes of memory over time through normal use. WindowServer no longer ramps up to ~500 MB just from the bar sitting on screen.
  - Fixed a permanent ~50 MB memory leak that occurred every time the Aero Menu or Customizer panel was opened. Memory is now fully released after closing them.
  - Optimized the display background dimmer service to defer heavy WindowServer surface allocations until the panel is actually shown, significantly reducing the idle WindowServer memory footprint.
  - Icon bitmap cache is now capped to prevent unbounded RAM growth when many apps are running simultaneously.
  - Memory from closed panels is now proactively returned to the OS via allocator pressure relief, keeping AeroBar's working set lean.
  - **What you'll notice**: AeroBar's base memory use is dramatically lower. Short spikes when opening Aero Menu / Customizer are expected and fully self-healing — memory comes back down after closing them.

### v8.9-beta8 - August 2026
- **Screenshot Thumbnail Conflict Resolved**:
  - AeroBar now automatically disables the macOS floating screenshot thumbnail preview (bottom-right corner) while it is running, preventing it from being obscured behind AeroBar's elevated window level.
  - On quit or crash, the original screenshot thumbnail setting is fully restored so the native thumbnail reappears normally when AeroBar is not running.
- **Dock Mode / Taskbar Mode Layout Auto-Correction**:
  - Switching between Dock Mode and Taskbar Mode now instantly re-clamps all background windows to the correct screen boundary, eliminating the gap or overlap that previously required a restart.
- **Bottom Gap Auto-Fill on Bar Height Reduction**:
  - When the AeroBar height is reduced (e.g. dragging the height slider down), windows docked above the bar now automatically expand downward to fill the freed space, keeping the screen fully utilized.
- **Singleton Initialization Crash Fixed (`EXC_BREAKPOINT`)**:
  - Fixed a crash during launch caused by `AeroBarSettings` static singleton re-entrancy when `updateBarHeight()` was called inside the initializer. All height update calls from settings setters are now safely dispatched async to the main thread.
- **Window Clamping on Mode Switch**:
  - Toggling Dock Mode, Taskbar Mode, or changing bar height now reliably triggers `WindowArrangementDaemon.updateBarHeight()` to re-clamp all windows instantly.
- **Aero Start Menu Positioning**:
  - Fixed the Start Menu anchoring directly above the Aero Vista Orb icon in Dock Mode instead of centering on screen.
  - Fixed taskbar button hover no longer prematurely dismissing the Aero Start Menu panel.
- **Default Bar Height**:
  - Updated the default AeroBar height to 60pt for new users and factory-reset profiles.
- **Music Widget Smart Play**:
  - Pressing Play when no track is loaded now automatically opens and focuses the selected music app (Spotify / Apple Music).
  - Fixed Apple Music window tab display when the app is closed or has no active AX windows.
- **UI Polish**:
  - Fixed horizontal spacing between the Aero Vista Orb and the pinned Finder icon.
  - Fixed utility tray button sizing staying correctly at 40pt inside the Utility Tray at all bar heights.
  - Standardized popover panel dismiss grace period (850ms) across all utility buttons and gap traversal zones.

### v8.9-beta7 - August 2026
- **Health Check Diagnostics & Watchdog Daemon Overhaul**:
  - **100% Health Check Diagnostic Pass**: Resolved all failing items in the Settings Health Check diagnostic panel (`Heartbeat freshness`, `External watchdog helper`, and `Emergency exit overlay`).
  - **In-Memory Heartbeat Tracking**: Updated `AeroBarWatchdogService` to track heartbeat freshness via in-memory main-thread Darwin IPC timestamps (`0.8s` freshness), eliminating unnecessary background disk I/O.
  - **External Watchdog Helper Daemon**: Built `AeroBarWatchdogHelper` as an independent SPM background daemon and registered its LaunchAgent plist (`com.aerobar.watchdoghelper`). It watches AeroBar from outside its process space, automatically saving hang reports and force-relaunching AeroBar if the main process ever wedges completely.
  - **Disabled-by-Design Overlay Status**: Updated `EmergencyExitOverlayService` health check status to accurately report `disabled by design (prevents UI overlap with menu bar and full-screen windows)` as a clean passing state.

### v8.9-beta6 - August 2026
- **Critical Crash Fix (`EXC_BAD_ACCESS` / `KERN_INVALID_ADDRESS at 0x8000000000000028`)**:
  - **Memory Safety in Accessibility Callbacks**: Resolved a critical fatal crash in `AccessibilityService` and `WindowLifecycleEventWatcher` caused by C-level `AXUIElementRef` parameters being dispatched into main-queue async blocks without an explicit `CFRetain`. macOS released the temporary C element immediately upon callback completion, leaving a dangling pointer when the main-thread block executed. All C-level Accessibility references are now retained synchronously before dispatching (`Unmanaged.passRetained(element)`), eliminating memory corruption.
  - **Global Event Tap Lifecycle Hardening**: Ensured background event tap runloops (`GlobalMouseTapService`) cleanly stop and invalidate MachPort runloops on object deallocation.

### v8.9-beta5 - August 2026
- **Clipboard History Overhaul (Left Alignment, Spacebar QuickLook & Save As)**:
  - **Left-Aligned Text & Files**: Text snippets, code blocks, file names, folder paths, and link URLs now align cleanly to the left directly beside their icons.
  - **Spacebar QuickLook for All Items**: Pressing Spacebar on *any* item (text, code, files, folders, images, GIFs, videos, audio) opens full, scrollable native macOS QuickLook previews.
  - **1-Click Save As / Save To**: Added a 1-click `"Save As..."` / `"Save Image"` / `"Save To"` hover button and right-click context menu options to export copied text as `.txt` files, images as `.png` files, or copy files and folders to custom locations.
- **Popover Gap & Glass Panel Standardization**: Standardized floating popover gap (~10pt above taskbar) across Music Widget, Window Previews, and Utility Buttons, with 24pt squircle panel masking.
- **Pinned App Preview Border Alignment**: Single-window pinned app previews now render with 0 outer margin, matching window tabs 1:1 and eliminating secondary dark box outlines.
- **Multi-Display Placement Precision**: Popover panels and window previews now open on the exact display your cursor is hovering over on multi-monitor setups.
- **HUD Glass Previews for Cmd+Tab & 3-Finger Swipe**: Window previews shown during `Cmd+Tab` and 3-finger swipe gestures now render in vibrant, translucent Liquid Wallpaper HUD Glass while remaining 100% non-focus-stealing.
- **AuraBar & AeroBar 1:1 Synchronized Theming**: Top menu bar (AuraBar) and bottom AeroBar now synchronize glass materials, tint hue, brightness, and surface tint density (default 50%) 1:1.
- **macOS Tahoe Compositor & Music Vibrancy Fixes**: Fixed macOS Tahoe (16.0) Window Server compositor dimming on glass popovers and restored Liquid Glass album art vibrancy in Spotify & Apple Music widgets.

### v8.9-beta4 - August 2026
- **Window Preview Reliability**: Fixed an issue where authorization prompts over window previews required two clicks instead of one.
- **Recycle Bin Feedback**: The Trash icon now instantly highlights and glows whenever you drag any file or folder anywhere on your screen.
- **Floating Bar Resizing Fixes**: Fixed a lingering ghost shadow on the screen after shrinking the bar height (such as switching from Default to Compact in Dock mode).
- **Maximized Window Stability**: Fixed a rare issue where maximizing a window (or using layout tools like Magnet) would cause a subtle 1-frame screen flash.
- **Performance & CPU Efficiency**: Optimized background processing to reduce CPU and battery consumption across all running applications.

### v8.9-beta3 - August 2026
- **Dock Mode & Taskbar Mode**: Easily force specific layouts (like macOS Dock or Windows Taskbar) directly from Settings. Dock Mode is now enabled by default for new users.
- **System Dock Protection**: Added a background watchdog to ensure your native macOS Dock settings are safely preserved under all conditions.
- **Music Widget Layout & Single-Click Focus**: Overhauled the Music Widget with clean tab layouts, instant 1-click app focusing for Spotify and Apple Music, and smoother hover behavior.
- **Drag & Drop to Trash**: Drag single or multiple files and folders directly from Finder onto the AeroBar Recycle Bin icon to instantly move them to macOS system Trash.
- **Unified Extensions & Shelves**: Centralized all element enable/disable toggles inside Extensions & Shelves with full toggle coverage for Mission Control and Search Icon.

### v8.9-beta2 - August 2026
- **Tooltip Reliability**: Fixed an issue where hover tooltips for buttons (like Trash, Mission Control) were hidden when the Start Menu was open.
- **Start Menu Orb Toggle**: Fixed an issue where clicking the Aero-menu Orb icon wouldn't toggle the Start Menu on and off.
- **Quick Links Shortcut**: Fixed an issue where using the keyboard shortcut for Quick Links would select the button but occasionally fail to render the panel.
- **Drag & Drop Glow Effects**: Added glowing visual feedback to Quick Links, File Shelf, and Pinned Folder buttons when dragging compatible files or URLs anywhere on your screen.

### v8.9-beta1 - August 2026
- **Global Keyboard Shortcuts**: Configure custom system-wide hotkeys (e.g. `⌥⇧C`) to instantly toggle panels (Clipboard History, File Shelf, Pinned Folders, Utility Tray, Widgets, Quick Links) or trigger key actions from anywhere.
- **Shortcut Safety & macOS Protection**: Built-in safety hard-blocks native system conflicts (like `⌘Space` or `⌘Tab`) and requires Option (`⌥`) modifier so you never override other apps.
- **Hardware Key Cap Previews**: Translucent hardware-style key cap badges (`[⌥][⇧][C]`) display directly in panel headers and Customizer UI.
- **Indestructible Tooltips & Action Hotkeys**: Hover tooltips display 100% reliably regardless of system focus with integrated shortcut hints.
- **Seamless Setup**: Deferred background engine initialization until after setup is complete, eliminating aggressive macOS permission prompts.

### v8.8-beta9 - July 2026
- **Dynamic Liquid Glass (Default)**: Introduced a brand new, highly optimized dynamic material that renders volumetric, real-time tracking liquid glass waves on hover.
- **Sleeker Glass Menus**: Reduced popup glass bevels to 1.5px with concentric squircle inner radii so inner glow and outer borders stay in visual sync.
- **Smooth Global Hover Tracking**: Dynamic liquid glass waves now sweep smoothly across the entire bar without freezing or dropping frames.
- **Battery & Performance**: Improved battery life and CPU efficiency by optimizing global mouse tracking and space detection.

### v8.7-beta3 - July 2026
- **Pinned App & Mission Control Hover Highlights**: Fixed hover highlight positioning on pinned apps and Mission Control buttons.
- **Utility Buttons Drag-to-Reorder**: Added live drag-to-reorder support for all right-side utility buttons (Clipboard, File Shelf, Quick Links, Widgets, Recycle Bin, Show Desktop, Pinned Folder).
- **Independent Light & Dark Mode Indicator Styles**: Made Indicator Styles (Pill, Full Line, Trimmed Line, Dot, Border) independent per appearance mode.
- **Automatic macOS App Icon Refresh**: System appearance changes automatically refresh native app icons when switching between Light and Dark modes.

### v8.7-beta2 - July 2026
- **Troubleshooting & Fixes Tab**: Added a dedicated Troubleshoot tab in AeroBar Settings featuring a 4-step quick fix guide and direct System Settings shortcuts for resolving post-system freeze macOS HID event tap blocks (Cmd+Tab / 3-finger swipe, hover highlights, button popups).
- **macOS App Icon Cache Refresh**: Added a "Refresh All macOS App Icons Now" tool to purge icon caches and force a system-wide reload across all pinned apps, window tabs, window previews, and start menu items when macOS themes or icon settings change.
- **Fullscreen Popover Suppression**: Resolved an issue where button popups and preview panels (Quick Links, Widgets, Window Previews, File Shelf, Pinned Folders) appeared on hover when watching videos or running apps in true fullscreen mode.
- **Opt-in Clipboard Background Processes**: Fully gated all clipboard background activity (0.4s pasteboard polling timer, system sleep/wake event observers, and thumbnail disk I/O) behind the Extensions setting toggle. When disabled, background clipboard activity and memory consumption drop to zero.
- **Main Thread Safety**: Dispatched coordinate hover tracker evaluations to the main thread, eliminating thread sanitizer/Main Thread Checker warnings and ensuring thread-safe window property reads.

### v8.7-beta1 - July 2026
- **Bar Height Dock Re-enforcement & Window Re-clamping**: Changing the Bar Height automatically re-enforces system Dock size defaults and autohide settings after a 500ms debounce, triggering window re-clamping across open applications.
- **Adaptive Button Fill Tint Presets**: Added independent Light Mode and Dark Mode button fill tint settings, with preset swatches (Auto, Dark, Ice White, Tahoe Blue, Mint, Turquoise, Amethyst, Amber, Crimson, Neon Cyan).
- **Color Sliders (Hue & Brightness)**: Introduced interactive Hue & Brightness sliders for Quick Icon Tint, Button Fill Tint, and Orb Logo Foreground Tint.
- **Advanced Per-Element Customization**: Upgraded per-element controls (Search, Recycle Bin, File Shelf, Clipboard, Widgets, Quick Links, Pinned Folder, Show Desktop, Mission Control) with 4 individual Hue & Brightness sliders + preset swatches for icon glyph and background fill.
- **Default Logo Brightness (85%)**: Updated default orb logo brightness to 85% (#D9D9D9).

### v8.6-beta9 - July 2026
- **Mission Control Divider Line Fix**: Resolved an issue where disabling the Mission Control button rendered two adjacent divider lines instead of a single divider line between pinned apps and window tabs.
- **Show Desktop Icon Spacing Fix**: Resolved an issue where disabling the Recycle Bin button caused the Show Desktop button and other right-side utility icons to stick directly together without proper margin/padding.

### v8.6-beta8 - July 2026
- **Per-Icon Show/Hide Toggles**: Added enable/disable switches to every row in Appearance → Icon Colors → Advanced - Per-Element, letting you hide individual bar icons (Search, Recycle Bin, File Shelf, Clipboard, Widgets, Quick Links, Pinned Folder, Show Desktop, Mission Control) independently, right alongside their color overrides. All icons remain enabled by default.

### v8.6-beta7 - July 2026
- **CheckedContinuation Crash Fix**: Resolved a fatal `SWIFT TASK CONTINUATION MISUSE` crash in the clipboard thumbnail generator where a checked continuation could be resumed multiple times when decryption failed.
- **Main Thread App Hang & Watchdog Fix**: Moved AppleScript execution (such as session actions, onboarding permission checks, and keystroke automation) entirely off the main thread to background queues, eliminating severe UI hangs and Watchdog timeout crashes.
- **Unified Hover Highlights**: All app icons and system buttons share the exact same selection-color border and glow highlights on hover.
- **MacOSSquircle Rendering**: Applied mathematical macOS superellipse curves to all overlays and clipping masks to eliminate edge aliasing.
- **High-Resolution Icon Scaling**: Refactored the icon rasterizer to retrieve high-resolution `256x256` representations and manually downsample them, preserving the squircle background on smaller bar heights.
- **Adaptive Button Sizing**: Dynamically scale system shortcut button containers and inner icons depending on active bar height to match the visible padding of native app icons.
- **Window Tab App Icon Upgrades**: Updated window tab icons to use the high-resolution rasterized loader, aligning them with the main tray's sharp rendering.

### v8.6-beta6 - July 2026
- **Window Tab Pruning Fix**: Fixed a bug where closed or stale app windows would still show up on the window tabs list for up to 15 seconds. Reduced the CGWindowList cache refresh interval to 0.5 seconds, ensuring closed windows are pruned immediately.

### v8.6-beta5 - July 2026
- **Critical Crash Fix**: Fixed a rare but fatal `SWIFT TASK CONTINUATION MISUSE` crash in the clipboard thumbnail generator. A code path introduced in v8.2-beta10 could resume the same async continuation twice whenever decrypting a clipboard item's cached payload failed (e.g. a stale or unreadable payload file), crashing the app outright. Thumbnail generation now safely resumes exactly once regardless of which path it takes.

### v8.6-beta4 - July 2026
- **Hardware-Derived Keys**: Migrated the clipboard encryption key directly to a secure, hardware-derived key using the Mac's logic board serial number, ensuring military-grade security without triggering macOS Keychain permission prompts.
- **Improved Lockout Flow**: The beta lockout panel is now immovable and automatically hides the main AeroBar taskbar when active. Also fixed a bug where clicking 'Disable launch at start' closed the confirmation alert prematurely.
- **Automated Check-Ins & Rate Limiting**: Implemented network change observation and a 24-hour background timer to fetch license updates automatically, with rate-limiting to protect free Cloudflare worker quotas.
- **Critical Bug Fixes**: Resolved a major memory leak (100MB+) that occurred when plugging/unplugging external displays by aggressively shredding orphaned SwiftUI window previews. Also fixed a minor memory leak where the Beta/Update alert panels failed to release their view controllers.
- **Update Prompt**: Engineered a flawless dynamic height system for the update panel that automatically shrink-wraps small release notes and natively scrolls massive release notes without cutting off UI elements.
- **AeroBar Options**: Added a new "Show Bevel on Empty Displays" toggle to control bevel visibility when a display has no active windows. Also fixed an issue where the bevel line was incorrectly hidden by the focus mode dimming overlay when the background dimmer was active.
- **Documentation**: Updated the memory optimizations guide to document edge-cases for display disconnects and clarify the difference between macOS Resident Memory (Warm Cache) and true active memory.

### v8.6-beta1 - July 2026
- Fixed an issue where hovering over pinned apps and buttons on the internal display broke after disconnecting an external monitor.

### v8.5-beta9 - July 2026
- Fixed a massive memory leak where the Customizer UI was retained in memory after closing.
- Fixed a severe main-thread hang (~950ms) during Space transitions by migrating window state queries off the WindowServer IPC hot path.

### v8.5-beta8 - July 2026
- Fixed a critical bug where pinned app hover highlights and popovers were misplaced when an external monitor was connected mid-session.

### v8.5-beta7 - July 2026
- **Power Save/Efficiency Mode Decoupling**: Completely separated the "Efficiency Mode" and "Power Save Mode" toggles. Power Save Mode on battery now correctly enforces a fully opaque bar, while Efficiency Mode preserves the blur effect. Additionally, Power Save Mode now fully respects macOS Low Power Mode.

### v8.5-beta6 - July 2026
- Minor improvements and under-the-hood code decoupling.

### v8.4-beta9 - July 2026
- **Multi-Display Window Previews**: Fixed an issue where hovering over a window tab on a secondary display would incorrectly highlight tabs on the primary display, and resolved instances where window previews would pop up on the wrong screen.
- **Preview Flicker / Stability**: Fixed a bug where hovering over window tabs for edge-aligned or maximized apps (like Antigravity IDE) would cause the window preview to infinitely retry and flicker due to a truncated display crop check.

### v8.4-beta3 - July 2026
- **Scroll View Fix**: Fixed an issue where adding a new window from a pinned tab would not automatically resize the tab scroll view.
- **Pinned App New Window**: Fixed the "Open New Window" context menu action for pinned apps to reliably open a new window even when the application is already running.
- **Preview Reliability**: Resolved a race condition where window previews on pinned apps would sometimes appear blank or missing during rapid mouse hovers.
- **Performance Enhancement**: Dramatically reduced lag when hovering over pinned apps and opening their context menus by eliminating heavy main-thread IPC calls.

### v8.3-beta8 - July 2026
- **Sentry Integration**: Fully integrated Sentry SDK to track live crashes and performance metrics.
- **Reliable Hang Detection**: Upgraded the Watchdog Service to spawn an independent AppleScript process, guaranteeing a functional crash popup even if the main thread completely deadlocks.
- **Reduced Timeout**: Watchdog kill threshold optimized from 15s to 10s.

### v8.3-beta6 - July 2026
- **Sleep Crashes**: Fixed an issue where the app's watchdog timer would time out and crash the app when waking the Mac from sleep.
- **System Freezes**: Resolved a critical deadlock issue where the macOS WindowServer could freeze during Cmd+Tab or gesture switching when interacting with AeroBar settings due to main thread lock contention.

### v8.3-beta4 - July 2026
- **Native Crash Reporter**: Moved the crash popup to a clean native launch window instead of a background script.
- **Log Size Guard**: Crash logs are automatically truncated to fit GitHub issue size limits.
- **Event Tap Circuit Breakers**: Built-in structural defense to prevent global Mac freezes if an event tap times out repeatedly.
- **Developer Options**: Moved testing tools safely into a dedicated Developer tab in settings.
- **App Menu**: Fixed an issue where system apps inside subfolders (like Utilities) and user-specific apps were not showing up in the Start Menu app list.

### v8.3-beta3 - July 2026
- **Performance**: Under-the-hood optimizations and minor bug fixes.

### v8.3-beta2 - July 2026
- **Hover Responsiveness**: Fixed hover lag and sticky button states during Focus Mode animations.

### v8.3-beta1 - July 2026
- **OS Support**: Added experimental support for macOS Sonoma and macOS Sequoia.

### v8.2-beta10 - July 2026
- **Memory Leaks & Performance**: Fixed severe memory leaks and CPU hitches related to window tracking and clipboard thumbnail generation.

### v8.2-beta8 - July 2026
- **Display Background Dimmer**: Added a new toggle to optionally dim the wallpaper on secondary/inactive displays when they have no windows, preventing bright wallpapers from causing glare.
- **Multi-Display Focus Mode**: Completely fixed multi-monitor Focus Mode bugs where dimming panels would display at the wrong coordinates (e.g., midway down external displays) or fail to correctly trigger on hover.
- **Codebase Cleanup**: Fixed deprecated property warnings and modernized dictionary initializers.

### v8.2-beta6 - July 2026
- **Settings UI**: Restructured "Surface Tint Density" to be grouped correctly under "Liquid Tint Hue", matching the visual style of "Tint Brightness" with a dark background fill.
- **Focus Mode Improvements**:
  - Corrected the icon shading for the Search and Trash buttons to match dimmed buttons.
  - The dim tint now applies instantly upon resizing the AeroBar window.
  - Disabled the "bevel" edge effect on both the top and bottom bars while in focus mode.
  - Fixed a flickering issue that occurred when hovering over pinned apps.

### v8.2-beta4 - July 2026
- **Daemon Optimization**: Eliminated severe CPU usage and UI hitches (saving ~500ms per tick) by caching Space IPC calls and eagerly short-circuiting invisible phantom windows.
- **Memory Leaks**: Plugged continuous memory leaks caused by undocumented CGS WindowServer APIs returning +1 unmanaged CF types.
- **Screen Recording Lifecycle**: Fixed a critical leak where the screen recording session (and purple indicator dot) would remain permanently stuck on even after a live window preview popover was closed.
- **Window Tab Previews**: Resolved an issue where window tab hover previews were completely blank or unresponsive due to a race condition in state synchronization.
- **Chromium Live Previews**: Fixed a ScreenCaptureKit bug that caused live previews for Chromium browsers (Chrome, Edge, Brave, etc.) to immediately abort and fall back to static thumbnails.
- **AeroBar Ghost Previews**: Prevented AeroBar from accidentally capturing its own invisible full-screen tracking overlays when generating a live preview for itself.

### v8.2-beta3 - July 2026
- **Performance**: Resolved a critical layout/rendering loop that caused massive 40% CPU overhead whenever the Start Menu or Cmd+Tab panels were open. The glass masking is now fully processed by native AppKit CoreAnimation layers.
- **Responsiveness**: Re-architected AX accessibility hit-testing to run completely off the main thread, fixing frequent 5-second UI lockups when clicking zoom and window control buttons.
- **Stability**: Fixed a layout crash (`Invalid frame dimension`) that occurred during the initial display of the Cmd+Tab panel.

### v8.2-beta2 - July 2026
- **Trackpad Gestures Redesign**: Migrated multidirectional app cycling from 4-finger to 3-finger swipes, completely freeing up 4-finger trackpad gestures for native macOS settings (like Mission Control or fullscreen spaces).
- **No Update Interruptions**: Prevented the update check popup from showing up and interrupting when any connected display is in true fullscreen mode or when the active app window is maximized.
- **Window Positioning & Repositioning Fix**: Resolved layout coordinate bugs that caused window tabs and previews to reposition application windows slightly lower/downward on screen when pulled cross-screen or focused.
- **Customization Button Interaction**: Fixed the AeroBar customization button click target so that clicking its hover area opens the customization panel correctly (previously only clicking the raw icon did so).
- **Pinned App Icon Roundness**: Adjusted pinned app icon corners and masks to match native macOS squircle/rounded icon aesthetics.
- **Hover Jitter Lock**: Silenced physical trackpad cursor drift from interfering with the active 3-finger swipe gesture cycle highlights.

### v8.1-beta2 - July 2026
- Memory leak, lag, and battery optimizations.

### v8.1-beta - July 2026
- **Cmd+Tab & Gesture Switching Fixes** - Fixed 3–4 finger swipe gestures and window preview size clipping.
- **Liquid Design macOS Aesthetics** - Added glass vibrancy, split accent colors, and 0.5pt bevel highlights.
- **UI Stutter & Memory Leak Resolution** - Fixed memory leaks causing lag and instability.
- **Window Workspace Fixes** - Resolved fullscreen Space flicker and VLC rendering compatibility bugs.
- Added a slider for selection highlight color intensity.
- Added Active Tab Dimmer for inactive window states.
- Fixed icon padding, welcome screen gaps, and EULA boot layout.
- Moved window tracking updates to dynamic background threads.
- Added battery drain warnings for heavy CPU background loops.
- Reduced overall idle CPU utilization.
- Added a delete confirmation prompt for Clipboard History.
- Fixed bugs causing Context Menu freezes.
- Upgraded license and trial handling logic.
