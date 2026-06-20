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

                    // Button now fires reliably on every click — AppKitTabButtonView's
                    // preview is hosted in a non-activating panel (AeroPreviewPanel)
                    // that never takes key/activation status, so there is no longer a
                    // key-window handoff for a click to race against. onTap is passed
                    // through so AppKitTabButtonView can close its own preview state
                    // (cancel pending tasks, remove its outside-click monitor) in the
                    // same action as the interaction itself.
                    Button(action: { onTabInteraction(tab) }) {
                        AppKitTabButtonView(
                            tab: tab,
                            isActive: isActive,
                            onTap: { onTabInteraction(tab) }
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
