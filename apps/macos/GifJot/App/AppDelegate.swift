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
        permissionService: permissionService,
        onRestart: { [weak self] in
            self?.permissionService.prepareForRelaunch()
            self?.applicationRelauncher.relaunch()
        },
        onStartRecording: { [weak self] in
            self?.startRecordingFromPermissionWindow()
        }
    )
    private lazy var recordingHUDController = RecordingHUDController(
        coordinator: recordingCoordinator,
        settings: settings
    )
    private lazy var menuBarController = GifJotMenuBarController(
        appDelegate: self
    )
    private lazy var settingsWindowController = SettingsWindowController(
        settings: settings
    )
    let globalShortcutService = GlobalShortcutService()
    private let applicationRelauncher = ApplicationRelauncher()

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
        GIFFileExporter.removeAbandonedWorkingFiles()
        menuBarController.start()
        recordingHUDController.start()
        let shortcutRegistered = globalShortcutService.start { [weak self] in
            self?.performRecordingShortcut()
        }
        if !shortcutRegistered {
            NSLog("GifJot could not register the %@ shortcut.", GlobalShortcutService.displayName)
        }

        if permissionService.refreshStatus() != .authorized
            || permissionService.showReadyOnLaunch
        {
            permissionWindowController.present()
        }
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        permissionService.refreshStatus()
    }

    func applicationWillTerminate(_ notification: Notification) {
        globalShortcutService.stop()
        menuBarController.stop()
        recordingHUDController.stop()
        recordingCoordinator.applicationWillTerminate()
    }

    func showPermissionWindow() {
        DispatchQueue.main.async { [weak self] in
            self?.permissionWindowController.present()
        }
    }

    func showSettingsWindow() {
        DispatchQueue.main.async { [weak self] in
            self?.settingsWindowController.present()
        }
    }

    private func startRecordingFromPermissionWindow() {
        recordingCoordinator.begin(
            configuration: settings.recordingConfiguration()
        )
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
