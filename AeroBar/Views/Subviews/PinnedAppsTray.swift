import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct PinnedAppsTray: View {
    @ObservedObject var settings = AeroBarSettings.shared
    @Binding var draggedPinnedItem: PinnedApp?
    let onLaunch: (String) -> Void
    let onUnpin: (String) -> Void

    @State private var activeHoveredAppID: String? = nil
    // Issue 2: track which window is being hovered inside a multi-window popover
    @State private var hoveredWindowID: CGWindowID? = nil
    @State private var showTask: Task<Void, Never>? = nil
    @State private var dismissTask: Task<Void, Never>? = nil
    @State private var outsideClickMonitor: Any? = nil

    var body: some View {
        HStack(spacing: 8) {
            ForEach(settings.pinnedBarApps) { app in
                let associatedTabs = settings.activeTabs.filter { tab in
                    NSRunningApplication(processIdentifier: tab.processID)?.bundleIdentifier == app.bundleIdentifier
                }

                // Issue 3: the pinned app button tap always works — launch or bring to
                // front — regardless of whether a preview popover is showing.
                Button(action: {
                    if activeHoveredAppID == app.bundleIdentifier {
                        // Close preview first, then launch/focus
                        activeHoveredAppID = nil
                        removeOutsideClickMonitor()
                    }
                    onLaunch(app.bundleIdentifier)
                }) {
                    Image(nsImage: app.appIcon)
                        .resizable()
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(PlainButtonStyle())
                .onDrag {
                    self.draggedPinnedItem = app
                    return NSItemProvider(object: app.bundleIdentifier as NSString)
                }
                .onDrop(of: [.text], delegate: PinnedAppDropDelegate(currentItem: app, settings: settings, draggedItem: $draggedPinnedItem))
                .onHover { entering in
                    guard settings.enablePreviews, !settings.isStartMenuOpen else { return }
                    if entering && !associatedTabs.isEmpty {
                        dismissTask?.cancel()
                        showTask?.cancel()
                        showTask = Task {
                            try? await Task.sleep(for: .seconds(settings.previewDelayValue))
                            guard !Task.isCancelled, settings.enablePreviews, !settings.isStartMenuOpen else { return }
                            await MainActor.run {
                                // Issue 1: only show the popover — do NOT activate/focus the app.
                                hoveredWindowID = nil
                                activeHoveredAppID = app.bundleIdentifier
                                installOutsideClickMonitor()
                            }
                        }
                    } else {
                        showTask?.cancel()
                        startDismissalGracePeriod()
                    }
                }
                .popover(isPresented: popoverBinding(for: app.bundleIdentifier), arrowEdge: .top) {
                    previewContent(for: associatedTabs, appID: app.bundleIdentifier)
                }
                .contextMenu {
                    contextMenuItems(for: app)
                }
            }
        }
        .onChange(of: settings.isStartMenuOpen) { _, open in
            if open {
                showTask?.cancel()
                dismissTask?.cancel()
                activeHoveredAppID = nil
                hoveredWindowID = nil
                removeOutsideClickMonitor()
            }
        }
        .onDisappear { removeOutsideClickMonitor() }
    }

    private func popoverBinding(for id: String) -> Binding<Bool> {
        Binding<Bool>(
            get: { activeHoveredAppID == id },
            set: { if !$0 { activeHoveredAppID = nil; hoveredWindowID = nil; removeOutsideClickMonitor() } }
        )
    }

    @ViewBuilder
    private func previewContent(for tabs: [WindowTab], appID: String) -> some View {
        let stackSpacing: CGFloat = 6.0
        let contentLayout = settings.previewStackVertical
            ? AnyLayout(VStackLayout(spacing: stackSpacing))
            : AnyLayout(HStackLayout(spacing: stackSpacing))

        contentLayout {
            ForEach(tabs) { tab in
                // Issue 2: a chip is "selected" if the user is currently hovering it
                // inside the popover (gliding between windows highlights each one),
                // falling back to the actual frontmost window when nothing is hovered.
                let isFrontmost = tab.windowID == settings.activeTabs.first(where: { $0.processID == tab.processID })?.windowID
                let isHoveredInPanel = hoveredWindowID == tab.windowID
                let showSelected = isHoveredInPanel || (hoveredWindowID == nil && isFrontmost)

                UniversalWindowPreviewChip(tab: tab, isSelected: showSelected) { chipHovering in
                    if chipHovering {
                        // Issue 1 & 2: hovering a chip highlights it but does NOT
                        // activate or focus that window.
                        dismissTask?.cancel()
                        activeHoveredAppID = appID
                        hoveredWindowID = tab.windowID  // highlight this chip
                    } else {
                        // Mouse left this chip — clear highlight and start grace period
                        hoveredWindowID = nil
                        startDismissalGracePeriod()
                    }
                }
                // Issue 2 & 3: tapping a chip in the multi-window panel focuses that
                // specific window and dismisses the panel.
                .onTapGesture {
                    activeHoveredAppID = nil
                    hoveredWindowID = nil
                    removeOutsideClickMonitor()
                    PreviewWindowManager.focusTargetWindowContext(for: tab)
                }
            }
        }
        .padding(6)
        .background(Color.clear)
    }

    @ViewBuilder
    private func contextMenuItems(for app: PinnedApp) -> some View {
        Button {
            handleOpenNewWindow(app: app)
        } label: {
            Label("Open New Window", systemImage: "macwindow.badge.plus")
        }

        if ["com.google.Chrome", "com.apple.Safari", "com.microsoft.edgemac"].contains(app.bundleIdentifier) {
            Button {
                handleOpenPrivateWindow(app: app)
            } label: {
                Label("Open New Private Window", systemImage: "eyeglasses")
            }
        }

        Divider()

        if app.bundleIdentifier != "com.apple.finder" {
            Button(role: .destructive) { onUnpin(app.bundleIdentifier) } label: {
                Label("Unpin from Taskbar", systemImage: "pin.slash")
            }

            if let running = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == app.bundleIdentifier }) {
                Button { running.terminate() } label: {
                    Label("Close App", systemImage: "minus.circle")
                }
            }
        }
    }

    private func handleOpenNewWindow(app: PinnedApp) {
        if app.bundleIdentifier == "com.apple.finder" {
            NSWorkspace.shared.open(URL(fileURLWithPath: NSHomeDirectory()))
        } else if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: app.bundleIdentifier) {
            let config = NSWorkspace.OpenConfiguration()
            config.createsNewApplicationInstance = true
            NSWorkspace.shared.openApplication(at: appURL, configuration: config, completionHandler: nil)
        }
    }

    private func handleOpenPrivateWindow(app: PinnedApp) {
        if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: app.bundleIdentifier) {
            let config = NSWorkspace.OpenConfiguration()
            config.createsNewApplicationInstance = true
            NSWorkspace.shared.openApplication(at: appURL, configuration: config, completionHandler: nil)
        }
    }

    private func startDismissalGracePeriod() {
        dismissTask?.cancel()
        dismissTask = Task {
            try? await Task.sleep(for: .seconds(0.3))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                activeHoveredAppID = nil
                hoveredWindowID = nil
                removeOutsideClickMonitor()
            }
        }
    }

    // Issue 3 fix: NSEvent.addGlobalMonitorForEvents only fires for events in OTHER
    // applications — clicks inside our own popover are local events and are NOT
    // captured by the global monitor, so they reach the chip's onTapGesture safely.
    private func installOutsideClickMonitor() {
        guard outsideClickMonitor == nil else { return }
        outsideClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { _ in
            Task { @MainActor in
                activeHoveredAppID = nil
                hoveredWindowID = nil
                removeOutsideClickMonitor()
            }
        }
    }

    private func removeOutsideClickMonitor() {
        if let monitor = outsideClickMonitor {
            NSEvent.removeMonitor(monitor)
            outsideClickMonitor = nil
        }
    }
}
