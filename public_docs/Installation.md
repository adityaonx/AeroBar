# Installation Guide

> [!NOTE]
> **Why are these extra setup steps required?**
> Apple charges developers a $100/year subscription fee to sign and notarize macOS applications. To keep AeroBar completely free during our experimental alpha, we distribute it as a self-signed binary rather than paying Apple's fee. Because of this, macOS Gatekeeper flags it by default, and window tracking requires Accessibility access to interact with your workspace. Both permissions are completely safe and take less than a minute to authorize.

### Option 1: Homebrew (Recommended)

```bash
brew tap adityaonx/aerobar https://github.com/adityaonx/AeroBar
brew trust adityaonx/aerobar
HOMEBREW_NO_QUARANTINE=1 brew install --cask aerobar
xattr -rd com.apple.quarantine /Applications/AeroBar.app
```
*(The `HOMEBREW_NO_QUARANTINE=1` env var bypasses macOS Gatekeeper for this self-signed app. If you omit it, you will need to follow Step 2 below).*

### Option 2: Manual Download

#### 1. Download AeroBar.dmg

Open the `.dmg`, drag **AeroBar.app** to your `/Applications` folder.

#### 2. Bypass Gatekeeper (first launch only)

AeroBar is self-signed. macOS will block the first launch.

**Option A - System Settings:**

1. Try to open AeroBar. macOS will show a security warning.
2. Go to **System Settings → Privacy & Security**.
3. Scroll down to the Security section and click **Open Anyway**.

**Option B - Terminal (if you see a "damaged app" error):**

```bash
xattr -rd com.apple.quarantine /Applications/AeroBar.app
```

### 3. Grant Accessibility Permission (Required for all installation methods)

AeroBar needs Accessibility access to track and control your windows.

1. On first launch, an onboarding screen will guide you.
2. Click **Open Accessibility Settings** - this takes you directly to the right panel.
3. Toggle **AeroBar** on in the list.
4. Click **Start AeroBar** in the onboarding panel.

That's it. The taskbar appears at the bottom of your screen immediately.
