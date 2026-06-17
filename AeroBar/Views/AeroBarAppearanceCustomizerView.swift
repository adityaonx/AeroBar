import SwiftUI

struct AeroBarAppearanceCustomizerView: View {
    @StateObject private var settings = AeroBarSettings.shared
    @Environment(\.colorScheme) var colorScheme
    
    // 🎯 Control states for the inline expander studio drawers
    @State private var showSpectrumStudio = false
    @State private var showBarSpectrumStudio = false
    
    // Custom macOS Tahoe matching theme swatches for the Taskbar body
    let colorPalette = [
        ("#FFFFFF", "Frosted Ice"),
        ("#1E1E1E", "Obsidian Dark"),
        ("#0A84FF", "Tahoe Sky"),
        ("#30D158", "Vibrant Mint"),
        ("#FF453A", "Satin Crimson"),
        ("#BF5AF2", "Neon Amethyst"),
        ("#FF9F0A", "Industrial Amber")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            
            // =======================================================
            // 🏷️ HEADER & MASTER PANEL CONTROLS
            // =======================================================
            HStack(spacing: 6) {
                Image(systemName: "paintpalette.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.accentColor)
                Text("Taskbar Appearance Lab")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                
                Spacer()
                
                Button(action: resetToSystemDefaults) {
                    HStack(spacing: 3) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 9, weight: .bold))
                        Text("Reset")
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                    }
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.primary.opacity(0.06))
                    .cornerRadius(4)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // =======================================================
            // 🔮 SECTION 1: NATIVE INLINE START ORB STUDIO
            // =======================================================
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Aero Start Orb Profile")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                    Spacer()
                    
                    Button(action: {
                        settings.appendOrbPreset(hex: settings.selectedOrbColorHex)
                    }) {
                        HStack(spacing: 2) {
                            Image(systemName: "plus.circle.fill").font(.system(size: 9))
                            Text("Save Preset").font(.system(size: 9, weight: .semibold))
                        }
                        .foregroundColor(.accentColor)
                    }
                    .buttonStyle(.plain)
                }
                
                HStack(spacing: 8) {
                    Button(action: {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                            showSpectrumStudio.toggle()
                        }
                    }) {
                        Circle()
                            .fill(AngularGradient(
                                colors: [.red, .orange, .yellow, .green, .blue, .purple, .pink, .red],
                                center: .center
                            ))
                            .frame(width: 18, height: 18)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(showSpectrumStudio ? 0.9 : 0.3), lineWidth: showSpectrumStudio ? 1.5 : 1)
                            )
                            .shadow(color: Color.black.opacity(0.2), radius: 1, x: 0, y: 0.5)
                    }
                    .buttonStyle(.plain)
                    .help("Toggle Inline Custom Spectrum Studio")
                    
                    Rectangle()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 1, height: 14)
                        .padding(.horizontal, 2)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(settings.parsedOrbPresets, id: \.self) { hexStr in
                                Circle()
                                    .fill(Color(hexStr))
                                    .frame(width: 18, height: 18)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: settings.selectedOrbColorHex.lowercased() == hexStr.lowercased() ? 1.5 : 0)
                                    )
                                    .onTapGesture {
                                        settings.selectedOrbColorHex = hexStr
                                    }
                                    .contextMenu {
                                        Button("Wipe Custom Preset Matrix Entry", role: .destructive) {
                                            settings.removeOrbPreset(hex: hexStr)
                                        }
                                    }
                            }
                        }
                        .padding(.horizontal, 2)
                        .padding(.vertical, 3)
                    }
                }
                .padding(6)
                .background(Color.white.opacity(0.04))
                .cornerRadius(6)
                
                if showSpectrumStudio {
                    VStack(alignment: .leading, spacing: 10) {
                        // Core Sphere Glow Customizer Pipeline Track
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Studio Precision Hue")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.secondary)
                                Spacer()
                                Circle()
                                    .fill(Color(settings.selectedOrbColorHex))
                                    .frame(width: 8, height: 8)
                                Text(settings.selectedOrbColorHex.uppercased())
                                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                            
                            Slider(
                                value: Binding(
                                    get: { currentHueFromHex(settings.selectedOrbColorHex) },
                                    set: { updateOrbColorFromHue($0) }
                                ),
                                in: 0...360,
                                step: 1
                            )
                            .accentColor(Color(settings.selectedOrbColorHex))
                            .background(
                                LinearGradient(
                                    colors: [.red, .orange, .yellow, .green, .blue, .purple, .pink, .red],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                                .frame(height: 3)
                                .cornerRadius(1.5)
                                .opacity(0.4),
                                alignment: .center
                            )
                        }
                        
                        Divider().opacity(0.15)
                        
                        // 🎯 NEW: Center Vector Icon Logo Customizer Matrix
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Logo Foreground Tint")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.secondary)
                                Spacer()
                                Circle()
                                    .fill(Color(settings.selectedOrbLogoColorHex))
                                    .frame(width: 8, height: 8)
                                Text(settings.selectedOrbLogoColorHex.uppercased())
                                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack(spacing: 6) {
                                // Dynamic Core Baseline Quick Swatches
                                ForEach(["#FFFFFF", "#1E1E1E"], id: \.self) { staticHex in
                                    Circle()
                                        .fill(Color(staticHex))
                                        .frame(width: 14, height: 14)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.accentColor, lineWidth: settings.selectedOrbLogoColorHex.lowercased() == staticHex.lowercased() ? 1.5 : 0)
                                                .padding(-1)
                                        )
                                        .onTapGesture {
                                            settings.selectedOrbLogoColorHex = staticHex
                                        }
                                }
                                
                                // Dynamic Continuous Spectrum Pipeline Slider
                                Slider(
                                    value: Binding(
                                        get: { currentHueFromHex(settings.selectedOrbLogoColorHex) },
                                        set: { updateLogoColorFromHue($0) }
                                    ),
                                    in: 0...360,
                                    step: 1
                                )
                                .accentColor(Color(settings.selectedOrbLogoColorHex))
                                .background(
                                    LinearGradient(
                                        colors: [.red, .orange, .yellow, .green, .blue, .purple, .pink, .red],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                    .frame(height: 3)
                                    .cornerRadius(1.5)
                                    .opacity(0.4),
                                    alignment: .center
                                )
                            }
                        }
                    }
                    .padding(8)
                    .background(Color.black.opacity(0.12))
                    .cornerRadius(6)
                    .transition(.asymmetric(insertion: .opacity.combined(with: .move(edge: .top)), removal: .opacity))
                }
            }
            
            Divider()
            
            // =======================================================
            // 🌊 SECTION 2: TASKBAR MATERIAL BLEND & TINT ENGINE
            // =======================================================
            VStack(alignment: .leading, spacing: 12) {
                // Item 2A: Blur Material Selection Configuration Grid
                VStack(alignment: .leading, spacing: 4) {
                    Text("Wallpaper Glass Blend Style")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                    
                    Picker("", selection: $settings.blurMaterialRaw) {
                        Text("Liquid Wallpaper Look (HUD)").tag(8)
                        Text("Deep Core Content Layer").tag(11)
                        Text("Translucent System Sidebar").tag(4)
                        Text("High Contrast Selection Tint").tag(1)
                        Text("Standard Translucent Overlay").tag(7)
                    }
                    .pickerStyle(PopUpButtonPickerStyle())
                    .labelsHidden()
                }
                
                // Item 2B: Precise Palette Color Swatches Selection Group
                VStack(alignment: .leading, spacing: 6) {
                    Text("Liquid Tint Hue")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 8) {
                        Button(action: {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                                showBarSpectrumStudio.toggle()
                            }
                        }) {
                            Circle()
                                .fill(AngularGradient(
                                    colors: [.red, .orange, .yellow, .green, .blue, .purple, .pink, .red],
                                    center: .center
                                ))
                                .frame(width: 18, height: 18)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(showBarSpectrumStudio ? 0.9 : 0.3), lineWidth: showBarSpectrumStudio ? 1.5 : 1)
                                )
                                .shadow(color: Color.black.opacity(0.2), radius: 1, x: 0, y: 0.5)
                        }
                        .buttonStyle(.plain)
                        .help("Custom Tint Color Selector")
                        
                        Rectangle()
                            .fill(Color.white.opacity(0.15))
                            .frame(width: 1, height: 14)
                            .padding(.horizontal, 2)
                        
                        ForEach(colorPalette, id: \.0) { hexStr, name in
                            let isCurrentSelection = (settings.tintColorHex == hexStr)
                            
                            Circle()
                                .fill(Color(hexStr))
                                .frame(width: 20, height: 20)
                                .overlay(
                                    Circle()
                                        .stroke(Color.accentColor, lineWidth: isCurrentSelection ? 2 : 0)
                                        .padding(-2)
                                )
                                .help(name)
                                .onTapGesture {
                                    settings.tintColorHex = hexStr
                                }
                        }
                    }
                    .padding(6)
                    .background(Color.white.opacity(0.04))
                    .cornerRadius(6)
                    
                    if showBarSpectrumStudio {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Custom Tint Color Selector")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.secondary)
                                Spacer()
                                Circle()
                                    .fill(Color(settings.tintColorHex))
                                    .frame(width: 8, height: 8)
                                Text(settings.tintColorHex.uppercased())
                                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                            
                            Slider(
                                value: Binding(
                                    get: { currentHueFromHex(settings.tintColorHex) },
                                    set: { updateBarColorFromHue($0) }
                                ),
                                in: 0...360,
                                step: 1
                            )
                            .accentColor(Color(settings.tintColorHex))
                            .background(
                                LinearGradient(
                                    colors: [.red, .orange, .yellow, .green, .blue, .purple, .pink, .red],
                                    startPoint: .leading,
                                endPoint: .trailing
                                )
                                .frame(height: 3)
                                .cornerRadius(1.5)
                                .opacity(0.4),
                                alignment: .center
                            )
                        }
                        .padding(8)
                        .background(Color.black.opacity(0.12))
                        .cornerRadius(6)
                        .transition(.asymmetric(insertion: .opacity.combined(with: .move(edge: .top)), removal: .opacity))
                    }
                }
                
                // Item 2C: Saturation Opacity Sliders
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Surface Tint Density").font(.system(size: 10, weight: .bold)).foregroundColor(.secondary)
                        Spacer()
                        Text("\(Int(settings.backdropOpacity * 100))%").font(.system(size: 10, weight: .bold))
                    }
                    Slider(value: $settings.backdropOpacity, in: 0.00...1.00, step: 0.01)
                        .accentColor(.accentColor)
                }
            }
            
            Divider()
            
            // Item 4: Structural Accent Toggle Filters
            Toggle(isOn: $settings.showTopBorder) {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Render Upper Specular Bevel Line").font(.system(size: 11, weight: .medium))
                    Text("Adds a native 0.5pt high-contrast edge highlight").font(.system(size: 9)).foregroundColor(.secondary)
                }
            }
            .toggleStyle(CheckboxToggleStyle())
            
            // Item 5: Taskbar Quick Access Visibility Filter
            Toggle(isOn: $settings.showSearchIcon) {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Show Search Icon")
                        .font(.system(size: 11, weight: .medium))
                    Text("Toggle spotlight quick access in taskbar")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }
            }
            .toggleStyle(CheckboxToggleStyle())
            
            // Item 6: Master Labels Control Switch
            Toggle(isOn: $settings.hideWindowLabelsTemporarily.animation(.easeInOut(duration: 0.2))) {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Collapse Taskbar Labels")
                        .font(.system(size: 11, weight: .medium))
                    Text("Force icon-only mode across all active windows")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }
            }
            .toggleStyle(SwitchToggleStyle(tint: .accentColor))
            .padding(.top, 4)
            
            // ITEM 7: THE ADVANCED DISPLAY TOPOLOGY SELECTOR
            VStack(alignment: .leading, spacing: 4) {
                Text("Show Taskbar On")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.secondary)
                
                Picker("", selection: $settings.displayTargetMode) {
                    ForEach(DisplayTargetMode.allCases) { mode in
                        Text(mode.rawValue).font(.system(size: 11)).tag(mode)
                    }
                }
                .pickerStyle(PopUpButtonPickerStyle())
                .frame(maxWidth: .infinity)
            }
            .padding(.top, 2)
        }
        .padding(14)
        .frame(width: 290)
    }
    
    // MARK: - Dynamic HSB Pipeline Translation Drivers
    private func updateOrbColorFromHue(_ hue: Double) {
        let nsColor = NSColor(hue: CGFloat(hue / 360.0), saturation: 0.90, brightness: 0.95, alpha: 1.0)
        if let rgbColor = nsColor.usingColorSpace(.sRGB) {
            let r = Int(rgbColor.redComponent * 255)
            let g = Int(rgbColor.greenComponent * 255)
            let b = Int(rgbColor.blueComponent * 255)
            settings.selectedOrbColorHex = String(format: "#%02X%02X%02X", r, g, b)
        }
    }
    
    // 🎯 NEW: Translates HSB hue position back to hexadecimal for the vector icon logo
    private func updateLogoColorFromHue(_ hue: Double) {
        let nsColor = NSColor(hue: CGFloat(hue / 360.0), saturation: 0.85, brightness: 0.95, alpha: 1.0)
        if let rgbColor = nsColor.usingColorSpace(.sRGB) {
            let r = Int(rgbColor.redComponent * 255)
            let g = Int(rgbColor.greenComponent * 255)
            let b = Int(rgbColor.blueComponent * 255)
            settings.selectedOrbLogoColorHex = String(format: "#%02X%02X%02X", r, g, b)
        }
    }
    
    private func updateBarColorFromHue(_ hue: Double) {
        let nsColor = NSColor(hue: CGFloat(hue / 360.0), saturation: 0.75, brightness: 0.35, alpha: 1.0)
        if let rgbColor = nsColor.usingColorSpace(.sRGB) {
            let r = Int(rgbColor.redComponent * 255)
            let g = Int(rgbColor.greenComponent * 255)
            let b = Int(rgbColor.blueComponent * 255)
            settings.tintColorHex = String(format: "#%02X%02X%02X", r, g, b)
        }
    }
    
    private func currentHueFromHex(_ targetHex: String) -> Double {
        let hex = targetHex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        guard Scanner(string: hex).scanHexInt64(&int) else { return 0.0 }
        let r, g, b: UInt64
        switch hex.count {
        case 3: (r, g, b) = ((int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default: return 0.0
        }
        let nsColor = NSColor(red: CGFloat(r)/255.0, green: CGFloat(g)/255.0, blue: CGFloat(b)/255.0, alpha: 1.0)
        if let hsbColor = nsColor.usingColorSpace(.deviceRGB) {
            return Double(hsbColor.hueComponent * 360.0)
        }
        return 0.0
    }
    
    private func resetToSystemDefaults() {
        withAnimation(.easeInOut(duration: 0.2)) {
            settings.blurMaterialRaw = 8
            settings.backdropOpacity = 0.50
            settings.tintColorHex = "#1E1E1E"
            settings.showTopBorder = true
            settings.hideWindowLabelsTemporarily = false
            settings.displayTargetMode = .all
            settings.selectedOrbColorHex = "#FF453A"
            settings.selectedOrbLogoColorHex = "#FFFFFF" // 🎯 Clear logo color default reset step
        }
    }
}

// MARK: - Hex Parser Utility Color Extension
extension Color {
    init(_ hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}
