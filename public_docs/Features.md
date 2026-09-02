# AeroBar Features

### Liquid Glass Taskbar & Liquid Design macOS Aesthetics
The taskbar itself is a persistent, borderless panel that sits at the very bottom of your screen at all times across Spaces, full-screen transitions, and display changes. 
- **Genuine Glass Surface**: Uses Apple's native vibrancy and blur materials to sample your wallpaper dynamically.
- **Five Glass Blend Styles**: Dial it from deep frosted to nearly transparent, featuring a 0.5pt specular bevel highlight line.
- **Liquid Tinting & Intensity Sliders**: Fully custom light/dark mode-split accent colors with fine-grained tint and selection glow intensity controls.

### Cmd+Tab Integration & Multi-Gesture Switching
AeroBar integrates directly with macOS window focus behavior:
- **Cmd+Tab & 3-4 Finger Swipe Fix**: Full support for 3-4 finger swipe gestures to switch to the last active window without losing focus or experiencing stutters.
- **Window Preview Resizing**: Hover previews scale beautifully, matching your customized window preview sizes.
- **Performance & Stability**: Prevents app updates and window switches from causing lag, keeping the interface responsive and light on system resources.

### Mac Aero Start Orb
The circular Start Orb in the bottom-left corner is your system hub. Click it and the Start Menu opens above it, anchored to whichever display you clicked on. Light and dark hover states are supported, and the orb itself is customizable in the Appearance Lab.

### Live Window Tab Strip
Every open, non-minimized window across every running app appears as a tab in the taskbar in real time. Tabs show the app icon and window title. Clicking a tab:
- **Focuses** the window if it isn't active
- **Minimizes** it if it is already the front window
- **Unminimizes** it if it was minimized

This gives you the exact same one-click window switching behaviour Windows users are used to - no Exposé, no Command-Tab cycling required.

### Pinned App Launcher
A drag-and-drop tray of your favourite apps lives between the Orb and the window tabs. Pinned apps behave the way Windows taskbar icons do:
- Click to **launch** the app if it isn't running
- Click to **show / raise** all its windows if it is running
- Click again to **minimize** all its windows if it is already focused
- Right-click any open window tab to **pin that app** to the bar directly

Pinned order persists across reboots.

### Spotlight Quick Search
A search field sits inline in the taskbar (toggleable). It fires macOS Spotlight directly - type an app name, file, or calculation and press Return, exactly like the Windows search box in the taskbar.

### Start Menu
The full Start Menu panel opens from the Orb and contains:

| Section | What it does |
|---|---|
| **User profile header** | Shows your macOS account name and avatar |
| **Search bar** | Live-filters all sections simultaneously as you type |
| **Pinned Apps grid** | Your pinned Start apps, drag-to-reorder, right-click to pin/unpin |
| **All Apps browser** | Full alphabetically grouped list of every app installed on your Mac |
| **Recommendations** | Recent files surfaced via Spotlight metadata - the things you were just working on (toggleable panel) |

### Recycle Bin Button
A Trash shortcut lives on the right end of the taskbar - the same position Windows users expect. Click it to open the Trash in Finder.

### Multi-Display Support
AeroBar can show its taskbar rail on:
- **All Displays** - every connected monitor gets its own taskbar
- **Main Screen Only** - primary display only
- **External Displays Only** - secondary monitors only

Each display's taskbar is independent. The Start Menu opens anchored to the display you clicked on.

### Appearance Lab
Every visual aspect of the bar is tunable from the Appearance Lab popover:

| Control | Options |
|---|---|
| **Glass Blend Style** | Liquid Wallpaper (HUD), Deep Content Layer, Translucent Sidebar, High Contrast, Standard Overlay |
| **Liquid Tint Hue** | Full colour picker for the glass tint |
| **Surface Tint Density** | 0–100% opacity slider |
| **Upper Specular Bevel** | Toggles a 0.5pt highlight line along the top edge |
| **Spotlight Search Icon** | Show/hide the inline search field |
| **Window Label Collapse** | Icon-only mode - hides window title text in all tabs |
| **Display Target** | Which monitors show the bar |

All settings persist across reboots.

---

## How to Use

| Action | How |
|---|---|
| Open Start Menu | Click the **blue orb** (bottom-left) |
| Switch to a window | Click its **tab** in the taskbar |
| Minimize a window | Click its **tab** again while it's focused |
| Launch a pinned app | Click its **icon** in the pinned tray |
| Pin an app to the bar | Right-click any window tab → **Pin to Bar** |
| Pin an app to Start | Right-click any window tab → **Pin to Start** |
| Search apps / files | Type in the **Spotlight field** in the bar, or use the Start Menu search |
| Open Trash | Click the **bin icon** on the right end of the bar |
| Customize appearance | Click the **Start Orb → Appearance Lab** |
| Move a window between displays | Drag normally - AeroBar won't interfere while your mouse button is held |
| Emergency Exit | Press `Cmd+Opt+Ctrl+Shift+Q` to forcefully quit AeroBar and safely restore your macOS Dock |
