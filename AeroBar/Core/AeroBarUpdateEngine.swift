import Foundation
import AppKit
import SwiftUI
import Combine

struct GitHubAsset: Codable {
    let name: String
    let browserDownloadUrl: String
}

// 🎯 BUG 7 FIX: Map the body parameter to extract remote GitHub Changelogs
struct GitHubRelease: Codable {
    let tagName: String?
    let assets: [GitHubAsset]?
    let body: String?
}

final class AeroBarUpdateEngine: ObservableObject {
    static let shared = AeroBarUpdateEngine()
    
    @Published var isDownloadingDirectly: Bool = false
    @Published var backgroundDownloadProgress: Double = 0.0
    @Published var installationStatusMessage: String = ""
    
    private let githubLatestReleaseURL = URL(string: "https://api.github.com/repos/adityaonx/AeroBar/releases/latest")
    private var directDmgDownloadURL: URL?
    
    func checkForUpdatesSilently() {
        guard let url = githubLatestReleaseURL else { return }
        
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.setValue("AuraBar-UpdateEngine", forHTTPHeaderField: "User-Agent")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard error == nil, let data = data else { return }
            
            Task { @MainActor in
                do {
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .convertFromSnakeCase
                    
                    let release = try decoder.decode(GitHubRelease.self, from: data)
                    guard let rawTagName = release.tagName, let assetsList = release.assets else {
                        print("DEBUG: GitHub API missing tag name or assets matrix metadata payload layout.")
                        return
                    }
                    
                    if let dmgAsset = assetsList.first(where: {
                        $0.name.lowercased().hasSuffix(".dmg") ||
                        $0.name.lowercased().contains(".dmg")
                    }) {
                        self.directDmgDownloadURL = URL(string: dmgAsset.browserDownloadUrl)
                    } else {
                        print("ERROR: Engine analyzed asset strings but could not isolate a valid '.dmg' binary file asset.")
                    }
                    
                    let remoteCleanedVersion = rawTagName.trimmingCharacters(in: CharacterSet.letters)
                    guard let localVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else { return }
                    
                    if remoteCleanedVersion.compare(localVersion, options: .numeric) == .orderedDescending {
                        let settings = AeroBarSettings.shared
                        settings.isUpdateAvailable = true
                        settings.latestRemoteVersionString = rawTagName
                        
                        self.triggerNativeUpdateAlertNotification(
                            version: rawTagName,
                            changelog: release.body ?? "General stability improvements and bug fixes."
                        )
                    }
                } catch {
                    print("Failed parsing update telemetry data: \(error.localizedDescription)")
                }
            }
        }.resume()
    }
    
    // MARK: - Native Notification System Popup
    @MainActor
    private func triggerNativeUpdateAlertNotification(version: String, changelog: String) {
        let alert = NSAlert()
        alert.messageText = "AeroBar Update Available!"
        alert.informativeText = "Version \(version) has been discovered on your remote release branch. Would you like to download and update your system instance right now?"
        
        // 🎯 BUG 7 FIX: Inject a scrollable text area for the Changelog directly into the popup
        let scrollViewer = NSScrollView(frame: NSRect(x: 0, y: 0, width: 380, height: 140))
        scrollViewer.hasVerticalScroller = true
        scrollViewer.borderType = .bezelBorder
        
        let textView = NSTextView(frame: NSRect(x: 0, y: 0, width: 380, height: 140))
        textView.isEditable = false
        textView.backgroundColor = NSColor.textBackgroundColor
        textView.string = "What's New in \(version):\n\n\(changelog)"
        
        scrollViewer.documentView = textView
        alert.accessoryView = scrollViewer
        
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Install Update Instantly")
        alert.addButton(withTitle: "Later")
        
        NSApp.activate(ignoringOtherApps: true)
        let trackingResponse = alert.runModal()
        
        if trackingResponse == .alertFirstButtonReturn {
            self.downloadAndInstallUpdateSilently()
        }
    }
    
    func downloadAndInstallUpdateSilently() {
        guard let downloadURL = directDmgDownloadURL else {
            print("ERROR: Direct DMG path reference string missing inside engine instance allocation.")
            return
        }
        
        DispatchQueue.main.async {
            self.isDownloadingDirectly = true
            self.installationStatusMessage = "Downloading fresh binary canvas..."
        }
        
        let temporaryDirectoryURL = FileManager.default.temporaryDirectory
        let destinationLocalURL = temporaryDirectoryURL.appendingPathComponent("AeroBarUpdate.dmg")
        
        try? FileManager.default.removeItem(at: destinationLocalURL)
        
        let configuration = URLSessionConfiguration.default
        let session = URLSession(configuration: configuration, delegate: nil, delegateQueue: nil)
        
        session.dataTask(with: downloadURL) { data, response, error in
            guard let data = data, error == nil else {
                DispatchQueue.main.async { self.installationStatusMessage = "Download failure connection reset." }
                return
            }
            
            do {
                try data.write(to: destinationLocalURL)
                
                DispatchQueue.main.async { self.installationStatusMessage = "Mounting disk container safely..." }
                self.executeInAppBinaryReplacementWorkflow(dmgLocation: destinationLocalURL)
            } catch {
                print("Failed saving intermediate payload container asset: \(error.localizedDescription)")
            }
        }.resume()
    }
    
    private func executeInAppBinaryReplacementWorkflow(dmgLocation: URL) {
        let processQueue = DispatchQueue.global(qos: .userInteractive)
        processQueue.async {
            let fileManager = FileManager.default
            let currentRunningAppURL = Bundle.main.bundleURL
            let targetApplicationsFolderURL = currentRunningAppURL.deletingLastPathComponent()
            
            let mountPointName = "AeroBar_Update_Mount_\(UUID().uuidString.prefix(6))"
            let mountTargetLocation = "/Volumes/\(mountPointName)"
            
            let mountTask = Process()
            mountTask.launchPath = "/usr/bin/hdiutil"
            mountTask.arguments = ["attach", dmgLocation.path, "-mountpoint", mountTargetLocation, "-nobrowse", "-quiet"]
            mountTask.launch()
            mountTask.waitUntilExit()
            
            let sourceAppPath = "\(mountTargetLocation)/AeroBar.app"
            
            if fileManager.fileExists(atPath: sourceAppPath) {
                DispatchQueue.main.async { self.installationStatusMessage = "Replacing binary with latest build..." }
                
                let backupAppURL = targetApplicationsFolderURL.appendingPathComponent("AeroBar_Old_Backup.app")
                try? fileManager.removeItem(at: backupAppURL)
                
                do {
                    try fileManager.moveItem(at: currentRunningAppURL, to: backupAppURL)
                    try fileManager.copyItem(at: URL(fileURLWithPath: sourceAppPath), to: currentRunningAppURL)
                    try? fileManager.removeItem(at: backupAppURL)
                    
                    DispatchQueue.main.async { self.installationStatusMessage = "Finalizing update installation..." }
                } catch {
                    if !fileManager.fileExists(atPath: currentRunningAppURL.path) && fileManager.fileExists(atPath: backupAppURL.path) {
                        try? fileManager.moveItem(at: backupAppURL, to: currentRunningAppURL)
                    }
                    print("Structural installation collision fault error encountered: \(error.localizedDescription)")
                }
            }
            
            let unmountTask = Process()
            unmountTask.launchPath = "/usr/bin/hdiutil"
            unmountTask.arguments = ["detach", mountTargetLocation, "-force", "-quiet"]
            unmountTask.launch()
            unmountTask.waitUntilExit()
            
            try? fileManager.removeItem(at: dmgLocation)
            
            DispatchQueue.main.async {
                self.installationStatusMessage = "Relaunching system environment..."
                
                let relaunchProcess = Process()
                relaunchProcess.launchPath = "/usr/bin/open"
                relaunchProcess.arguments = [currentRunningAppURL.path]
                relaunchProcess.launch()
                
                NSApp.terminate(nil)
            }
        }
    }
}
