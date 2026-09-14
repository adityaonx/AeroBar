<p align="center">
  <img src="docs/assets/aerobar-orb-v2.svg" alt="AeroBar Logo" width="100"/>
</p>
<h3 align="center">AeroBar</h3>
<p align="center">
  <b>The Advanced Dock for macOS</b>
</p>

<p align="center">
  <a href="https://adityaonx.github.io/AeroBar/"><img src="docs/assets/website-btn.svg" alt="Website" /></a>
  <a href="https://github.com/adityaonx/AeroBar/releases/latest"><img src="docs/assets/download-btn.svg" alt="Downloads" /></a>
  <a href="https://www.youtube.com/watch?v=NY2qc3SOwXk"><img src="docs/assets/youtube_guide.svg" alt="YouTube Guide" /></a>
</p>

AeroBar brings the familiar workflow of an advanced dock directly to your Mac. It features a Liquid Glass Taskbar, Cmd+Tab integration, and a comprehensive Start Menu, all built with native macOS APIs for optimal performance.

## Documentation

- [Introduction](public_docs/Introduction.md)
- [Installation Guide](public_docs/Installation.md)
- [Features & Usage](public_docs/Features.md)
- [Troubleshooting & Limitations](public_docs/Troubleshooting.md)
- [Release Notes](public_docs/Releases.md)


## Installation

The recommended method to install AeroBar is via Homebrew:

```bash
brew tap adityaonx/aerobar https://github.com/adityaonx/AeroBar
brew trust adityaonx/aerobar
HOMEBREW_NO_QUARANTINE=1 brew install --cask aerobar
xattr -rd com.apple.quarantine /Applications/AeroBar.app
```

For manual `.dmg` download instructions, please refer to the [Installation Guide](public_docs/Installation.md).


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
## Previews

<p align="center">
  <img src="https://github.com/user-attachments/assets/33fced61-d520-46bf-8478-e262af05c88b" width="800" alt="Quick switch between app windows" />
</p>

<p align="center">
  <img src="https://github.com/user-attachments/assets/0c251738-e864-4302-8de3-c56c01c92adb" width="400" alt="Start Menu" />
  <img src="https://github.com/user-attachments/assets/02f417a4-a3e1-42ed-a69d-fc981313a0eb" width="400" alt="Pinned Apps" />
</p>

<p align="center">
  <img src="https://github.com/user-attachments/assets/4f390c64-a2ed-4103-8956-cc26318a09ad" width="400" alt="Context Menu" />
  <img src="https://github.com/user-attachments/assets/ace2dd16-2770-42ac-8e5e-48a6d25abb85" width="400" alt="Appearance Lab" />
</p>

## Community

AeroBar's development is community-driven. 

- [Discussions](https://github.com/adityaonx/AeroBar/discussions/new/choose): Share ideas, ask questions, or request features.
- [Issues](https://github.com/adityaonx/AeroBar/issues/new): Report a bug or issue.

---
