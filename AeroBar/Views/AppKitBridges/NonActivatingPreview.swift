// NonActivatingPreview.swift — SwiftUI bridge to AeroPreviewPanel.
// Owner: Views/AppKitBridges
// Depends on: AppKit, SwiftUI, AeroPreviewPanel
//
// Drop-in replacement for `.popover(isPresented:arrowEdge:content:)` for use inside
// AeroBar's window-preview surfaces. See AeroPreviewPanel.swift for the full
// rationale — in short, SwiftUI's real `.popover` always takes key status, and
// AeroBar's accessory/non-key panel architecture has no key-capable window for the
// OS to hand status back to when it closes.
//
// Positioning strategy:
//   X: Derived from the anchor NSView's actual on-screen midX via
//      view.convert(view.bounds, to: nil) → window.convertPoint(toScreen:).
//      This is scroll-offset-correct (no SwiftUI .global coordinate-space
//      confusion) and frozen at show-time so async repositions don't chase
//      the cursor as it moves from tab into panel.
//
//   Y: window.frame.maxY + 2pt. AeroBarPanel.frame.maxY is the exact bar
//      top edge in screen coordinates. Panel bottom-center is pinned there,
//      anchored to the tab's top-center (tooltip/popover anchor model).

import AppKit
import SwiftUI

struct NonActivatingPreviewModifier<PreviewContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    let content: () -> PreviewContent

    @State private var panel: AeroPreviewPanel? = nil
    @State private var hostingView: NSHostingView<MeasuredContent<PreviewContent>>? = nil
    @State private var anchorView: NSView? = nil   // the NSView backing this modifier's anchor
    @State private var hostWindow: NSWindow? = nil
    /// Tab center X in screen coordinates, captured at show-time and frozen.
    /// Reused for all async repositions so the panel doesn't drift as the
    /// cursor moves from the tab into the preview panel.
    @State private var anchorScreenMidX: CGFloat = 0

    func body(content base: Content) -> some View {
        refreshHostedContentIfNeeded()

        return base
            .background(AnchorViewAccessor(anchorView: $anchorView, hostWindow: $hostWindow))
            .onChange(of: isPresented) { _, show in
                if show { showPanel() } else { hidePanel() }
            }
            .onDisappear { hidePanel() }
    }

    private func showPanel() {
        // Compute the true screen-space midX of the anchor tab button by converting
        // the NSView's own bounds midpoint through the window into screen coordinates.
        // This is correct regardless of scroll offset, display scale, or which screen
        // the bar is on — no SwiftUI coordinate-space ambiguity.
        anchorScreenMidX = computeAnchorMidX()

        let host = NSHostingView(
            rootView: MeasuredContent(content: content(), onSizeChange: handleContentSizeChange)
        )
        let fitted = host.fittingSize
        host.frame = CGRect(origin: .zero, size: fitted)
        hostingView = host

        let p = panel ?? AeroPreviewPanel()
        p.contentView = host
        panel = p

        // hostWindow may be nil on the very first show (AnchorViewAccessor resolves
        // it one runloop tick after mount). Defer one tick if needed.
        if hostWindow != nil {
            applyFrame(p, size: fitted)
            p.orderFront(nil)
        } else {
            DispatchQueue.main.async {
                guard self.isPresented, let panel = self.panel else { return }
                // Re-derive midX now that hostWindow is resolved
                self.anchorScreenMidX = self.computeAnchorMidX()
                self.applyFrame(panel, size: fitted)
                panel.orderFront(nil)
            }
        }
    }

    private func hidePanel() {
        panel?.orderOut(nil)
    }

    private func refreshHostedContentIfNeeded() {
        guard isPresented, let host = hostingView else { return }
        host.rootView = MeasuredContent(content: content(), onSizeChange: handleContentSizeChange)
    }

    private func handleContentSizeChange(_ size: CGSize) {
        guard let p = panel, isPresented, size.width > 0, size.height > 0 else { return }
        guard size != p.frame.size else { return }
        applyFrame(p, size: size)
    }

    /// Returns the anchor tab's horizontal center in screen coordinates.
    ///
    /// Strategy: walk the anchorView's superview chain to find its frame
    /// in the window's coordinate space. We use `convert(_:to:nil)` which
    /// converts FROM the view's SUPERVIEW coordinate space (where `frame`
    /// lives) to the window base. This avoids the `bounds.midX == 0` trap
    /// that occurs when the NSView's own bounds haven't been sized yet by
    /// SwiftUI layout — `frame` in the superview is set by the layout engine
    /// and is always correct by the time the user can hover.
    ///
    /// Falls back to NSEvent.mouseLocation.x if the view hierarchy isn't
    /// accessible (shouldn't happen in practice after first layout pass).
    private func computeAnchorMidX() -> CGFloat {
        guard let view = anchorView,
              let superview = view.superview,
              let window = view.window else {
            return NSEvent.mouseLocation.x
        }
        // view.frame is in superview coordinates (set by SwiftUI/AppKit layout).
        // Convert the frame's midX from superview space → window base → screen.
        let midInSuper  = CGPoint(x: view.frame.midX, y: view.frame.midY)
        let midInWindow = superview.convert(midInSuper, to: nil)
        let midOnScreen = window.convertPoint(toScreen: midInWindow)
        // Sanity: if the result is 0 or off-screen, fall back to mouse X.
        // This guards against the rare case where layout hasn't run yet.
        let mouse = NSEvent.mouseLocation.x
        guard let screen = window.screen ?? NSScreen.main,
              midOnScreen.x > screen.frame.minX,
              midOnScreen.x < screen.frame.maxX else {
            return mouse
        }
        return midOnScreen.x
    }

    /// Computes the correct origin for `size` and applies size+origin to the
    /// panel in a SINGLE setFrame(_:display:) call.
    ///
    /// Previously this was two AppKit calls — setContentSize() then
    /// setFrameOrigin() — which is the root cause of the panel dipping into
    /// the bar at mid-range preview scales: setContentSize() resizes anchored
    /// at the TOP-LEFT corner (grows/shrinks downward), so for one frame the
    /// panel's bottom edge moved toward/into the bar before setFrameOrigin
    /// pulled it back up. At the size extremes (clamped to the min/max box)
    /// there's no resize delta between the placeholder and the real capture,
    /// so the bug never showed. At the unclamped, in-between sizes there is
    /// always a delta, exposing it. Setting frame+origin together removes the
    /// bad intermediate state entirely — there is no longer a top-left-anchored
    /// frame to ever paint.
    private func applyFrame(_ p: AeroPreviewPanel, size: CGSize) {
        let screen = hostWindow?.screen
            ?? NSScreen.screens.first { $0.frame.contains(CGPoint(x: anchorScreenMidX, y: 0)) }
            ?? NSScreen.main

        // X: center panel on the frozen anchor midX; clamp to screen edges.
        let originX: CGFloat
        let idealX = anchorScreenMidX - size.width / 2
        if let visible = screen?.visibleFrame {
            let maxX = visible.maxX - size.width
            originX = maxX >= visible.minX ? min(max(idealX, visible.minX), maxX) : visible.minX
        } else {
            originX = idealX
        }

        // Y: pin panel's bottom-centre to the tab's top edge.
        // hostWindow.frame.maxY == the exact top of the bar/tab in screen coords
        // (AeroBarPanel sits at screen.frame.minY, height = barHeight).
        // +2pt gives a hairline gap so the panel doesn't visually merge with the bar.
        let barMinY: CGFloat
        if let w = hostWindow {
            barMinY = w.frame.maxY + 2
        } else {
            barMinY = (screen?.frame.minY ?? 0) + 56 + 2
        }

        p.setFrame(NSRect(x: originX, y: barMinY, width: size.width, height: size.height),
                   display: true)
    }
}

// MARK: - MeasuredContent

struct MeasuredContent<Content: View>: View {
    let content: Content
    let onSizeChange: (CGSize) -> Void

    var body: some View {
        content
            .background(
                GeometryReader { proxy in
                    Color.clear
                        .preference(key: PreviewContentSizeKey.self, value: proxy.size)
                }
            )
            .onPreferenceChange(PreviewContentSizeKey.self) { newSize in
                onSizeChange(newSize)
            }
    }
}

private struct PreviewContentSizeKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

// MARK: - AnchorViewAccessor
//
// Vends both the NSView backing this SwiftUI subtree AND the hosting NSWindow.
// The NSView is used to compute the anchor tab's true screen-space midX via
// AppKit coordinate conversion (correct through scroll offsets, Retina scaling,
// and multi-display layouts). The NSWindow is used for Y positioning.

private struct AnchorViewAccessor: NSViewRepresentable {
    @Binding var anchorView: NSView?
    @Binding var hostWindow: NSWindow?

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            self.anchorView  = view
            self.hostWindow  = view.window
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            if self.anchorView !== nsView  { self.anchorView = nsView }
            if self.hostWindow !== nsView.window { self.hostWindow = nsView.window }
        }
    }
}

extension View {
    func nonActivatingPreview<Content: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        modifier(NonActivatingPreviewModifier(isPresented: isPresented, content: content))
    }
}
