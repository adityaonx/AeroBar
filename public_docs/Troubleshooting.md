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
- **No built-in networking**: AeroBar itself does not connect to the internet. Beta codes, updates, feedback and Screen Search all happen in your web browser when you start them.
- **Beta codes and updates**: a beta build asks you to get a code from the activation page (it opens in your browser) and paste it in. Updates are downloaded from GitHub in your browser; you drop the downloaded file and its signature file into AeroBar, which checks them on your Mac before installing.
- **Diagnostics**: AeroBar keeps a short local record of recent events. It is not sent anywhere. If you report an issue, AeroBar can copy it to your clipboard for you to review and paste.
- **Install ID**: Settings -> Privacy shows a random ID stored on your Mac. It only ties a beta code to your install. See the Privacy Policy for details.
