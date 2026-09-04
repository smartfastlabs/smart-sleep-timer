import ServiceManagement
import os

/// Registers the app to open at login using the system login-item API.
enum LoginItem {
    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    static func setEnabled(_ enabled: Bool) throws {
        if enabled {
            try SMAppService.mainApp.register()
        } else {
            try SMAppService.mainApp.unregister()
        }
        Log.system.info("Login item \(enabled ? "enabled" : "disabled", privacy: .public)")
    }
}
