# AeroBar

### A Windows-style taskbar for macOS 

> Missed the Windows taskbar after switching to Mac? AeroBar puts it back Aero glass look, Start Menu, live window tabs, pinned app launcher, and all sitting at the bottom of your screen exactly where you expect it.

[![Download](https://img.shields.io/badge/⬇️%20Download-AeroBar%20Latest-blue?style=for-the-badge)](https://github.com/adityaonx/AeroBar/releases/latest/download/AeroBar.dmg)

If you liked this app, please consider <img width="20" height="20" alt="star-img" src="https://github.com/user-attachments/assets/14fa5920-374f-4985-acd6-d04bff1d4580" /> this project. Thanks.


## Installation


Open the `.dmg`, drag **AeroBar.app** to your `/Applications` folder.

### 2. Bypass Gatekeeper (first launch only)
AeroBar is self-signed. macOS will block the first launch.

**Option A — System Settings:**
1. Try to open AeroBar. macOS will show a security warning.
2. Go to **System Settings → Privacy & Security**.
3. Scroll down to the Security section and click **Open Anyway**.

**Option B — Terminal (if you see a "damaged app" error):**
```bash
xattr -rd com.apple.quarantine /Applications/AeroBar.app
```

### 3. Grant Accessibility Permission
AeroBar needs Accessibility access to track and control your windows.

1. On first launch, an onboarding screen will guide you.
2. Click **Open Accessibility Settings** — this takes you directly to the right panel.
3. Toggle **AeroBar** on in the list.
4. Click **Start AeroBar** in the onboarding panel.

That's it. The taskbar appears at the bottom of your screen immediately.

<hr>
1. Quick Switch between App Windows
<img width="960" height="624" alt="Gitmain-1" src="https://github.com/user-attachments/assets/33fced61-d520-46bf-8478-e262af05c88b" />
<hr>
2. Start Menu
<img width="960" height="624" alt="Gitmain-2" src="https://github.com/user-attachments/assets/0c251738-e864-4302-8de3-c56c01c92adb" />
<hr>
3. Quick Launch Pinned Apps
<img width="960" height="624" alt="Gitmain-3" src="https://github.com/user-attachments/assets/02f417a4-a3e1-42ed-a69d-fc981313a0eb" />
<hr>
4. Tab's Context menu
<img width="960" height="624" alt="Gitmain-4" src="https://github.com/user-attachments/assets/4f390c64-a2ed-4103-8956-cc26318a09ad" />
<hr>
5. Customization & Advance Settings
<img width="960" height="652" alt="gitmain-5" src="https://github.com/user-attachments/assets/ace2dd16-2770-42ac-8e5e-48a6d25abb85" />
<hr>


![Platform](https://img.shields.io/badge/macOS-Sequoia%20%2F%20Tahoe-black?style=for-the-badge&logo=apple)
![Status](https://img.shields.io/badge/Status-Experimental%20Alpha-orange?style=for-the-badge)
![Language](https://img.shields.io/badge/Swift-5.9-FA7343?style=for-the-badge&logo=swift)

---

## What is AeroBar?

macOS is a great operating system but if you spent years on Windows, the workflow transition is genuinely rough. The Dock hides, the menu bar is at the top, open windows have no persistent visual reference, and there's no Start Menu to search and launch from. You end up hunting.

**AeroBar fixes that.** It's a persistent taskbar that lives at the bottom of every display, built to feel like the Windows Vista / Windows 7 Aero taskbar translucent glass surface, a Start Orb, a live window tab strip, a pinned app launcher, and a Spotlight search field — all rendered natively on macOS using real system materials, not a skin on top.

It is not a theme. It is not a wrapper. It talks directly to macOS accessibility APIs to track, focus, minimize, and raise your windows in real time.

---

## Features

### 🪟 Liquid Glass Taskbar Rail
The taskbar itself is a persistent, borderless panel that sits at the very bottom of your screen at all times across Spaces, full-screen transitions, and display changes. It uses Apple's native vibrancy / blur materials to sample your wallpaper and produce a genuine translucent glass surface. Five distinct glass blend styles let you dial it from deep frosted to nearly transparent.

### 🔵 Aero Vista Start Orb
The circular Start Orb in the bottom-left corner is your system hub. Click it and the Start Menu opens above it, anchored to whichever display you clicked on. Light and dark hover states are supported, and the orb itself is customizable in the Appearance Lab.

### 🗂️ Live Window Tab Strip
Every open, non-minimized window across every running app appears as a tab in the taskbar in real time. Tabs show the app icon and window title. Clicking a tab:
- **Focuses** the window if it isn't active
- **Minimizes** it if it is already the front window
- **Unminimizes** it if it was minimized

This gives you the exact same one-click window switching behaviour Windows users are used to — no Exposé, no Command-Tab cycling required.

### 📌 Pinned App Launcher
A drag-and-drop tray of your favourite apps lives between the Orb and the window tabs. Pinned apps behave the way Windows taskbar icons do:
- Click to **launch** the app if it isn't running
- Click to **show / raise** all its windows if it is running
- Click again to **minimize** all its windows if it is already focused
- Right-click any open window tab to **pin that app** to the bar directly

Pinned order persists across reboots.

### 🔍 Spotlight Quick Search
A search field sits inline in the taskbar (toggleable). It fires macOS Spotlight directly type an app name, file, or calculation and press Return, exactly like the Windows search box in the taskbar.

### 🚀 Start Menu
The full Start Menu panel opens from the Orb and contains:

| Section | What it does |
|---|---|
| **User profile header** | Shows your macOS account name and avatar |
| **Search bar** | Live-filters all sections simultaneously as you type |
| **Pinned Apps grid** | Your pinned Start apps, drag-to-reorder, right-click to pin/unpin |
| **All Apps browser** | Full alphabetically grouped list of every app installed on your Mac |
| **Recommendations** | Recent files surfaced via Spotlight metadata — the things you were just working on (toggleable panel) |

### 🗑️ Recycle Bin Button
A Trash shortcut lives on the right end of the taskbar — the same position Windows users expect. Click it to open the Trash in Finder.

### 🖥️ Multi-Display Support
AeroBar can show its taskbar rail on:
- **All Displays** — every connected monitor gets its own taskbar
- **Main Screen Only** — primary display only
- **External Displays Only** — secondary monitors only

Each display's taskbar is independent. The Start Menu opens anchored to the display you clicked on.

### 🎨 Appearance Lab
Every visual aspect of the bar is tunable from the Appearance Lab popover:

| Control | Options |
|---|---|
| **Glass Blend Style** | Liquid Wallpaper (HUD), Deep Content Layer, Translucent Sidebar, High Contrast, Standard Overlay |
| **Liquid Tint Hue** | Full colour picker for the glass tint |
| **Surface Tint Density** | 0–100% opacity slider |
| **Upper Specular Bevel** | Toggles a 0.5pt highlight line along the top edge |
| **Spotlight Search Icon** | Show/hide the inline search field |
| **Window Label Collapse** | Icon-only mode — hides window title text in all tabs |
| **Display Target** | Which monitors show the bar |

All settings persist across reboots.

### ⚙️ System Settings
- **Launch at Login** — AeroBar starts automatically when you log in
- **Recommendations** — toggle the recent files panel in the Start Menu
- **Auto-update check** — checks for new builds on launch, configurable to Daily or Weekly

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
| Move a window between displays | Drag normally — AeroBar won't interfere while your mouse button is held |

---

## System Requirements

| | |
|---|---|
| **OS** | macOS Sequoia 14+ (macOS Tahoe compatible) |
| **Architecture** | Apple Silicon & Intel |
| **Permission** | Accessibility (required) |

---

## Known Limitations

- AeroBar is in **Experimental Alpha**. Expect rough edges.
- Requires Accessibility permission — without it the app cannot track or control windows.
- Self-signed build requires a one-time Gatekeeper bypass on first launch.
- Window tab ordering follows the order macOS reports running apps, not launch order.

---

## Status

> **⚠️ Experimental Alpha** — AeroBar is a personal project in active development. It interacts with macOS system-level UI via Accessibility APIs. Use it knowing that and keep backups of anything important. No warranties, no guarantees of stability.

Bug reports and feedback welcome via [GitHub Issues](https://github.com/adityaonx/AeroBar/issues).

---

## Built With

- **Swift / SwiftUI** — UI layer
- **AppKit / NSPanel** — window management and panel architecture
- **Accessibility API (AXUIElement)** — live window tracking, focus, minimize, raise
- **NSMetadataQuery / Spotlight** — recent file recommendations
- **ServiceManagement** — launch-at-login
- **Core Animation** — glass surface and visual effects

---

*Made for people who switched from Windows and know exactly where the taskbar should be.*
