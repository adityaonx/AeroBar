// PinnedAppsTray.swift — Drag-to-reorder tray of pinned apps shown in the bar.
// Owner: Views/Subviews
// Depends on: Core/Services/AeroBarSettings, Views/Subviews/PinnedAppDropDelegate
//
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
    @State private var outsideClickMonitor: (Any?, Any?)? = nil

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
                // Non-activating replacement for `.popover` — see AeroPreviewPanel.swift.
                // A real `.popover` here takes key/activation status; AeroBar's
                // accessory-app / non-key-panel architecture has nothing key-capable
                // to hand status back to when it closes, so the user's next click
                // anywhere in AeroBar would get consumed re-establishing input focus
                // instead of reaching any control — the "needs two clicks" bug.
                .nonActivatingPreview(isPresented: popoverBinding(for: app.bundleIdentifier)) {
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
                    hoveredWindowID    = nil
                    removeOutsideClickMonitor()
                    // No key-status handoff to wait out anymore (AeroPreviewPanel
                    // never takes key status), so focus can run immediately instead
                    // of after an arbitrary animation-completion delay.
                    PreviewWindowManager.focusTargetWindowContext(for: tab)
                }
            }
        }
        .padding(6)
        .background(Color.clear)
        // Cover the popover background: if mouse parks between chips or in padding,
        // neither chip fires onHoverAction — so we'd never start dismissal.
        // This container hover tracks the whole popover area:
        //   entering → cancel any pending dismissal (mouse is still in-panel)
        //   leaving  → start dismissal (mouse has left the popover entirely)
        .onHover { inPanel in
            if inPanel {
                dismissTask?.cancel()
                activeHoveredAppID = appID
            } else {
                startDismissalGracePeriod()
            }
        }
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
            // 0.6s grace: enough time to move from pinned icon through popover gap into chip.
            // Chip onHoverAction cancels this before it fires when mouse enters chip.
            try? await Task.sleep(for: .seconds(0.6))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                activeHoveredAppID = nil
                hoveredWindowID = nil
                removeOutsideClickMonitor()
            }
        }
    }

    // AeroPreviewPanel never takes key status, so unlike a real `.popover` it does
    // NOT auto-dismiss on outside clicks — we restore that here deliberately, as a
    // pure dismiss signal that never intercepts/reroutes the click itself.
    //
    // Two monitors, not one: addGlobalMonitorForEvents only fires for clicks in
    // OTHER apps/processes (never a click on AeroBar's own pinned icon row);
    // addLocalMonitorForEvents only fires for clicks inside AeroBar's own windows
    // (never a click in some other app). Together they cover "clicked anywhere."
    private func installOutsideClickMonitor() {
        guard outsideClickMonitor == nil else { return }
        let global = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { _ in
            Task { @MainActor in
                activeHoveredAppID = nil
                hoveredWindowID = nil
                removeOutsideClickMonitor()
            }
        }
        let local = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { event in
            activeHoveredAppID = nil
            hoveredWindowID = nil
            removeOutsideClickMonitor()
            return event  // never consumed — just observed, then passed straight through
        }
        outsideClickMonitor = (global, local)
    }

    private func removeOutsideClickMonitor() {
        if let (global, local) = outsideClickMonitor {
            if let g = global { NSEvent.removeMonitor(g) }
            if let l = local  { NSEvent.removeMonitor(l) }
        }
        outsideClickMonitor = nil
    }
}
