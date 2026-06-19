// AeroBarSettingsView.swift — Settings popover root (General + Updates + Quit).
// Owner: Views/Settings
// Depends on: Core/Services/AeroBarSettings, Core/Services/AeroBarUpdateEngine

import SwiftUI

struct AeroBarSettingsView: View {
    @ObservedObject var settings = AeroBarSettings.shared
    @ObservedObject var updateEngine = AeroBarUpdateEngine.shared
    @State private var showChangelog = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            generalSection
            Divider().background(Color.white.opacity(0.1))
            updatesSection
            Divider().background(Color.white.opacity(0.1))
            quitButton
        }
        .padding(16)
        .frame(width: 260)
        .background(VisualEffectBlurView(material: .hudWindow, blendingMode: .withinWindow, state: .active))
        .animation(.easeInOut(duration: 0.2), value: settings.isUpdateAvailable)
        .animation(.easeInOut(duration: 0.2), value: updateEngine.isDownloadingDirectly)
        .sheet(isPresented: $showChangelog) {
            AeroBarChangelogSheetView(
                version: settings.latestRemoteVersionString,
                changelog: settings.latestChangelog,
                isPresented: $showChangelog
            )
        }
    }

    // MARK: - Sections

    private var generalSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("General")
            Toggle("Launch at Login", isOn: $settings.launchAtLogin)
            Toggle("Enable Recommendations", isOn: $settings.showRecommendations)
        }
    }

    private var updatesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Updates")

            VStack(alignment: .leading, spacing: 4) {
                Toggle("Silent Auto-Update", isOn: $settings.enableSilentUpdates)
                Text("When enabled, AeroBar installs updates automatically. When disabled, a popup shows release notes first.")
                    .font(.system(size: 9.5))
                    .foregroundColor(.white.opacity(0.35))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Toggle("Check for updates on launch", isOn: $settings.checkUpdatesOnLaunch)

            VStack(alignment: .leading, spacing: 6) {
                Text("Check frequency").font(.system(size: 11, weight: .medium)).foregroundColor(.white.opacity(0.7))
                Picker("", selection: $settings.updateFrequency) {
                    Text("Daily").tag(0)
                    Text("Weekly").tag(1)
                }
                .pickerStyle(.segmented).labelsHidden()
            }

            if settings.isUpdateAvailable {
                UpdateAvailableBanner(showChangelog: $showChangelog)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            HStack(spacing: 8) {
                Button("Check for Updates") { AeroBarUpdateEngine.shared.checkForUpdatesSilently() }
                    .buttonStyle(BarButtonStyle())
                if !settings.latestChangelog.isEmpty {
                    Button("Changelog") { showChangelog = true }
                        .buttonStyle(BarButtonStyle())
                }
            }
        }
    }

    private var quitButton: some View {
        Button(action: { NSApp.terminate(nil) }) {
            Text("Quit AeroBar")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.red.opacity(0.9))
                .frame(maxWidth: .infinity, minHeight: 24)
                .background(Color.red.opacity(0.15))
                .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .foregroundColor(.white.opacity(0.4))
    }
}

// MARK: - Reusable button style for settings rows

struct BarButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 11, weight: .medium))
            .frame(maxWidth: .infinity, minHeight: 24)
            .background(Color.white.opacity(configuration.isPressed ? 0.12 : 0.08))
            .cornerRadius(6)
            .foregroundColor(.white.opacity(0.85))
    }
}

// MARK: - Update available banner (extracted to keep the main body readable)

private struct UpdateAvailableBanner: View {
    @ObservedObject var settings = AeroBarSettings.shared
    @ObservedObject var engine   = AeroBarUpdateEngine.shared
    @Binding var showChangelog: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: engine.isDownloadingDirectly ? "arrow.clockwise.circle.fill" : "arrow.down.circle.fill")
                    .font(.system(size: 14)).foregroundColor(.accentColor)
                    .rotationEffect(.degrees(engine.isDownloadingDirectly ? 360 : 0))
                    .animation(engine.isDownloadingDirectly
                        ? .linear(duration: 1).repeatForever(autoreverses: false)
                        : .default, value: engine.isDownloadingDirectly)
                Text("New Build: \(settings.latestRemoteVersionString)")
                    .font(.system(size: 11, weight: .bold)).foregroundColor(.white.opacity(0.95))
            }
            Text(engine.isDownloadingDirectly ? engine.installationStatusMessage : "A fresh build is ready.")
                .font(.system(size: 9.5)).foregroundColor(.white.opacity(0.5))
            if engine.isDownloadingDirectly {
                HStack(spacing: 8) {
                    ProgressView().controlSize(.small)
                    Text("Don't close the app...").font(.system(size: 9)).foregroundColor(.white.opacity(0.3))
                }
            } else {
                HStack(spacing: 8) {
                    Button("View Changelog") { showChangelog = true }
                        .buttonStyle(BarButtonStyle())
                    Button("Download & Install") { engine.downloadAndInstallUpdateSilently() }
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity, minHeight: 22)
                        .background(Color.accentColor)
                        .cornerRadius(4)
                        .buttonStyle(.plain)
                }
            }
        }
        .padding(10)
        .background(Color.accentColor.opacity(0.08))
        .cornerRadius(8)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.accentColor.opacity(0.2), lineWidth: 1))
    }
}
