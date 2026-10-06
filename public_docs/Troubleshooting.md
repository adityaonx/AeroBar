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
- **Verification and Updates**: Beta builds verify beta status with a Cloudflare Worker at launch, when the network returns, and every 2 hours while running. Update checks go to GitHub. If "Share Usage Statistics" is on in Settings -> Privacy, the verification also sends a random install ID, app version, macOS version and an update-reminder count; Cloudflare derives a country code from your IP address and only the country code is kept. If it is off, only a one-time random code is sent.
- **Diagnostics**: If "Crash & Hang Reporting" is on in Settings -> Privacy, crashes and hangs are reported to Sentry (EU region) with the call stack, app and macOS version, CPU architecture, your country code and the random install ID. No user input, clipboard data or window titles are collected.
- **Your Data**: Settings -> Privacy -> "Delete My Usage Data & Reset ID" deletes your usage record and feedback from our server. See the License Agreement, section 5, for details.
