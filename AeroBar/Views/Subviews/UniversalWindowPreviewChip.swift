// UniversalWindowPreviewChip.swift
// Owner: Views/Subviews
//
// CAPTURE STRATEGY:
//   SCScreenshotManager with desktopIndependentWindow filter FAILS for:
//     • Chrome / Electron  — GPU-composited in a separate process
//     • System Settings    — private window server
//     • Minimised windows  — not on screen
//
//   WORKING FIX: Capture the entire display with SCContentFilter(display:excluding:)
//   then crop to the window's frame rect. This path goes through the display
//   compositor which already has all GPU surfaces composited — so Chrome, Settings,
//   and any other window type all appear correctly.

import SwiftUI
import AppKit
import ScreenCaptureKit
import Combine

// CGRect area helper for spatial SCWindow matching
private extension CGRect {
    nonisolated var area: CGFloat { width * height }
}

// MARK: - Nonisolated AX helper (free function — callable from Task.detached)
//
// Must be outside the View struct. View conforms to protocol on @MainActor,
// so any static method inside it is implicitly @MainActor and cannot be called
// from nonisolated async contexts (Task.detached) in Swift 6 strict concurrency.

nonisolated func axWindowScreenFrame(for axElement: AXUIElement) -> CGRect {
    var posRef: CFTypeRef?, sizeRef: CFTypeRef?
    AXUIElementCopyAttributeValue(axElement, kAXPositionAttribute as CFString, &posRef)
    AXUIElementCopyAttributeValue(axElement, kAXSizeAttribute as CFString, &sizeRef)

    var axOrigin = CGPoint.zero
    var axSize   = CGSize.zero
    if let p = posRef as! AXValue? { AXValueGetValue(p, .cgPoint, &axOrigin) }
    if let s = sizeRef as! AXValue? { AXValueGetValue(s, .cgSize,   &axSize) }

    // AX coords: top-left origin on primary screen.
    // SCKit / Cocoa coords: bottom-left origin.
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
    @State private var captureFailed = false
    @State private var isMinimised = false
    @State private var hasScreenRecordingAccess = true
    @State private var windowSize: CGSize = .zero  // actual window dims, drives aspect-ratio preview

    let timer = Timer.publish(every: 2.0, on: .main, in: .common).autoconnect()

    // Width = previewSizeWidth (fixed px) as fallback; once windowSize is known,
    // width = previewSizeWidth and height = width × (windowH / windowW) for true aspect ratio.
    private var containerWidth: CGFloat  { CGFloat(settings.previewSizeWidth) }
    private var containerHeight: CGFloat {
        guard windowSize.width > 0, windowSize.height > 0 else { return containerWidth * 0.6 }
        return containerWidth * (windowSize.height / windowSize.width)
    }
    private var innerImageWidth: CGFloat  { containerWidth - 8 }
    private var innerImageHeight: CGFloat { containerHeight - 8 }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(nsImage: tab.appIcon).resizable().frame(width: 14, height: 14)
                Text(tab.windowTitle.isEmpty ? tab.appName : tab.windowTitle)
                    .font(.system(size: 10, weight: .bold))
                    .lineLimit(1)
            }
            .foregroundColor(.white)

            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.black.opacity(0.4))
                    .frame(width: containerWidth, height: containerHeight)

                if !hasScreenRecordingAccess {
                    permissionPrompt
                } else if isMinimised {
                    VStack(spacing: 6) {
                        Image(nsImage: tab.appIcon)
                            .resizable().scaledToFit()
                            .frame(width: 36, height: 36)
                        Text("Minimised")
                            .font(.system(size: 8)).foregroundColor(.secondary)
                    }
                    .frame(width: innerImageWidth)
                } else if let image = previewImage {
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: innerImageWidth, height: innerImageHeight)
                        .cornerRadius(4)
                } else if captureFailed {
                    VStack(spacing: 6) {
                        Image(nsImage: tab.appIcon)
                            .resizable().scaledToFit()
                            .frame(width: 36, height: 36)
                        Text(tab.appName)
                            .font(.system(size: 8)).foregroundColor(.secondary).lineLimit(1)
                    }
                    .frame(width: innerImageWidth)
                } else {
                    VStack(spacing: 6) {
                        ProgressView().controlSize(.small)
                        Text("Loading preview…")
                            .font(.system(size: 8)).foregroundColor(.secondary)
                    }
                }
            }
            .frame(width: containerWidth, height: containerHeight)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.accentColor, lineWidth: isSelected ? 2 : 0)
            )
        }
        .padding(8)
        .background(VisualEffectBlurView(material: .hudWindow, blendingMode: .withinWindow, state: .active))
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.15), lineWidth: 1))
        .frame(width: containerWidth + 16)
        .onAppear { captureWindowImage() }
        .onReceive(timer) { _ in captureWindowImage() }
        .onHover { hovering in onHoverAction?(hovering) }
    }

    // MARK: - Permission prompt

    private var permissionPrompt: some View {
        VStack(spacing: 6) {
            Image(systemName: "lock.fill").font(.system(size: 14)).foregroundColor(.secondary)
            Text("Permission Required").font(.system(size: 9, weight: .semibold)).foregroundColor(.secondary)
            Button(action: openScreenRecordingSettings) {
                Text("Authorize")
                    .font(.system(size: 9, weight: .bold)).foregroundColor(.black)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Color.accentColor).cornerRadius(4)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Capture

    private func captureWindowImage() {
        hasScreenRecordingAccess = CGPreflightScreenCaptureAccess()
        guard hasScreenRecordingAccess else { return }

        // Read minimised state on MainActor before entering detached task (Swift 6 requirement).
        var minRef: CFTypeRef?
        AXUIElementCopyAttributeValue(tab.axElement, kAXMinimizedAttribute as CFString, &minRef)
        let minimised = (minRef as? Bool) ?? false
        
        // Read current AX window size for aspect-ratio preview sizing
        var sizeRef: CFTypeRef?
        AXUIElementCopyAttributeValue(tab.axElement, kAXSizeAttribute as CFString, &sizeRef)
        var axSize = CGSize.zero
        if let s = sizeRef as! AXValue? { AXValueGetValue(s, .cgSize, &axSize) }
        if axSize.width > 10 && axSize.height > 10 { windowSize = axSize }

        // Capture values needed inside the detached task NOW, while on MainActor.
        let axElem    = tab.axElement
        let windowID  = tab.windowID
        let processID = tab.processID
        let winTitle  = tab.windowTitle

        Task.detached(priority: .userInitiated) {
            do {
                // Fetch all shareable content including offscreen windows
                let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: false)
                
                // Find the SCWindow that corresponds to THIS specific window.
                var scWin = content.windows.first(where: { $0.windowID == windowID })
                if scWin == nil {
                    scWin = content.windows.first(where: {
                        $0.owningApplication?.processID == processID && $0.title == winTitle
                    })
                }

                if minimised {
                    guard let targetWindow = scWin else {
                        await MainActor.run {
                            self.isMinimised   = true
                            self.previewImage  = nil
                        }
                        return
                    }

                    // Modern API configuration
                    let config = SCStreamConfiguration()
                    config.pixelFormat   = kCVPixelFormatType_32BGRA
                    config.showsCursor   = false
                    config.capturesAudio = false
                    
                    let scale = min(NSScreen.main?.backingScaleFactor ?? 2.0, 2.0)
                    config.width  = max(Int(targetWindow.frame.width * scale), 2)
                    config.height = max(Int(targetWindow.frame.height * scale), 2)

                    // Create the filter specifically for an independent standalone window
                    let windowFilter = SCContentFilter(desktopIndependentWindow: targetWindow)
                    let img = try await SCScreenshotManager.captureImage(contentFilter: windowFilter, configuration: config)
                    
                    await MainActor.run {
                        let ns = NSImage(cgImage: img, size: CGSize(width: img.width, height: img.height))
                        self.windowSize    = CGSize(width: CGFloat(img.width) / scale, height: CGFloat(img.height) / scale)
                        self.previewImage  = ns
                        self.captureFailed = false
                        self.isMinimised   = false
                    }
                    return
                }

                // --- Standard On-Screen Composited Capture Sequence ---
                let approxWindowFrame = axWindowScreenFrame(for: axElem)
                let scDisplay = content.displays.first(where: {
                    $0.frame.intersects(approxWindowFrame)
                }) ?? content.displays.first

                guard let scDisplay else {
                    await MainActor.run { self.captureFailed = true }
                    return
                }

                if scWin == nil {
                    scWin = content.windows
                        .filter { $0.owningApplication?.processID == processID }
                        .max(by: {
                            $0.frame.intersection(approxWindowFrame).area <
                            $1.frame.intersection(approxWindowFrame).area
                        })
                }

                let windowsToExclude = content.windows.filter { w in
                    w.owningApplication?.processID != processID
                }

                let filter = SCContentFilter(display: scDisplay, excludingWindows: windowsToExclude)
                let scale = min(NSScreen.main?.backingScaleFactor ?? 2.0, 2.0)
                
                let config = SCStreamConfiguration()
                config.pixelFormat   = kCVPixelFormatType_32BGRA
                config.showsCursor   = false
                config.capturesAudio = false
                config.width  = max(Int(scDisplay.frame.width  * scale), 2)
                config.height = max(Int(scDisplay.frame.height * scale), 2)

                let fullImage = try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)

                let windowFrame = scWin?.frame ?? approxWindowFrame
                let displayOrigin = scDisplay.frame.origin
                let relX = (windowFrame.minX - displayOrigin.x) * scale
                let relY = (windowFrame.minY - displayOrigin.y) * scale
                let relW = windowFrame.width  * scale
                let relH = windowFrame.height * scale

                let cropRect = CGRect(x: relX, y: relY, width: relW, height: relH)
                    .intersection(CGRect(x: 0, y: 0, width: CGFloat(fullImage.width), height: CGFloat(fullImage.height)))

                if cropRect.width > 8, cropRect.height > 8,
                   let cropped = fullImage.cropping(to: cropRect) {
                    let ns = NSImage(cgImage: cropped, size: CGSize(width: cropped.width, height: cropped.height))
                    let capturedSize = CGSize(width: windowFrame.width, height: windowFrame.height)
                    await MainActor.run {
                        if capturedSize.width > 10 { self.windowSize = capturedSize }
                        self.previewImage  = ns
                        self.captureFailed = false
                        self.isMinimised   = false
                    }
                } else {
                    let ns = NSImage(cgImage: fullImage, size: CGSize(width: fullImage.width, height: fullImage.height))
                    await MainActor.run {
                        self.previewImage  = ns
                        self.captureFailed = false
                        self.isMinimised   = false
                    }
                }
            } catch {
                await MainActor.run {
                    if minimised {
                        self.isMinimised = true
                        self.previewImage = nil
                    } else {
                        self.captureFailed = true
                    }
                }
            }
        }
    }

    private func openScreenRecordingSettings() {
        NSWorkspace.shared.open(
            URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!)
    }
}

// MARK: - Focus helper

struct PreviewWindowManager {
    /// Always focuses/restores a specific window — never minimizes it.
    /// Called from preview chip taps in both AppKitTabButtonView and PinnedAppsTray.
    static func focusTargetWindowContext(for tab: WindowTab) {
        NotificationCenter.default.post(name: .dismissStartMenuWindow, object: nil)

        let appRef   = AXUIElementCreateApplication(tab.processID)
        let axWindow = tab.axElement

        var minimizedRef: CFTypeRef?
        AXUIElementCopyAttributeValue(axWindow, kAXMinimizedAttribute as CFString, &minimizedRef)
        let isMinimized = (minimizedRef as? Bool) ?? false

        if isMinimized {
            AeroBarSettings.shared.currentSystemFocusedElement = axWindow
            NotificationCenter.default.post(name: .suppressFocusUpdates, object: nil)
            AXUIElementSetAttributeValue(axWindow, kAXMinimizedAttribute as CFString, false as CFTypeRef)

            let pid = tab.processID
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                let app = AXUIElementCreateApplication(pid)
                AXUIElementSetAttributeValue(app,      kAXFrontmostAttribute as CFString, true as CFTypeRef)
                AXUIElementSetAttributeValue(axWindow, kAXMainAttribute      as CFString, true as CFTypeRef)
                AXUIElementPerformAction(axWindow, kAXRaiseAction as CFString)
                NSRunningApplication(processIdentifier: pid)?.activate(options: [])
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    AeroBarSettings.shared.currentSystemFocusedElement = axWindow
                    NotificationCenter.default.post(name: .resumeFocusUpdates, object: nil)
                }
            }
        } else {
            AXUIElementPerformAction(axWindow, kAXRaiseAction as CFString)
            AXUIElementSetAttributeValue(axWindow, kAXMainAttribute      as CFString, true as CFTypeRef)
            AXUIElementSetAttributeValue(appRef,   kAXFrontmostAttribute as CFString, true as CFTypeRef)
            NSRunningApplication(processIdentifier: tab.processID)?.activate(options: [])
        }
    }
}
