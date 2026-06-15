import SwiftUI
import AppKit

struct WindowTabsScrollView: View {
    @ObservedObject var settings = AeroBarSettings.shared
    let onTabInteraction: (WindowTab) -> Void
    
    // Dual-closure system for multi-target pinning destinations
    let onPinToStartMenu: (WindowTab) -> Void
    let onPinToAeroBar: (WindowTab) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                                ForEach(settings.activeTabs, id: \.windowID) { tab in
                                    // 🎯 THE FIX: Drop the standalone 'let' variable assignment here!
                                    // Pass the boolean verification logic straight into your Button view.
                                    Button(action: { onTabInteraction(tab) }) {
                                        AppKitTabButtonView(
                                            tab: tab,
                                            isActive: settings.currentSystemFocusedElement != nil && CFEqual(tab.axElement, settings.currentSystemFocusedElement!)
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    // Context Menu for Active Running Window Tiles
                                    .contextMenu {
                        Button {
                            onPinToStartMenu(tab)
                        } label: {
                            Label("📌 Pin to Start", systemImage: "square.grid.3x3.square")
                        }
                        
                        Button {
                            onPinToAeroBar(tab)
                        } label: {
                            Label("📌 Pin to Taskbar", systemImage: "dock.arrow.up.bars")
                        }
                        
                        // =======================================================
                        // 👁️ TARGETED WINDOW VISIBILITY CONTROL (PINPOINT ONLY):
                        // =======================================================
                        let isThisWindowLabelHidden = settings.manuallyHiddenWindowIDs.contains(tab.windowID)
                        
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                if isThisWindowLabelHidden {
                                    settings.manuallyHiddenWindowIDs.remove(tab.windowID)
                                } else {
                                    settings.manuallyHiddenWindowIDs.insert(tab.windowID)
                                }
                            }
                        } label: {
                            Label(
                                isThisWindowLabelHidden ? "Show Window Label" : "Hide Window Label",
                                systemImage: isThisWindowLabelHidden ? "text.bubble" : "text.bubble.fill"
                            )
                        }
                        
                        // =======================================================
                        // 📥 INDIVIDUAL WINDOW CLOSE OPTION SHIFTED TO BOTTOM:
                        // =======================================================
                        Divider()
                        
                        // 🛑 CLOSE WINDOW ACTION: Calls underlying AX Framework vectors to click window close buttons
                        Button(role: .destructive) {
                            _ = AXUIElementCreateApplication(tab.processID)
                            var closeButtonRef: CFTypeRef?
                            
                            // Query the specific layout handle for this targeted sub-window frame sheet
                            AXUIElementCopyAttributeValue(tab.axElement, kAXCloseButtonAttribute as CFString, &closeButtonRef)
                            
                            if let closeButton = closeButtonRef {
                                AXUIElementPerformAction(closeButton as! AXUIElement, kAXPressAction as CFString)
                            }
                        } label: {
                            Label("Close Window", systemImage: "xmark.square")
                        }
                    }
                }
            }
            .padding(.horizontal, 4)
            .frame(height: 56)
        }
    }
}
