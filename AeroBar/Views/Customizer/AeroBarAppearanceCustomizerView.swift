// AeroBarAppearanceCustomizerView.swift — Appearance popover root.
// Owner: Views/Customizer
// Depends on: Core/Services/AeroBarSettings, Core/Utilities/ColorExtensions
//
// ADDING A NEW APPEARANCE TOGGLE:
//   1. Add its @AppStorage key to AeroBarSettings.
//   2. Create a small View in this file (or a new file in Views/Customizer).
//   3. Drop it into the body below — no other file needs changing.

import SwiftUI

struct AeroBarAppearanceCustomizerView: View {
    @StateObject private var settings = AeroBarSettings.shared
    @Environment(\.colorScheme) var colorScheme

    @State private var showOrbSpectrum = false
    @State private var showBarSpectrum = false

    // Preset tint swatches aligned to macOS Tahoe palette
    private let tintPalette: [(hex: String, name: String)] = [
        ("#FFFFFF", "Frosted Ice"),     ("#1E1E1E", "Obsidian Dark"),
        ("#0A84FF", "Tahoe Sky"),       ("#30D158", "Vibrant Mint"),
        ("#FF453A", "Satin Crimson"),   ("#BF5AF2", "Neon Amethyst"),
        ("#FF9F0A", "Industrial Amber")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            customizerHeader
            orbSection
            Divider()
            materialAndTintSection
            Divider()
            togglesSection
        }
        .padding(14)
        .frame(width: 290)
    }

    // MARK: - Header

    private var customizerHeader: some View {
        HStack(spacing: 6) {
            Image(systemName: "paintpalette.fill").font(.system(size: 13, weight: .bold)).foregroundColor(.accentColor)
            Text("Taskbar Appearance Lab").font(.system(size: 13, weight: .bold, design: .rounded))
            Spacer()
            Button(action: resetToDefaults) {
                HStack(spacing: 3) {
                    Image(systemName: "arrow.triangle.2.circlepath").font(.system(size: 9, weight: .bold))
                    Text("Reset").font(.system(size: 10, weight: .medium, design: .rounded))
                }
                .foregroundColor(.secondary)
                .padding(.horizontal, 6).padding(.vertical, 3)
                .background(Color.primary.opacity(0.06)).cornerRadius(4)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Orb section

    private var orbSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                subLabel("Aero Start Orb Profile")
                Spacer()
                Button(action: { settings.appendOrbPreset(hex: settings.selectedOrbColorHex) }) {
                    HStack(spacing: 2) {
                        Image(systemName: "plus.circle.fill").font(.system(size: 9))
                        Text("Save Preset").font(.system(size: 9, weight: .semibold))
                    }
                    .foregroundColor(.accentColor)
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 8) {
                spectrumToggleButton(isOpen: showOrbSpectrum) {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) { showOrbSpectrum.toggle() }
                }
                thinDivider
                presetScrollRow(
                    presets: settings.parsedOrbPresets,
                    selected: settings.selectedOrbColorHex,
                    onSelect: { settings.selectedOrbColorHex = $0 },
                    onDelete: { settings.removeOrbPreset(hex: $0) }
                )
            }
            .pillBackground

            if showOrbSpectrum {
                orbSpectrumStudio
                    .pillBackground
                    .transition(.asymmetric(insertion: .opacity.combined(with: .move(edge: .top)), removal: .opacity))
            }
        }
    }

    private var orbSpectrumStudio: some View {
        VStack(alignment: .leading, spacing: 10) {
            hueRow(label: "Studio Precision Hue", hex: settings.selectedOrbColorHex) {
                updateColorFromHue($0, saturation: 0.90, brightness: 0.95, target: \.selectedOrbColorHex)
            }
            Divider().opacity(0.15)
            logoTintRow
        }
        .padding(8)
    }

    private var logoTintRow: some View {
        VStack(alignment: .leading, spacing: 4) {
            hueHexLabel("Logo Foreground Tint", hex: settings.selectedOrbLogoColorHex)
            HStack(spacing: 6) {
                ForEach(["#FFFFFF", "#1E1E1E"], id: \.self) { hex in
                    Circle().fill(Color(hex)).frame(width: 14, height: 14)
                        .overlay(Circle().stroke(Color.accentColor, lineWidth: settings.selectedOrbLogoColorHex.lowercased() == hex.lowercased() ? 1.5 : 0).padding(-1))
                        .onTapGesture { settings.selectedOrbLogoColorHex = hex }
                }
                Slider(
                    value: Binding(get: { hueFromHex(settings.selectedOrbLogoColorHex) },
                                   set: { updateColorFromHue($0, saturation: 0.85, brightness: 0.95, target: \.selectedOrbLogoColorHex) }),
                    in: 0...360, step: 1
                )
                .rainbowBackground
            }
        }
    }

    // MARK: - Material & tint

    private var materialAndTintSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                subLabel("Wallpaper Glass Blend Style")
                Picker("", selection: $settings.blurMaterialRaw) {
                    Text("Liquid Wallpaper Look (HUD)").tag(8)
                    Text("Deep Core Content Layer").tag(11)
                    Text("Translucent System Sidebar").tag(4)
                    Text("High Contrast Selection Tint").tag(1)
                    Text("Standard Translucent Overlay").tag(7)
                }
                .pickerStyle(PopUpButtonPickerStyle()).labelsHidden()
            }

            VStack(alignment: .leading, spacing: 6) {
                subLabel("Liquid Tint Hue")
                HStack(spacing: 8) {
                    spectrumToggleButton(isOpen: showBarSpectrum) {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) { showBarSpectrum.toggle() }
                    }
                    thinDivider
                    ForEach(tintPalette, id: \.hex) { swatch in
                        Circle().fill(Color(swatch.hex)).frame(width: 20, height: 20)
                            .overlay(Circle().stroke(Color.accentColor, lineWidth: settings.tintColorHex == swatch.hex ? 2 : 0).padding(-2))
                            .help(swatch.name)
                            .onTapGesture { settings.tintColorHex = swatch.hex }
                    }
                }
                .pillBackground

                if showBarSpectrum {
                    hueRow(label: "Custom Tint Color Selector", hex: settings.tintColorHex) {
                        updateColorFromHue($0, saturation: 0.75, brightness: 0.35, target: \.tintColorHex)
                    }
                    .pillBackground
                    .transition(.asymmetric(insertion: .opacity.combined(with: .move(edge: .top)), removal: .opacity))
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    subLabel("Surface Tint Density")
                    Spacer()
                    Text("\(Int(settings.backdropOpacity * 100))%").font(.system(size: 10, weight: .bold))
                }
                Slider(value: $settings.backdropOpacity, in: 0...1, step: 0.01).accentColor(.accentColor)
            }
        }
    }

    // MARK: - Toggles

    private var togglesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle(isOn: $settings.showTopBorder) {
                labelWithSubtext("Render Upper Specular Bevel Line", sub: "Adds a 0.5pt edge highlight")
            }
            .toggleStyle(CheckboxToggleStyle())

            Toggle(isOn: $settings.showSearchIcon) {
                labelWithSubtext("Show Search Icon", sub: "Toggle Spotlight quick access in taskbar")
            }
            .toggleStyle(CheckboxToggleStyle())

            Toggle(isOn: $settings.hideWindowLabelsTemporarily.animation(.easeInOut(duration: 0.2))) {
                labelWithSubtext("Collapse Taskbar Labels", sub: "Force icon-only mode for all window tabs")
            }
            .toggleStyle(SwitchToggleStyle(tint: .accentColor))
            .padding(.top, 4)

            VStack(alignment: .leading, spacing: 4) {
                Text("Show Taskbar On").font(.system(size: 11, weight: .bold)).foregroundColor(.secondary)
                Picker("", selection: $settings.displayTargetMode) {
                    ForEach(DisplayTargetMode.allCases) { mode in
                        Text(mode.rawValue).font(.system(size: 11)).tag(mode)
                    }
                }
                .pickerStyle(PopUpButtonPickerStyle()).frame(maxWidth: .infinity)
            }
            .padding(.top, 2)
        }
    }

    // MARK: - Reusable small components

    private func spectrumToggleButton(isOpen: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Circle()
                .fill(AngularGradient(colors: [.red,.orange,.yellow,.green,.blue,.purple,.pink,.red], center: .center))
                .frame(width: 18, height: 18)
                .overlay(Circle().stroke(Color.white.opacity(isOpen ? 0.9 : 0.3), lineWidth: isOpen ? 1.5 : 1))
                .shadow(color: .black.opacity(0.2), radius: 1)
        }
        .buttonStyle(.plain)
    }

    private var thinDivider: some View {
        Rectangle().fill(Color.white.opacity(0.15)).frame(width: 1, height: 14).padding(.horizontal, 2)
    }

    private func presetScrollRow(
        presets: [String], selected: String,
        onSelect: @escaping (String) -> Void,
        onDelete: @escaping (String) -> Void
    ) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(presets, id: \.self) { hex in
                    Circle().fill(Color(hex)).frame(width: 18, height: 18)
                        .overlay(Circle().stroke(Color.white, lineWidth: selected.lowercased() == hex.lowercased() ? 1.5 : 0))
                        .onTapGesture { onSelect(hex) }
                        .contextMenu {
                            Button("Remove Preset", role: .destructive) { onDelete(hex) }
                        }
                }
            }
            .padding(.horizontal, 2).padding(.vertical, 3)
        }
    }

    private func hueRow(label: String, hex: String, onChange: @escaping (Double) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            hueHexLabel(label, hex: hex)
            Slider(value: Binding(get: { hueFromHex(hex) }, set: onChange), in: 0...360, step: 1)
                .accentColor(Color(hex))
                .rainbowBackground
        }
    }

    private func hueHexLabel(_ label: String, hex: String) -> some View {
        HStack {
            Text(label).font(.system(size: 9, weight: .bold)).foregroundColor(.secondary)
            Spacer()
            Circle().fill(Color(hex)).frame(width: 8, height: 8)
            Text(hex.uppercased()).font(.system(size: 9, weight: .bold, design: .monospaced)).foregroundColor(.secondary)
        }
    }

    private func subLabel(_ text: String) -> some View {
        Text(text).font(.system(size: 10, weight: .bold)).foregroundColor(.secondary)
    }

    private func labelWithSubtext(_ main: String, sub: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(main).font(.system(size: 11, weight: .medium))
            Text(sub).font(.system(size: 9)).foregroundColor(.secondary)
        }
    }

    // MARK: - Colour math

    private func updateColorFromHue(_ hue: Double, saturation: CGFloat, brightness: CGFloat, target: ReferenceWritableKeyPath<AeroBarSettings, String>) {
        let ns = NSColor(hue: CGFloat(hue / 360), saturation: saturation, brightness: brightness, alpha: 1)
        guard let rgb = ns.usingColorSpace(.sRGB) else { return }
        settings[keyPath: target] = String(format: "#%02X%02X%02X",
            Int(rgb.redComponent * 255), Int(rgb.greenComponent * 255), Int(rgb.blueComponent * 255))
    }

    private func resetToDefaults() {
        withAnimation(.easeInOut(duration: 0.2)) {
            settings.blurMaterialRaw = 8
            settings.backdropOpacity = 0.50
            settings.tintColorHex = "#1E1E1E"
            settings.showTopBorder = true
            settings.hideWindowLabelsTemporarily = false
            settings.displayTargetMode = .all
            settings.selectedOrbColorHex = "#FF453A"
            settings.selectedOrbLogoColorHex = "#FFFFFF"
        }
    }
}

// MARK: - View modifiers used internally

private extension View {
    var pillBackground: some View {
        self.padding(6).background(Color.white.opacity(0.04)).cornerRadius(6)
    }
    var rainbowBackground: some View {
        self.background(
            LinearGradient(colors: [.red,.orange,.yellow,.green,.blue,.purple,.pink,.red],
                           startPoint: .leading, endPoint: .trailing)
                .frame(height: 3).cornerRadius(1.5).opacity(0.4),
            alignment: .center
        )
    }
}
