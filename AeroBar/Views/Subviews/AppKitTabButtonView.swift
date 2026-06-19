import SwiftUI
import AppKit

struct AppKitTabButtonView: View {
    let tab: WindowTab
    let isActive: Bool
    // Called by WindowTabsScrollView's Button — minimize/restore/focus logic lives there.
    // We also call it directly from our local monitor when the popover intercepts a tap.
    var onTap: (() -> Void)? = nil

    @ObservedObject private var settings = AeroBarSettings.shared
    @Environment(\.colorScheme) var colorScheme

    @State private var isTabPopoverPresented = false
    @State private var showTask: Task<Void, Never>? = nil
    @State private var dismissTask: Task<Void, Never>? = nil
    @State private var localClickMonitor: Any? = nil
    @State private var globalClickMonitor: Any? = nil

    var body: some View {
        let shouldShowThisLabel = !settings.hideWindowLabelsTemporarily
            && !settings.manuallyHiddenWindowIDs.contains(tab.windowID)

        HStack(spacing: 0) {
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                Image(nsImage: tab.appIcon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.2 : 0.05),
                            radius: 1, x: 0, y: 1)
                Spacer(minLength: 0)
            }
            .frame(width: 34, height: settings.barHeight)
            .padding(.leading, 6)

            if shouldShowThisLabel {
                Text(tab.windowTitle.isEmpty ? tab.appName : tab.windowTitle)
                    .font(.system(size: 11, weight: isActive ? .semibold : .regular, design: .default))
                    .foregroundColor(colorScheme == .dark
                        ? Color.white.opacity(isActive ? 0.95 : 0.80)
                        : Color.black.opacity(isActive ? 0.90 : 0.70))
                    .lineLimit(1)
                    .frame(maxWidth: 140)
                    .padding(.leading, 6)
                    .padding(.trailing, 12)
            } else {
                Spacer(minLength: 0).frame(width: 6)
            }
        }
        .frame(height: settings.barHeight)
        .background(tabBackground)
        .cornerRadius(4)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(
                    colorScheme == .dark
                        ? Color.white.opacity(isActive ? 0.3 : 0.1)
                        : Color.black.opacity(isActive ? 0.2 : 0.05),
                    lineWidth: 1
                )
        )
        // NO .onTapGesture — the Button wrapper in WindowTabsScrollView owns tap handling.
        // We use a local monitor (installed only while the popover is open) to intercept
        // bar-panel clicks that the Button can't receive because the popover is key window.
        .onHover { entering in
            guard settings.enablePreviews, !settings.isStartMenuOpen else { return }
            if entering {
                dismissTask?.cancel()
                showTask?.cancel()
                showTask = Task {
                    try? await Task.sleep(for: .seconds(settings.previewDelayValue))
                    guard !Task.isCancelled, settings.enablePreviews,
                          !settings.isStartMenuOpen else { return }
                    await MainActor.run {
                        isTabPopoverPresented = true
                        installLocalClickMonitor()
                    }
                }
            } else {
                showTask?.cancel()
                startDismissalGracePeriod()
            }
        }
        .onChange(of: settings.isStartMenuOpen) { _, open in
            if open { closePopover() }
        }
        .onChange(of: isTabPopoverPresented) { _, presented in
            if !presented { removeLocalClickMonitor() }
        }
        .popover(isPresented: $isTabPopoverPresented, arrowEdge: .top) {
            UniversalWindowPreviewChip(tab: tab, isSelected: isActive) { chipHovering in
                if chipHovering {
                    dismissTask?.cancel()
                } else {
                    startDismissalGracePeriod()
                }
            }
            // Tapping the chip always focuses/restores that window — never minimizes.
            // We use PreviewWindowManager directly (not onTap/handleWindowInteraction)
            // because handleWindowInteraction has a "already focused → minimize" branch
            // that would minimize the window on first chip tap.
            .onTapGesture {
                closePopover()
                // Small delay so popover fully closes and bar regains key status
                // before AX window-raise calls execute.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    PreviewWindowManager.focusTargetWindowContext(for: tab)
                }
            }
            .padding(4)
        }
        .onDisappear { closePopover() }
    }

    // MARK: - Background

    private var tabBackground: some View {
        ZStack(alignment: .bottom) {
            if isActive {
                VisualEffectBlurView(material: colorScheme == .dark ? .selection : .headerView,
                                     blendingMode: .withinWindow, state: .active)
                    .opacity(colorScheme == .dark ? 0.4 : 0.2)
            } else {
                VisualEffectBlurView(material: colorScheme == .dark ? .contentBackground : .underWindowBackground,
                                     blendingMode: .withinWindow, state: .active)
                    .opacity(0.25)
            }
            LinearGradient(
                gradient: Gradient(colors: [
                    colorScheme == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.05),
                    Color.clear
                ]),
                startPoint: .top, endPoint: .center
            )
            if isActive {
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.accentColor)
                    .frame(height: 2.5)
                    .padding(.horizontal, 4)
            }
        }
    }

    // MARK: - Popover lifecycle

    private func closePopover() {
        showTask?.cancel()
        dismissTask?.cancel()
        isTabPopoverPresented = false
        removeLocalClickMonitor()
    }

    private func startDismissalGracePeriod() {
        dismissTask?.cancel()
        dismissTask = Task {
            try? await Task.sleep(for: .seconds(0.3))
            guard !Task.isCancelled else { return }
            await MainActor.run { closePopover() }
        }
    }

    // MARK: - Local click monitor
    //
    // Problem: When the popover is shown it becomes the NSApp keyWindow.
    // Clicks on the AeroBar panel (non-key window) are delivered as NSEvents
    // but SwiftUI's Button wrapper never fires its action because the event
    // goes to the panel window which isn't key — SwiftUI's gesture recogniser
    // doesn't pick it up from a non-key window click.
    //
    // Solution: install a LOCAL event monitor (fires for events in OUR process).
    // When we detect a left-click NOT inside the popover window:
    //   1. Close the popover.
    //   2. Call onTap() directly — this is the same action the Button would have called.
    //   3. Return the event (nil would swallow it; we don't want to swallow it but
    //      since onTap already handled the action, returning nil is safe here to
    //      avoid double-firing if the Button somehow also receives it).
    //
    // The monitor is only installed while the popover is open, so normal (no-popover)
    // clicks still go through the Button as usual.

    private func installLocalClickMonitor() {
        guard localClickMonitor == nil else { return }

        // GLOBAL monitor — fires for clicks in OTHER processes (dismiss when user clicks a focused window)
        if globalClickMonitor == nil {
            globalClickMonitor = NSEvent.addGlobalMonitorForEvents(
                matching: [.leftMouseDown, .rightMouseDown]
            ) { [self] _ in
                guard isTabPopoverPresented else { return }
                DispatchQueue.main.async { closePopover() }
            }
        }

        localClickMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.leftMouseDown]
        ) { [self] event in
            guard isTabPopoverPresented else { return event }

            let clickWindow = event.window
            let popoverWindow = NSApp.keyWindow
            let clickIsInsidePopover = (clickWindow != nil && clickWindow == popoverWindow)

            if !clickIsInsidePopover {
                let isBarPanelClick = clickWindow?.isKind(of: AeroBarPanel.self) ?? false
                closePopover()
                if isBarPanelClick {
                    // Dispatch on next runloop tick — bar must regain key status first
                    // so AX window-focus changes in handleWindowInteraction succeed.
                    DispatchQueue.main.async { self.onTap?() }
                    return nil  // consume — handled via onTap
                }
                return event
            }
            return event
        }
    }

    private func removeLocalClickMonitor() {
        if let m = localClickMonitor  { NSEvent.removeMonitor(m); localClickMonitor  = nil }
        if let m = globalClickMonitor { NSEvent.removeMonitor(m); globalClickMonitor = nil }
    }
}
