import SwiftUI
import AppKit

struct OnboardingWizardView: View {
    @ObservedObject var settings = AeroBarSettings.shared
    let onStartEngine: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // HEADER BAR
            HStack {
                Text("AeroBar Setup Wizard")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))
                Spacer()
            }
            .padding(.horizontal, 16)
            .frame(height: 32)
            .background(Color.black.opacity(0.2))
            
            VStack(spacing: 18) {
                // INTRO DESCRIPTION
                VStack(spacing: 6) {
                    Text("Welcome to AeroBar")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("To anchor your taskbar and manage running window boundaries, macOS requires Accessibility API authorization.")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                .padding(.top, 12)
                
                // STATUS BOX INDICATOR
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(settings.isAccessibilityEnabled ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: settings.isAccessibilityEnabled ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(settings.isAccessibilityEnabled ? .green : .red)
                    }
                    
                    VStack(alignment: .leading, spacing: 3) {
                        Text(settings.isAccessibilityEnabled ? "System Authorization Unlocked" : "System Authorization Locked")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                        Text(settings.isAccessibilityEnabled ? "Ready to launch desktop taskbar environment." : "AeroBar requires permission entry in System Settings.")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    Spacer()
                }
                .padding(12)
                .background(Color.black.opacity(0.25))
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.1), lineWidth: 1))
                .padding(.horizontal, 24)
                
                // INSTRUCTIONAL STEPS
                VStack(alignment: .leading, spacing: 8) {
                    Text("How to Enable:")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white.opacity(0.9))
                    
                    InstructionRow(step: "1", text: "Click 'Open Privacy Settings' below.")
                    InstructionRow(step: "2", text: "Locate 'AeroBar' in the Accessibility list tray.")
                    InstructionRow(step: "3", text: "Toggle the switch next to it to ON.")
                }
                .padding(.horizontal, 28)
                
                Spacer()
                
                // ACTION ROW
                HStack(spacing: 12) {
                    Button(action: openAccessibilityPrivacySettings) {
                        HStack {
                            Image(systemName: "gearshape.fill")
                            Text("Open Privacy Settings")
                        }
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .frame(height: 32)
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(6)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: {
                        if settings.isAccessibilityEnabled {
                            onStartEngine()
                        }
                    }) {
                        Text("Start AeroBar")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(settings.isAccessibilityEnabled ? .black : .white.opacity(0.3))
                            .padding(.horizontal, 20)
                            .frame(height: 32)
                            .background(settings.isAccessibilityEnabled ? Color.green : Color.white.opacity(0.05))
                            .cornerRadius(6)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(!settings.isAccessibilityEnabled)
                }
                .padding(.bottom, 20)
            }
        }
        .frame(width: 440, height: 340)
        .background(
            ZStack {
                VisualEffectBlurView(material: .hudWindow, blendingMode: .withinWindow, state: .active)
                Color.black.opacity(0.15)
            }
        )
    }
    
    private func openAccessibilityPrivacySettings() {
        // Direct anchor path straight to System Settings -> Privacy & Security -> Accessibility
        let targetURL = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(targetURL)
    }
}

private struct InstructionRow: View {
    let step: String
    let text: String
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text(step)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.black)
                .frame(width: 16, height: 16)
                .background(Circle().fill(Color.white.opacity(0.7)))
            Text(text)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.7))
            Spacer()
        }
    }
}
