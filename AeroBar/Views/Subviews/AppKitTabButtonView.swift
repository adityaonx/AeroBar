// AppKitTabButtonView.swift — A single window-tab chip in the taskbar strip.
// Owner: Views/Subviews
// Depends on: Core/Models/WindowTab, Views/Subviews/UniversalWindowPreviewChip
//
import SwiftUI
import AppKit

struct AppKitTabButtonView: View {
    let tab: WindowTab
    let isActive: Bool
    // No longer called internally — kept for call-site compatibility with
    // WindowTabsScrollView. Previously this was invoked from a click monitor that
    // worked around the bar's Button failing to fire while a popover held key
    // status; that problem no longer exists (see AeroPreviewPanel.swift), so the
    // parent's own Button(action:) now handles every tap directly.
    var onTap: (() -> Void)? = nil

    @ObservedObject private var settings = AeroBarSettings.shared
    @Environment(\.colorScheme) var colorScheme

    @State private var showTask: Task<Void, Never>? = nil
    @State private var dismissTask: Task<Void, Never>? = nil
    @State private var outsideClickMonitor: (Any?, Any?)? = nil

    // SINGLE SOURCE OF TRUTH: preview is open iff activePreviewTabID == this tab's ID.
    // Using a local @State bool caused a race: SwiftUI's popover close animation (~200ms)
    // overlapped with the next tab's popover opening, causing SwiftUI to re-route
    // the popover to the adjacent tab (the "adjacent tab auto-expands" bug).
    private var isPreviewOpen: Bool { settings.activePreviewTabID == tab.windowID }

    var body: some View {
        let shouldShowThisLabel = !settings.hideWindowLabelsTemporarily
            && !settings.manuallyHiddenWindowIDs.contains(tab.windowID)

        HStack(spacing: 0) {
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                Image(nsImage: tab.appIcon)
                    .resizable().scaledToFit()
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
        // Tap handling lives in the parent's Button(action:) (WindowTabsScrollView).
        // That now fires reliably on the FIRST click, every time, because
        // AeroPreviewPanel (used below) never takes key/activation status — there is
        // no longer a key-window handoff for any click to race against, so the old
        // "Button can't fire while popover is key" problem this view used to work
        // around with a click monitor no longer exists.
        .onHover { entering in
            guard settings.enablePreviews, !settings.isStartMenuOpen else { return }
            if entering {
                dismissTask?.cancel()
                showTask?.cancel()
                // Claim the slot immediately — any other tab whose preview is open will
                // see this via .onChange(of: activePreviewTabID) and close instantly.
                settings.activePreviewTabID = tab.windowID
                showTask = Task {
                    try? await Task.sleep(for: .seconds(settings.previewDelayValue))
                    guard !Task.isCancelled, settings.enablePreviews,
                          !settings.isStartMenuOpen,
                          settings.activePreviewTabID == tab.windowID else { return }
                    await MainActor.run { installOutsideClickMonitor() }
                }
            } else {
                showTask?.cancel()
                // Do NOT clear activePreviewTabID here — that closes the preview
                // instantly, with zero travel time for the cursor to glide from the
                // tab into the preview panel. The grace-period task below is what
                // actually owns the close; the panel's own hover handler cancels it
                // if the cursor lands inside in time.
                startDismissalGracePeriod()
            }
        }
        .onChange(of: settings.isStartMenuOpen) { _, open in
            if open { closePreview() }
        }
        .onChange(of: isPreviewOpen) { _, open in
            if !open { removeOutsideClickMonitor() }
        }
        // Non-activating replacement for `.popover` — see AeroPreviewPanel.swift for
        // why a real `.popover` here caused every popover-adjacent click to need two
        // taps (it takes key status; AeroBar's accessory/non-key panel architecture
        // has nothing key-capable to hand status back to when it closes).
        .nonActivatingPreview(isPresented: Binding(
            get: { isPreviewOpen },
            set: { if !$0 { closePreview() } }
        )) {
            UniversalWindowPreviewChip(tab: tab, isSelected: isActive) { chipHovering in
                if chipHovering {
                    // Mouse entered the chip — cancel any pending dismissal
                    dismissTask?.cancel()
                } else {
                    // Mouse left chip — start grace period (chip→gap→nothing)
                    startDismissalGracePeriod()
                }
            }
            .onTapGesture {
                // Chip tap: always bring-to-front / restore. Never minimize.
                // We do NOT call onTap()/handleWindowInteraction here because that
                // function has a "already focused → minimize" branch. The chip is
                // explicitly a "focus this window" action.
                //
                // No key-status handoff to wait out anymore (see AeroPreviewPanel),
                // so this can run focus immediately instead of after an arbitrary
                // animation-completion delay — that delay was partly why focus felt
                // like it needed a second click.
                closePreview()
                PreviewWindowManager.focusTargetWindowContext(for: tab)
            }
            .padding(4)
            // Cover the padding gap around the chip: if the cursor lands here instead
            // of squarely on the chip while gliding in from the tab, this still
            // cancels the dismissal countdown instead of letting it expire.
            .onHover { inPanel in
                if inPanel {
                    dismissTask?.cancel()
                } else {
                    startDismissalGracePeriod()
                }
            }
        }
        .onDisappear { closePreview() }
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

    // MARK: - Preview lifecycle

    private func closePreview() {
        showTask?.cancel()
        dismissTask?.cancel()
        if settings.activePreviewTabID == tab.windowID {
            settings.activePreviewTabID = nil
        }
        removeOutsideClickMonitor()
    }

    private func startDismissalGracePeriod() {
        dismissTask?.cancel()
        dismissTask = Task {
            // 0.6s: enough time to move from tab edge through panel gap into chip.
            // The chip's onHoverAction cancels this task when mouse enters the chip.
            try? await Task.sleep(for: .seconds(0.6))
            guard !Task.isCancelled else { return }
            await MainActor.run { closePreview() }
        }
    }

    // MARK: - Outside click dismissal
    //
    // AeroPreviewPanel never takes key status, so unlike a real `.popover` it does
    // NOT auto-dismiss on outside clicks — that auto-dismissal in `.popover` was a
    // direct consequence of the key-window resignation we deliberately removed.
    // We restore "click elsewhere closes it" deliberately here, but ONLY as a
    // dismiss signal — neither monitor below ever intercepts/consumes/reroutes the
    // click (the local monitor always `return event`s, the global monitor doesn't
    // return anything to redirect), so nothing here can race or interfere with
    // where the click is actually delivered. That distinction is what makes this
    // safe where the old local-monitor click-REROUTING was not.
    //
    // Two monitors are needed, not one:
    //   - addGlobalMonitorForEvents only fires for clicks in OTHER apps/processes —
    //     it never sees a click on AeroBar's own bar tab.
    //   - addLocalMonitorForEvents only fires for clicks inside AeroBar's own
    //     windows — it never sees a click in some other app.
    // Together they cover "clicked literally anywhere" without either one trying
    // to do both jobs (which is what produced the races before).
    private func installOutsideClickMonitor() {
        guard outsideClickMonitor == nil else { return }

        let global = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { _ in
            Task { @MainActor in closePreview() }
        }
        let local = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { event in
            closePreview()
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
