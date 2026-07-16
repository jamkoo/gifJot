import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let permissionService: CapturePermissionService
    let regionSelectionService: RegionSelectionService
    let recordingCoordinator: RecordingCoordinator
    let settings: SettingsStore
#if DEBUG
    let diagnosticCaptureService: ScreenCaptureDiagnosticService
#endif

    private lazy var permissionWindowController = CapturePermissionWindowController(
        permissionService: permissionService
    )
    private lazy var recordingHUDController = RecordingHUDController(
        coordinator: recordingCoordinator
    )
    private let globalShortcutService = GlobalShortcutService()

    override init() {
        let permissionService = CapturePermissionService()
        let regionSelectionService = RegionSelectionService()
        let settings = SettingsStore()
        self.permissionService = permissionService
        self.regionSelectionService = regionSelectionService
        self.settings = settings
        recordingCoordinator = RecordingCoordinator(
            permissionService: permissionService,
            regionSelectionService: regionSelectionService
        )
#if DEBUG
        diagnosticCaptureService = ScreenCaptureDiagnosticService(
            permissionService: permissionService
        )
#endif
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        TemporaryRecordingStore.removeAbandonedSessions()
        recordingHUDController.start()
        let shortcutRegistered = globalShortcutService.start { [weak self] in
            self?.performRecordingShortcut()
        }
        if !shortcutRegistered {
            NSLog("GifJot could not register the %@ shortcut.", GlobalShortcutService.displayName)
        }

        if permissionService.refreshStatus() != .authorized {
            permissionWindowController.present()
        }
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        permissionService.refreshStatus()
    }

    func applicationWillTerminate(_ notification: Notification) {
        globalShortcutService.stop()
        recordingHUDController.stop()
        recordingCoordinator.applicationWillTerminate()
    }

    func showPermissionWindow() {
        permissionWindowController.present()
    }

    private func performRecordingShortcut() {
        let isStarting = !recordingCoordinator.isBusy
        if isStarting && (
            permissionService.refreshStatus() != .authorized
                || permissionService.restartRecommended
        ) {
            showPermissionWindow()
            return
        }

        recordingCoordinator.performPrimaryAction(
            configuration: settings.recordingConfiguration()
        )
    }
}
