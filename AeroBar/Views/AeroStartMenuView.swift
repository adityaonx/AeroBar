import SwiftUI
import AppKit
import UniformTypeIdentifiers
import CoreServices
import Collaboration
import CoreServices.DictionaryServices

// ==========================================
// 📦 CORE STRUCTS & MODELS
// ==========================================
struct LocalSystemApp: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let bundleID: String
    let pathURL: URL
    let icon: NSImage
}

struct RecentFinderItem: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let fileURL: URL
    let fileExtension: String
    let accessTimeDescription: String
}

// ==========================================
// 🏢 MAIN START MENU VIEW
// ==========================================
struct AeroStartMenuView: View {
    @StateObject private var settings = AeroBarSettings.shared
    @Environment(\.colorScheme) private var systemColorScheme
    @State private var searchInput: String = ""
    @FocusState private var isSearchFieldFocused: Bool
    @State private var showSettings: Bool = false
    @State private var showCustomizer: Bool = false
    
    @State private var dynamicSystemAccountName: String = ""
    @State private var dynamicSystemAccountImage: Image? = nil
    
    @State private var localizedAppsRegistry: [LocalSystemApp] = []
    @State private var recentFinderItems: [RecentFinderItem] = []
    
    @State private var spotlightQuery: NSMetadataQuery?
    
    private let pinnedColumns = Array(repeating: GridItem(.fixed(64), spacing: 16), count: 6)
    
    // MARK: - 🔍 HIGH-PERFORMANCE SEARCH FILTER COMPUTATIONS
    // 🎯 THE FIX: Computed filter properties break type evaluation bottlenecks
    // and provide instant, zero-latency UI matching across text updates.
    private var filteredApplications: [LocalSystemApp] {
        if searchInput.isEmpty { return localizedAppsRegistry }
        return localizedAppsRegistry.filter { $0.name.localizedCaseInsensitiveContains(searchInput) }
    }
    
    private var filteredPinnedApps: [PinnedApp] {
        if searchInput.isEmpty { return settings.pinnedStartApps }
        return settings.pinnedStartApps.filter { $0.appName.localizedCaseInsensitiveContains(searchInput) }
    }
    
    private var filteredRecommendations: [RecentFinderItem] {
        if searchInput.isEmpty { return recentFinderItems }
        return recentFinderItems.filter { $0.name.localizedCaseInsensitiveContains(searchInput) }
    }
    
    private var alphabetizedGroupKeys: [String] {
        Array(Set(filteredApplications.map { String($0.name.prefix(1)).uppercased() })).sorted()
    }
    
    // MARK: - 🎯 Intelligent Contrast Logic Engine
    private var isVisualBackdropBright: Bool {
        if systemColorScheme == .light { return true }
        return settings.blurMaterialRaw == 7
    }
    
    private var optimalTextColor: Color {
        return isVisualBackdropBright ? Color(red: 0.10, green: 0.10, blue: 0.12) : Color(red: 0.98, green: 0.98, blue: 0.98)
    }

    private var optimalSubtextColor: Color {
        return isVisualBackdropBright ? Color(red: 0.42, green: 0.42, blue: 0.46) : Color(red: 0.65, green: 0.65, blue: 0.68)
    }
    
    private var layoutBevelColor: Color {
        return isVisualBackdropBright ? Color.black.opacity(0.12) : Color.white.opacity(0.14)
    }
    
    var body: some View {
        HStack(spacing: 0) {
            Spacer().frame(width: 48)
            
            VStack(spacing: 0) {
                // ==========================================
                // 👤 TOP HEADER SECTION
                // ==========================================
                HStack(spacing: 16) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(colors: [.accentColor, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                            
                            if let cgAvatar = settings.cachedUserAvatar {
                                Image(cgAvatar, scale: 1.0, label: Text("User Avatar"))
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 38, height: 38)
                                    .clipShape(Circle())
                            } else {
                                if let platformFinderIcon = NSWorkspace.shared.icon(forFile: "/System/Library/CoreServices/Finder.app") as NSImage? {
                                    var proposalRect = CGRect(x: 0, y: 0, width: 38, height: 38)
                                    if let cgImage = platformFinderIcon.cgImage(forProposedRect: &proposalRect, context: nil, hints: nil) {
                                        Image(cgImage, scale: 1.0, label: Text("User Avatar"))
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 38, height: 38)
                                            .clipShape(Circle())
                                    }
                                }
                            }
                        }
                        .frame(width: 38, height: 38)
                        .overlay(Circle().stroke(optimalTextColor.opacity(0.15), lineWidth: 1))
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(dynamicSystemAccountName.isEmpty ? NSFullUserName() : dynamicSystemAccountName)
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundColor(optimalTextColor)
                        }
                    }
                    Spacer()
                    
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(optimalSubtextColor)
                        
                        TextField("Search Apps", text: $searchInput)
                                                    .textFieldStyle(PlainTextFieldStyle())
                                                    .font(.system(size: 13, weight: .medium))
                                                    .foregroundColor(optimalTextColor)
                                                    // 🎯 THE FIX: Binds this native text block to our system focus tracker
                                                    .focused($isSearchFieldFocused)
                    }
                    .padding(.horizontal, 12)
                    .frame(width: 260, height: 32)
                    .background(isVisualBackdropBright ? Color.black.opacity(0.06) : Color.white.opacity(0.12))
                    .cornerRadius(8)
                }
                .padding(.horizontal, 12)
                .padding(.top, 22)
                .padding(.bottom, 16)
                
                Divider().background(optimalTextColor.opacity(0.12))
                
                // ==========================================
                // 🏢 MAIN TRIPLE PANEL ARCHITECTURE
                // ==========================================
                HStack(alignment: .top, spacing: 0) {
                    
                    // 📂 1. LEFT SIDEBAR: Applications Stream
                    VStack(alignment: .leading, spacing: 12) {
                        Text(searchInput.isEmpty ? "All Applications" : "Search Results")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(optimalSubtextColor)
                            .padding(.leading, 12)
                        
                        ScrollView(.vertical, showsIndicators: false) {
                            VStack(alignment: .leading, spacing: 14) {
                                if filteredApplications.isEmpty {
                                    Text("No matching applications.")
                                        .font(.system(size: 12))
                                        .foregroundColor(optimalSubtextColor)
                                        .padding(.leading, 12)
                                        .padding(.top, 4)
                                } else {
                                    ForEach(alphabetizedGroupKeys, id: \.self) { letter in
                                        Text(letter)
                                            .font(.system(size: 13, weight: .bold, design: .rounded))
                                            .foregroundColor(.accentColor.opacity(0.9))
                                            .padding(.leading, 12)
                                        
                                        ForEach(filteredApplications.filter { String($0.name.prefix(1)).uppercased() == letter }) { app in
                                            StartSidebarRow(app: app, optimalTextColor: optimalTextColor, optimalSubtextColor: optimalSubtextColor, isVisualBackdropBright: isVisualBackdropBright) {
                                                launchAppByPath(url: app.pathURL)
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 4)
                        }
                    }
                    .frame(width: 224)
                    .padding(.top, 16)
                    .padding(.bottom, 12)
                    
                    StartMenuVerticalDivider(layoutBevelColor: layoutBevelColor)
                        .padding(.leading, 12)
                    
                    // 📌 2. CENTER PANEL: Shortcuts Grid
                                        VStack(alignment: .leading, spacing: 12) {
                                            Text(searchInput.isEmpty ? "Pinned Shortcuts" : "Matching Shortcuts")
                                                .font(.system(size: 11, weight: .bold))
                                                .foregroundColor(optimalSubtextColor)
                                                .padding(.leading, 15) // 🎯 THE FIX: Adds a clean layout gutter buffer so the text never hits the line!
                        
                        ScrollView(.vertical, showsIndicators: false) {
                            if filteredPinnedApps.isEmpty {
                                CustomPlaceholderPanel(
                                    iconName: searchInput.isEmpty ? "square.grid.3x3.square" : "magnifyingglass",
                                    labelText: searchInput.isEmpty ? "Right-click apps to pin shortcuts." : "No shortcuts match '\(searchInput)'.",
                                    optimalSubtextColor: optimalSubtextColor
                                )
                            } else {
                                LazyVGrid(columns: pinnedColumns, spacing: 18) {
                                    ForEach(filteredPinnedApps) { app in
                                        Button(action: {
                                            NotificationCenter.default.post(name: Notification.Name("dismissStartMenuWindow"), object: nil)
                                            if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: app.bundleIdentifier) {
                                                NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration(), completionHandler: nil)
                                            }
                                        }) {
                                            VStack(spacing: 6) {
                                                Image(nsImage: app.appIcon)
                                                    .resizable()
                                                    .frame(width: 32, height: 32)
                                                    .shadow(color: .black.opacity(isVisualBackdropBright ? 0.12 : 0.35), radius: 2, y: 1)
                                                
                                                Text(app.appName)
                                                    .font(.system(size: 11, weight: .semibold))
                                                    .foregroundColor(optimalTextColor.opacity(0.90))
                                                    .lineLimit(1)
                                                    .frame(width: 64, alignment: .center)
                                            }
                                            .frame(width: 64, height: 72)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        .contextMenu {
                                            if app.bundleIdentifier == "com.apple.finder" {
                                                Text("System Core: Unpin Locked")
                                                    .font(.system(size: 11))
                                                    .foregroundColor(optimalSubtextColor)
                                            } else {
                                                Button(role: .destructive) {
                                                    settings.pinnedStartApps.removeAll(where: { $0.bundleIdentifier == app.bundleIdentifier })
                                                } label: { Label("Unpin from Start", systemImage: "pin.slash") }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .frame(width: 420)
                    .padding(.top, 16)
                    .padding(.bottom, 12)
                    .padding(.horizontal, 14)
                    
                    // 📑 3. RIGHT PANEL: Recommendations Section
                    if settings.showRecommendations {
                        StartMenuVerticalDivider(layoutBevelColor: layoutBevelColor)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text(searchInput.isEmpty ? "Recommended" : "Matching Documents")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(optimalSubtextColor)
                            
                            ScrollView(.vertical, showsIndicators: false) {
                                if filteredRecommendations.isEmpty {
                                    CustomPlaceholderPanel(
                                        iconName: searchInput.isEmpty ? "doc.text.magnifyingglass" : "doc.text.fill",
                                        labelText: searchInput.isEmpty ? "Items you open will appear here." : "No matching recent files.",
                                        optimalSubtextColor: optimalSubtextColor
                                    )
                                } else {
                                    VStack(spacing: 8) {
                                        ForEach(filteredRecommendations) { item in
                                            StartRecommendedRow(
                                                fallbackIcon: "doc.text",
                                                title: item.name,
                                                time: item.accessTimeDescription,
                                                optimalTextColor: optimalTextColor,
                                                optimalSubtextColor: optimalSubtextColor,
                                                isVisualBackdropBright: isVisualBackdropBright,
                                                fileExtension: item.fileExtension,
                                                filePathFallback: item.fileURL.path
                                            )
                                        }
                                    }
                                }
                            }
                        }
                        .frame(width: 240)
                        .padding(.top, 16)
                        .padding(.bottom, 12)
                        .padding(.leading, 14)
                        .padding(.trailing, 20)
                    }
                }
                .frame(height: 392)
                
                // ==========================================
                // 🔋 UTILITY BOTTOM RAIL
                // ==========================================
                ZStack {
                    Color.clear
                    HStack {
                        Spacer()
                        HStack(spacing: 16) {
                            Button(action: { showCustomizer.toggle() }) {
                                Image(systemName: "paintpalette").font(.system(size: 15)).foregroundColor(optimalTextColor.opacity(0.65))
                            }
                            .buttonStyle(PlainButtonStyle())
                            .popover(isPresented: $showCustomizer, arrowEdge: .top) { AeroBarAppearanceCustomizerView() }
                            
                            Button(action: { showSettings.toggle() }) {
                                Image(systemName: "gearshape").font(.system(size: 15)).foregroundColor(optimalTextColor.opacity(0.65))
                            }
                            .buttonStyle(PlainButtonStyle())
                            .popover(isPresented: $showSettings, arrowEdge: .top) { AeroBarSettingsView() }
                        }
                        .padding(.trailing, 16)
                    }
                }
                .frame(height: 46)
            }
            Spacer().frame(width: 24)
        }
        .frame(width: settings.showRecommendations ? 1010 : 760, height: 530)
        .background(
            ZStack {
                VisualEffectBlurView(material: settings.selectedMaterial, blendingMode: .withinWindow, state: .active)
                Color(hex: settings.tintColorHex)
                    .opacity(settings.backdropOpacity * 0.4)
                    .blendMode(.multiply)
                Color(hex: settings.tintColorHex)
                    .opacity(settings.backdropOpacity * 0.3)
                    .blendMode(.overlay)
            }
        )
        .cornerRadius(18)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(layoutBevelColor.opacity(0.5), lineWidth: 1.5))
        .onAppear {
                    let dynamicFullName = NSFullUserName()
                    self.dynamicSystemAccountName = dynamicFullName.isEmpty ? NSUserName().capitalized : dynamicFullName
                    buildDynamicApplicationsRegistry()
                    startSpotlightRecentFilesQuery()
                    
                    // 🎯 THE FIX: Forces the window controller to slam the cursor focus down into the search bar instantly on load!
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        self.isSearchFieldFocused = true
                    }
                }
    }
    
    private func startSpotlightRecentFilesQuery() {
        if let existingQuery = spotlightQuery {
            existingQuery.stop()
            NotificationCenter.default.removeObserver(self, name: .NSMetadataQueryDidFinishGathering, object: existingQuery)
        }
        
        let query = NSMetadataQuery()
        let referenceDate = Date(timeIntervalSince1970: 0) as NSDate
        query.predicate = NSPredicate(format: "%K > %@", NSMetadataItemLastUsedDateKey, referenceDate)
        query.searchScopes = [NSMetadataQueryUserHomeScope]
        query.sortDescriptors = [NSSortDescriptor(key: NSMetadataItemLastUsedDateKey, ascending: false)]
        
        self.spotlightQuery = query
        
        NotificationCenter.default.addObserver(forName: .NSMetadataQueryDidFinishGathering, object: query, queue: .main) { [weak query] _ in
            guard let query = query else { return }
            var verifiedItems: [RecentFinderItem] = []
            for i in 0..<query.resultCount {
                if verifiedItems.count >= 6 { break }
                guard let item = query.result(at: i) as? NSMetadataItem,
                      let path = item.value(forAttribute: NSMetadataItemPathKey) as? String else { continue }
                let fileURL = URL(fileURLWithPath: path)
                let fileExt = fileURL.pathExtension
                if fileExt == "app" || fileExt == "plist" || fileExt == "appiconset" || fileURL.lastPathComponent.hasPrefix(".") || path.contains("/Library/") { continue }
                
                let timeLabels = ["Just now", "Minutes ago", "An hour ago", "Earlier today", "Today", "Yesterday"]
                let accessLabel = verifiedItems.count < timeLabels.count ? timeLabels[verifiedItems.count] : "Recently"
                
                verifiedItems.append(RecentFinderItem(name: fileURL.lastPathComponent, fileURL: fileURL, fileExtension: fileExt, accessTimeDescription: accessLabel))
            }
            self.recentFinderItems = verifiedItems
        }
        query.start()
    }
    
    private func buildDynamicApplicationsRegistry() {
        DispatchQueue.global(qos: .userInitiated).async {
            var rawDiscoveredApps: [LocalSystemApp] = []
            let workspace = NSWorkspace.shared
            let fileManager = FileManager.default
            for folderPath in ["/Applications", "/System/Applications"] {
                guard let directoryEnumerator = fileManager.enumerator(at: URL(fileURLWithPath: folderPath), includingPropertiesForKeys: [.isApplicationKey], options: [.skipsSubdirectoryDescendants, .skipsHiddenFiles]) else { continue }
                for case let fileURL as URL in directoryEnumerator where fileURL.pathExtension == "app" {
                    let appName = fileURL.deletingPathExtension().lastPathComponent
                    let bundleIDString = Bundle(url: fileURL)?.bundleIdentifier ?? "com.aerobar.placeholder"
                    let discoveredItem = LocalSystemApp(name: appName, bundleID: bundleIDString, pathURL: fileURL, icon: workspace.icon(forFile: fileURL.path))
                    if !rawDiscoveredApps.contains(where: { $0.bundleID == bundleIDString }) { rawDiscoveredApps.append(discoveredItem) }
                }
            }
            DispatchQueue.main.async {
                self.localizedAppsRegistry = rawDiscoveredApps.sorted {
                    $0.name.localizedCompare($1.name) == .orderedAscending
                }
            }
        }
    }
    
    private func launchAppByPath(url: URL) {
        NotificationCenter.default.post(name: Notification.Name("dismissStartMenuWindow"), object: nil)
        NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration(), completionHandler: nil)
    }
}

// ==========================================
// 🛠️ INLINE SUBVIEW COMPONENTS
// ==========================================
struct CustomPlaceholderPanel: View {
    let iconName: String
    let labelText: String
    let optimalSubtextColor: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: iconName)
                .font(.system(size: 24))
                .foregroundColor(optimalSubtextColor.opacity(0.35))
            Text(labelText)
                .font(.system(size: 12, design: .rounded))
                .foregroundColor(optimalSubtextColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        }
        .frame(maxWidth: .infinity, minHeight: 220)
    }
}

struct StartSidebarRow: View {
    let app: LocalSystemApp
    let optimalTextColor: Color
    let optimalSubtextColor: Color
    let isVisualBackdropBright: Bool
    let action: () -> Void
    
    @State private var isHovering = false
    @ObservedObject var settings = AeroBarSettings.shared
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(nsImage: app.icon)
                    .resizable()
                    .frame(width: 20, height: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(app.name)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(optimalTextColor)
                    Text("Application")
                        .font(.system(size: 10))
                        .foregroundColor(optimalSubtextColor)
                }
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(isHovering ? optimalTextColor.opacity(0.08) : (!isVisualBackdropBright ? Color.white.opacity(0.02) : Color.black.opacity(0.03)))
            .cornerRadius(6)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in isHovering = hovering }
        .contextMenu {
            Button {
                if !settings.pinnedStartApps.contains(where: { $0.bundleIdentifier == app.bundleID }) {
                    settings.pinnedStartApps.append(PinnedApp(bundleIdentifier: app.bundleID, appName: app.name))
                }
            } label: { Label("📌 Pin to Start", systemImage: "square.grid.3x3.square") }
            
            Button {
                if !settings.pinnedBarApps.contains(where: { $0.bundleIdentifier == app.bundleID }) {
                    settings.pinnedBarApps.append(PinnedApp(bundleIdentifier: app.bundleID, appName: app.name))
                }
            } label: { Label("📌 Pin to Taskbar", systemImage: "dock.arrow.up.bars") }
        }
    }
}

struct StartRecommendedRow: View {
    let fallbackIcon: String
    let title: String
    let time: String
    let optimalTextColor: Color
    let optimalSubtextColor: Color
    let isVisualBackdropBright: Bool
    
    var fileExtension: String? = nil
    var filePathFallback: String? = nil
    @State private var isHovering = false
    
    var body: some View {
        Button(action: {
            NotificationCenter.default.post(name: Notification.Name("dismissStartMenuWindow"), object: nil)
            if let targetPath = filePathFallback {
                NSWorkspace.shared.open(URL(fileURLWithPath: targetPath))
            }
        }) {
            HStack(spacing: 12) {
                Image(nsImage: nativeFileIcon)
                    .resizable()
                    .frame(width: 22, height: 22)
                    .shadow(color: .black.opacity(!isVisualBackdropBright ? 0.25 : 0.05), radius: 1, y: 0.5)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(optimalTextColor)
                        .lineLimit(1)
                    Text(time)
                        .font(.system(size: 10))
                        .foregroundColor(optimalSubtextColor)
                }
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(isHovering ? optimalTextColor.opacity(0.08) : (!isVisualBackdropBright ? Color.white.opacity(0.02) : Color.black.opacity(0.03)))
            .cornerRadius(6)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in isHovering = hovering }
    }
    
    private var nativeFileIcon: NSImage {
        if let ext = fileExtension, let type = UTType(filenameExtension: ext) {
            return NSWorkspace.shared.icon(for: type)
        }
        return NSWorkspace.shared.icon(for: UTType.text)
    }
}

struct StartMenuVerticalDivider: View {
    let layoutBevelColor: Color
    var body: some View {
        Rectangle()
            .fill(layoutBevelColor.opacity(0.2))
            .frame(width: 1)
            .frame(maxHeight: .infinity)
    }
}

// ==========================================
// 🛠️ DATA TELEMETRY HEX CONVERTER UTILITY
// ==========================================
extension Data {
    init?(fromTelemetryHexString hexString: String) {
        let cleanLen = hexString.count / 2
        var dataBuffer = Data(capacity: cleanLen)
        var stringIndex = hexString.startIndex
        
        for _ in 0..<cleanLen {
            let doubleOffsetIndex = hexString.index(stringIndex, offsetBy: 2)
            let substringByte = hexString[stringIndex..<doubleOffsetIndex]
            
            if let targetInt = Int(String(substringByte), radix: 16) {
                dataBuffer.append(UInt8(targetInt))
            } else {
                return nil
            }
            stringIndex = doubleOffsetIndex
        }
        self = dataBuffer
    }
}
