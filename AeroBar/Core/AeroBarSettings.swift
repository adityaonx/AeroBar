import SwiftUI
import AppKit
import Combine
import UniformTypeIdentifiers
import ServiceManagement

struct WindowTab: Identifiable, Equatable {
    var id: String { "\(processID)-\(windowID)" }
    let windowID: CGWindowID
    let processID: pid_t
    let appName: String
    let windowTitle: String
    let axElement: AXUIElement
    let appIcon: NSImage
    
    static func == (lhs: WindowTab, rhs: WindowTab) -> Bool {
        return lhs.windowID == rhs.windowID && lhs.processID == rhs.processID
    }
}

struct PinnedApp: Identifiable, Equatable, Codable {
    var id: String { bundleIdentifier }
    let bundleIdentifier: String
    let appName: String
    
    var appIcon: NSImage {
        if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) {
            return NSWorkspace.shared.icon(forFile: appURL.path)
        }
        return NSWorkspace.shared.icon(for: UTType.application)
    }
}

struct DiscoverableApp: Identifiable, Equatable {
    var id: String { path }
    let appName: String
    let path: String
    let icon: NSImage
}

class AeroBarSettings: ObservableObject {
    static let shared = AeroBarSettings()
    
    private let pinnedStartStorageKey = "com.aerobar.pinnedStartApplicationsOrder"
    private let pinnedBarStorageKey = "com.aerobar.pinnedBarApplicationsOrder"
    
    private var metadataQuery: NSMetadataQuery?
    private var permissionHeartbeatTimer: Timer?
    // Inside class AeroBarSettings: ObservableObject
    @AppStorage("showRecommendations") var showRecommendations: Bool = true
    @Published var cachedUserAvatar: CGImage? = nil
    @Published var isUpdateAvailable: Bool = false
    @Published var latestRemoteVersionString: String = ""
    @Published var downloadURLString: String = ""
    @Published var currentSystemFocusedElement: AXUIElement? = nil
    @Published var barHeight: CGFloat = 40
    @Published var displayTargetMode: DisplayTargetMode = .all {
        didSet {
            // Broadcast structural topology shifts instantly to the layout controllers
            NotificationCenter.default.post(name: Notification.Name("AeroBarMultiDisplayChanged"), object: nil)
        }
    }
    @Published var showOnExternalDisplays: Bool = true {
        didSet {
            // Broadcast globally so the window controller can update geometry instantly
            NotificationCenter.default.post(name: Notification.Name("AeroBarMultiDisplayChanged"), object: nil)
        }
    }
    @Published var manuallyHiddenWindowIDs: Set<CGWindowID> = []
    @Published var glassOpacity: Double = 0.2
    @Published var hideWindowLabelsTemporarily: Bool = false
    @Published var edgePadding: CGFloat = 0
    @Published var activeTabs: [WindowTab] = []
    
    // ==========================================
    // 🚀 NATIVE REGISTERED LOGIN STATE ENGINE
    // ==========================================
    @Published var launchAtLogin: Bool = {
        if #available(macOS 13.0, *) {
            return SMAppService.mainApp.status == .enabled
        } else {
            return UserDefaults.standard.bool(forKey: "com.aerobar.launchAtLoginFallback")
        }
    }() {
        didSet {
            if #available(macOS 13.0, *) {
                let mainService = SMAppService.mainApp
                do {
                    if launchAtLogin {
                        if mainService.status != .enabled { try mainService.register() }
                    } else {
                        if mainService.status == .enabled { try mainService.unregister() }
                    }
                } catch {
                    print("SMAppService registration exception error: \(error.localizedDescription)")
                }
            } else {
                let helperBundleIdentifier = "com.aerobar.LauncherHelper" as CFString
                SMLoginItemSetEnabled(helperBundleIdentifier, launchAtLogin)
                UserDefaults.standard.set(launchAtLogin, forKey: "com.aerobar.launchAtLoginFallback")
            }
        }
    }
    
    @Published var checkUpdatesOnLaunch: Bool = true
    @Published var updateFrequency: Int = 0 // 0 = Daily, 1 = Weekly
    
    @Published var pinnedStartApps: [PinnedApp] = [] {
        didSet { savePinnedStartState() }
    }
    @Published var pinnedBarApps: [PinnedApp] = [] {
        didSet { savePinnedBarState() }
    }

    @Published var transitionalWindowLockID: CGWindowID? = nil
    @Published var indexedLocalApps: [DiscoverableApp] = []
    
    @Published var isAccessibilityEnabled: Bool = false
    @Published var showSetupWizard: Bool = true
    @AppStorage("showSearchIcon") var showSearchIcon: Bool = true
    @AppStorage("blurMaterialRaw") var blurMaterialRaw: Int = 8
    @AppStorage("backdropOpacity") var backdropOpacity: Double = 0.50
    @AppStorage("tintColorHex") var tintColorHex: String = "#1E1E1E"
    @AppStorage("showTopBorder") var showTopBorder: Bool = true
    
    var selectedMaterial: NSVisualEffectView.Material {
        switch blurMaterialRaw {
        case 0: return .titlebar
        case 1: return .selection
        case 2: return .menu
        case 3: return .popover
        case 4: return .sidebar
        case 5: return .headerView
        case 6: return .sheet
        case 7: return .windowBackground
        case 8: return .hudWindow
        case 9: return .fullScreenUI
        case 10: return .toolTip
        case 11: return .contentBackground
        case 12: return .underWindowBackground
        case 13: return .underPageBackground
        default: return .hudWindow
        }
    }
    
    init() {
        self.isAccessibilityEnabled = AXIsProcessTrusted()
        self.showSetupWizard = !self.isAccessibilityEnabled
        
        loadPinnedStates()
        ensureFinderDefaultPin() // FIXED: Injects standard system Finder defaults instantly
        setupHighPerformanceSpotlightQuery()
        startPermissionHeartbeat()
    }
    
    private func ensureFinderDefaultPin() {
        let finderBundle = "com.apple.finder"
        let finderObject = PinnedApp(bundleIdentifier: finderBundle, appName: "Finder")
        
        if !pinnedStartApps.contains(where: { $0.bundleIdentifier == finderBundle }) {
            pinnedStartApps.insert(finderObject, at: 0)
        }
        if !pinnedBarApps.contains(where: { $0.bundleIdentifier == finderBundle }) {
            pinnedBarApps.insert(finderObject, at: 0)
        }
    }
    
    private func startPermissionHeartbeat() {
        permissionHeartbeatTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let currentStatus = AXIsProcessTrusted()
            if currentStatus != self.isAccessibilityEnabled {
                DispatchQueue.main.async { self.isAccessibilityEnabled = currentStatus }
            }
        }
    }
    
    private func savePinnedStartState() {
        if let encodedData = try? JSONEncoder().encode(pinnedStartApps) {
            UserDefaults.standard.set(encodedData, forKey: pinnedStartStorageKey)
        }
    }
    
    private func savePinnedBarState() {
        if let encodedData = try? JSONEncoder().encode(pinnedBarApps) {
            UserDefaults.standard.set(encodedData, forKey: pinnedBarStorageKey)
        }
    }
    
    private func loadPinnedStates() {
        if let storedStartData = UserDefaults.standard.data(forKey: pinnedStartStorageKey),
           let decodedStartApps = try? JSONDecoder().decode([PinnedApp].self, from: storedStartData) {
            self.pinnedStartApps = decodedStartApps
        }
        if let storedBarData = UserDefaults.standard.data(forKey: pinnedBarStorageKey),
           let decodedBarApps = try? JSONDecoder().decode([PinnedApp].self, from: storedBarData) {
            self.pinnedBarApps = decodedBarApps
        }
    }
    
    private func setupHighPerformanceSpotlightQuery() {
        let query = NSMetadataQuery()
        self.metadataQuery = query
        query.searchScopes = [NSMetadataQueryLocalComputerScope]
        query.predicate = NSPredicate(format: "kMDItemContentType == 'com.apple.application-bundle'")
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleMetadataQueryUpdates), name: .NSMetadataQueryDidFinishGathering, object: query)
        NotificationCenter.default.addObserver(self, selector: #selector(handleMetadataQueryUpdates), name: .NSMetadataQueryDidUpdate, object: query)
        query.start()
    }
    
    @objc private func handleMetadataQueryUpdates(notification: Notification) {
        guard let query = notification.object as? NSMetadataQuery else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            var foundApps: [DiscoverableApp] = []
            let finderPath = "/System/Library/CoreServices/Finder.app"
            if FileManager.default.fileExists(atPath: finderPath) {
                let finderIcon = NSWorkspace.shared.icon(forFile: finderPath)
                foundApps.append(DiscoverableApp(appName: "Finder", path: finderPath, icon: finderIcon))
            }
            
            query.disableUpdates()
            let resultCount = query.resultCount
            for i in 0..<resultCount {
                guard let item = query.result(at: i) as? NSMetadataItem,
                      let path = item.value(forAttribute: NSMetadataItemPathKey) as? String,
                      let displayName = item.value(forAttribute: NSMetadataItemDisplayNameKey) as? String else { continue }
                if foundApps.contains(where: { $0.path == path }) || path.contains("/Contents/Frameworks/") { continue }
                let icon = NSWorkspace.shared.icon(forFile: path)
                foundApps.append(DiscoverableApp(appName: displayName, path: path, icon: icon))
            }
            query.enableUpdates()
            let sortedApps = foundApps.sorted(by: { $0.appName.localizedCaseInsensitiveCompare($1.appName) == .orderedAscending })
            DispatchQueue.main.async { self.indexedLocalApps = sortedApps }
        }
    }
}
