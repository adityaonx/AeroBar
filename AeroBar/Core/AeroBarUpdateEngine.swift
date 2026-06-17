import Foundation
import AppKit
import SwiftUI
import Combine

// Structures to map the direct downloadable binaries out of GitHub's assets payload array
struct GitHubAsset: Codable {
    let name: String
    let browserDownloadUrl: String // 🎯 System converts from snake_case dynamically via keyDecodingStrategy
}

struct GitHubRelease: Codable {
    let tagName: String?          // 🎯 System converts from snake_case dynamically via keyDecodingStrategy
    let assets: [GitHubAsset]?
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
            
            // 🎯 THE SWIFT 6 CONCURRENCY FIX: Isolates the JSON parsing validation block
            // onto the MainActor, clearing cross-thread isolation restrictions.
            Task { @MainActor in
                do {
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .convertFromSnakeCase
                    
                    let release = try decoder.decode(GitHubRelease.self, from: data)
                    guard let rawTagName = release.tagName, let assetsList = release.assets else {
                        print("DEBUG: GitHub API missing tag name or assets matrix metadata payload layout.")
                        return
                    }
                    
                    // 🎯 CONSOLE TELEMETRY LOGS FOR LIVE DEBUGGING
                    print("DEBUG: GitHub API successfully returned version tag: \(rawTagName)")
                    print("DEBUG: Found \(assetsList.count) total attached release assets.")
                    for asset in assetsList {
                        print("--> Asset name in payload: \"\(asset.name)\"")
                    }
                    
                    // 🎯 SCAN: Containment filter checks for .dmg or .DMG variations
                    if let dmgAsset = assetsList.first(where: {
                        $0.name.lowercased().hasSuffix(".dmg") ||
                        $0.name.lowercased().contains(".dmg")
                    }) {
                        self.directDmgDownloadURL = URL(string: dmgAsset.browserDownloadUrl)
                        print("DEBUG: Direct target mapping secured -> \(dmgAsset.browserDownloadUrl)")
                    } else {
                        print("ERROR: Engine analyzed asset strings but could not isolate a valid '.dmg' binary file asset.")
                    }
                    
                    let remoteCleanedVersion = rawTagName.trimmingCharacters(in: CharacterSet.letters)
                    guard let localVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else { return }
                    
                    if remoteCleanedVersion.compare(localVersion, options: .numeric) == .orderedDescending {
                        let settings = AeroBarSettings.shared
                        settings.isUpdateAvailable = true
                        settings.latestRemoteVersionString = rawTagName
                        
                        // 🎯 TRIGGER NATIVE SYSTEM POPUP ALERT WINDOW
                        self.triggerNativeUpdateAlertNotification(version: rawTagName)
                    }
                } catch {
                    print("Failed parsing update telemetry data: \(error.localizedDescription)")
                }
            }
        }.resume()
    }
    
    // MARK: - Native Notification System Popup
    @MainActor
    private func triggerNativeUpdateAlertNotification(version: String) {
        let alert = NSAlert()
        alert.messageText = "AeroBar Update Available!"
        alert.informativeText = "Version \(version) has been discovered on your remote release branch. Would you like to download and update your system instance right now?"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Install Update Instantly")
        alert.addButton(withTitle: "Later")
        
        // Bring alert to absolute focus layout layer foreground
        NSApp.activate(ignoringOtherApps: true)
        let trackingResponse = alert.runModal()
        
        if trackingResponse == .alertFirstButtonReturn {
            self.downloadAndInstallUpdateSilently()
        }
    }
    
    // MARK: - In-App Silent Extraction & Installation Engine
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
        
        // Clean up any stale artifacts left over from initial execution passes
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
            let currentRunningAppURL = Bundle.main.bundleURL // e.g., /Applications/AeroBar.app
            let targetApplicationsFolderURL = currentRunningAppURL.deletingLastPathComponent() // /Applications
            let backupAppURL = targetApplicationsFolderURL.appendingPathComponent("AeroBar_Old_Backup.app")
            // System level sub-shell mount script executions
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
                
                // Generate secure isolated unique transaction backup filename
                let backupAppURL = targetApplicationsFolderURL.appendingPathComponent("AeroBar_Old_Backup.app")
                
                do {
                    // 1. Move currently running bundle to local temp backup location
                    try fileManager.moveItem(at: currentRunningAppURL, to: backupAppURL)
                    
                    // 2. Copy the fresh update bundle file straight into place
                    try fileManager.copyItem(at: URL(fileURLWithPath: sourceAppPath), to: currentRunningAppURL)
                    
                    // 3. (Removed internal deletion because macOS locks the running executable)
                    
                    DispatchQueue.main.async { self.installationStatusMessage = "Finalizing update installation..." }
                } catch {
                    // Critical atomic rollback mechanism: restore old binary frame if copy layout failed
                    if !fileManager.fileExists(atPath: currentRunningAppURL.path) && fileManager.fileExists(atPath: backupAppURL.path) {
                        try? fileManager.moveItem(at: backupAppURL, to: currentRunningAppURL)
                    }
                    print("Structural installation collision fault error encountered: \(error.localizedDescription)")
                }
            }
            
            // Detach disk loop mounts gracefully to prevent system memory leaks
            let unmountTask = Process()
            unmountTask.launchPath = "/usr/bin/hdiutil"
            unmountTask.arguments = ["detach", mountTargetLocation, "-force", "-quiet"]
            unmountTask.launch()
            unmountTask.waitUntilExit()
            
            // Clean local storage cache temp path boundaries
            try? fileManager.removeItem(at: dmgLocation)
            
            // 🎯 STEP 4: HOT RELAUNCH REBOOT TRANSITION & CLEANUP
            DispatchQueue.main.async {
                self.installationStatusMessage = "Relaunching system environment..."
                
                // We use a detached shell script to wait for the current app to completely die,
                // then forcefully delete the locked backup folder, and finally open the new app.
                let cleanupAndRelaunchScript = """
                sleep 1.5
                rm -rf "\(backupAppURL.path)"
                open "\(currentRunningAppURL.path)"
                """
                
                let relaunchProcess = Process()
                relaunchProcess.launchPath = "/bin/sh"
                relaunchProcess.arguments = ["-c", cleanupAndRelaunchScript]
                relaunchProcess.launch()
                
                // Kill current outdated executing thread environment safely
                NSApp.terminate(nil)
            }
        }
    }
}
