# AeroBar – Privacy Policy

**Policy version:** 4 · **Last updated:** 7 October 2026 · Applies to AeroBar for macOS, v9.6-beta1 and later

## 1. Who we are
AeroBar is published by an individual developer, Aditya from India. We decide what personal data is handled and why (the "data fiduciary" under India's Digital Personal Data Protection Act, 2023, and the "controller" under the EU/UK GDPR).

**Privacy and grievance contact:** adityaonlinux@gmail.com (subject line: "AeroBar privacy"). We reply within 30 days, usually sooner.

## 2. The short version
- **AeroBar's own code does not connect to the internet.** It has no analytics, no crash reporter, no update checker and no feedback upload. A script that we run before pushing changes to our repository scans our source code for networking code.
- Things that need the internet (getting a beta code, downloading an update, sending feedback, Screen Search) happen **in your web browser**, when you start them. AeroBar asks you first before it opens any web or mail link, and before each Screen Search upload. The website you reach sees that request, as with any website.
- Your clipboard history, keystrokes, window contents and screenshots stay on your Mac. Clipboard history is encrypted on disk.
- AeroBar has no ads, no cross-app tracking, and does not sell data.
- AeroBar identifies your install with a random ID created on your Mac. It is used only to tie a beta code to your install.

## 3. What stays on your Mac
- **Settings, Quick Links, widgets and layouts:** stored in AeroBar's preferences and support folder.
- **Clipboard history:** stored encrypted in AeroBar's support folder. You can clear it in the app. The encryption key is worked out on your Mac from your Mac's serial number each time AeroBar runs; it is never saved to disk and never sent anywhere. This keeps the files unreadable to other apps and in backups, but it does not protect them from someone who can already run AeroBar on your Mac.
- **Install ID:** a random value stored in AeroBar's preferences. It is not derived from your hardware, serial number or Apple ID. Deleting AeroBar's preferences, or a factory reset in the app, creates a new one.
- **Beta code:** stored in the macOS Keychain, together with the latest time AeroBar has seen, so a beta code cannot be reused after it expires by setting the clock back.
- **Diagnostics:** AeroBar keeps a short local record of recent events and errors. It is never sent anywhere by AeroBar. You decide whether to share any of it (see 4d).

## 4. What happens in your browser, and who sees it
Each item below starts only when you click it. AeroBar opens your default browser; AeroBar does not send the request itself.

**a. Getting a beta code (beta builds)**
* **What is sent:** Your install ID and the release channel (beta or testing), in the address of the activation page, and the one-time request you make by pressing "Get my code"
* **Recipient:** Our activation page, run as a Cloudflare Worker
* **What comes back:** A signed code, valid for 14 days, which you paste into AeroBar. AeroBar checks it on your Mac.
* **Kept by us:** Nothing. The page keeps no database and no user list.

**b. Downloading an update**
* **What is sent:** A standard web request (your IP address)
* **Recipient:** GitHub (the AeroBar releases page). If you install with Homebrew, Homebrew downloads the same release from GitHub; Homebrew's own privacy policy and analytics settings apply to that tool, not to AeroBar.
* **What happens next:** You drop the downloaded file and its signature file into AeroBar, which checks them on your Mac before installing.
* **Kept by:** GitHub, under its own policy

**c. Screen Search**
* **What is sent:** A screenshot of the area you select
* **Recipient:** Google Lens. AeroBar saves the screenshot inside a temporary page on your Mac and opens that page in your browser, which sends it to Google.
* **Control:** After you select an area, AeroBar shows the capture and asks whether to send it to Google Lens. Nothing is written or opened if you choose Cancel. If you agree, AeroBar opens the page in your default web browser and deletes it from your Mac about two minutes later. A page left behind by a crash or quit is deleted the next time AeroBar starts.
* **Kept by:** Google, under its own policy

**d. Feedback and issue reports**
* **What is sent:** A pre-filled GitHub issue containing your rating, the categories you pick, the text you type, and the AeroBar and macOS versions. AeroBar can also copy its local diagnostics to your clipboard so you can paste them, or save a crash report zip (Settings > Diagnostics > Export Crash Report). The zip holds the local event log, AeroBar's macOS crash files and any MetricKit reports; AeroBar shows a preview and removes your account name and install ID before saving. AeroBar never sends it; you choose whether to attach it to an issue. If you prefer not to use GitHub, the same report can be opened as an email draft in your mail app, addressed to us; nothing is sent until you press Send. Please read it first.
* **Recipient:** GitHub. **Issues in the AeroBar repository are public.** Nothing is posted until you press Submit on GitHub.
* **Kept by:** GitHub, under its own policy

**e. Quick Links and Community links**
* **What is sent:** A standard web request to the site you open
* **Recipient:** That site
* **Control:** AeroBar asks once before Quick Links are used, and asks again before every other link it opens (About, Contact, GitHub, releases, activation page, feedback). Links are opened in your default web browser.
* **Note:** AeroBar does not download icons or page titles. Links show a coloured letter tile.

### Notes
- **IP addresses.** Any website you reach sees your IP address. Our activation page uses your IP address only to limit how often one address can ask for a code, through Cloudflare's rate-limit feature. We do not store it or build a list of it. Cloudflare, as our infrastructure provider, processes requests under its own terms and may keep technical logs for security and operation; we do not enable Worker log retention.
- **What we never collect.** Clipboard contents, window titles, file names or contents, keystrokes, your name, email address, Apple ID or hardware serial numbers.
- **The License Agreement and this Privacy Policy** are bundled inside AeroBar and read from disk. Whether a newer version exists is only known when you install a newer AeroBar.
- **Your Mac and other apps.** macOS itself may contact Apple (for example, to check an app's signature), and apps that AeroBar controls, such as Music or Spotify, use the internet on their own. AeroBar does not send or receive that traffic.
- **Third-party software.** AeroBar includes open-source components; their notices are under Acknowledgements in the app. None of them is used to contact a server.

## 5. Earlier versions
Builds before v9.6-beta1 could send usage statistics (install ID, app and macOS version, country), crash and hang reports (to Sentry, EU data center) and feedback (to our Cloudflare Worker). If you used one, you can ask us to delete anything we still hold: email us the install ID from before you updated, and we will delete the matching records. Reports held by Sentry are kept under Sentry's own retention rules; you can ask us to request their deletion.

## 6. Why we process this data (legal bases)
- **Beta code:** to provide the beta and enforce its expiry. This is necessary for the service you asked for and is in our legitimate interest in running a time-limited beta.
- **Feedback and Screen Search:** your consent, given when you accept the link prompt and press Submit on GitHub, or accept the Screen Search prompt that follows each capture.

We do not use your data for advertising, profiling, or automated decisions about you.

## 7. Your rights
- **Access, correct, or erase** data we hold, withdraw consent, or object: email adityaonlinux@gmail.com with your install ID. We may need the ID to find your data, because we hold no name or email for you.
- **Under the DPDP Act, 2023** you may access information about your data, correct or erase it, nominate someone to exercise your rights if you die or cannot, and have your grievance answered. If we do not resolve it, you may complain to the Data Protection Board of India.
- **Under the EU/UK GDPR** you also have the right to portability and to complain to your local supervisory authority.
- **Data in third-party services** (GitHub issues you post, anything sent to Google) is handled by those services; use their tools to delete it.

## 8. Where data goes
Cloudflare runs a global network, so requests to our activation page may be handled in many countries. GitHub and Google operate in the United States and elsewhere. They rely on their own standard safeguards for international transfers. By using these browser features you understand your request may be processed outside your country.

## 9. Security
Beta codes are signed, and AeroBar checks the signature on your Mac. Updates are checked against a signature before installation. No system is perfectly secure. If we learn of a breach that affects you, we will notify you and the authorities as the law requires.

## 10. Children
AeroBar is not directed to children, and we do not knowingly collect data from anyone under 18. If you believe a child has sent us data, contact us and we will delete it.

## 11. Changes
We will update this policy as AeroBar changes. The version and date at the top show the current policy. If a change means AeroBar handles more data or shares it with a new recipient, we will say so in the release notes or in the app before it takes effect and ask for your consent again where the law requires.

## 12. Contact
adityaonlinux@gmail.com · AeroBar, India
