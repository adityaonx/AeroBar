// LoginItemService.swift — Registers or removes AeroBar as a login item.
// Owner: Core/Services
// Depends on: ServiceManagement
// Tested by: Tests/LoginItemServiceTests.swift (mock SMAppService)

import Foundation
import ServiceManagement

final class LoginItemService {
    static let shared = LoginItemService()
    private init() {}

    func setEnabled(_ enabled: Bool) {
        if #available(macOS 13.0, *) {
            let service = SMAppService.mainApp
            do {
                if enabled {
                    if service.status != .enabled { try service.register() }
                } else {
                    if service.status == .enabled { try service.unregister() }
                }
            } catch {
                print("AeroBar LoginItemService: \(error.localizedDescription)")
            }
        } else {
            let helperID = "com.aerobar.LauncherHelper" as CFString
            SMLoginItemSetEnabled(helperID, enabled)
            UserDefaults.standard.set(enabled, forKey: "com.aerobar.launchAtLoginFallback")
        }
    }
}
