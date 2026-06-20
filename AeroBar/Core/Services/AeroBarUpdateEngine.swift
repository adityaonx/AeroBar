// AeroBarUpdateEngine.swift — Checks GitHub Releases for new builds and handles
// the in-place update (download DMG, swap the app bundle, relaunch).
// Owner: Core/Services
// Depends on: Core/Models/GitHubRelease, Window/AeroBarUpdateAlertPanel
//
// Single shared instance. checkForUpdatesSilently() is the entry point, called
// from AeroBarWindowController on launch and from a periodic timer. Everything
// below it is plumbing for the actual download/install/relaunch sequence.

import Foundation
import AppKit
import Combine

final class AeroBarUpdateEngine: ObservableObject {
    static let shared = AeroBarUpdateEngine()

    @Published var isDownloadingDirectly: Bool = false
    @Published var installationStatusMessage: String = ""

    private let githubLatestReleaseURL = URL(string: "https://api.github.com/repos/adityaonx/AeroBar/releases/latest")
    private var directDmgDownloadURL: URL?

    // MARK: - Check

    /// Fetches the latest GitHub release and, if it's newer than the running
    /// build, either shows the update prompt or installs silently depending on
    /// `enableSilentUpdates`. `onComplete` always fires exactly once, success or not.
    func checkForUpdatesSilently(showAlertIfAvailable: Bool = false, onComplete: (() -> Void)? = nil) {
        guard let url = githubLatestReleaseURL else { onComplete?(); return }

        // GitHub's API requires a User-Agent header or it returns 403.
        var request = URLRequest(url: url)
        request.setValue("AeroBarApp-Updater", forHTTPHeaderField: "User-Agent")
        request.cachePolicy = .reloadIgnoringLocalCacheData

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                print("[AeroBarUpdateEngine] Network error: \(error.localizedDescription)")
                DispatchQueue.main.async { onComplete?() }
                return
            }
            guard let data = data else { DispatchQueue.main.async { onComplete?() }; return }
            Task { @MainActor in
                defer { onComplete?() }
                do {
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .convertFromSnakeCase
                    let release = try decoder.decode(GitHubRelease.self, from: data)
                    guard let rawTagName = release.tagName, let assetsList = release.assets else { return }

                    let settings = AeroBarSettings.shared
                    settings.latestChangelog = release.body ?? ""

                    if let dmgAsset = assetsList.first(where: { $0.name.lowercased().contains(".dmg") }) {
                        self.directDmgDownloadURL = URL(string: dmgAsset.browserDownloadUrl)
                    }

                    let localVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
                    let isNewer = rawTagName
                        .replacingOccurrences(of: "v", with: "")
                        .compare(localVersion, options: .numeric) == .orderedDescending

                    if isNewer {
                        settings.isUpdateAvailable = true
                        settings.latestRemoteVersionString = rawTagName

                        if settings.enableSilentUpdates {
                            self.downloadAndInstallUpdateSilently()
                        } else {
                            self.presentUpdatePopup(version: rawTagName, changelog: settings.latestChangelog)
                        }
                    } else if !showAlertIfAvailable {
                        print("[AeroBarUpdateEngine] Already on the latest version: \(localVersion)")
                    }
                } catch {
                    print("[AeroBarUpdateEngine] Decode error: \(error)")
                }
            }
        }.resume()
    }

    // MARK: - Present

    @MainActor
    func presentUpdatePopup(version: String, changelog: String) {
        AeroBarUpdateAlertPanel.show(version: version, changelog: changelog) {
            AeroBarUpdateEngine.shared.downloadAndInstallUpdateSilently()
        }
    }

    // MARK: - Download & install

    /// Downloads the release DMG and hands off to the bundle-swap workflow.
    /// Used both by the "Update Now" button and the silent-update path.
    func downloadAndInstallUpdateSilently() {
        guard let downloadURL = directDmgDownloadURL else { return }
        DispatchQueue.main.async {
            self.isDownloadingDirectly = true
            self.installationStatusMessage = "Downloading update..."
        }

        let tempDir = FileManager.default.temporaryDirectory
        let dest = tempDir.appendingPathComponent("AeroBarUpdate.dmg")
        try? FileManager.default.removeItem(at: dest)

        URLSession.shared.dataTask(with: downloadURL) { data, _, _ in
            guard let data = data else {
                DispatchQueue.main.async { self.installationStatusMessage = "Download failed." }
                return
            }
            DispatchQueue.main.async { self.installationStatusMessage = "Installing..." }
            try? data.write(to: dest)
            self.replaceRunningAppBundle(withDmgAt: dest)
        }.resume()
    }

    /// Mounts the downloaded DMG, swaps the running .app bundle for the one
    /// inside it (keeping a backup until relaunch succeeds), then relaunches.
    private func replaceRunningAppBundle(withDmgAt dmgLocation: URL) {
        DispatchQueue.global(qos: .userInteractive).async {
            let fm = FileManager.default
            let currentAppURL = Bundle.main.bundleURL
            let appDir = currentAppURL.deletingLastPathComponent()
            let backupURL = appDir.appendingPathComponent("AeroBar_Old_Backup.app")

            let mountPoint = "/Volumes/AeroBar_Update_\(UUID().uuidString.prefix(6))"
            let mountTask = Process()
            mountTask.launchPath = "/usr/bin/hdiutil"
            mountTask.arguments = ["attach", dmgLocation.path, "-mountpoint", mountPoint, "-nobrowse", "-quiet"]
            mountTask.launch(); mountTask.waitUntilExit()

            if fm.fileExists(atPath: "\(mountPoint)/AeroBar.app") {
                try? fm.moveItem(at: currentAppURL, to: backupURL)
                try? fm.copyItem(at: URL(fileURLWithPath: "\(mountPoint)/AeroBar.app"), to: currentAppURL)
            }

            let unmountTask = Process()
            unmountTask.launchPath = "/usr/bin/hdiutil"
            unmountTask.arguments = ["detach", mountPoint, "-force", "-quiet"]
            unmountTask.launch(); unmountTask.waitUntilExit()
            try? fm.removeItem(at: dmgLocation)

            DispatchQueue.main.async {
                // Relaunch from a detached shell so the new bundle can start after
                // this process (which is still running out of the old bundle) exits,
                // then clean up the backup once the new copy is confirmed in place.
                let script = """
                sleep 1.5
                rm -rf "\(backupURL.path)"
                open "\(currentAppURL.path)"
                """
                let relaunchTask = Process()
                relaunchTask.launchPath = "/bin/sh"
                relaunchTask.arguments = ["-c", script]
                relaunchTask.launch()
                NSApp.terminate(nil)
            }
        }
    }
}
