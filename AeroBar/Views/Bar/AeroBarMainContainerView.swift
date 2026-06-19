// AeroBarMainContainerView.swift — Root SwiftUI view for the taskbar.
// Owner: Views/Bar
// Depends on: Core/Services/AeroBarSettings, Views/Subviews/*
//
// Layout: background layers → HStack of bar sections.
// All interaction callbacks are defined here and passed down — subviews are pure displays.

import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct AeroBarMainContainerView: View {
    @StateObject private var settings = AeroBarSettings.shared
    @Environment(\.colorScheme) var colorScheme

    @State private var draggedPinnedItem: PinnedApp? = nil

    var body: some View {
        ZStack(alignment: .leading) {
            barBackground
            barContent
        }
        .frame(maxWidth: .infinity, maxHeight: 56)
        .foregroundColor(colorScheme == .dark ? .white : .black)
    }

    // MARK: - Background

    private var barBackground: some View {
        ZStack {
            VisualEffectBlurView(material: settings.selectedMaterial, blendingMode: .behindWindow, state: .active)
                .id(settings.blurMaterialRaw)

            Color(settings.tintColorHex)
                .opacity(settings.backdropOpacity)
                .blendMode(.overlay)

            LinearGradient(
                gradient: Gradient(colors: [
                    colorScheme == .dark ? Color.white.opacity(0.18) : Color.white.opacity(0.28),
                    colorScheme == .dark ? Color.white.opacity(0.03) : Color.white.opacity(0.06),
                    Color.clear
                ]),
                startPoint: .top,
                endPoint: .center
            )
            .blendMode(.plusLighter)

            SurfaceNoiseView().opacity(0.01).blendMode(.overlay)

            if settings.showTopBorder {
                VStack {
                    Rectangle()
                        .fill(colorScheme == .dark ? Color.white.opacity(0.25) : Color.white.opacity(0.40))
                        .frame(height: 0.5)
                    Spacer()
                }
            }
        }
        .frame(height: settings.barHeight)
        .offset(y: 8)
    }

    // MARK: - Bar sections

    private var barContent: some View {
        HStack(spacing: 0) {
            AeroVistaOrbButton()

            if settings.showSearchIcon {
                SpotlightSearchField()
                    .padding(.leading, 10)
                    .padding(.trailing, 12)
                    .transition(.move(edge: .leading).combined(with: .opacity))
            } else {
                Spacer().frame(width: 12)
            }

            PinnedAppsTray(
                draggedPinnedItem: $draggedPinnedItem,
                onLaunch: launchOrActivatePinnedApp,
                onUnpin: unpinApplication
            )

            // Divider between pinned apps and window tabs
            Rectangle()
                .fill(colorScheme == .dark ? Color.white.opacity(0.20) : Color.black.opacity(0.20))
                .frame(width: 1, height: 22)
                .padding(.horizontal, 12)

            WindowTabsScrollView(
                onTabInteraction: handleWindowInteraction,
                onPinToStartMenu: pinTabToStart,
                onPinToAeroBar: pinTabToBar
            )
            .frame(maxWidth: .infinity)

            RecycleBinButton(action: { NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: "~/.Trash") })
                .padding(.trailing, 24)
        }
        .frame(height: settings.barHeight)
        .offset(y: 8)
    }

    // MARK: - Window interaction

    private func handleWindowInteraction(for tab: WindowTab) {
        let appRef = AXUIElementCreateApplication(tab.processID)
        var minimizedRef: CFTypeRef?
        AXUIElementCopyAttributeValue(tab.axElement, kAXMinimizedAttribute as CFString, &minimizedRef)
        let isMinimized = (minimizedRef as? Bool) ?? false

        if isMinimized {
            // Lock focused element and suppress observer callbacks during the unminimize
            // animation. Finder fires kAXFocusedWindowChangedNotification with a transient
            // Desktop element during restore, which would clear the active-tab highlight.
            AeroBarSettings.shared.currentSystemFocusedElement = tab.axElement
            NotificationCenter.default.post(name: .suppressFocusUpdates, object: nil)
            AXUIElementSetAttributeValue(tab.axElement, kAXMinimizedAttribute as CFString, false as CFTypeRef)

            let elem = tab.axElement
            let pid  = tab.processID
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                let delayed = AXUIElementCreateApplication(pid)
                AXUIElementSetAttributeValue(delayed, kAXFrontmostAttribute as CFString, true as CFTypeRef)
                AXUIElementSetAttributeValue(elem, kAXMainAttribute as CFString, true as CFTypeRef)
                NSRunningApplication(processIdentifier: pid)?.activate()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    AeroBarSettings.shared.currentSystemFocusedElement = elem
                    NotificationCenter.default.post(name: .resumeFocusUpdates, object: nil)
                }
            }
        } else {
            let isFrontmost = NSWorkspace.shared.frontmostApplication?.processIdentifier == tab.processID
            if isFrontmost {
                var focusedRef: CFTypeRef?
                let result = AXUIElementCopyAttributeValue(appRef, kAXFocusedWindowAttribute as CFString, &focusedRef)
                if result == .success, let systemFocused = focusedRef, CFEqual(tab.axElement, systemFocused) {
                    AXUIElementSetAttributeValue(tab.axElement, kAXMinimizedAttribute as CFString, true as CFTypeRef)
                } else {
                    AXUIElementSetAttributeValue(tab.axElement, kAXMainAttribute as CFString, true as CFTypeRef)
                }
            } else {
                AXUIElementSetAttributeValue(tab.axElement, kAXMainAttribute as CFString, true as CFTypeRef)
                AXUIElementSetAttributeValue(appRef, kAXFrontmostAttribute as CFString, true as CFTypeRef)
                NSRunningApplication(processIdentifier: tab.processID)?.activate()
            }
        }
    }

    // MARK: - Pinned app actions

    private func pinTabToStart(tab: WindowTab) {
        guard let app = NSRunningApplication(processIdentifier: tab.processID),
              let bundleID = app.bundleIdentifier,
              !settings.pinnedStartApps.contains(where: { $0.bundleIdentifier == bundleID })
        else { return }
        settings.pinnedStartApps.append(PinnedApp(bundleIdentifier: bundleID, appName: tab.appName))
    }

    private func pinTabToBar(tab: WindowTab) {
        guard let app = NSRunningApplication(processIdentifier: tab.processID),
              let bundleID = app.bundleIdentifier,
              !settings.pinnedBarApps.contains(where: { $0.bundleIdentifier == bundleID })
        else { return }
        settings.pinnedBarApps.append(PinnedApp(bundleIdentifier: bundleID, appName: tab.appName))
    }

    private func unpinApplication(bundleID: String) {
        guard bundleID != "com.apple.finder" else { return }
        settings.pinnedBarApps.removeAll { $0.bundleIdentifier == bundleID }
    }

    private func launchOrActivatePinnedApp(bundleID: String) {
        guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else { return }
        let config = NSWorkspace.OpenConfiguration()
        config.createsNewApplicationInstance = false

        func openNewWindow() {
            if bundleID == "com.apple.finder" {
                NSWorkspace.shared.open(URL(fileURLWithPath: NSHomeDirectory()), configuration: config)
            } else {
                if ["com.google.Chrome", "com.microsoft.edgemac", "com.microsoft.VSCode"].contains(bundleID) {
                    config.arguments = ["--new-window"]
                } else if bundleID == "org.mozilla.firefox" {
                    config.arguments = ["-new-window"]
                }
                NSWorkspace.shared.openApplication(at: appURL, configuration: config)
            }
        }

        guard let running = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == bundleID }) else {
            openNewWindow()
            return
        }

        let appRef = AXUIElementCreateApplication(running.processIdentifier)
        var windowsRef: CFTypeRef?
        AXUIElementCopyAttributeValue(appRef, kAXWindowsAttribute as CFString, &windowsRef)
        var windows = (windowsRef as? [AXUIElement]) ?? []

        if bundleID == "com.apple.finder" {
            windows = windows.filter {
                var t: CFTypeRef?
                AXUIElementCopyAttributeValue($0, kAXTitleAttribute as CFString, &t)
                let title = t as? String ?? ""
                return !title.isEmpty && title != "Desktop"
            }
        }

        guard let primary = windows.first else { openNewWindow(); return }

        let isFront = NSWorkspace.shared.frontmostApplication?.processIdentifier == running.processIdentifier
        var minRef: CFTypeRef?
        AXUIElementCopyAttributeValue(primary, kAXMinimizedAttribute as CFString, &minRef)
        let isMin = (minRef as? Bool) ?? false

        if isFront && !isMin {
            AXUIElementSetAttributeValue(primary, kAXMinimizedAttribute as CFString, true as CFTypeRef)
        } else {
            if isMin { AXUIElementSetAttributeValue(primary, kAXMinimizedAttribute as CFString, false as CFTypeRef) }
            AXUIElementSetAttributeValue(primary, kAXMainAttribute as CFString, true as CFTypeRef)
            AXUIElementPerformAction(primary, "AXRaise" as CFString)
            running.activate()
        }
    }
}
