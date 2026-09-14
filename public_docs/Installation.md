# Installation Guide

> [!NOTE]
> **Setup Requirements**
> AeroBar is distributed as a self-signed binary. Therefore, macOS Gatekeeper validation must be bypassed on the first launch, and Accessibility permissions must be explicitly granted for window tracking functionality.

### Option 1: Homebrew (Recommended)

```bash
brew tap adityaonx/aerobar https://github.com/adityaonx/AeroBar
brew trust adityaonx/aerobar
HOMEBREW_NO_QUARANTINE=1 brew install --cask aerobar
xattr -rd com.apple.quarantine /Applications/AeroBar.app
```
*(The `HOMEBREW_NO_QUARANTINE=1` environment variable prevents Gatekeeper quarantine. If omitted, proceed to Step 2 below).*

### Option 2: Manual Download

#### 1. Download AeroBar.dmg

Open the `.dmg` file and copy **AeroBar.app** into the `/Applications` directory.

#### 2. Gatekeeper Bypass (First Launch Only)

Because the application is self-signed, macOS will block the initial execution.

**Method A: System Settings**

1. Attempt to launch AeroBar. A security warning will appear.
2. Navigate to **System Settings -> Privacy & Security**.
3. Under the Security section, click **Open Anyway**.

**Method B: Terminal (For "damaged application" errors)**

```bash
xattr -rd com.apple.quarantine /Applications/AeroBar.app
```

### 3. Grant Accessibility Permission (Required)

Accessibility permissions are required to manage window states.

1. The initial setup screen will appear on first launch.
2. Click **Open Accessibility Settings** to navigate to the correct preference pane.
3. Enable the toggle for **AeroBar**.
4. Click **Start AeroBar** in the setup window to launch the application.
