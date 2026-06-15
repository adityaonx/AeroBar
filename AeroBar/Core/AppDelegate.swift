import AppKit
import Collaboration

final class AppDelegate: NSObject, NSApplicationDelegate {
    var windowController: AeroBarWindowController?
    
    @MainActor func applicationDidFinishLaunching(_ notification: Notification) {
        // 🎯 THE DOCK FIX: Programmatically enforce background activation status
        // This hides the icon from your system Dock instantly on startup
        NSApp.setActivationPolicy(.accessory)
        
        // ⚙️ LINKED CONFIGURATOR PASS:
        // Invokes your custom layout parameters (Bottom position, small tiles, magnification)
        // and safely cycles the Dock server process tree using the native AppKit API.
        SystemDockConfigurator.enforceAeroDockDefaults()
        
        // 🎯 FIXED ROUTING CONTEXT: Hand control back over to your custom controller!
        // This lets AeroBarWindowController drive its custom launch lifecycle evaluation,
        // firing up your welcome onboarding popup view seamlessly before painting the panel.
        windowController = AeroBarWindowController()
        DispatchQueue.global(qos: .utility).async {
                print("[AeroBar Core] Prefetching system user record identity asset context...")
                
                if let targetIdentity = CBIdentity(name: NSUserName(), authority: CBIdentityAuthority.local()),
                   let accountNSImage = targetIdentity.image {
                    
                    var proposalRect = CGRect(x: 0, y: 0, width: accountNSImage.size.width, height: accountNSImage.size.height)
                    if let cgImageHandle = accountNSImage.cgImage(forProposedRect: &proposalRect, context: nil, hints: nil) {
                        
                        DispatchQueue.main.async {
                            // Cache the asset securely in our permanent state store
                            AeroBarSettings.shared.cachedUserAvatar = cgImageHandle
                            print("[AeroBar Core] User identity picture cached cleanly in system memory.")
                        }
                    }
                }
            }
    }
}
