<div align="center">

<sub>🟢 EXPERIMENTAL ALPHA · FREE FOR A LIMITED TIME</sub>

# The **Windows Taskbar** you missed on Mac

Aero glass look, Start Menu, live window tabs, pinned app launcher — all sitting at the bottom of your screen, exactly where you expect it.

[![Download for Mac](https://img.shields.io/badge/⬇_Download_for_Mac-0A6CFF?style=for-the-badge&logoColor=white)](https://github.com/adityaonx/AeroBar/releases/latest/download/AeroBar.dmg)
[![Website](https://img.shields.io/badge/%F0%9F%8C%90_Visit_Website-9B004D?style=for-the-badge&logoColor=white)](https://adityaonx.github.io/AeroBar/)

[see all releases](https://github.com/adityaonx/AeroBar/releases)

Free (Limited Time) · macOS Tahoe · Apple Silicon

If you liked this project, please consider giving it a <img width="20" height="20" alt="star-img" src="https://github.com/user-attachments/assets/14fa5920-374f-4985-acd6-d04bff1d4580" /> star. Thanks.

</div>

<hr>

## Screenshots
<hr>

<img width="735" height="478" alt="image" src="https://github.com/user-attachments/assets/c68cba9f-b743-42b1-87ed-f224f3163611" />

<hr>

<img width="735" height="478" alt="image" src="https://github.com/user-attachments/assets/9cdb3cbb-5e15-49f1-83f2-894f64b6780e" />

<hr>

<img width="735" height="478" alt="image" src="https://github.com/user-attachments/assets/84bac2b9-b4ed-4122-bc45-5810ede0a83e" />

<hr>

<img width="735" height="478" alt="image" src="https://github.com/user-attachments/assets/596fb09f-b4c7-4d16-ab7d-64cc07766d5f" />

<hr>


Supported: macOS Sequoia/Tahoe

</div>

---

## Table of Contents

- [Installation](#installation)
- [Screenshots](#screenshots)
- [What is AeroBar?](#what-is-aerobar)
- [Features](#features)
  - [Liquid Glass Taskbar](#liquid-glass-taskbar)
  - [Mac Aero Start Orb](#mac-aero-start-orb)
  - [Live Window Tab Strip](#live-window-tab-strip)
  - [Pinned App Launcher](#pinned-app-launcher)
  - [Spotlight Quick Search](#spotlight-quick-search)
  - [Start Menu](#start-menu)
  - [Recycle Bin Button](#recycle-bin-button)
  - [Multi-Display Support](#multi-display-support)
  - [Appearance Lab](#appearance-lab)
  - [System Settings](#system-settings)
- [How to Use](#how-to-use)
- [System Requirements](#system-requirements)
- [Known Limitations](#known-limitations)
- [Status](#status)
- [Community & Feedback](#community--feedback)
- [Built With](#built-with)

---

## Installation

> [!NOTE]
> **Why are these extra setup steps required?**
> Apple charges developers a $100/year subscription fee to sign and notarize macOS applications. To keep AeroBar completely free during our experimental alpha, we distribute it as a self-signed binary rather than paying Apple's fee. Because of this, macOS Gatekeeper flags it by default, and window tracking requires Accessibility access to interact with your workspace. Both permissions are completely safe and take less than a minute to authorize.

### 1. Download AeroBar.dmg

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

[⬆ Back to top](#aerobar)

---

## Screenshots

<div align="center">

**1. Quick Switch between App Windows**

<img width="800" alt="Quick switch between app windows" src="https://github.com/user-attachments/assets/33fced61-d520-46bf-8478-e262af05c88b" />

<br><br>

**2. Start Menu**

<img width="800" alt="Start Menu" src="https://github.com/user-attachments/assets/0c251738-e864-4302-8de3-c56c01c92adb" />

<br><br>

**3. Quick Launch Pinned Apps**

<img width="800" alt="Quick launch pinned apps" src="https://github.com/user-attachments/assets/02f417a4-a3e1-42ed-a69d-fc981313a0eb" />

<br><br>

**4. Tab's Context Menu**

<img width="800" alt="Tab context menu" src="https://github.com/user-attachments/assets/4f390c64-a2ed-4103-8956-cc26318a09ad" />

<br><br>

**5. Customization & Advanced Settings**

<img width="800" alt="Customization and advanced settings" src="https://github.com/user-attachments/assets/ace2dd16-2770-42ac-8e5e-48a6d25abb85" />

</div>

[⬆ Back to top](#aerobar)

---

## What is AeroBar?

macOS is a great operating system but if you spent years on Windows, the workflow transition is genuinely rough. The Dock hides, the menu bar is at the top, open windows have no persistent visual reference, and there's no Start Menu to search and launch from. You end up hunting.

**AeroBar fixes that.** It's a persistent taskbar that lives at the bottom of every display, built to feel like the Windows Vista / Windows 7 Aero taskbar — translucent glass surface, a Start Orb, a live window tab strip, a pinned app launcher, and a Spotlight search field — all rendered natively on macOS using real system materials, not a skin on top.

It is not a theme. It is not a wrapper. It talks directly to macOS accessibility APIs to track, focus, minimize, and raise your windows in real time.

[⬆ Back to top](#aerobar)

---

## Features

### Liquid Glass Taskbar & Liquid Design macOS Aesthetics
The taskbar itself is a persistent, borderless panel that sits at the very bottom of your screen at all times across Spaces, full-screen transitions, and display changes. 
- **Genuine Glass Surface**: Uses Apple's native vibrancy and blur materials to sample your wallpaper dynamically.
- **Five Glass Blend Styles**: Dial it from deep frosted to nearly transparent, featuring a 0.5pt specular bevel highlight line.
- **Liquid Tinting & Intensity Sliders**: Fully custom light/dark mode-split accent colors with fine-grained tint and selection glow intensity controls.

### Cmd+Tab Integration & Multi-Gesture Switching
AeroBar integrates directly with macOS window focus behavior:
- **Cmd+Tab & 3-4 Finger Swipe Fix**: Full support for 3-4 finger swipe gestures to switch to the last active window without losing focus or experiencing stutters.
- **Window Preview Resizing**: Hover previews scale beautifully, matching your customized window preview sizes.
- **Memory Leak & Stutter Mitigation**: High-efficiency Swift 6 background concurrency guarantees that webpage updates and window list refreshes never leak memory or cause UI microhangs.

### Mac Aero Start Orb
The circular Start Orb in the bottom-left corner is your system hub. Click it and the Start Menu opens above it, anchored to whichever display you clicked on. Light and dark hover states are supported, and the orb itself is customizable in the Appearance Lab.

### Live Window Tab Strip
Every open, non-minimized window across every running app appears as a tab in the taskbar in real time. Tabs show the app icon and window title. Clicking a tab:
- **Focuses** the window if it isn't active
- **Minimizes** it if it is already the front window
- **Unminimizes** it if it was minimized

This gives you the exact same one-click window switching behaviour Windows users are used to — no Exposé, no Command-Tab cycling required.

### Pinned App Launcher
A drag-and-drop tray of your favourite apps lives between the Orb and the window tabs. Pinned apps behave the way Windows taskbar icons do:
- Click to **launch** the app if it isn't running
- Click to **show / raise** all its windows if it is running
- Click again to **minimize** all its windows if it is already focused
- Right-click any open window tab to **pin that app** to the bar directly

Pinned order persists across reboots.

### Spotlight Quick Search
A search field sits inline in the taskbar (toggleable). It fires macOS Spotlight directly — type an app name, file, or calculation and press Return, exactly like the Windows search box in the taskbar.

### Start Menu
The full Start Menu panel opens from the Orb and contains:

| Section | What it does |
|---|---|
| **User profile header** | Shows your macOS account name and avatar |
| **Search bar** | Live-filters all sections simultaneously as you type |
| **Pinned Apps grid** | Your pinned Start apps, drag-to-reorder, right-click to pin/unpin |
| **All Apps browser** | Full alphabetically grouped list of every app installed on your Mac |
| **Recommendations** | Recent files surfaced via Spotlight metadata — the things you were just working on (toggleable panel) |

### Recycle Bin Button
A Trash shortcut lives on the right end of the taskbar — the same position Windows users expect. Click it to open the Trash in Finder.

### Multi-Display Support
AeroBar can show its taskbar rail on:
- **All Displays** — every connected monitor gets its own taskbar
- **Main Screen Only** — primary display only
- **External Displays Only** — secondary monitors only

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
| **Window Label Collapse** | Icon-only mode — hides window title text in all tabs |
| **Display Target** | Which monitors show the bar |

All settings persist across reboots.

### System Settings
- **Launch at Login** — AeroBar starts automatically when you log in
- **Recommendations** — toggle the recent files panel in the Start Menu
- **Auto-update check** — checks for new builds on launch, configurable to Daily or Weekly

[⬆ Back to top](#aerobar)

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

[⬆ Back to top](#aerobar)

---

## System Requirements

| | |
|---|---|
| **OS** | macOS Sequoia 14+ (macOS Tahoe compatible) |
| **Architecture** | Apple Silicon & Intel |
| **Permission** | Accessibility (required) |

[⬆ Back to top](#aerobar)

---

## Known Limitations

- AeroBar is in **Experimental Alpha**. Expect rough edges.
- Requires Accessibility permission — without it the app cannot track or control windows.
- Self-signed build requires a one-time Gatekeeper bypass on first launch.
- Window tab ordering follows the order macOS reports running apps, not launch order.

[⬆ Back to top](#aerobar)

---

## Status & Licensing

AeroBar is in **Active Development** with a hyper-focus on performance and native macOS integration.

### Monetization (Upcoming)
As AeroBar stabilizes towards a 1.0 release, the monetization strategy will be:
- **Free Trial**: Users will get unrestricted access to the app for a set period (e.g., 7 or 14 days) to fully experience the workflow.
- **One-Time Pro Unlock**: After the trial, users can purchase a one-time perpetual license to unlock the full "Pro" feature set (including advanced theming, unlimited pinned apps, multi-display controls, and clipboard managers). There will be **no subscriptions**.

[⬆ Back to top](#aerobar)

---

## Community & Feedback

Have a feature request, a bug report, or just want to share your AeroBar setup? We use **GitHub Discussions** to keep the roadmap transparent and community-driven.

- **[Start a Discussion](https://github.com/adityaonx/AeroBar/discussions/new/choose)** — Use this for general questions, feedback, or sharing your ideas.
- **[Report a Bug](https://github.com/adityaonx/AeroBar/issues/new)** — Use the issue tracker for technical bugs (please include your macOS version and logs if possible).

[⬆ Back to top](#aerobar)


### Built With
- **AI Pair Programming** — Accelerated and profiled using Google DeepMind's AntiGravity (AGY) agentic coding system.

[⬆ Back to top](#aerobar)

---

<div align="center">

*Made for people who switched from Windows and know exactly where the taskbar should be.*

</div>
