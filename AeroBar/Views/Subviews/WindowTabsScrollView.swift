import SwiftUI
import AppKit

struct WindowTabsScrollView: View {
    @ObservedObject var settings = AeroBarSettings.shared
    let onTabInteraction: (WindowTab) -> Void
    
    let onPinToStartMenu: (WindowTab) -> Void
    let onPinToAeroBar: (WindowTab) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(settings.activeTabs, id: \.windowID) { tab in
                    Button(action: { onTabInteraction(tab) }) {
                        AppKitTabButtonView(
                            tab: tab,
                            isActive: settings.currentSystemFocusedElement != nil && CFEqual(tab.axElement, settings.currentSystemFocusedElement!)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .contextMenu {
                        // 🎯 BUG 3 FIX: Removed the buggy emojis, using native SF Symbols
                        Button {
                            onPinToStartMenu(tab)
                        } label: {
                            Label("Pin to Start", systemImage: "square.grid.3x3.square")
                        }
                        
                        Button {
                            onPinToAeroBar(tab)
                        } label: {
                            Label("Pin to Taskbar", systemImage: "dock.arrow.up.bars")
                        }
                        
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
                        
                        Divider()
                        
                        Button(role: .destructive) {
                            _ = AXUIElementCreateApplication(tab.processID)
                            var closeButtonRef: CFTypeRef?
                            
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
        // 🎯 BUG 2 FIX: Background layer intercepts modifier keystrokes (CapsLock) natively
        .background(ModifierKeyFilterView())
    }
}

// AppKit bridge layer to swallow CapsLock hardware flag changes natively
struct ModifierKeyFilterView: NSViewRepresentable {
    func makeNSView(context: Context) -> FilterView { return FilterView() }
    func updateNSView(_ nsView: FilterView, context: Context) {}
    
    class FilterView: NSView {
        override var acceptsFirstResponder: Bool { true }
        override func flagsChanged(with event: NSEvent) {
            // Silently swallow modifier flag events so they do not propagate
        }
    }
}
