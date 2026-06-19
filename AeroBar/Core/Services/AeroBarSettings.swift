// AeroBarSettings.swift — Central published-state coordinator. No side-effect logic.
// Owner: Core/Services
import SwiftUI
import AppKit
import Combine
import ServiceManagement
import UniformTypeIdentifiers

class AeroBarSettings: ObservableObject {
    static let shared = AeroBarSettings()

    // MARK: - Live window state (updated by WindowArrangementDaemon)
    @Published var activeTabs: [WindowTab] = []
    @Published var currentSystemFocusedElement: AXUIElement? = nil
    @Published var manuallyHiddenWindowIDs: Set<CGWindowID> = []
    @Published var transitionalWindowLockID: CGWindowID? = nil
    @Published var isStartMenuOpen: Bool = false

    // MARK: - Bar geometry
    @Published var barHeight: CGFloat = 40
    @Published var edgePadding: CGFloat = 0

    // MARK: - Display topology
    @Published var displayTargetMode: DisplayTargetMode = .all {
        didSet { NotificationCenter.default.post(name: .aeroBarMultiDisplayChanged, object: nil) }
    }
    @Published var showOnExternalDisplays: Bool = true {
        didSet { NotificationCenter.default.post(name: .aeroBarMultiDisplayChanged, object: nil) }
    }

    // MARK: - Pinned apps (persisted by PinnedAppsService)
    @Published var pinnedStartApps: [PinnedApp] = [] {
        didSet { PinnedAppsService.shared.savePinnedStart(pinnedStartApps) }
    }
    @Published var pinnedBarApps: [PinnedApp] = [] {
        didSet { PinnedAppsService.shared.savePinnedBar(pinnedBarApps) }
    }

    // MARK: - Spotlight index (populated by SpotlightService)
    @Published var indexedLocalApps: [DiscoverableApp] = []

    // MARK: - Update state (written by UpdateService)
    @Published var isUpdateAvailable: Bool = false
    @Published var latestRemoteVersionString: String = ""
    @Published var downloadURLString: String = ""
    @Published var latestChangelog: String = ""

    // MARK: - Accessibility permission
    @Published var isAccessibilityEnabled: Bool = false
    @Published var showSetupWizard: Bool = true

    // MARK: - User avatar (populated lazily on first Start Menu open)
    @Published var cachedUserAvatar: CGImage? = nil

    // MARK: - UI display flags
    @Published var glassOpacity: Double = 0.2
    @Published var hideWindowLabelsTemporarily: Bool = false

    // MARK: - AppStorage (survives restarts, synced to UserDefaults automatically)
    @AppStorage("showSearchIcon")    var showSearchIcon: Bool = true
    @AppStorage("blurMaterialRaw")   var blurMaterialRaw: Int = 8
    @AppStorage("backdropOpacity")   var backdropOpacity: Double = 0.50
    @AppStorage("tintColorHex")      var tintColorHex: String = "#1E1E1E"
    @AppStorage("showTopBorder")     var showTopBorder: Bool = true
    @AppStorage("showRecommendations") var showRecommendations: Bool = true
    @AppStorage("enableSilentUpdates") var enableSilentUpdates: Bool = false

    // MARK: - Window Previews Customization State
    @AppStorage("com.aerobar.enablePreviews")     var enablePreviews: Bool = true
    @AppStorage("com.aerobar.previewDelayValue")  var previewDelayValue: Double = 0.5
    @AppStorage("com.aerobar.previewSizeWidth")   var previewSizeWidth: Double = 180.0
    @AppStorage("com.aerobar.previewStackVert")   var previewStackVertical: Bool = true

    // MARK: - Orb customisation
    @AppStorage("selectedOrbColorHex")     var selectedOrbColorHex: String = "#FF453A"
    @AppStorage("selectedOrbLogoColorHex") var selectedOrbLogoColorHex: String = "#FFFFFF"
    @AppStorage("savedOrbPresets")         var savedOrbPresetsString: String = "#00F3FF,#BF5AF2,#30D158,#FF453A"

    // MARK: - Update preferences
    @AppStorage("com.aerobar.checkUpdatesOnLaunch") var checkUpdatesOnLaunch: Bool = true
    @AppStorage("com.aerobar.updateFrequency")      var updateFrequency: Int = 0

    // MARK: - Launch at login (write-through to SMAppService)
    @Published var launchAtLogin: Bool = {
        if #available(macOS 13.0, *) { return SMAppService.mainApp.status == .enabled }
        return UserDefaults.standard.bool(forKey: "com.aerobar.launchAtLoginFallback")
    }() {
        didSet { LoginItemService.shared.setEnabled(launchAtLogin) }
    }

    // MARK: - Derived helpers

    var parsedOrbPresets: [String] {
        savedOrbPresetsString.components(separatedBy: ",").filter { !$0.isEmpty }
    }

    func appendOrbPreset(hex: String) {
        var current = parsedOrbPresets
        let clean = hex.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if !current.contains(clean) { current.append(clean) }
        savedOrbPresetsString = current.joined(separator: ",")
    }

    func removeOrbPreset(hex: String) {
        savedOrbPresetsString = parsedOrbPresets
            .filter { $0.lowercased() != hex.lowercased() }
            .joined(separator: ",")
    }

    var selectedMaterial: NSVisualEffectView.Material {
        let map: [Int: NSVisualEffectView.Material] = [
            0: .titlebar, 1: .selection, 2: .menu, 3: .popover, 4: .sidebar,
            5: .headerView, 6: .sheet, 7: .windowBackground, 8: .hudWindow,
            9: .fullScreenUI, 10: .toolTip, 11: .contentBackground,
            12: .underWindowBackground, 13: .underPageBackground
        ]
        return map[blurMaterialRaw] ?? .hudWindow
    }

    // MARK: - Init
    private init() {
        setupRegistry() // 🎯 FIXED: Replaced invalid 'init()' function identifier wrapper context cleanly
    }

    private func setupRegistry() {
        isAccessibilityEnabled = AXIsProcessTrusted()
        showSetupWizard = !isAccessibilityEnabled

        var loaded = PinnedAppsService.shared.load()
        pinnedStartApps = loaded.start
        pinnedBarApps   = loaded.bar
        PinnedAppsService.shared.ensureFinderPinned(start: &loaded.start, bar: &loaded.bar)
    }
}
