# Release Notes

## v9.6-beta3 - October 2026
**The Customization & Clipboard Update**

This beta adds encrypted Clipboard Backup, a stronger install and update safety net, a fix for the empty strip the macOS Dock leaves behind, much better macOS Dock + Extensions support, and a long list of fixes for the Aero Menu, the Music Widget and Top placement.

✨ **What's New & Improved**

**Encrypted Clipboard Backup**
- **Back up your Clipboard History:** Protect your history with a password. Backups are encrypted on your Mac and saved in a folder you choose. Each run is incremental, so only new items are added.
- **Save-your-password step:** Setup gives you a recovery key and makes you confirm you have saved both before the first backup. AeroBar cannot recover a backup if you lose the password and the recovery key.
- **Restore what you want:** Open a backup, choose what comes back, preview it, then restore.
- **Easy to find:** The Clipboard History header now has a "Backup & Restore" button that opens the backup card in the Customizer, with a one-time intro for existing users. Backups run when you press Back Up Now. There is no automatic schedule yet.

**Install & Update Safety**
- **Updates only through the Update Basket:** Dragging an app of another version into Applications no longer bypasses the signature, hash and no-downgrade checks.
- **Signature check at every launch:** A modified, unsigned or re-signed copy of AeroBar does not run. After one, the next genuine copy resets settings once, keeps your Clipboard History and backup, and takes you back through setup and the beta code.
- **Exact-build check:** The running build must be the one the Update Basket verified, so a different build of the same version does not run.
- **Safer install details:** The install ID and trial start are kept in the Keychain with a second copy, and Customizer > General shows the accepted version and how it was installed.
- **Homebrew:** `brew install --cask aerobar` now downloads the real release and checks it. AeroBar still updates through the Update Basket, so `brew upgrade` leaves it alone.
- **Warnings stay in front:** Alerts, consent questions and Open and Save panels now appear above every window, including the bar.
- **Feedback links ask first:** The Discussions and star links in Feedback now ask before opening your browser, like every other link.

**macOS Dock + Extensions**
- **Empty strip gone:** AeroBar now clears the empty strip macOS leaves where the Dock was. Customizer > Layout > Dock Gap Fix has two switches: "Refresh Dock space with System Settings" (on by default; System Settings opens in the background and closes at once) and "Show the Dock briefly before AeroBar takes over" (on by default).
- **Same previews as the bar:** Dock hover previews now use the same window preview as the taskbar, Pinned Apps tray and Cmd-Tab. Multi-Window Stacking, Show Close Buttons and Add New Window Button are available in this mode too.
- **Auto-hide Dock:** Hover previews now work when the Dock is set to auto-hide, appear sooner, and the Dock indicators slide in and out with the Dock.
- **Settings carry over:** The Window Previews setting stays as you set it when you switch between the AeroBar and macOS Dock engines.
- **Indicators:** The AeroBar engine now has an Indicators category, and Pinned App Indicator Style has moved to Indicators > Indicator Style.

**Music Widget**
- **Any music web app:** Add YouTube, YouTube Music, Gaana, Wynk, JioSaavn or any other music web app under Customizer > Extensions > Support Music Apps. The "+" next to the tabs takes you there.
- **Tabs:** The tab strip also shows with a single source, and a tab name is saved when you click away.
- **Same card in both engines:** The macOS Dock engine now has the full Music Widget settings, the same shadow and corner radius as the bar, and a more compact card. The card is no longer cut off at the top and bottom.

**Aero Menu, Pinned Apps & Top Placement**
- **Unpin Finder:** Finder can be unpinned and reordered in the Aero Menu and in AeroBar's pinned apps. Start Menu defaults are added only once, so an unpinned System Settings no longer returns after a restart.
- **Apps reopen properly:** Clicking a pinned or unpinned app icon brings back its main window, even if only a child window (such as a mail draft) was open.
- **Inner Glow Line:** The Aero Menu is 4 pt taller, so the Inner Glow Line shows along the top and bottom edges.
- **Top placement:** The Tasks panel opens on hover and closes when the pointer leaves. With stacked displays, the cursor no longer jumps to the upper display's top edge. The Mission Control button now shows in Top Dock mode, between the pinned and unpinned apps.

**Defaults & Polish**
- **Hover panels:** Open Panels on Hover is on for everyone, with a Hover Delay slider and a one-time tip.
- **Borders:** Custom Border Tint and the Inner Glow Line are on by default (#990AFF, 27%, 100%) and stay on after resets. Border settings are also shown in the macOS Dock engine.
- **Surface Tint:** Density 100% and Brightness 0% by default, for new and existing users, in both engines.
- **Setup window:** The glass in the onboarding window now follows the system window corners.

**Beta Codes**
- **Shorter validity:** A beta code is now valid for 7 days (was 14). The code page is protected by Cloudflare Turnstile.

*Plus smaller fixes under the hood.*

---

## v9.6-beta1 - October 2026
**The Glass & Polish Update!**

We've been hard at work bringing AeroBar's signature aesthetic to every corner of the app, alongside some massive under-the-hood polish.

✨ **What's New & Improved**
- **Beautiful Glass Setup**: The entire setup wizard and gesture guides have been completely redesigned. They now feature our gorgeous, signature translucent glass material, perfectly blending with macOS's native window controls and rounded corners.
- **Unified Customizer**: We are saying goodbye to the old settings popover! Settings now live in the modern Customizer under a brand new "General" tab.
- **Simpler Privacy Onboarding**: The onboarding flow is shorter, with one agreement checkbox and the same wording in every region.
- **Readable Documents**: The in-app License and Privacy Policy sheets now render with beautiful, proper formatting instead of a giant wall of text.
- **AeroBar Stays Offline**: AeroBar no longer connects to the internet itself. There is no crash service, no usage statistics, no update check and no feedback upload. Things that need the web open in your browser.
- **Beta Codes**: Beta builds ask for an activation code tied to your install. Get Code opens a page in your browser; paste the code back in. AeroBar checks it on your Mac.
- **Update Basket**: AeroBar reminds you about once a week. Download the .dmg and its .sig file from the release page, drop both in the basket, and AeroBar checks the signature and version before installing.
- **Feedback Without Upload**: Submit opens a pre-filled GitHub issue, or an email draft if you prefer. Diagnostics are copied for you to paste. Nothing is sent by AeroBar.
- **Local Crash Reports**: Export a crash report as a zip you can read first. Your account name and install ID are removed. Nothing is sent.
- **Letter Tiles for Quick Links**: Quick Links show coloured letter tiles instead of downloading site icons.
- **Updated License and Privacy Policy**: Agreement version 4 and a rewritten Privacy Policy, both bundled in the app. You will be asked to accept the new Agreement once.

Dive into the new Customizer and enjoy the glass!


### v9.5-beta9 - October 2026
- **Smarter Setup From Start to Finish**: Setup now picks up where it left off after the Screen Recording restart. Glass only appears once you choose a placement, and the pages for size, glass, panels and hotkeys are clearer and easier to follow.
- **One App Switcher Switch**: One App Switcher switch turns on Cmd+Tab, with Classic or Smart style right below it. It replaces the old Replace macOS Cmd+Tab and Enable Cmd+Tab rows, and the Cmd+Tab card under Options is gone.
- **Send Feedback**: New feedback card to rate AeroBar, report an issue or share an idea. It shows up once per version, a little after an update or your first setup, and any time from **Customizer > General > About > Send Feedback**. Not now simply closes it.
- **Fixed: Music Widget With Web Apps**: The music widget now finds YouTube and YouTube Music web apps, even if you renamed them. This works for web apps made in Safari or a Chromium browser.
- **Window Tabs and Badges Get Their Own Sections**: In the AeroBar engine, the Customizer sidebar now has **Window Tabs** and **Badges**. Tabs, tab indicator style, uniform tab width, collapse labels, selection color and app visibility moved to Window Tabs, and the badge cards moved to Badges. Each section has its own Reset.
- **Two App Lists, Not One**: The tab strip and the App Switcher each have their own App Visibility list on their own page, and each Reset clears only its list.
- **⌘ Key Taps Always Available**: **Lone Cmd for Search** and **Double-Tap Cmd for App Menu** now live in **Shortcuts > ⌘ Key Taps** and show even when the App Switcher is off. Double-Tap is for the AeroBar engine only.
- **App Switcher and Swipe Need Window Previews**: Cmd+Tab and Swipe to Switch now work only while Window Previews are on, because both open previews. With previews off, macOS keeps them and a hint row takes you to the switch. Your saved choices are kept.
- **Search Takes You There**: Jumping from search now opens the right tab and flashes the header so you can see where you landed. Recent searches no longer list settings that do not exist in your current mode.
- **Pick Your Switcher in Setup**: The Hotkeys page lets you choose Classic or Smart with animated tiles, and its switches match the Customizer.
- **Trackpad Guide Beside System Settings**: In setup, the trackpad step opens a guide panel instead of moving the wizard, and it only asks while Window Previews are on.
- **Cleaner Glass in Setup**: No glass shows until you pick a placement. The menu bar glass appears on the AuraBar page, which the macOS Dock engine now gets too when the menu bar background is already off. Setup steps sit behind System Settings while the menu bar guide is open.
- **Bar Size Preview**: The size page shows a live preview with Compact, Default and Custom (Pro). Compact is now 46 pt, up from 30 pt, and 30 pt is still there under Custom.
- **Dock Glass Colors in Setup**: The Dock Glass step has a brightness slider and a custom color picker.
- **Brightness Sliders Stay Neutral**: 50% keeps your color as chosen, lower darkens it and higher lightens it. Moving the color no longer resets brightness.
- **Panels on Hover and Glass on Desktop in Setup**: The Previews page has **Open Panels on Hover** with an animated preview. The Bar Glass page has **Only when a window is maximized**, the same switch as **Layout > Glass on Desktop**.
- **Window Tabs Where They Exist**: Setup offers Active window only in layouts that have window tabs. In Dock layout, Window Tabs now tells you tabs are not shown there and takes you to **Layout > Mode** to pick Taskbar or Custom.
- **Run Setup Again**: A new row at the top of the Customizer sidebar reopens setup.
- **Clear a Leftover Dock Gap**: **Customizer > Troubleshoot > Fixes** has a new card, **App window not repositioned correctly?**. It re-applies AeroBar's Dock layout and restarts the Dock to clear a gap where the Dock used to be. AeroBar engine only.
- **Fixed: App Color Reset**: App color sliders no longer mark an app as overridden by themselves, and Reset works with one click.
- **Release Notes of Your Version**: **Customizer > General > Updates** shows the notes of the version you are running, collapsed until you open it.
- **GitHub Opens in Front**: When the feedback card opens GitHub, the Customizer steps behind your browser. After you tap the star row, a small guide points at the Star button.

### v9.5-beta8 - October 2026
- **Clipboard History, Rebuilt List**: The clipboard panel's list is now a native, reusable list, so it stays smooth with a long history. Your history, pins and labels are untouched.
- **Pin, Delete and Close Buttons**: Hover a clipboard row to pin or delete it with one click. The panel header has a close button, and the Pinned tab now tells you how to pin (hover and click the pin, or press Cmd+P).
- **Clipboard Keyboard Shortcuts**: Up and Down move through items, Return pastes, Space previews, Cmd+S saves, Cmd+L sets a label, Cmd+P pins, Cmd+Delete deletes and Cmd+1 to 9 pastes the numbered row. Option+Return, or Option-click, pastes and keeps the panel open. A hint line under the list shows them. Space only previews while the search field is empty.
- **Pin the Clipboard Panel on Top**: A header switch keeps the panel open when you click elsewhere or open another bar panel. Esc, the close button and the hotkey still close it. It turns off again each time you open the panel.
- **Move the Clipboard Panel**: Drag the header to move it. The macOS Dock engine remembers the position. Right-click the header and choose **Reset Panel Position** to go back to the default spot. The bar engine's panel now also takes keyboard input once you click it.
- **Swipe to Switch Works Again**: The switch and the sensitivity slider now reach the gesture service, so turning it off really turns it off. The unused Four-Finger Swipe row is gone.
- **Trackpad Gestures Section**: Swipe to Switch has its own **Trackpad Gestures** category in the Customizer. It is off by default on a new install, and AeroBar only asks you to change macOS trackpad settings after you turn it on. Existing installs keep their current choice.
- **Fewer, Clearer Setup Pages**: Setup now has one window size for every page and two-column feature pages. Window Previews, Click to Minimize, Cmd+Tab and Swipe to Switch share one page. A new Hotkeys page covers Cmd+Tab, Lone Cmd and Double-Tap Cmd. The Accessibility page is skipped when it is already on, and the "Accessibility is on" page is gone.
- **Screen Recording Asked When You Need It**: Setup asks for Screen Recording only after you turn Window Previews on, with a live status and a guide window that sits beside System Settings. Window Previews and Cmd+Tab start off for a new user. The Screen Recording, Accessibility and Automation guides now share one layout.
- **Authorize Card on the Dock**: In the macOS Dock engine, hovering an app icon without Screen Recording shows an Authorize card instead of nothing. A click on it starts the permission guide.
- **Menu Bar Icon Always On in the Dock Engine**: The tray icon always shows in the macOS Dock engine, since it is the way into Settings. Opening AeroBar again while it runs opens Settings.
- **Tab Titles Dim With App Icons**: **Dim App Icons** now also fades window tab titles. Hover brings them back.
- **Fixed: Dock Click Minimize**: Clicking a Dock icon no longer minimizes a window that is still coming back, and a window the Dock just restored is not sent away again. Quick double-clicks and slow system reads are handled.
- **Fixed: Event Tap Retries**: AeroBar stops retrying a failed keyboard and mouse hook after a few attempts, so the "control this Mac" prompt no longer reappears.
- **Fixed: Ghost Finder Window**: A closed Finder window no longer lingers in the bar or the Cmd+Tab switcher as a blank "Recents" tab.
- **Show Apps With No Windows**: New switch under **Customizer > App Switcher**. It is off by default, so Cmd+Tab lists only apps that have a window. Turn it on to also list running apps with every window closed, such as Finder.

### v9.5-beta7 - October 2026
- **Windows Sit Flush Against the Bar**: The small gap between app windows and AeroBar is gone, on every side of the screen.
- **Auto Reposition App Windows**: New switch under **Customizer > Troubleshoot > Fixes**. It is on by default and keeps app windows clear of the bar. Turn it off if windows jump, resize or fight with AeroBar, and AeroBar will never move or resize a window.
- **Windows Stay Clear of the Bar**: A window that overlaps the bar is moved away from it, the way the Dock does it. If an app keeps putting its window back, AeroBar tries a few times and then leaves it alone instead of fighting.
- **Green Button and Title Bar Double-Click**: These now fill the space beside the bar, and the next click puts the window back to its earlier size. This works in the AeroBar engine.
- **Bar Moved to Another Edge**: When you move the bar to another edge, your windows reflow once into the space it left and move out of the new bar's way.
- **macOS Dock Engine Left Alone**: AeroBar does not move or resize windows when the macOS Dock engine is on.
- **Cleaner Release Builds**: Removed leftover debug logging from the released app, including temporary files it used to write.

### v9.5-beta6 - October 2026
- **No Glass on a Bare Desktop**: The menu bar glass and the bar or Dock glass now disappear when no window is maximized, and come back when you maximize one. This works in every mode: the macOS Dock engine and all AeroBar layouts and placements. Focus Mode and the Display Background Dimmer no longer change it.
- **Only When a Window Is Maximized**: This switch now covers the AeroBar engine too, and it is on by default. Find it under **Layout** (in AeroBar mode as **Glass on Desktop**, in the macOS Dock engine in **Dock Glass**), and in the **Bar** tab of the menu bar popover. Turn it off to keep the glass showing all the time.
- **Fixed: Menu Bar Glass on the Desktop**: In the macOS Dock engine the menu bar glass used to stay on a bare desktop even though the Dock glass left. It now leaves with it.
- **Always Available in the Dock Engine**: The switch no longer hides when Glass Behind the Dock is off, because it also controls the menu bar glass.
- **Resets Turn It Back On**: Its Reset, the Appearance Reset and the full resets all put it back on.

### v9.5-beta5 - October 2026
- **Dim App Icons**: New option that grays out just your app icons while the wallpaper is dimmed, and leaves the bar or Dock glass as it is. Find it under **Displays** or in the menu bar popover.
- **Dock Dim That Keeps Up**: In the macOS Dock engine, the dim now follows your Dock when apps open, quit or hide, so the icons never look out of step.
- **Focus Mode Fits the Glass**: Focus Mode's dim now follows the same rounded outline as the AeroBar glass, so the corners dim too.
- **Fixed: Closed Window Tabs**: A window's tab now disappears right after you close the window, instead of hanging around for a few seconds.
- **Dim Everything Together**: Dim App Icons also covers the bar's buttons, search field and dividers. On the Dock it dims the open-app dots, the AeroBar marks and the Trash. The icon you hover lights up, and so does its mark.
- **Fixed: Cmd+Tab Windows**: Cmd+Tab now shows window previews and can bring back a minimized window in the macOS Dock engine. It skips windows you just closed.
- **Cmd+Tab Opens Windowless Apps**: Switching to an app with no open window now reopens it, the way a Dock click does.
- **Lighter on Memory**: The Dock glass and indicator panels are now fully released when they are rebuilt, so they no longer pile up in the background.
- **Shorter Waits**: The Dock dim now catches up in a fraction of a second after an app launches or quits.
- **Better Close Detection**: AeroBar spots closed windows from Cmd+W, from a window disappearing, and from focus moving to another window, and does nothing extra while you simply switch between windows.

### v9.5-beta4 - October 2026
- **Resets Do What They Say**: **Reset All** now asks you to confirm, then runs the full reset and restarts AeroBar, and each section's Reset covers everything in that section. Your pinned apps, clipboard history, quick links and permissions are kept.
- **Fixed: Crash in Setup**: Fixed AeroBar closing when you dragged the Brightness slider on the Bar Glass setup page. The Strength slider, the Dynamic boost slider and the tint swatches on the Bar Glass and Dock Glass pages are protected the same way.
- **Setup Shows Once**: The setup pages now appear once after an update and never again. Finishing setup no longer brings Choose Mode back on the next launch, and the reset options keep this choice.
- **Appearance Reset Restores AuraBar**: Appearance > Reset now puts AuraBar's corners, bevel, follow, dynamic and intensity back to their defaults instead of only switching it off. AuraBar stays off when the bar is at the top or the macOS menu bar background is on.
- **Glass Above the Dock**: In the AeroBar engine, the bar's glass is now drawn above the real Dock, so the Dock no longer shows through it in Mission Control.
- **Reset Details**: Layout also resets centered vertical items. Appearance resets both the light and the dark values. Extensions resets the Recycle Bin, Show Desktop and Mission Control icons, the music widget, hover-to-open and the clipboard limits. Windows resets uniform tab width, the tab and pinned indicator styles and the active tab dimmer. Displays resets the dimmer opacity, "only when empty" and show on external displays.
- **Total Factory Reset**: Now also removes AeroBar's Accessibility permission, deletes your quick links, turns off launch at login and clears caches, so the setup guide shows again.
- **Reset Descriptions**: The three options in Reset now say exactly what they keep and what they clear. Dry Wipe says it keeps quick links, and Reset Settings & Cache also clears the icon cache and downloaded release images.

### v9.5-beta3.0 - October 2026
- **Choose Your Mode**: AeroBar now offers two ways to work. **macOS Dock + Extensions** keeps the real Dock and adds features around it, and **AeroBar** uses AeroBar's own bar (AeroDock, AeroTaskBar or Legacy AeroBar). Pick one during setup, or switch any time in **Layout > Mode > Engine**. Switching to the macOS Dock asks you to confirm first.
- **Smart App Switcher**: Press ⌘Tab to move between apps and ⌘` to move between the windows of the selected app, with live window previews above the app row. Choose the Large icons or Window previews layout, pick a preview size (Extra large is the default), hide the labels with Minimal previews, and list apps where the switcher should step aside. Find it under **Customizer > App Switcher**. Each card has its own Reset.
- **New Setup Experience**: The setup window is larger and sized per page, the license agreement is a single line, and the feature pages have expandable cards with animated previews of each mode. Permissions now come on the second page, and the setup after Choose Your Mode follows the mode you picked. If you already use AeroBar, the new setup pages are shown once after you update, and you can close them at any time.
- **No More Input Monitoring**: AeroBar no longer asks for Input Monitoring. The ⌘Q warning, ⌘W warning and Cmd+Tab switcher only need Accessibility.
- **Glass Behind the Dock**: In the macOS Dock engine, the Dock gets the same blur and tint as AeroBar's glass. It can show only while a window is maximized, so a bare desktop stays clean.
- **Dock Hover Previews**: Hover an app in the Dock to see cards for its open windows, and click one to bring it forward.
- **Window Indicators**: A mark under each Dock app that has open windows. Choose the style and thickness.
- **Click to Minimize**: Click the front app's Dock icon to minimize its windows, and click again to restore them.
- **Focus Mode on the Dock**: Focus Mode now dims the Dock's icons, except the one you are hovering, along with the wallpaper.
- **Music Widget**: Hover a music app in the Dock to see its now-playing widget.
- **Clipboard History Without the Bar**: Clipboard History opens from its shortcut or the menu bar popover in the macOS Dock engine, with no AeroBar needed on screen.
- **Customizer Matches Your Mode**: The Customizer hides settings that only apply to AeroBar's own bar while the macOS Dock engine is on, and adds **Dock Glass**, **Indicators** and **Interactions** under Layout. Each Dock section has its own Reset. Search only shows settings that exist in your current mode.
- **Wording That Fits Your Mode**: Focus Mode and Opaque Dock descriptions, and the list of shortcuts, now match the engine you are using.
- **Menu Bar Popover**: In the macOS Dock engine the first tab becomes **Dock**, with switches for glass, previews, indicators and click to minimize. Links to settings that do not exist in that mode are hidden.
- **Safe Fallback**: If AeroBar closes unexpectedly while starting the macOS Dock engine, the next launch switches back to the AeroBar engine and tells you.
- **Welcome Tour**: Added **Options > Welcome Tour > Show Welcome Tour Again** to reopen Choose Your Mode and the setup pages.
- **Matching Glass**: In both modes the menu bar and the Dock now share one glass outline, drawn as a single L-shaped panel like GlassDock, with the same blur and tint in Follow and Custom. Nothing is drawn behind the menu bar when the bar is at the top.
- **Window Indicator Colour**: Pick your own colour for the marks under Dock apps, or leave it on the selection colour. Window Indicators now has its own Customizer section with an Accessibility status row.
- **One Switch for Your Mode**: **Show AeroBar** in the menu bar popover and the Engine setting in Layout are now the same switch. Turning AeroBar off gives you the macOS Dock engine and your own Dock settings back.
- **Safer Dock Settings**: AeroBar now keeps one backup of your own Dock settings and puts them back when you switch to the macOS Dock engine, turn Show AeroBar off or quit. If AeroBar closes unexpectedly while it had changed your Dock, the next launch restores it. Added support for the Dock's position and size on macOS 27.
- **Dock Features Survive a Dock Restart**: Window indicators and Dock hover previews now come back by themselves when the Dock restarts, for example after you change the bar's position.
- **Customizer Sections**: Added **General**, **Mac Window**, **Troubleshoot** and **Reset** to the Customizer, so the old Settings popover is no longer needed. The Mac Window scope list now has proper padding and the "All apps | Only listed apps" picker no longer overflows.
- **Release Cards**: The update window and the post-update panel now show short feature cards for what is new in each release.
- **Fixed: Enable Cmd+Tab**: The Enable Cmd+Tab switch and the excluded apps list now really reach the switcher. If you had turned Enable Cmd+Tab off, you now get the macOS switcher, as you asked.
- **Fixed: ⌘Q and ⌘W Warnings**: Fixed a crash that could happen when a warning appeared, caused by the warning panel being built on the wrong thread.
- **Fixed: Window Behaviour in the macOS Dock Engine**: AeroBar no longer limits window sizes or changes the Dock's own zoom when you use the macOS Dock engine.

### v9.5-beta2.8 - October 2026
- **Window Options During Setup**: Fixed ⌘Q Warning, ⌘W Warning and AppQuit not working until you relaunched AeroBar when you turned them on during setup. They now start as soon as you switch them on and stop as soon as you switch them off. Turning one on may ask for Input Monitoring permission, which AeroBar needs to detect the shortcuts.
- **Hide the Menu Bar Icon**: Added **Options > Menu Bar > Show Menu Bar Icon** so you can remove AeroBar's menu bar icon if you don't want it. The icon disappears right away, and you can still open Settings from the Aero Menu. It can't be turned off while the bar is hidden, so you can't lock yourself out of Settings.
- **Clearer Option Descriptions**: Corrected the descriptions of Focus Mode, Display Background Dimmer, ⌘W Warning and AppQuit in setup, the menu bar popover and Settings so they match what each option actually does. AppQuit no longer says "Double ⌘W", and ⌘W Warning no longer says it only works in Safari and Chrome.
- **Clipboard Tab in the Menu Bar Popover**: The AeroBar menu bar popover now has a Clipboard tab. Turn Clipboard History on or off, or open the history panel with one click. The row shows your current shortcut. The panel opens from the bar, so AeroBar needs to be visible.
- **Quick Links to Settings**: The popover now links straight to Settings. **Manage App Inclusion/Exclusion Lists…** opens the Windows settings, and **Clipboard Settings…** opens Extensions.
- **Acknowledgements Button**: Added a heart button at the bottom of the menu bar popover that opens the Open Source Acknowledgements.
- **Position and Mode in the Popover**: Changing Placement from the popover now follows the same rules as Settings, including the guides for the menu bar background and for Top placement. The Mode menu also gained **Custom**, so it matches your bar's current mode.

### v9.5-beta2.2 - October 2026
- **Centered Dock Mode on Left/Right**: In Dock Mode with the bar on the Left or Right, the icons are now vertically centered instead of sitting at the top. If there are too many to fit, the bar falls back to the scrolling list with utilities at the bottom. You can turn this off under Layout > **Center Items in Dock Mode**, which only appears for Dock Mode on Left or Right. It is on by default.
- **Background Dimmer Rework**: The Display Background Dimmer has been rebuilt for lower CPU use and quicker reactions. It now notices a window being maximized, restored, minimized, opened or closed right away, even in the app you are already using, instead of waiting for you to switch apps.
- **Dim Only Behind Maximized Windows**: With one display, the wallpaper now dims only when a window is maximized to fill the screen. Before, any large window turned it on. A native full-screen app never triggers it.
- **Multiple Displays**: A display with a maximized window stays dimmed even while your mouse is on it. Other displays keep the existing rule: displays you are not using are dimmed, or only empty ones if **Only dim empty screens** is on.
- **Smoother Menus**: The dimmer no longer watches every mouse movement, which removes the stutter it could cause while a menu was open. It also stops checking windows entirely while the dimmer is switched off.
- **Fewer Needless Checks**: Changing an unrelated setting no longer makes the dimmer rescan your windows. It reacts only to its own three settings: enable, opacity and Only dim empty screens.
- **Under the Hood**: Added a shared window-event watcher that the dimmer now uses, so AeroBar does not need a separate accessibility observer for each feature. The window scan now runs off the main thread.

### v9.5-beta2.1 - October 2026
- **Window Tab Icons in Focus Mode**: Fixed window tab icons staying in full colour when Focus Mode was on. They now turn grey like the pinned app icons and scroll arrows, and the colour returns when you hover a tab. This works on horizontal and vertical bars.
- **Update Pop-up Corners**: Fixed the update alert, the "Update Successful" panel and the changelog sheet showing a faint ghost rim and mismatched corners. The window and the card now use the same corner shape and radius, and the shadow is redrawn after layout.
- **Aero Menu Border Lines**: Added two new switches under Appearance > Aero Menu Border Tint: **Show Outer Edge Line** (the thin white outline on the panel edge) and **Show Inner Glow Line** (the coloured line just inside the edge). Both are off by default, which removes the doubled rim some panels showed. They apply live to every panel that uses the shared border (Aero Menu, Clipboard, Music, extension panels and alerts), with no relaunch.
- **Custom Border Tint Linked to the Lines**: The custom border tint only colours the inner glow line, so the two are now linked. Turning on **Enable Custom Border Tint** also turns on the inner glow line. Turning it off hides both lines.
- **Existing Users**: If you already had Custom Border Tint on, AeroBar switches the inner glow line on for you once after updating, so your tint keeps working. Anything you change afterwards is left alone.
- **Reset**: **Reset App Menu Appearance** now also hides both edge lines, and a factory reset returns them to the hidden default.
- **Diagnostics**: Removed the two old rim switches from Panel Rim Diagnostics, now replaced by the permanent toggles above. The section has four switches: window shadow, SwiftUI shadow, layer mask and SwiftUI clip.

### v9.5-beta2 - October 2026
- **Customizer Redesign**: The Customizer now uses the same clean layout as GlassDock. The sidebar lists categories only (Layout, Appearance, Extensions, Windows, Displays, Options, Shortcuts), and the expandable accordion is gone.
- **Section Tabs**: Each category's sections now appear as tabs under its title, and tapping one jumps straight to that section. Layout has Mode, Position, Bar Sections and Sizing & Scale. Appearance has Basics, Theming, Colors, Borders and AuraBar. Windows has Previews, Highlight and Tabs. Bar Sections only appears in Custom mode.
- **Customizer Header & Reset**: The title now reads "AeroBar Customize". Each category has its own Reset button, and the top-bar button is now Reset All.
- **Customizer Cleanup**: Removed the "Limited Pro Free Trial" badge and the "Pro features are free during the beta" banner. The purple-tinted advanced boxes now use the same cards as the rest of the panel.
- **Pinned Apps Section**: Fixed the Pinned Apps section not appearing when turned on in Layout. A leftover Extensions setting was overriding the Layout toggle, so the duplicate toggle was removed.
- **Don't Move Windows**: Added a "Don't move windows" option under Displays > Cross-Space Window Focus Behavior. Clicking a window tab or preview now switches to that window's own display and Space instead of pulling it to the bar you clicked.
- **Window Tab Focus**: Fixed window tabs always pulling windows to the clicked display regardless of the Cross-Space Window Focus Behavior setting.
- **Uniform Tab Width**: Added Windows > Tabs > Uniform Tab Width, which gives every window tab the same width even when titles are short. It is on by default for everyone, and Reset turns it back on.
- **Pinned Apps Ordering**: You can now drag to reorder apps in the Pinned Apps grid popover. The bar's pinned section follows the same order, and Finder stays first.
- **Pinned Shortcuts Reordering**: Fixed reordering Pinned Shortcuts in the Aero-Menu, where dragging an icon could drop a copy on the desktop behind the menu instead of moving it. Reordering now stays inside the menu.
- **Drag-and-Drop Shortcuts**: Pinned Shortcuts can no longer be dragged out of the Aero-Menu onto the Desktop or Finder. Dragging apps from "All Apps" still works for pinning and creating shortcuts.

### v9.5-beta1 - September 2026
- **Performance**: Fixed a bug where the background check that watches for Accessibility permission being revoked was running far more often than needed, contributing to elevated CPU usage, Energy Impact, and disk activity over time. It now checks on a much longer interval with no measurable loss in responsiveness if permission is actually revoked.
- **Stability**: Removed leftover internal diagnostic logging that could silently fail and waste resources on some setups.
- **Under the Hood**: Cleaned up a hardcoded internal build path so the Watchdog Helper installer resolves correctly across different development environments.

### v9.4-beta8 - September 2026
- **Onboarding Welcome Page Continue Button Clip Fix**

### v9.4-beta8 - September 2026
- **Open Source Acknowledgements**: Added a new section in Settings > General to view the attributions and licenses for third-party libraries powering AeroBar.

### v9.4-beta7 - September 2026
- **False Malware warning fix**: Due to mediaadapter library was unsigned we got a false alarm from macos which restricted Aerobar app to launch, we fixed it.

### v9.4-beta5 - September 2026
- **App Tint Overrides**: Fixed a bug where opening the Customizer would automatically overwrite custom app tint rules for Chromium browsers with their auto-extracted colors due to an unprompted state update.
- **Update Engine**: Significantly reduced the app restart delay during an update by pre-mounting the update disk image in the background before waiting for the app to quit.
- **Focus Mode UI**: Fixed an issue in Light Mode where the sharp white dividers would remain intensely bright even when Focus Mode dimmed the bar to an opaque dark state, blending them smoothly instead.

### v9.4-beta4 - September 2026
- **Custom Color Overrides**: Fixed a bug where AeroBar could accidentally target itself or Finder when assigning Active App Colors, overriding default system themes.
- **Auto-Repair**: Added a startup check that automatically removes any accidentally saved color overrides for AeroBar or Finder to instantly repair stuck theming.
- **Menu Bar Interaction**: Fixed an issue where the native menu bar could become permanently unclickable due to an invisible focus tracking panel swallowing mouse clicks while AuraBar was disabled.

### v9.4-beta3 - September 2026
- **Window Tabs**: Fixed an issue where window tabs could randomly flicker or redraw themselves if an application momentarily stopped responding to accessibility checks.
- **PWA Support**: Expanded YouTube Music integration to correctly load track names and album art for Progressive Web Apps installed via Google Chrome or Microsoft Edge.
- **Start Menu**: Added a hardcoded fallback to ensure Finder always appears in the "All Apps" list, even if macOS indexing temporarily loses track of it.
- **Stability**: Fixed a hard crash (Swift Exclusivity Violation) that occurred when rapidly dragging the "Surface Tint Density" slider in the Customizer.
- **Welcome Panel**: Fixed a layout bug where the Post-Update welcome notes panel could erroneously anchor itself to the top-right corner of the screen instead of properly centering.
### v9.4-beta2 - September 2026

- **Website UI**: Redesigned index.html buttons with a modern Liquid Glass aesthetic using backdrop-filter blurring and inset shadows.
- **Documentation Alignment**: Re-anchored README headers and replaced external Shields.io badges with unified vector SVG buttons.
- **Static Download Links**: Replaced dynamic GitHub API fetch operations with static URLs for release assets to improve load reliability.
- **Drag-and-Drop Shortcuts**: Dragging an app from the Aero-Menu onto your Desktop or Finder now correctly generates a lightweight native macOS shortcut (alias), rather than incorrectly copying the entire application bundle.
- **Drag-and-Drop Reliability**: Fixed an issue where dragging an app from the "All Apps" list and dropping it into the "Pinned Shortcuts" section would fail to register.
- **Performance & Stability**: Fixed a severe bug where dragging certain system apps out of the Aero-Menu could cause AeroBar to hang and crash due to macOS sandbox restrictions on drag thumbnail generation.
- **Under the Hood**: Resolved Xcode build warnings and excessive runtime console spam by migrating internal drag-and-drop payloads to standard string identifiers.
- **Hover Consistency**: Fixed an issue where hovering over icons in Dock Mode failed to highlight or un-dim them when Display Dimmer or Focus Mode was enabled.
- **UI Consistency**: Updated all remaining guide popups (such as the Top Placement and Native Menu Bar guides) to correctly use the new Liquid Glass design language, matching the main onboarding flow.
- **Customizer**: The "Liquid Glass" bar material option is now unlocked and available for selection on all macOS versions (previously restricted to macOS Tahoe 26.0+). On older OSes, it will gracefully degrade to a high-quality ultra-thin material fallback.


### v9.3-beta9 - September 2026
- **Post-Update Experience**: Added a brand new "Update Successful" floating panel that automatically greets you with the release notes right after AeroBar completes an update and relaunches.
- **Intelligent Updater UI**: The updater popup now renders GitHub release notes natively with Markdown, properly displaying clickable hyperlinks, bold text, and lists.
- **Unified Liquid Glass Styling**: The updater popup now perfectly matches the OS-conditional Liquid Glass and Static Bar materials used in the onboarding UI.
- **Simplified Update Settings**: Removed the confusing Release Channel selectors (Beta, Testing, Final) from Settings. The updater now strictly fetches the single latest release from GitHub to reduce complexity.
- **Customizer Enhancements**: The Customizer's sidebar now automatically snaps back and expands the Layout section every time you open the panel.

### v9.3-beta8 - September 2026
- **Clipboard Security & Permissions**: Redesigned the "Save To" feature for copied file pointers in the Clipboard History panel. To strictly adhere to the Principle of Least Privilege, file pointers can now only be "Revealed in Finder" rather than duplicated. This completely removes the reliance on `FileManager` and Apple Events, preventing macOS from falsely flagging AeroBar for Full Disk Access.

### v9.3-beta7 - September 2026
- **Chromium UI Overlay Fix**: Fixed an issue introduced in beta6 where AeroBar would incorrectly clamp and shift Chromium-based browser (Google Chrome, Arc, Brave) search dropdowns, autocomplete menus, and focus rings.

### v9.3-beta6 - September 2026
- **Focus Mode Rendering**: Replaced opacity-based dimming on pinned and unpinned application icons with saturation and color-multiply filters. This prevents wallpaper bleed-through and ensures visual consistency with utility icons when the taskbar is translucent.
- **macOS 15/16 Clipboard Compatibility**: Fixed an issue where the system clipboard would fail to record copied items while AeroBar was active. Added a 150ms read debounce and strict type validation to prevent AeroBar from interrupting background write transactions in macOS Sequoia and Tahoe.
- **Divider Alignment**: Fixed an issue where section dividers would incorrectly render adjacent to empty space on vertical or top-placed taskbars when application lists did not fully fill the available screen area.
- **Cross-Platform App Compatibility**: Relaxed macOS Accessibility (AX) window role restrictions. AeroBar now natively recognizes and manages custom-drawn windows from cross-platform frameworks (e.g. Qt-based apps like DaVinci Resolve) that omit standard macOS window subroles.
- **Advanced Mode Deprecation**: Removed the "Advanced" toggle button from the Customizer. All advanced appearance and layout settings are now universally unlocked and visible by default for all users.

### v9.3-beta5 - September 2026
- **Light Mode Onboarding UI**: Fixed text visibility during first-time setup on Macs running Light Mode by enforcing a dark appearance globally.
- **EULA Checkbox**: Added accent-colored border and a "Please check mark to continue" prompt to the EULA checkbox.

### v9.3-beta4 - September 2026
- **Gatekeeper Validation**: Replaced dummy app symlinks with shell scripts and ad-hoc signatures to prevent ZIP extraction corruption and bypass Gatekeeper false-positives.

### v9.3-beta2 - September 2026
- **Window Preview Focus**: Fixed issue where clicking a live window preview thumbnail would incorrectly restore focus to the previous application upon closing.
- **Preview Animations**: Removed redundant window-raise commands when clicking window previews to prevent visual flashing.

### v9.3-beta1 - September 2026
- **Flicker Fixes**: Fixed flickering of pinned apps, unpinned apps, and window tabs when Screen Recording permission is denied.

### v9.2-beta9 - September 2026
- **Chromium Hover Cursor**: Added a 2px visual gap to the taskbar edge to guarantee `mouseExited` events register correctly for maximized Chromium-based apps.
- **Focus Mode Fullscreen**: Configured the dimming panel to automatically hide on monitors displaying a fullscreen application.

### v9.2-beta8 - September 2026
- **Window Clamping**: Updated clamping behavior to allow manual window placement behind or over the AeroBar, while retaining intelligent clamping for maximized or edge-snapped windows.
- **Maximize Clamping Delay**: Fixed delay where maximizing windows would overlap the AeroBar before being clamped.
- **Horizontal Clamping**: Fixed horizontal magnetic snapping and manual overlap overrides for left/right edge placements.
- **Auto-Updater**: Migrated the update installation process to a detached background script to prevent failure from extended-attribute copy errors or app crashes.
- **Crash Fixes**: Resolved thread deadlock (`EXC_BREAKPOINT`) in the window arrangement coordinator.
- **Taskbar Mode Flicker**: Fixed visual flickering of window tab chips during active window changes or bar height adjustments.

### v9.2-beta7 - September 2026
- **App Hangs**: Moved dynamic icon color extraction (`AuraBar`) to detached background tasks, removing synchronous `IconServices` caching loops.
- **AppleScript Stability**: Routed internal AppleScript executions through a dedicated serial queue to prevent `EXC_BAD_ACCESS` memory corruption crashes.
- **Shelf Hub Icon**: Replaced Shelf Hub icon with a native Asset Catalog (`Assets.car`) implementation to support real-time macOS dark mode and custom icon tints.
- **Auto-Updater**: Updated backup logic to use unique UUIDs, preventing "item with same name already exists" errors during installation.

### v9.2-beta6 - September 2026
- **AuraBar Flickering**: Fixed issue where the top menu bar would disappear during rapid app switches or focus changes.
- **App Badges**: Fixed macOS Accessibility API parsing errors causing missing red badges and attention animations for certain apps.
- **Efficiency Mode Dialogs**: Fixed issue in Customizer where Efficiency Mode and Power Save warning dialogs would instantly close without applying changes.
- **Telemetry Identifiers**: Migrated Cloudflare and Sentry telemetry to use a stable hardware ID (via IOKit) instead of random UUIDs.
- **Developer Options**: Added toggles to disable Sentry and Cloudflare reporting during local development.
- **Dashboard Telemetry**: Added manual cleanup tools and update deferral tracking metrics to the dashboard.

### v9.2-beta5 - September 2026
- **Focus Mode Opaque Bar**: Added toggle under Display Background Dimmer to disable the opaque dark bar effect when active.
- **Panel Depth Toggle**: Added toggle to switch popup panels from native WindowServer focus to emulated glass using `orderFrontRegardless`.

### v8.5-beta6 - July 2026
- Code decoupling and minor layout improvements.

### v8.4-beta9 - July 2026
- **Multi-Display Window Previews**: Fixed incorrect tab highlighting and incorrect screen placement for window previews on secondary displays.
- **Preview Stability**: Fixed infinite retry loop and flickering caused by truncated display crops for edge-aligned or maximized apps.

### v8.4-beta3 - July 2026
- **Scroll View Sizing**: Fixed issue where adding new windows from pinned tabs failed to resize the tab scroll view.
- **Pinned App Window Launch**: Fixed "Open New Window" context menu action failing when the application is already running.
- **Preview Reliability**: Resolved race condition causing blank window previews during rapid mouse hovers.
- **Performance**: Optimized main-thread IPC calls during pinned app hovers and context menu rendering.

### v8.3-beta8 - July 2026
- **Sentry Integration**: Integrated Sentry SDK for crash and performance metric tracking.
- **Hang Detection**: Updated Watchdog Service to spawn an independent AppleScript process for reliable crash reporting during main thread deadlocks.
- **Watchdog Threshold**: Reduced kill threshold from 15s to 10s.

### v8.3-beta6 - July 2026
- **Sleep Crashes**: Fixed watchdog timer timeouts when waking the Mac from sleep.
- **System Freezes**: Resolved deadlock with macOS WindowServer during Cmd+Tab or gesture switching when interacting with settings.

### v8.3-beta4 - July 2026
- **Native Crash Reporter**: Replaced background script crash popup with a native launch window.
- **Log Formatting**: Truncated crash logs to comply with GitHub issue size limits.
- **Event Tap Failsafe**: Added circuit breakers to prevent global OS freezes during event tap timeouts.
- **Developer Settings**: Moved testing tools to a dedicated Developer tab.
- **App Menu**: Fixed missing system apps and user-specific apps in the Start Menu app list.

### v8.3-beta3 - July 2026
- Under-the-hood performance optimizations.

### v8.3-beta2 - July 2026
- **Hover Animations**: Fixed hover lag and sticky button states during Focus Mode.

### v8.3-beta1 - July 2026
- **OS Support**: Added experimental support for macOS Sonoma and macOS Sequoia.

### v8.2-beta10 - July 2026
- **Memory Leaks**: Fixed memory leaks and CPU usage spikes related to window tracking and clipboard thumbnail generation.

### v8.2-beta8 - July 2026
- **Display Background Dimmer**: Added toggle to dim wallpaper on secondary or inactive displays lacking active windows.
- **Multi-Display Focus Mode**: Fixed dimming panel coordinates on external displays.
- **Codebase Modernization**: Addressed deprecated property warnings and updated dictionary initializers.

### v8.2-beta6 - July 2026
- **Settings UI**: Restructured "Surface Tint Density" grouping.
- **Focus Mode**: Corrected shading for Search and Trash buttons, applied dim tint instantly upon resize, and disabled bevel edges while active.
- **Flickering**: Fixed flickering during pinned app hovers.

### v8.2-beta4 - July 2026
- **Daemon Optimization**: Cached Space IPC calls and short-circuited phantom windows to reduce CPU usage.
- **Memory Leaks**: Addressed leaks from undocumented CGS WindowServer APIs.
- **Screen Recording Lifecycle**: Fixed issue where screen recording sessions remained active after popover closure.
- **Window Tab Previews**: Resolved state synchronization race condition causing blank hover previews.
- **Chromium Live Previews**: Fixed ScreenCaptureKit bug causing live previews to fallback to static thumbnails.
- **AeroBar Ghost Previews**: Excluded AeroBar's invisible tracking overlays from live preview captures.

### v8.2-beta3 - July 2026
- **Performance**: Shifted glass masking to native AppKit CoreAnimation layers to reduce CPU overhead.
- **Responsiveness**: Moved AX accessibility hit-testing off the main thread.
- **Stability**: Fixed `Invalid frame dimension` layout crash during initial Cmd+Tab panel display.

### v8.2-beta2 - July 2026
- **Trackpad Gestures**: Migrated multidirectional app cycling from 4-finger to 3-finger swipes.
- **Update Dialogs**: Suppressed update check popups when a display is in true fullscreen mode.
- **Window Positioning**: Fixed layout coordinate bugs causing windows to shift downward when pulled cross-screen.
- **Customization Button**: Expanded the Customization button click target to match its hover area.
- **Pinned App Icons**: Adjusted corner radii and masks to match macOS squircle aesthetics.
- **Hover Jitter**: Filtered physical trackpad cursor drift during 3-finger swipe gesture cycle highlights.

### v8.1-beta2 - July 2026
- Memory, battery, and performance optimizations.

### v8.1-beta - July 2026
- **Cmd+Tab & Gesture Switching**: Fixed 3/4 finger swipe gestures and window preview size clipping.
- **Aesthetics**: Added glass vibrancy, split accent colors, and 0.5pt bevel highlights.
- **Memory Optimization**: Fixed memory leaks causing instability.
- **Workspace**: Resolved fullscreen Space flickering and VLC rendering compatibility bugs.
- **UI Settings**: Added a slider for selection highlight color intensity and an Active Tab Dimmer for inactive window states.
- **Layout**: Fixed icon padding, welcome screen gaps, and EULA layout.
- **Threading**: Moved window tracking updates to background threads.
- **Clipboard History**: Added a delete confirmation prompt.
- **Context Menus**: Fixed bugs causing Context Menu freezes.
