import Foundation
import AppKit
import SwiftUI
import Combine

struct GitHubAsset: Codable {
    let name: String
    let browserDownloadUrl: String
}

struct GitHubRelease: Codable {
    let tagName: String?
    let body: String?
    let assets: [GitHubAsset]?
}

// ==========================================
// 🔔 UPDATE ALERT PANEL
// A floating NSPanel that shows changelog + Update Now / Later buttons.
// Presented as a proper popup above all AeroBar panels.
// ==========================================
final class AeroBarUpdateAlertPanel: NSPanel {

    static func show(version: String, changelog: String, onUpdateNow: @escaping () -> Void) {
        let panel = AeroBarUpdateAlertPanel(
            contentRect: NSRect(x: 0, y: 0, width: 460, height: 480),
            styleMask: [.titled, .closable, .fullSizeContentView, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.titlebarAppearsTransparent = true
        panel.title = ""
        panel.isMovableByWindowBackground = true
        panel.level = .floating
        panel.isReleasedWhenClosed = false
        panel.center()

        let rootView = AeroBarUpdateAlertView(
            version: version,
            changelog: changelog,
            onUpdateNow: {
                panel.close()
                onUpdateNow()
            },
            onLater: {
                panel.close()
            }
        )
        panel.contentView = NSHostingView(rootView: rootView)
        panel.makeKeyAndOrderFront(nil)
    }
}

// ==========================================
// 🎨 UPDATE ALERT SWIFTUI VIEW
// Shows version badge, full scrollable changelog, and two action buttons.
// ==========================================
struct AeroBarUpdateAlertView: View {
    let version: String
    let changelog: String
    let onUpdateNow: () -> Void
    let onLater: () -> Void

    var body: some View {
        ZStack {
            VisualEffectBlurView(material: .hudWindow, blendingMode: .withinWindow, state: .active)

            VStack(spacing: 0) {
                // ── HEADER ──────────────────────────────────────────
                VStack(spacing: 8) {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 36, weight: .light))
                        .foregroundColor(.accentColor)

                    Text("AeroBar \(version) Available")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("A new version is ready to install.")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding(.top, 28)
                .padding(.bottom, 16)

                Divider().background(Color.white.opacity(0.1))

                // ── CHANGELOG ───────────────────────────────────────
                VStack(alignment: .leading, spacing: 8) {
                    Text("What's New")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.4))
                        .padding(.horizontal, 16)
                        .padding(.top, 12)

                    ScrollView(.vertical, showsIndicators: true) {
                        Text(changelog.isEmpty ? "No release notes provided." : changelog)
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.85))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 12)
                            .textSelection(.enabled)
                    }
                    .frame(maxHeight: 260)
                }

                Divider().background(Color.white.opacity(0.1))

                // ── ACTION BUTTONS ───────────────────────────────────
                HStack(spacing: 10) {
                    Button(action: onLater) {
                        Text("Later")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white.opacity(0.7))
                            .frame(maxWidth: .infinity, minHeight: 30)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(7)
                    }
                    .buttonStyle(.plain)

                    Button(action: onUpdateNow) {
                        Text("Update Now")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity, minHeight: 30)
                            .background(Color.accentColor)
                            .cornerRadius(7)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
        }
        .frame(width: 460, height: 480)
    }
}

// ==========================================
// 🔄 UPDATE ENGINE
// ==========================================
final class AeroBarUpdateEngine: ObservableObject {
    static let shared = AeroBarUpdateEngine()

    @Published var isDownloadingDirectly: Bool = false
    @Published var installationStatusMessage: String = ""

    private let githubLatestReleaseURL = URL(string: "https://api.github.com/repos/adityaonx/AeroBar/releases/latest")
    private var directDmgDownloadURL: URL?

    // ── Called on launch and by "Check for Updates Now" button ─────
    func checkForUpdatesSilently(showAlertIfAvailable: Bool = false) {
        guard let url = githubLatestReleaseURL else { return }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data else { return }
            Task { @MainActor in
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
                            // User opted in to fully automatic silent updates — just do it
                            self.downloadAndInstallUpdateSilently()
                        } else {
                            // Show the update popup with changelog
                            self.presentUpdatePopup(version: rawTagName, changelog: settings.latestChangelog)
                        }
                    }
                } catch { print("[AeroBarUpdateEngine] Decode error: \(error)") }
            }
        }.resume()
    }

    // ── Present the floating update alert panel ────────────────────
    @MainActor
    func presentUpdatePopup(version: String, changelog: String) {
        AeroBarUpdateAlertPanel.show(version: version, changelog: changelog) {
            AeroBarUpdateEngine.shared.downloadAndInstallUpdateSilently()
        }
    }

    // ── Called by "Update Now" button or silent-update path ────────
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
            self.executeInAppBinaryReplacementWorkflow(dmgLocation: dest)
        }.resume()
    }

    private func executeInAppBinaryReplacementWorkflow(dmgLocation: URL) {
        DispatchQueue.global(qos: .userInteractive).async {
            let fm = FileManager.default
            let cur = Bundle.main.bundleURL
            let appDir = cur.deletingLastPathComponent()
            let backup = appDir.appendingPathComponent("AeroBar_Old_Backup.app")

            let mount = "/Volumes/AeroBar_Update_\(UUID().uuidString.prefix(6))"
            let mountTask = Process()
            mountTask.launchPath = "/usr/bin/hdiutil"
            mountTask.arguments = ["attach", dmgLocation.path, "-mountpoint", mount, "-nobrowse", "-quiet"]
            mountTask.launch(); mountTask.waitUntilExit()

            if fm.fileExists(atPath: "\(mount)/AeroBar.app") {
                try? fm.moveItem(at: cur, to: backup)
                try? fm.copyItem(at: URL(fileURLWithPath: "\(mount)/AeroBar.app"), to: cur)
            }

            let unmount = Process()
            unmount.launchPath = "/usr/bin/hdiutil"
            unmount.arguments = ["detach", mount, "-force", "-quiet"]
            unmount.launch(); unmount.waitUntilExit()
            try? fm.removeItem(at: dmgLocation)

            DispatchQueue.main.async {
                let script = """
                sleep 1.5
                rm -rf "\(backup.path)"
                open "\(cur.path)"
                """
                let proc = Process()
                proc.launchPath = "/bin/sh"; proc.arguments = ["-c", script]
                proc.launch()
                NSApp.terminate(nil)
            }
        }
    }
}
