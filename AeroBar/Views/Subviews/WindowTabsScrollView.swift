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
                    let isActive = settings.currentSystemFocusedElement != nil
                        && CFEqual(tab.axElement, settings.currentSystemFocusedElement!)

                    // The Button handles normal taps (no popover open).
                    // AppKitTabButtonView.onTap handles taps when the popover IS open
                    // and the Button can't fire (bar is non-key window).
                    Button(action: { onTabInteraction(tab) }) {
                        AppKitTabButtonView(
                            tab: tab,
                            isActive: isActive,
                            onTap: { onTabInteraction(tab) }  // passed for popover-intercept path
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
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
    }
}
