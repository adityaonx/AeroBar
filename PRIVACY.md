# AeroBar – Privacy Policy

**Policy version:** 3 · **Last updated:** 6 October 2026 · Applies to AeroBar for macOS, v9.6-beta1 and later

## 1. Who we are
AeroBar is published by an individual developer, Aditya from India. We decide what data AeroBar collects and why (the "data fiduciary" under India's Digital Personal Data Protection Act, 2023, and the "controller" under the EU/UK GDPR).

**Privacy and grievance contact:** adityaonlinux@gmail.com (subject line: "AeroBar privacy"). We reply within 30 days, usually sooner.

## 2. The short version
- Your clipboard history, keystrokes, window contents, and screenshots stay on your Mac. Clipboard history is encrypted on disk.
- AeroBar has no ads and no cross-app tracking, and it does not sell data.
- The only data AeroBar sends to us is: a beta-verification code; optional usage statistics; optional crash and hang reports; and feedback you choose to write.
- Usage statistics and crash reports are **on by default**. You can turn each off in **Settings → Privacy**.
- We identify your install with a random ID, not your name or email. This is **pseudonymous**, not anonymous: the ID, combined with other information, could single out an install. We treat it as personal data.
- You can delete your usage data from our server at any time with **Delete My Usage Data & Reset ID**.

## 3. What AeroBar sends, to whom, and why

| # | What | Data | Recipient | Can you stop it? | Kept for |
|---|------|------|-----------|------------------|----------|
| a | Beta verification (beta builds) | A one-time random code | Cloudflare Worker (ours) | No. It is needed to run the beta. | Not stored by us |
| b | Usage statistics | Random install ID, app version, macOS version, update-reminder count; country (derived by Cloudflare from your IP); first-seen, last-seen, check-in count; a daily-active marker | Cloudflare Worker (ours) | Yes, "Share Usage Statistics" | 12 months after last check-in; daily markers 30 days |
| c | Crash and hang reports | Call stack, app version, macOS version, CPU type, country code, install ID, and device details that Sentry's SDK attaches by default (such as device model, memory, locale, and time zone). Home-folder names in file paths are removed. | Sentry, EU data center in Germany | Yes, "Crash & Hang Reporting" | About 90 days (Sentry's retention) |
| d | Updates | Standard web request (your IP address) | GitHub | Not while you use update checks | GitHub's own policy |
| e | Feedback (only if you press Send) | Rating, issue categories, text you type, app and build version, macOS version, install ID | Cloudflare Worker (ours) | You choose whether to send | 12 months from submission |
| f | Screen Search (only when you click it) | A screenshot of the area you select | Google Lens (lens.google.com) | Yes. Asks for consent before first use. | Google's own policy |
| g | Quick Links icons | The domain of a linked site | That site, then DuckDuckGo and Google favicon services as fallback | Do not add Quick Links | Providers' own policies |
| h | License Agreement and Privacy Policy text; Agreement version check | Standard web request (your IP address). After you have accepted, AeroBar also checks once per launch whether the published License Agreement has a newer version number. | GitHub | No | GitHub's own policy |

### Notes on the table
- **IP addresses.** Any server you contact sees your IP address. Our Cloudflare Worker reads it only to derive a two-letter country code. We do not store it, and our code does not log it. Cloudflare, as our infrastructure provider, processes requests under its own terms and may keep technical logs for security and operation; we do not enable Worker log retention. Sentry is configured not to store IP addresses.
- **Agreement check.** Once each time AeroBar starts, after you have accepted the License Agreement, it downloads LICENSE.md from GitHub to read the Agreement version number. If the number is newer, you are asked to review and accept it at the next launch. The request carries no install ID and does not depend on your statistics setting; GitHub sees the standard details of any web request, such as your IP address. If the download fails, nothing changes.
- **Beta verification and crash reports.** Verification works even if usage statistics are off, and then sends only the one-time code. Crash and hang reporting only starts after you accept the license, and stops when you turn it off.
- **What we never collect.** Clipboard contents, window titles, file names or contents, keystrokes, your name, email address, Apple ID, or hardware serial numbers. The install ID is a random value created on your Mac, not derived from your hardware.
- **Free-text feedback.** Please do not write personal information into feedback. If you do, we keep it for the same 12 months and you can delete it as described below.

## 4. Why we process this data (legal bases)
- **Beta verification:** to provide the beta and enforce its expiry. This is necessary for the service you asked for, and is in our legitimate interest in running a time-limited beta.
- **Usage statistics and crash reports:** our legitimate interest in counting active installs, finding crashes, and fixing bugs. Because the data is minimal and you can turn it off at any time, we believe this is proportionate. Where the law requires your consent (for example under India's DPDP Act), your consent is the choice you make in Settings → Privacy, and you can withdraw it there at any time.
- **Feedback and Screen Search:** your consent, given by pressing Send or by accepting the Screen Search prompt.

We do not use your data for advertising, profiling, or automated decisions about you.

## 5. Your choices and rights
- **Turn off** statistics and crash reports any time in Settings → Privacy. Turning off crash reporting stops the Sentry SDK, including session tracking.
- **Delete** your server-side usage data and feedback: Settings → Privacy → **Delete My Usage Data & Reset ID**. This removes your usage record, feedback, and daily markers from our worker, then gives your install a new random ID. If the request fails, your ID is kept so you can try again.
- **Sentry reports** are not covered by that button. To have them deleted, email us the install ID shown in the same screen from before you reset it, and we will delete the matching reports from Sentry.
- **Access, correct, or erase** other data, withdraw consent, or object: email adityaonlinux@gmail.com with your install ID. We may need the ID to find your data, because we hold no name or email for you.
- **Under the DPDP Act, 2023** you may access information about your data, correct or erase it, nominate someone to exercise your rights if you die or cannot, and have your grievance answered. If we do not resolve it, you may complain to the Data Protection Board of India.
- **Under the EU/UK GDPR** you also have the right to portability and to complain to your local supervisory authority.

## 6. Where data goes
Cloudflare runs a global network, so requests may be handled in many countries. Sentry data is stored in Germany, but Sentry's operator is a US company. GitHub and Google operate in the United States and elsewhere. We rely on these providers' standard contractual or certification-based safeguards for international transfers. By using AeroBar you understand your data may be processed outside your country.

## 7. Retention and security
Our server records expire automatically 12 months after your last check-in or submission (daily-active markers after 30 days). Feedback entries older than 12 months are removed whenever new feedback is saved, and expire with the record. Access to our dashboard is limited to the developer, protected by a secret password, and uses encrypted connections. No system is perfectly secure; if we learn of a breach that affects you, we will notify you and the authorities as the law requires.

## 8. Children
AeroBar is not directed to children, and we do not knowingly collect data from anyone under 18. If you believe a child has sent us data, contact us and we will delete it.

## 9. Changes
We will update this policy as AeroBar changes. The version and date at the top show the current policy. If a change means we collect more data or share it with a new recipient, we will say so in the release notes or in the app before it takes effect and ask for your consent again where the law requires.

## 10. Contact
adityaonlinux@gmail.com · AeroBar, India
