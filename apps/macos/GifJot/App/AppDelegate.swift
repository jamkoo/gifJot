import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let permissionService: CapturePermissionService
#if DEBUG
    let diagnosticCaptureService: ScreenCaptureDiagnosticService
#endif

    private lazy var permissionWindowController = CapturePermissionWindowController(
        permissionService: permissionService
    )

    override init() {
        let permissionService = CapturePermissionService()
        self.permissionService = permissionService
#if DEBUG
        diagnosticCaptureService = ScreenCaptureDiagnosticService(
            permissionService: permissionService
        )
#endif
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
