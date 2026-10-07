# Security Policy

## Supported Versions

Security updates are provided for the current major release of AeroBar.

| Version | Supported |
| ------- | --------- |
| >= 1.0  | Yes       |
| < 1.0   | No        |

## Reporting a Vulnerability

If a security vulnerability is identified, do not open a public issue.

Report it by creating a private security advisory on GitHub, or by contacting the maintainer directly at adityaonlinux@gmail.com.

Reports will be acknowledged within 48 hours.

## Checking a download

AeroBar is not notarized by Apple, so macOS asks you to choose "Open Anyway" the first time. Before you do, check the download against the values published in the release notes of each version:

```
shasum -a 256 ~/Downloads/AeroBar-<version>.dmg
```

After you move AeroBar to Applications, you can check the app itself:

```
codesign -dvvv /Applications/AeroBar.app 2>&1 | grep CDHash
```

Both values must match the release notes. The second page of the setup wizard runs a similar check on the app and shows the same CDHash. If it finds a changed or unsigned copy, setup stops and only offers Quit. A modified app could still remove that page, so the Terminal command is the check to trust.

Updates are separate: the Update Basket only installs a DMG whose `.sig` file verifies against the public key built into the app.
