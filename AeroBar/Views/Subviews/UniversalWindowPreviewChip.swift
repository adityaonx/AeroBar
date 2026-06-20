// UniversalWindowPreviewChip.swift — Live thumbnail shown when hovering a taskbar tab.
// Owner: Views/Subviews
// Depends on: ScreenCaptureKit, Core/Models/WindowTab
//
// CAPTURE STRATEGY:
//   Two paths depending on what SCKit reports:
//
//   PATH A — desktopIndependentWindow (preferred):
//     When we can match a specific SCWindow, capture ONLY that window through
//     the compositor. This correctly captures Chrome/Electron (renderer runs in
//     a separate process — the exclude-by-PID approach strips the renderer layer
//     leaving a blank frame). Works for on-screen AND minimized windows.
//
//   PATH B — full display + crop (fallback):
//     When no SCWindow match is found (rare: private window server apps like
//     some System Settings panes), capture the display and crop to AX frame.

import SwiftUI
import AppKit
import ScreenCaptureKit
import Combine

// MARK: - Nonisolated AX helper (callable from Task.detached / nonisolated contexts)
nonisolated func axWindowScreenFrame(for axElement: AXUIElement) -> CGRect {
    var posRef: CFTypeRef?, sizeRef: CFTypeRef?
    AXUIElementCopyAttributeValue(axElement, kAXPositionAttribute as CFString, &posRef)
    AXUIElementCopyAttributeValue(axElement, kAXSizeAttribute as CFString, &sizeRef)

    var axOrigin = CGPoint.zero
    var axSize   = CGSize.zero
    if let p = posRef as! AXValue? { AXValueGetValue(p, .cgPoint, &axOrigin) }
    if let s = sizeRef as! AXValue? { AXValueGetValue(s, .cgSize,   &axSize) }

    // Convert AX top-left origin → Cocoa/SCKit bottom-left origin
    let primaryH = NSScreen.screens.first?.frame.height ?? 0
    let cocoaY   = primaryH - axOrigin.y - axSize.height
    return CGRect(x: axOrigin.x, y: cocoaY, width: axSize.width, height: axSize.height)
}

// MARK: - Preview chip

struct UniversalWindowPreviewChip: View {
    let tab: WindowTab
    var isSelected: Bool = false
    var onHoverAction: ((Bool) -> Void)? = nil

    @ObservedObject private var settings = AeroBarSettings.shared
    @State private var previewImage: NSImage? = nil
    @State private var captureFailed  = false
    @State private var isMinimised    = false
    @State private var hasAccess      = true
    @State private var isHovered: Bool = false

    let timer = Timer.publish(every: 3.0, on: .main, in: .common).autoconnect()

    private static let minContainerWidth:  CGFloat = 120
    private static let minContainerHeight: CGFloat = 80
    private static let maxContainerWidth:  CGFloat = 420
    private static let maxContainerHeight: CGFloat = 240
    private static let minScale: CGFloat = 0.05
    private static let maxScale: CGFloat = 0.35

    /// Box size is a PURE function of `previewScale` — deliberately NOT derived
    /// from the captured window's own pixel size. Two things this fixes at once:
    ///   1. Uniformity: every window's chip is the same size at a given scale
    ///      setting (a Finder window and a Chrome window no longer produce
    ///      different-sized boxes at the same slider value — previously they
    ///      only looked uniform at 5%/30%/35% by accident, because those were
    ///      the values where every window happened to hit the same min/max clamp).
    ///   2. Stability: the box can never change size when the real capture
    ///      replaces the placeholder, because nothing here reads `source` any
    ///      more — eliminating the resize event that caused the host panel
    ///      (NonActivatingPreview) to dip into the bar at in-between scales.
    /// The captured image is still shown via `.scaledToFit()` inside this fixed
    /// box (pillarboxed/letterboxed as needed) so any window's own aspect ratio
    /// is respected without affecting the box itself.
    private var containerSize: CGSize {
        let t = (CGFloat(settings.previewScale) - Self.minScale) / (Self.maxScale - Self.minScale)
        let clampedT = min(max(t, 0), 1)
        let width  = Self.minContainerWidth  + (Self.maxContainerWidth  - Self.minContainerWidth)  * clampedT
        let height = Self.minContainerHeight + (Self.maxContainerHeight - Self.minContainerHeight) * clampedT
        return CGSize(width: width, height: height)
    }

    private var containerWidth:  CGFloat { containerSize.width }
    private var containerHeight: CGFloat { containerSize.height }
    private var innerW: CGFloat { containerWidth  - 8 }
    private var innerH: CGFloat { containerHeight - 8 }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header
            HStack(spacing: 6) {
                Image(nsImage: tab.appIcon).resizable().frame(width: 14, height: 14)
                Text(tab.windowTitle.isEmpty ? tab.appName : tab.windowTitle)
                    .font(.system(size: 10, weight: .bold)).lineLimit(1)
            }
            .foregroundColor(.white)

            // Preview frame
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.black.opacity(0.4))
                    .frame(width: containerWidth, height: containerHeight)

                content
            }
            .frame(width: containerWidth, height: containerHeight)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.accentColor, lineWidth: isSelected ? 2 : (isHovered ? 1.5 : 0))
            )
        }
        .padding(8)
        .background(VisualEffectBlurView(material: .hudWindow, blendingMode: .withinWindow, state: .active))
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.15), lineWidth: 1))
        .frame(width: containerWidth + 16)
        .onAppear { captureWindowImage() }
        .onReceive(timer) { _ in captureWindowImage() }
        .onHover { hovering in isHovered = hovering; onHoverAction?(hovering) }

    }

    @ViewBuilder
    private var content: some View {
        if !hasAccess {
            permissionPrompt
        } else if let image = previewImage {
            // Got a real capture — show it (works for both on-screen and minimized).
            // containerSize is always landscape (1.5:1 at min scale, 1.75:1 at max
            // — see containerSize doc above); for a wide
            // window this scaledToFit() just absorbs the 8pt padding inset, but for
            // a portrait/tall window it's doing real work — shrinking the image to
            // fit the box's height and centering it horizontally (pillarboxed),
            // which is what keeps the chip itself landscape-shaped.
            Image(nsImage: image)
                .resizable().scaledToFit()
                .frame(width: innerW, height: innerH)
                .cornerRadius(4)
        } else if captureFailed {
            // SCKit found no window or capture failed — show icon placeholder
            VStack(spacing: 6) {
                Image(nsImage: tab.appIcon).resizable().scaledToFit().frame(width: 36, height: 36)
                Text(tab.appName).font(.system(size: 8)).foregroundColor(.secondary).lineLimit(1)
            }
        } else {
            // Still loading (first capture in flight)
            VStack(spacing: 6) {
                ProgressView().controlSize(.small)
                Text("Loading…").font(.system(size: 8)).foregroundColor(.secondary)
            }
        }
    }

    private var permissionPrompt: some View {
        VStack(spacing: 6) {
            Image(systemName: "lock.fill").font(.system(size: 14)).foregroundColor(.secondary)
            Text("Screen Recording Required")
                .font(.system(size: 9, weight: .semibold)).foregroundColor(.secondary)
            Button(action: {
                NSWorkspace.shared.open(
                    URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!)
            }) {
                Text("Authorize")
                    .font(.system(size: 9, weight: .bold)).foregroundColor(.black)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Color.accentColor).cornerRadius(4)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Capture

    /// Smallest capture scale that still fills `targetBoxPts` at `screenScale`
    /// density — i.e. capture at "what will actually be shown" resolution
    /// rather than the source window's full native resolution. Never exceeds
    /// `screenScale` (no benefit capturing denser than the display itself).
    /// `static` (not an instance method) so it's callable from inside
    /// `Task.detached` without capturing `self` across the isolation boundary.
    private static nonisolated func captureScale(forSource sourceSize: CGSize, targetBoxPts: CGSize, screenScale: CGFloat) -> CGFloat {
        guard sourceSize.width > 0, sourceSize.height > 0 else { return screenScale }
        let fit = min(targetBoxPts.width  * screenScale / sourceSize.width,
                       targetBoxPts.height * screenScale / sourceSize.height)
        return min(max(fit, 0.05), screenScale)
    }

    private func captureWindowImage() {
        hasAccess = CGPreflightScreenCaptureAccess()
        guard hasAccess else { return }

        // Read minimized state on MainActor before entering detached task (Swift 6).
        var minRef: CFTypeRef?
        AXUIElementCopyAttributeValue(tab.axElement, kAXMinimizedAttribute as CFString, &minRef)
        let minimised = (minRef as? Bool) ?? false

        // Snapshot values needed in the nonisolated Task.detached context
        let axElem    = tab.axElement
        let windowID  = tab.windowID
        let processID = tab.processID
        let winTitle  = tab.windowTitle

        // Snapshot the CURRENT on-screen preview box size + display density.
        // captureScale(forSource:targetBoxPts:screenScale:) below uses these to
        // size the SCKit capture to roughly what's actually displayed, instead
        // of the source window's full native resolution. A large window was
        // previously captured at up to 2x ITS OWN native pixel size — e.g. a
        // 2560x1600 browser window became a ~5120x3200px capture — just to be
        // shown in a box that tops out around 420x240pt. That's the CPU/GPU
        // spike on hover: full-resolution SCKit capture + color conversion +
        // NSImage creation, repeated on every hover and every 3s refresh.
        let targetBoxPts = containerSize
        let screenScale  = min(NSScreen.main?.backingScaleFactor ?? 2.0, 2.0)

        // Capturing minimized windows requires SCKit with onScreenWindowsOnly:false
        // — CGWindowListCreateImage can't see them on modern macOS, but SCKit can
        // still reach the window server's backing store via desktopIndependentWindow.
        if minimised {
            Task.detached(priority: .userInitiated) {
                do {
                    let content = try await SCShareableContent.excludingDesktopWindows(
                        false, onScreenWindowsOnly: false)

                    var scWin = content.windows.first { $0.windowID == windowID }
                    if scWin == nil {
                        scWin = content.windows.first {
                            $0.owningApplication?.processID == processID && $0.title == winTitle
                        }
                    }
                    if scWin == nil {
                        scWin = content.windows
                            .filter { $0.owningApplication?.processID == processID }
                            .max(by: { ($0.frame.width * $0.frame.height) < ($1.frame.width * $1.frame.height) })
                    }

                    guard let win = scWin else {
                        await MainActor.run { self.isMinimised = true; self.previewImage = nil }
                        return
                    }

                    let scale = Self.captureScale(forSource: win.frame.size,
                                                   targetBoxPts: targetBoxPts, screenScale: screenScale)
                    let config = SCStreamConfiguration()
                    config.pixelFormat   = kCVPixelFormatType_32BGRA
                    config.showsCursor   = false
                    config.capturesAudio = false
                    config.width  = max(Int(win.frame.width  * scale), 2)
                    config.height = max(Int(win.frame.height * scale), 2)

                    let cgImage = try await SCScreenshotManager.captureImage(
                        contentFilter: SCContentFilter(desktopIndependentWindow: win),
                        configuration: config)
                    let ns = NSImage(cgImage: cgImage,
                                     size: CGSize(width: cgImage.width, height: cgImage.height))
                    await MainActor.run {
                        self.previewImage  = ns
                        self.captureFailed = false
                        self.isMinimised   = false
                    }
                } catch {
                    await MainActor.run { self.isMinimised = true; self.previewImage = nil }
                }
            }
            return  // Don't proceed to the on-screen SCKit path below
        }

        Task.detached(priority: .userInitiated) {
            do {
                let content = try await SCShareableContent.excludingDesktopWindows(
                    false, onScreenWindowsOnly: true)  // on-screen only (not minimized — handled above)

                // Match SCWindow by windowID (most reliable), fall back to pid+title
                var scWin = content.windows.first { $0.windowID == windowID }
                if scWin == nil {
                    scWin = content.windows.first {
                        $0.owningApplication?.processID == processID && $0.title == winTitle
                    }
                }
                if scWin == nil {
                    // No exact match — fall back to the largest window owned by this
                    // pid. Apps with multiple helper/background windows (Chrome, most
                    // Electron apps) tend to have the real browser window be the biggest.
                    scWin = content.windows
                        .filter { $0.owningApplication?.processID == processID }
                        .max(by: { ($0.frame.width * $0.frame.height) < ($1.frame.width * $1.frame.height) })
                }

                if let win = scWin {
                    // PATH A: desktopIndependentWindow filter.
                    //
                    // desktopIndependentWindow captures the window through the system
                    // compositor, which already has every child process's GPU layer
                    // composited in. That matters for apps like Chrome and Electron,
                    // where capturing "this process only" leaves out the renderer
                    // process and produces an empty browser shell. The same path
                    // handles minimized windows, since SCKit can still read them from
                    // the window server's backing store.
                    let filter = SCContentFilter(desktopIndependentWindow: win)
                    let scale = Self.captureScale(forSource: win.frame.size,
                                                   targetBoxPts: targetBoxPts, screenScale: screenScale)
                    let config = SCStreamConfiguration()
                    config.pixelFormat   = kCVPixelFormatType_32BGRA
                    config.showsCursor   = false
                    config.capturesAudio = false
                    config.width  = max(Int(win.frame.width  * scale), 2)
                    config.height = max(Int(win.frame.height * scale), 2)

                    let cgImage = try await SCScreenshotManager.captureImage(
                        contentFilter: filter, configuration: config)
                    let ns = NSImage(cgImage: cgImage,
                                     size: CGSize(width: cgImage.width, height: cgImage.height))
                    await MainActor.run {
                        self.previewImage  = ns
                        self.captureFailed = false
                        self.isMinimised   = false
                    }
                } else {
                    // PATH B: no SCWindow found — capture display and crop to AX frame.
                    // Handles apps with private window servers (rare).
                    let approxFrame = axWindowScreenFrame(for: axElem)
                    let scDisplay = content.displays.first { $0.frame.intersects(approxFrame) }
                        ?? content.displays.first

                    guard let display = scDisplay else {
                        await MainActor.run { self.captureFailed = true }
                        return
                    }

                    // Exclude unrelated apps for a cleaner capture
                    let exclude = content.windows.filter {
                        $0.owningApplication?.processID != processID
                    }
                    let filter = SCContentFilter(display: display, excludingWindows: exclude)
                    // Fit against the AX window's own size (what we'll crop OUT of the
                    // display), not the full display's size — otherwise this path still
                    // captures the entire screen at full native resolution regardless of
                    // how small the actual cropped result will be.
                    let scale = Self.captureScale(forSource: approxFrame.size,
                                                   targetBoxPts: targetBoxPts, screenScale: screenScale)
                    let config = SCStreamConfiguration()
                    config.pixelFormat   = kCVPixelFormatType_32BGRA
                    config.showsCursor   = false
                    config.capturesAudio = false
                    config.width  = max(Int(display.frame.width  * scale), 2)
                    config.height = max(Int(display.frame.height * scale), 2)

                    let full = try await SCScreenshotManager.captureImage(
                        contentFilter: filter, configuration: config)

                    let origin  = display.frame.origin
                    let cropRect = CGRect(
                        x: (approxFrame.minX - origin.x) * scale,
                        y: (approxFrame.minY - origin.y) * scale,
                        width:  approxFrame.width  * scale,
                        height: approxFrame.height * scale
                    ).intersection(CGRect(x: 0, y: 0,
                                          width: CGFloat(full.width),
                                          height: CGFloat(full.height)))

                    let cgImage: CGImage? = (cropRect.width > 8 && cropRect.height > 8)
                        ? full.cropping(to: cropRect) : full

                    if let img = cgImage {
                        let ns = NSImage(cgImage: img, size: CGSize(width: img.width, height: img.height))
                        await MainActor.run {
                            self.previewImage = ns
                            self.captureFailed = false
                        }
                    } else {
                        await MainActor.run { self.captureFailed = true }
                    }
                }
            } catch {
                await MainActor.run {
                    // On failure show icon placeholder — don't show stale image
                    if minimised { self.isMinimised = true }
                    self.captureFailed = self.previewImage == nil
                }
            }
        }
    }
}

// MARK: - PreviewWindowManager

struct PreviewWindowManager {
    /// Focuses and restores the specific window. Never minimizes.
    /// Used by preview chip taps (not by bar tab clicks which use handleWindowInteraction).
    static func focusTargetWindowContext(for tab: WindowTab) {
        NotificationCenter.default.post(name: .dismissStartMenuWindow, object: nil)

        let axWindow = tab.axElement
        let appRef   = AXUIElementCreateApplication(tab.processID)
        let pid      = tab.processID

        var minimizedRef: CFTypeRef?
        AXUIElementCopyAttributeValue(axWindow, kAXMinimizedAttribute as CFString, &minimizedRef)
        let isMinimized = (minimizedRef as? Bool) ?? false

        if isMinimized {
            // Suppress focus-update flicker during Dock unminimize animation
            AeroBarSettings.shared.currentSystemFocusedElement = axWindow
            NotificationCenter.default.post(name: .suppressFocusUpdates, object: nil)
            AXUIElementSetAttributeValue(axWindow, kAXMinimizedAttribute as CFString, false as CFTypeRef)

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                AXUIElementSetAttributeValue(appRef,   kAXFrontmostAttribute as CFString, true as CFTypeRef)
                AXUIElementSetAttributeValue(axWindow, kAXMainAttribute      as CFString, true as CFTypeRef)
                AXUIElementPerformAction(axWindow, kAXRaiseAction as CFString)
                activateTargetApp(pid: pid)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    AeroBarSettings.shared.currentSystemFocusedElement = axWindow
                    NotificationCenter.default.post(name: .resumeFocusUpdates, object: nil)
                }
            }
        } else {
            // Window is on-screen — raise and activate directly.
            AXUIElementPerformAction(axWindow, kAXRaiseAction as CFString)
            AXUIElementSetAttributeValue(axWindow, kAXMainAttribute      as CFString, true as CFTypeRef)
            AXUIElementSetAttributeValue(appRef,   kAXFrontmostAttribute as CFString, true as CFTypeRef)
            activateTargetApp(pid: pid)
        }
    }

    /// Brings the target app's process to the front from AeroBar's .accessory (LSUIElement)
    /// process.
    ///
    /// `.activateIgnoringOtherApps` is deprecated as of macOS 14 and is a documented no-op
    /// going forward. Apple's replacement, the parameterless `activate()`, only works when
    /// the *calling* process is already active or the call is a direct result of user input —
    /// neither of which reliably holds for an .accessory app fielding an AX/event-tap-driven
    /// click. So we activate AeroBar itself first (which *can* always activate itself), which
    /// makes the very next `activate()` call on the target app be treated as "from the active
    /// app" / user-driven, satisfying the new requirement instead of fighting it.
    ///
    /// The AX calls above (`kAXRaiseAction`, `kAXMainAttribute`, `kAXFrontmostAttribute`) do
    /// the actual window raise/focus work and are not affected by this deprecation at all —
    /// this activation step only ensures the target app's Dock icon/menu bar truly become
    /// frontmost, not just its window.
    private static func activateTargetApp(pid: pid_t) {
        guard let target = NSRunningApplication(processIdentifier: pid) else { return }
        NSApp.activate()
        if #available(macOS 14.0, *) {
            target.activate()
        } else {
            target.activate(options: .activateIgnoringOtherApps)
        }
    }
}
