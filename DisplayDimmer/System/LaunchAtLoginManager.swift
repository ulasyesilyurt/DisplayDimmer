import Foundation
import ServiceManagement
import Combine

@MainActor
final class LaunchAtLoginManager: ObservableObject {

    @Published private(set) var isEnabled = false
    @Published private(set) var errorMessage: String?

    init() {
        refreshStatus()
    }

    func refreshStatus() {
        isEnabled = SMAppService.mainApp.status == .enabled
    }

    func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }

            refreshStatus()
            errorMessage = nil

        } catch {
            refreshStatus()
            errorMessage = error.localizedDescription
        }
    }
}
