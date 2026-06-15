import SwiftUI

struct AeroBarOnboardingPopoverView: View {
    @ObservedObject var settings = AeroBarSettings.shared
    let onOpenSettings: () -> Void
    let onStartEngine: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("AeroBar Setup")
                    .font(.system(size: 13, weight: .bold))
                Spacer()
                Text("v1.1").font(.system(size: 10)).foregroundColor(.secondary)
            }
            .padding(16)
            
            Divider()
            
            // Fixed-Height Content Area (Prevents "Jumping")
            ZStack {
                if settings.isAccessibilityEnabled {
                    // Success View
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.green)
                        Text("System Trusted")
                            .font(.system(size: 14, weight: .bold))
                        Text("Workspace engine is live.")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                } else {
                    // Setup Required View
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Accessibility Required")
                            .font(.system(size: 14, weight: .bold))
                        Text("AeroBar needs permission to snap window grids.")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Text("1. Click Authorize API Hook.")
                            Text("2. Toggle 'AeroBar' to ON.")
                        }
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 16)
                }
            }
            .frame(height: 140) // Rigid height prevents layout shift
            
            Divider()
            
            // Bottom Action Shelf
            HStack {
                Button(action: { NSApp.terminate(nil) }) {
                    Text("Quit").foregroundColor(.red)
                }
                .buttonStyle(.plain)
                .padding(.leading, 16)
                
                Spacer()
                
                Button(action: onOpenSettings) {
                    Text("Authorize API Hook")
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(5)
                }
                .buttonStyle(.plain)
                .disabled(settings.isAccessibilityEnabled)
                
                Button(action: onStartEngine) {
                    Text("Start")
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(settings.isAccessibilityEnabled ? Color.green : Color.gray.opacity(0.2))
                        .foregroundColor(.white)
                        .cornerRadius(5)
                }
                .buttonStyle(.plain)
                .disabled(!settings.isAccessibilityEnabled)
                .padding(.trailing, 16)
            }
            .padding(.vertical, 12)
        }
        .frame(width: 320, height: 280) // Absolute fixed container
    }
}

private struct OnboardingStepRow: View {
    let number: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // Number indicator with a small fixed circular background
            Text(number)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(width: 16, height: 16) // Correct small size
                .background(Circle().fill(Color.primary.opacity(0.06)))
            
            // Step instruction text
            Text(text)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true) // Ensure text wraps correctly
            
            Spacer()
        }
    }
}
