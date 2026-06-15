import SwiftUI

struct AeroBarAppearanceCustomizerView: View {
    @StateObject private var settings = AeroBarSettings.shared
    @Environment(\.colorScheme) var colorScheme
    
    // Custom macOS Tahoe matching theme swatches
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
            // Panel Header branding rows with inline Reset Action
            HStack(spacing: 6) {
                Image(systemName: "paintpalette.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.accentColor)
                Text("Taskbar Appearance Lab")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                
                Spacer()
                
                // Reset to Default Trigger Configuration
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
            
            Divider()
            
            // Item 1: Blur Material Selection Configuration Grid
            VStack(alignment: .leading, spacing: 4) {
                Text("Wallpaper Glass Blend Style")
                    .font(.system(size: 10, weight: .semibold))
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
            
            // Item 2: Precise Palette Color Swatches Selection Group
            VStack(alignment: .leading, spacing: 6) {
                Text("Liquid Tint Hue")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.secondary)
                
                HStack(spacing: 8) {
                    ForEach(colorPalette, id: \.0) { hexStr, name in
                        // 🎯 THE FIX: Extract the complex evaluation context to a simplified Boolean flag
                        let isCurrentSelection = (settings.tintColorHex == hexStr)
                        
                        Circle()
                            .fill(Color(hex: hexStr))
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
                .padding(.vertical, 2)
            }
            
            // Item 3: Saturation Opacity Sliders
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Surface Tint Density").font(.system(size: 10, weight: .semibold)).foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int(settings.backdropOpacity * 100))%").font(.system(size: 10, weight: .bold))
                }
                // Upper bounds limit pushed to 1.00 so it can slide smoothly to 50% and higher
                Slider(value: $settings.backdropOpacity, in: 0.00...1.00, step: 0.01)
                    .accentColor(.accentColor)
            }
            
            Divider()
            
            // Item 4: Structural Accent Toggle Filters
            Toggle(isOn: $settings.showTopBorder) {
                VStack(alignment: .leading, spacing: 1) { // 🎯 FIXED: Reverted back to the true .leading property descriptor
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
            
            // =======================================================
            // 🎯 ITEM 7: THE ADVANCED DISPLAY TOPOLOGY SELECTOR
            // =======================================================
            VStack(alignment: .leading, spacing: 4) {
                Text("Show Taskbar On")
                    .font(.system(size: 11, weight: .medium))
                
                Picker("", selection: $settings.displayTargetMode) {
                    ForEach(DisplayTargetMode.allCases) { mode in
                        Text(mode.rawValue)
                            .font(.system(size: 11))
                            .tag(mode)
                    }
                }
                .pickerStyle(PopUpButtonPickerStyle())
                .frame(maxWidth: .infinity)
                
                Text("Configure across which desktop monitor workspaces the rails should be instantiated.")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
            .padding(.top, 6)
        }
        .padding(14)
        .frame(width: 290) // Widened frame to handle switch strings cleanly without line splitting
    }
    
    // MARK: - Core Reset Method Routine
    private func resetToSystemDefaults() {
        withAnimation(.easeInOut(duration: 0.2)) {
            settings.blurMaterialRaw = 8       // Reset to HUD
            settings.backdropOpacity = 0.50    // Reset to 50%
            settings.tintColorHex = "#1E1E1E"  // Reset to Deep Black Obsidian
            settings.showTopBorder = true      // Reset top line active
            settings.hideWindowLabelsTemporarily = false // Reset window text to visible
            settings.displayTargetMode = .all  // Reset workspace target layout rule to show everywhere
        }
    }
}

// MARK: - Hex Parser Utility Color Extension
extension Color {
    init(hex: String) {
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
