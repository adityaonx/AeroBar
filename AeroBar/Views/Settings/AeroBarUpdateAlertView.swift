// AeroBarUpdateAlertView.swift — Content view for the update-available prompt.
// Owner: Views/Settings
// Depends on: Views/AppKitBridges/VisualEffectBlurView
//
// Shows the new version number, a scrollable changelog, and Update Now / Later
// actions. Hosted inside AeroBarUpdateAlertPanel.

import SwiftUI

struct AeroBarUpdateAlertView: View {
    let version: String
    let changelog: String
    let onUpdateNow: () -> Void
    let onLater: () -> Void

    var body: some View {
        ZStack {
            VisualEffectBlurView(material: .hudWindow, blendingMode: .withinWindow, state: .active)

            VStack(spacing: 0) {
                header
                Divider().background(Color.white.opacity(0.1))
                changelogSection
                Divider().background(Color.white.opacity(0.1))
                actionButtons
            }
        }
        .frame(width: 460, height: 480)
    }

    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: "arrow.down.circle.fill")
                .font(.system(size: 36, weight: .light))
                .foregroundColor(.accentColor)

            Text("AeroBar \(version) Available")
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text("A new version is ready to install.")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(.top, 28)
        .padding(.bottom, 16)
    }

    private var changelogSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("What's New")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.4))
                .padding(.horizontal, 16)
                .padding(.top, 12)

            ScrollView(.vertical, showsIndicators: true) {
                Text(changelog.isEmpty ? "No release notes provided." : changelog)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.85))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                    .textSelection(.enabled)
            }
            .frame(maxHeight: 260)
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 10) {
            Button(action: onLater) {
                Text("Later")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(maxWidth: .infinity, minHeight: 30)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(7)
            }
            .buttonStyle(.plain)

            Button(action: onUpdateNow) {
                Text("Update Now")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity, minHeight: 30)
                    .background(Color.accentColor)
                    .cornerRadius(7)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}
