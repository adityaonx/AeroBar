# System Requirements & Troubleshooting

## System Requirements

| | |
|---|---|
| **OS** | macOS Sequoia 14+ (macOS Tahoe compatible) |
| **Architecture** | Apple Silicon & Intel |
| **Permission** | Accessibility (required) |

---

## Troubleshooting

- **Emergency Exit**: If AeroBar ever freezes or misbehaves, press `Cmd+Opt+Ctrl+Shift+Q` to forcefully quit the app and safely restore your standard macOS Dock immediately.

---

## Known Limitations

- AeroBar is in **Experimental Alpha**. Expect rough edges.
- Requires Accessibility permission - without it the app cannot track or control windows.
- Self-signed build requires a one-time Gatekeeper bypass on first launch.
- Window tab ordering follows the order macOS reports running apps, not launch order.

---

## Privacy & Security

AeroBar respects your privacy and is built to be secure by design.
- **Local Data Storage**: All your personal data—including clipboard history, window layout preferences, widgets, and quick links—remains strictly offline, encrypted, and saved locally on your Mac. No user content ever leaves your machine.
- **Beta Verification & Updates**: AeroBar connects to the internet for two system checks: (1) to verify your beta license status dynamically against a lightweight Cloudflare Worker once every 24 hours, and (2) to check GitHub for new app updates.
- **Anonymous Diagnostics**: To resolve memory leaks, deadlocks, and system crashes (crucial during an experimental beta), the app uploads anonymous diagnostic telemetry via Sentry. We collect technical diagnostics (e.g. system hardware metrics, OS version, call stacks) strictly to resolve crashes, and absolutely never collect personal data, user input, or clipboard contents.
