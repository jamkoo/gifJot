import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let permissionService: CapturePermissionService

    private lazy var permissionWindowController = CapturePermissionWindowController(
        permissionService: permissionService
    )

    override init() {
        permissionService = CapturePermissionService()
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        if permissionService.refreshStatus() != .authorized {
            permissionWindowController.present()
        }
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        permissionService.refreshStatus()
    }

    func showPermissionWindow() {
        permissionWindowController.present()
    }
}
