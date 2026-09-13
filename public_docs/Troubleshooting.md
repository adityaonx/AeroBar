# System Requirements & Troubleshooting

## System Requirements

| Requirement | Details |
|---|---|
| OS | macOS Sequoia 14 or higher (macOS Tahoe compatible) |
| Architecture | Apple Silicon or Intel |
| Permissions | Accessibility (required) |

## Troubleshooting

- **Emergency Exit**: If AeroBar freezes or becomes unresponsive, press `Cmd+Opt+Ctrl+Shift+Q` to forcefully quit the application and restore the macOS Dock.

## Known Limitations

- AeroBar is in experimental alpha.
- Accessibility permission is strictly required for window tracking and control.
- The self-signed application requires a one-time Gatekeeper bypass during the first launch.
- Window tab ordering follows the order reported by macOS, rather than launch order.

## Privacy & Security

- **Local Data Storage**: All data, including clipboard history, window layout preferences, widgets, and quick links, is stored locally on the device. User content is not transmitted.
- **Verification and Updates**: The application connects to the internet to verify beta license status via Cloudflare once every 24 hours, and to check for software updates via GitHub.
- **Diagnostics**: Anonymous diagnostic telemetry is collected via Sentry to identify crashes and system deadlocks. This includes hardware metrics, OS version, and call stacks. No user input or clipboard data is collected.
