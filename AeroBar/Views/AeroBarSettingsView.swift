import SwiftUI

struct AeroBarSettingsView: View {
    @ObservedObject var settings = AeroBarSettings.shared
    // 🎯 Observed reference to track downloading, mounting, and installation statuses
    @ObservedObject var updateEngine = AeroBarUpdateEngine.shared
    
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
            // 🔄 UPDATES CONFIGURATION SECTION
            // ==========================================
            Text("Updates")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.4))
            
            // 🎯 UPDATED INLINE SILENT INSTALLER ALERT BANNER
            if settings.isUpdateAvailable {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: updateEngine.isDownloadingDirectly ? "arrow.clockwise.circle.fill" : "arrow.down.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.accentColor)
                            .rotationEffect(.degrees(updateEngine.isDownloadingDirectly ? 360 : 0))
                            .animation(updateEngine.isDownloadingDirectly ? Animation.linear(duration: 1).repeatForever(autoreverses: false) : .default, value: updateEngine.isDownloadingDirectly)
                        
                        Text("New Build: \(settings.latestRemoteVersionString)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white.opacity(0.95))
                    }
                    
                    // 🎯 Dynamic text adapts to show exact background mounting/copying progress
                    Text(updateEngine.isDownloadingDirectly ? updateEngine.installationStatusMessage : "A fresh executable revision was discovered on your remote branch.")
                        .font(.system(size: 9.5))
                        .foregroundColor(.white.opacity(0.5))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    if !updateEngine.isDownloadingDirectly {
                        Button(action: {
                            // 🎯 Runs the fully automated, silent native DMG extraction loop
                            updateEngine.downloadAndInstallUpdateSilently()
                        }) {
                            Text("Download & Install Instantly")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity, minHeight: 22)
                                .background(Color.accentColor)
                                .cornerRadius(4)
                        }
                        .buttonStyle(.plain)
                    } else {
                        // Progress layout display when update script takes control
                        HStack(spacing: 8) {
                            ProgressView()
                                .controlSize(.small)
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
            
            Button(action: {
                print("DEBUG: Initiating manual update sequence tracking...")
                AeroBarUpdateEngine.shared.checkForUpdatesSilently()
            }) {
                Text("Check for Updates Now")
                    .font(.system(size: 11, weight: .medium))
                    .frame(maxWidth: .infinity, minHeight: 24)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(6)
            }
            .buttonStyle(.plain)
            
            Divider().background(Color.white.opacity(0.1))
            
            // ==========================================
            // 🛑 TERMINATE APPLICATION BUTTON RAIL
            // ==========================================
            Button(action: {
                NSApp.terminate(nil)
            }) {
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
    }
}
