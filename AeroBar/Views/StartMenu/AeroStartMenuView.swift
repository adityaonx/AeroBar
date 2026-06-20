// AeroStartMenuView.swift — Start Menu root layout.
// Owner: Views/StartMenu
// Depends on: Core/Services/AeroBarSettings, Core/Models/*, Core/Utilities/Notifications
//
// LAYOUT NOTE: The panel frame width is driven by AeroBarSettings.showRecommendations.
// When this toggles, the panel is resized by StartMenuController.resizeIfVisible() so
// the SwiftUI layout always has the correct bounding box — no shift on toggle.

import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct AeroStartMenuView: View {
    @StateObject private var settings = AeroBarSettings.shared
    @Environment(\.colorScheme) private var colorScheme

    @State private var searchInput: String = ""
    @FocusState private var searchFocused: Bool
    @State private var showSettings   = false
    @State private var showCustomizer = false
    @State private var userName       = ""
    @State private var localApps: [LocalSystemApp]     = []
    @State private var recentItems: [RecentFinderItem] = []
    @State private var spotlightQuery: NSMetadataQuery?
    @State private var draggedStartItem: PinnedApp? = nil

    // MARK: - Filtered computed properties

    private var filteredApps: [LocalSystemApp] {
        searchInput.isEmpty ? localApps : localApps.filter { $0.name.localizedCaseInsensitiveContains(searchInput) }
    }
    private var filteredPinned: [PinnedApp] {
        searchInput.isEmpty ? settings.pinnedStartApps : settings.pinnedStartApps.filter { $0.appName.localizedCaseInsensitiveContains(searchInput) }
    }
    private var filteredRecent: [RecentFinderItem] {
        searchInput.isEmpty ? recentItems : recentItems.filter { $0.name.localizedCaseInsensitiveContains(searchInput) }
    }
    private var alphabetKeys: [String] {
        Array(Set(filteredApps.map { String($0.name.prefix(1)).uppercased() })).sorted()
    }

    // MARK: - Adaptive contrast

    private var backdropIsBright: Bool { colorScheme == .light || settings.blurMaterialRaw == 7 }
    private var textColor:    Color { backdropIsBright ? Color(red: 0.10, green: 0.10, blue: 0.12) : Color(red: 0.98, green: 0.98, blue: 0.98) }
    private var subtextColor: Color { backdropIsBright ? Color(red: 0.42, green: 0.42, blue: 0.46) : Color(red: 0.65, green: 0.65, blue: 0.68) }
    private var bevelColor:   Color { backdropIsBright ? Color.black.opacity(0.12) : Color.white.opacity(0.14) }

    // MARK: - Body

    var body: some View {
        HStack(spacing: 0) {
            Spacer().frame(width: 48)
            VStack(spacing: 0) {
                headerRow
                Divider().background(textColor.opacity(0.12))
                mainPanels
                utilityRail
            }
            Spacer().frame(width: 24)
        }
        // Width is fixed at panel creation time by StartMenuController.
        // The animation here only applies to in-place toggles (e.g. if resizeIfVisible
        // is called while the menu is open). Using GeometryReader instead of a fixed
        // frame means the layout fills whatever width the panel provides.
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(menuBackground)
        .cornerRadius(18)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(bevelColor.opacity(0.5), lineWidth: 1.5))
        .onAppear {
            userName = NSFullUserName().isEmpty ? NSUserName().capitalized : NSFullUserName()
            buildAppsRegistry()
            startRecentFilesQuery()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { searchFocused = true }
        }
        // When recommendations toggle changes while the menu is open, ask the controller
        // to resize the panel so the layout gets the right bounding box.
        .onChange(of: settings.showRecommendations) {
            NotificationCenter.default.post(name: .startMenuResizeNeeded, object: nil)
        }
    }

    // MARK: - Sections

    private var headerRow: some View {
        HStack(spacing: 16) {
            userAvatar
            Spacer()
            searchField
        }
        .padding(.horizontal, 12).padding(.top, 22).padding(.bottom, 16)
    }

    private var userAvatar: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(LinearGradient(colors: [.accentColor, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                if let cg = settings.cachedUserAvatar {
                    Image(cg, scale: 1, label: Text("Avatar")).resizable().scaledToFill()
                        .frame(width: 38, height: 38).clipShape(Circle())
                }
            }
            .frame(width: 38, height: 38)
            .overlay(Circle().stroke(textColor.opacity(0.15), lineWidth: 1))

            Text(userName).font(.system(size: 15, weight: .bold, design: .rounded)).foregroundColor(textColor)
        }
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").font(.system(size: 13, weight: .semibold)).foregroundColor(subtextColor)
            TextField("Search Apps", text: $searchInput)
                .textFieldStyle(.plain)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(textColor)
                .focused($searchFocused)
        }
        .padding(.horizontal, 12)
        .frame(width: 260, height: 32)
        .background(backdropIsBright ? Color.black.opacity(0.06) : Color.white.opacity(0.12))
        .cornerRadius(8)
    }

    private var mainPanels: some View {
        HStack(alignment: .top, spacing: 0) {
            appsPanel
            menuDivider
            pinnedPanel
            if settings.showRecommendations {
                menuDivider
                recentPanel
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 392)
    }

    private var appsPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            panelLabel(searchInput.isEmpty ? "All Applications" : "Search Results")
                .padding(.leading, 12)
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    if filteredApps.isEmpty {
                        Text("No matching applications.")
                            .font(.system(size: 12)).foregroundColor(subtextColor).padding(.leading, 12)
                    } else {
                        ForEach(alphabetKeys, id: \.self) { letter in
                            Text(letter).font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(.accentColor.opacity(0.9)).padding(.leading, 12)
                            ForEach(filteredApps.filter { String($0.name.prefix(1)).uppercased() == letter }) { app in
                                StartSidebarRow(app: app, textColor: textColor, subtextColor: subtextColor,
                                                backdropBright: backdropIsBright) { launch(app: app) }
                            }
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .frame(width: 224).padding(.top, 16).padding(.bottom, 12)
    }

    private var pinnedPanel: some View {
        let cols = Array(repeating: GridItem(.fixed(64), spacing: 16), count: 6)
        return VStack(alignment: .leading, spacing: 12) {
            panelLabel(searchInput.isEmpty ? "Pinned Shortcuts" : "Matching Shortcuts").padding(.leading, 15)
            ScrollView(.vertical, showsIndicators: false) {
                if filteredPinned.isEmpty {
                    StartMenuPlaceholder(icon: searchInput.isEmpty ? "square.grid.3x3.square" : "magnifyingglass",
                                         label: searchInput.isEmpty ? "Right-click apps to pin shortcuts." : "No shortcuts match '\(searchInput)'.",
                                         subtextColor: subtextColor)
                } else {
                    LazyVGrid(columns: cols, spacing: 18) {
                        ForEach(filteredPinned) { app in pinnedCell(app) }
                    }
                }
            }
        }
        // Pinned panel expands to fill remaining space when recommendations are off
        .frame(maxWidth: settings.showRecommendations ? 420 : .infinity)
        .padding(.top, 16).padding(.bottom, 12).padding(.horizontal, 14)
    }

    private var recentPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            panelLabel(searchInput.isEmpty ? "Recommended" : "Matching Documents")
            ScrollView(.vertical, showsIndicators: false) {
                if filteredRecent.isEmpty {
                    StartMenuPlaceholder(icon: "doc.text.magnifyingglass",
                                         label: "Items you open will appear here.",
                                         subtextColor: subtextColor)
                } else {
                    VStack(spacing: 8) {
                        ForEach(filteredRecent) { item in
                            StartRecommendedRow(item: item, textColor: textColor, subtextColor: subtextColor,
                                               backdropBright: backdropIsBright)
                        }
                    }
                }
            }
        }
        .frame(width: 240).padding(.top, 16).padding(.bottom, 12).padding(.leading, 14).padding(.trailing, 20)
    }

    private var utilityRail: some View {
        ZStack {
            Color.clear
            HStack {
                Spacer()
                HStack(spacing: 16) {
                    Button(action: { showCustomizer.toggle() }) {
                        Image(systemName: "paintpalette").font(.system(size: 15)).foregroundColor(textColor.opacity(0.65))
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $showCustomizer, arrowEdge: .top) { AeroBarAppearanceCustomizerView() }

                    Button(action: { showSettings.toggle() }) {
                        Image(systemName: "gearshape").font(.system(size: 15)).foregroundColor(textColor.opacity(0.65))
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $showSettings, arrowEdge: .top) { AeroBarSettingsView() }
                }
                .padding(.trailing, 16)
            }
        }
        .frame(height: 46)
    }

    private var menuBackground: some View {
        ZStack {
            VisualEffectBlurView(material: settings.selectedMaterial, blendingMode: .withinWindow, state: .active)
            Color(settings.tintColorHex).opacity(settings.backdropOpacity * 0.4).blendMode(.multiply)
            Color(settings.tintColorHex).opacity(settings.backdropOpacity * 0.3).blendMode(.overlay)
        }
    }

    private var menuDivider: some View {
        Rectangle().fill(bevelColor.opacity(0.2)).frame(width: 1).frame(maxHeight: .infinity).padding(.leading, 12)
    }

    private func pinnedCell(_ app: PinnedApp) -> some View {
        Button(action: {
            NotificationCenter.default.post(name: .dismissStartMenuWindow, object: nil)
            if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: app.bundleIdentifier) {
                NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
            }
        }) {
            VStack(spacing: 6) {
                Image(nsImage: app.appIcon).resizable().frame(width: 32, height: 32)
                    .shadow(color: .black.opacity(backdropIsBright ? 0.12 : 0.35), radius: 2, y: 1)
                Text(app.appName).font(.system(size: 11, weight: .semibold)).foregroundColor(textColor.opacity(0.90))
                    .lineLimit(1).frame(width: 64, alignment: .center)
            }
            .frame(width: 64, height: 72)
        }
        .buttonStyle(.plain)
        .onDrag {
            self.draggedStartItem = app
            return NSItemProvider(object: app.bundleIdentifier as NSString)
        }
        .onDrop(of: [.text], delegate: StartMenuPinnedDropDelegate(item: app, settings: settings, dragged: $draggedStartItem))
        .contextMenu {
            if app.bundleIdentifier == "com.apple.finder" {
                Text("System Core: Unpin Locked").font(.system(size: 11)).foregroundColor(subtextColor)
            } else {
                Button(role: .destructive) {
                    settings.pinnedStartApps.removeAll { $0.bundleIdentifier == app.bundleIdentifier }
                } label: { Label("Unpin from Start", systemImage: "pin.slash") }
            }
        }
    }

    private func panelLabel(_ text: String) -> some View {
        Text(text).font(.system(size: 11, weight: .bold)).foregroundColor(subtextColor)
    }

    private func launch(app: LocalSystemApp) {
        NotificationCenter.default.post(name: .dismissStartMenuWindow, object: nil)
        NSWorkspace.shared.openApplication(at: app.pathURL, configuration: NSWorkspace.OpenConfiguration())
    }

    // MARK: - Data loading

    private func buildAppsRegistry() {
        DispatchQueue.global(qos: .userInitiated).async {
            var found: [LocalSystemApp] = []
            let ws = NSWorkspace.shared
            for folder in ["/Applications", "/System/Applications"] {
                guard let enumerator = FileManager.default.enumerator(
                    at: URL(fileURLWithPath: folder),
                    includingPropertiesForKeys: [.isApplicationKey],
                    options: [.skipsSubdirectoryDescendants, .skipsHiddenFiles]
                ) else { continue }
                for case let url as URL in enumerator where url.pathExtension == "app" {
                    let name = url.deletingPathExtension().lastPathComponent
                    let bid  = Bundle(url: url)?.bundleIdentifier ?? "com.aerobar.placeholder"
                    if !found.contains(where: { $0.bundleID == bid }) {
                        found.append(LocalSystemApp(name: name, bundleID: bid, pathURL: url, icon: ws.icon(forFile: url.path)))
                    }
                }
            }
            let sorted = found.sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
            DispatchQueue.main.async { localApps = sorted }
        }
    }

    private func startRecentFilesQuery() {
        spotlightQuery?.stop()
        let q = NSMetadataQuery()
        q.predicate = NSPredicate(format: "%K > %@", NSMetadataItemLastUsedDateKey, Date(timeIntervalSince1970: 0) as NSDate)
        q.searchScopes = [NSMetadataQueryUserHomeScope]
        q.sortDescriptors = [NSSortDescriptor(key: NSMetadataItemLastUsedDateKey, ascending: false)]
        spotlightQuery = q
        NotificationCenter.default.addObserver(forName: .NSMetadataQueryDidFinishGathering, object: q, queue: .main) { [weak q] _ in
            guard let q else { return }
            let labels = ["Just now","Minutes ago","An hour ago","Earlier today","Today","Yesterday"]
            var items: [RecentFinderItem] = []
            for i in 0..<q.resultCount {
                guard items.count < 6,
                      let item = q.result(at: i) as? NSMetadataItem,
                      let path = item.value(forAttribute: NSMetadataItemPathKey) as? String
                else { continue }
                let url = URL(fileURLWithPath: path)
                let ext = url.pathExtension
                if ["app","plist","appiconset"].contains(ext) || url.lastPathComponent.hasPrefix(".") || path.contains("/Library/") { continue }
                items.append(RecentFinderItem(name: url.lastPathComponent, fileURL: url, fileExtension: ext,
                                               accessTimeDescription: items.count < labels.count ? labels[items.count] : "Recently"))
            }
            self.recentItems = items
        }
        q.start()
    }
}

// MARK: - Start Menu subviews

struct StartSidebarRow: View {
    let app: LocalSystemApp
    let textColor: Color
    let subtextColor: Color
    let backdropBright: Bool
    let action: () -> Void
    @State private var hovering = false
    @ObservedObject private var settings = AeroBarSettings.shared

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(nsImage: app.icon).resizable().frame(width: 20, height: 20)
                VStack(alignment: .leading, spacing: 2) {
                    Text(app.name).font(.system(size: 13, weight: .semibold)).foregroundColor(textColor)
                    Text("Application").font(.system(size: 10)).foregroundColor(subtextColor)
                }
                Spacer()
            }
            .padding(.horizontal, 10).padding(.vertical, 8)
            .background(hovering ? textColor.opacity(0.08) : (!backdropBright ? Color.white.opacity(0.02) : Color.black.opacity(0.03)))
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .contextMenu {
            Button { if !settings.pinnedStartApps.contains(where: { $0.bundleIdentifier == app.bundleID }) {
                settings.pinnedStartApps.append(PinnedApp(bundleIdentifier: app.bundleID, appName: app.name)) }
            } label: { Label("Pin to Start", systemImage: "square.grid.3x3.square") }

            Button { if !settings.pinnedBarApps.contains(where: { $0.bundleIdentifier == app.bundleID }) {
                settings.pinnedBarApps.append(PinnedApp(bundleIdentifier: app.bundleID, appName: app.name)) }
            } label: { Label("Pin to Taskbar", systemImage: "dock.arrow.up.bars") }
        }
    }
}

struct StartRecommendedRow: View {
    let item: RecentFinderItem
    let textColor: Color
    let subtextColor: Color
    let backdropBright: Bool
    @State private var hovering = false

    var body: some View {
        Button(action: {
            NotificationCenter.default.post(name: .dismissStartMenuWindow, object: nil)
            NSWorkspace.shared.open(item.fileURL)
        }) {
            HStack(spacing: 12) {
                Image(nsImage: fileIcon).resizable().frame(width: 22, height: 22)
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name).font(.system(size: 13, weight: .medium)).foregroundColor(textColor).lineLimit(1)
                    Text(item.accessTimeDescription).font(.system(size: 10)).foregroundColor(subtextColor)
                }
                Spacer()
            }
            .padding(.horizontal, 10).padding(.vertical, 8)
            .background(hovering ? textColor.opacity(0.08) : (!backdropBright ? Color.white.opacity(0.02) : Color.black.opacity(0.03)))
            .cornerRadius(6)
        }
        .buttonStyle(.plain).onHover { hovering = $0 }
    }

    private var fileIcon: NSImage {
        if let type = UTType(filenameExtension: item.fileExtension) { return NSWorkspace.shared.icon(for: type) }
        return NSWorkspace.shared.icon(for: UTType.text)
    }
}

struct StartMenuPlaceholder: View {
    let icon: String
    let label: String
    let subtextColor: Color

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 24)).foregroundColor(subtextColor.opacity(0.35))
            Text(label).font(.system(size: 12, design: .rounded)).foregroundColor(subtextColor)
                .multilineTextAlignment(.center).padding(.horizontal, 16)
        }
        .frame(maxWidth: .infinity, minHeight: 220)
    }
}
