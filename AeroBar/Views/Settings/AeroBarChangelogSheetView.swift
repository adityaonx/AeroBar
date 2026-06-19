// AeroBarChangelogSheetView.swift — Modal sheet displaying release notes.
// Owner: Views/Settings
// Depends on: Core/Services/AeroBarSettings, Views/AppKitBridges/VisualEffectBlurView

import SwiftUI

struct AeroBarChangelogSheetView: View {
    let version: String
    let changelog: String
    @Binding var isPresented: Bool

    var body: some View {
        ZStack {
            VisualEffectBlurView(material: .hudWindow, blendingMode: .withinWindow, state: .active)
            VStack(spacing: 0) {
                header
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
                doneButton
            }
        }
        .frame(width: 420, height: 420)
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Release Notes").font(.system(size: 15, weight: .bold, design: .rounded)).foregroundColor(.white)
                if !version.isEmpty {
                    Text("AeroBar \(version)").font(.system(size: 11)).foregroundColor(.white.opacity(0.4))
                }
            }
            Spacer()
            Button(action: { isPresented = false }) {
                Image(systemName: "xmark.circle.fill").font(.system(size: 18)).foregroundColor(.white.opacity(0.4))
            }.buttonStyle(.plain)
        }
        .padding(.horizontal, 16).padding(.top, 16).padding(.bottom, 12)
    }

    private var doneButton: some View {
        Button("Done") { isPresented = false }
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(.black)
            .frame(maxWidth: .infinity, minHeight: 30)
            .background(Color.accentColor)
            .cornerRadius(7)
            .buttonStyle(.plain)
            .padding(16)
    }
}
