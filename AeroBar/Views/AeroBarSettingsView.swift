import SwiftUI

struct AeroBarSettingsView: View {
    @ObservedObject var settings = AeroBarSettings.shared
    @ObservedObject var updateEngine = AeroBarUpdateEngine.shared

    // Controls the inline changelog sheet
    @State private var showChangelogSheet: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {

            // ==========================================
            // ⚙️ GENERAL PREFERENCES SECTION
            // ==========================================
            Text("General")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.4))

            Toggle("Launch at Login", isOn: $settings.launchAtLogin)
            Toggle("Enable Recommendations", isOn: $settings.showRecommendations)

            Divider().background(Color.white.opacity(0.1))

            // ==========================================
            // 🔄 UPDATE SECTION
            // ==========================================
            Text("Updates")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.4))

            // ── Silent auto-update toggle ────────────────────────────
            VStack(alignment: .leading, spacing: 4) {
                Toggle("Silent Auto-Update", isOn: $settings.enableSilentUpdates)
                Text("When enabled, AeroBar downloads and installs updates automatically without asking. When disabled, a popup is shown with release notes so you can decide.")
                    .font(.system(size: 9.5))
                    .foregroundColor(.white.opacity(0.35))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Toggle("Check for updates on launch", isOn: $settings.checkUpdatesOnLaunch)

            VStack(alignment: .leading, spacing: 6) {
                Text("Check frequency")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))

                Picker("", selection: $settings.updateFrequency) {
                    Text("Daily").tag(0)
                    Text("Weekly").tag(1)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }

            // ── Update available banner ──────────────────────────────
            if settings.isUpdateAvailable {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: updateEngine.isDownloadingDirectly
                              ? "arrow.clockwise.circle.fill"
                              : "arrow.down.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.accentColor)
                            .rotationEffect(.degrees(updateEngine.isDownloadingDirectly ? 360 : 0))
                            .animation(
                                updateEngine.isDownloadingDirectly
                                    ? .linear(duration: 1).repeatForever(autoreverses: false)
                                    : .default,
                                value: updateEngine.isDownloadingDirectly
                            )

                        Text("New Build: \(settings.latestRemoteVersionString)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white.opacity(0.95))
                    }

                    Text(updateEngine.isDownloadingDirectly
                         ? updateEngine.installationStatusMessage
                         : "A fresh executable revision was discovered.")
                        .font(.system(size: 9.5))
                        .foregroundColor(.white.opacity(0.5))

                    if !updateEngine.isDownloadingDirectly {
                        HStack(spacing: 8) {
                            // Changelog button — shows release notes inline
                            Button(action: { showChangelogSheet = true }) {
                                Text("View Changelog")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.8))
                                    .frame(maxWidth: .infinity, minHeight: 22)
                                    .background(Color.white.opacity(0.10))
                                    .cornerRadius(4)
                            }
                            .buttonStyle(.plain)

                            // Install button
                            Button(action: {
                                updateEngine.downloadAndInstallUpdateSilently()
                            }) {
                                Text("Download & Install")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity, minHeight: 22)
                                    .background(Color.accentColor)
                                    .cornerRadius(4)
                            }
                            .buttonStyle(.plain)
                        }
                    } else {
                        HStack(spacing: 8) {
                            ProgressView().controlSize(.small)
                            Text("Don't close the app...")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(.white.opacity(0.3))
                        }
                        .padding(.top, 2)
                    }
                }
                .padding(10)
                .background(Color.accentColor.opacity(0.08))
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.accentColor.opacity(0.2), lineWidth: 1))
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            // ── Manual check + changelog buttons row ─────────────────
            HStack(spacing: 8) {
                Button(action: {
                    AeroBarUpdateEngine.shared.checkForUpdatesSilently()
                }) {
                    Text("Check for Updates")
                        .font(.system(size: 11, weight: .medium))
                        .frame(maxWidth: .infinity, minHeight: 24)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)

                // Always-visible changelog button (shows last fetched notes)
                if !settings.latestChangelog.isEmpty {
                    Button(action: { showChangelogSheet = true }) {
                        Text("Changelog")
                            .font(.system(size: 11, weight: .medium))
                            .frame(minWidth: 80, minHeight: 24)
                            .background(Color.white.opacity(0.06))
                            .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                }
            }

            Divider().background(Color.white.opacity(0.1))

            // ==========================================
            // 🛑 TERMINATE APPLICATION BUTTON RAIL
            // ==========================================
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
        .padding(16)
        .frame(width: 260)
        .background(VisualEffectBlurView(material: .hudWindow, blendingMode: .withinWindow, state: .active))
        .animation(.easeInOut(duration: 0.2), value: settings.isUpdateAvailable)
        .animation(.easeInOut(duration: 0.2), value: updateEngine.isDownloadingDirectly)
        // ── Changelog sheet ─────────────────────────────────────────
        .sheet(isPresented: $showChangelogSheet) {
            AeroBarChangelogSheetView(
                version: settings.latestRemoteVersionString,
                changelog: settings.latestChangelog,
                isPresented: $showChangelogSheet
            )
        }
    }
}

// ==========================================
// 📋 INLINE CHANGELOG SHEET
// Shown when "Changelog" or "View Changelog" is tapped in settings.
// ==========================================
struct AeroBarChangelogSheetView: View {
    let version: String
    let changelog: String
    @Binding var isPresented: Bool

    var body: some View {
        ZStack {
            VisualEffectBlurView(material: .hudWindow, blendingMode: .withinWindow, state: .active)

            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Release Notes")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        if !version.isEmpty {
                            Text("AeroBar \(version)")
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.4))
                        }
                    }
                    Spacer()
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.white.opacity(0.4))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 12)

                Divider().background(Color.white.opacity(0.1))

                ScrollView(.vertical, showsIndicators: true) {
                    Text(changelog.isEmpty ? "No release notes available." : changelog)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.85))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .textSelection(.enabled)
                }

                Divider().background(Color.white.opacity(0.1))

                Button(action: { isPresented = false }) {
                    Text("Done")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity, minHeight: 30)
                        .background(Color.accentColor)
                        .cornerRadius(7)
                }
                .buttonStyle(.plain)
                .padding(16)
            }
        }
        .frame(width: 420, height: 420)
    }
}
