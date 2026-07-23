import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let permissionService: CapturePermissionService
    let regionSelectionService: RegionSelectionService
    let recordingCoordinator: RecordingCoordinator
    let settings: SettingsStore
#if DEBUG
    let diagnosticCaptureService: ScreenCaptureDiagnosticService
    private static let recordingSmokeTestNotification = Notification.Name(
        "com.gifjot.debug.runRecordingSmokeTest"
    )
    private var recordingSmokeTestObserver: NSObjectProtocol?
    private var recordingSmokeTestTask: Task<Void, Never>?
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
            regionSelectionService: regionSelectionService,
            exporterFactory: {
                try GIFFileExporter(
                    destinationDirectory: settings.outputDirectoryURL
                )
            }
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
        let outputDirectoryURL = settings.outputDirectoryURL
        Task.detached(priority: .utility) {
            GIFFileExporter.removeAbandonedWorkingFiles(
                destinationDirectory: outputDirectoryURL
            )
        }
        menuBarController.start()
        recordingHUDController.start()
        let shortcutRegistered = globalShortcutService.start { [weak self] in
            self?.performRecordingShortcut()
        }
        if !shortcutRegistered {
            NSLog("GifJot could not register the %@ shortcut.", GlobalShortcutService.displayName)
        }

#if DEBUG
        recordingSmokeTestObserver = DistributedNotificationCenter.default().addObserver(
            forName: Self.recordingSmokeTestNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.runRecordingSmokeTest()
            }
        }
#endif

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
#if DEBUG
        if let recordingSmokeTestObserver {
            DistributedNotificationCenter.default().removeObserver(
                recordingSmokeTestObserver
            )
            self.recordingSmokeTestObserver = nil
        }
        recordingSmokeTestTask?.cancel()
#endif
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

#if DEBUG
    private func runRecordingSmokeTest() {
        guard recordingSmokeTestTask == nil else {
            NSLog("GIFJOT_SMOKE_TEST_FAIL reason=already_running")
            return
        }
        guard !recordingCoordinator.isBusy else {
            NSLog("GIFJOT_SMOKE_TEST_FAIL reason=recording_workflow_busy")
            return
        }

        recordingSmokeTestTask = Task { [weak self] in
            guard let self else { return }
            await performRecordingSmokeTest()
            recordingSmokeTestTask = nil
        }
    }

    private func performRecordingSmokeTest() async {
        guard permissionService.refreshStatus() == .authorized else {
            NSLog("GIFJOT_SMOKE_TEST_FAIL reason=screen_recording_permission_required")
            return
        }
        guard !permissionService.restartRecommended else {
            NSLog("GIFJOT_SMOKE_TEST_FAIL reason=restart_required")
            return
        }

        let displayID = CGMainDisplayID()
        guard let screen = NSScreen.screens.first(where: { screen in
            let key = NSDeviceDescriptionKey("NSScreenNumber")
            return (screen.deviceDescription[key] as? NSNumber)?.uint32Value
                == displayID
        }) else {
            NSLog("GIFJOT_SMOKE_TEST_FAIL reason=main_display_unavailable")
            return
        }

        let displaySize = screen.frame.size
        let captureSize = CGSize(
            width: min(640, displaySize.width),
            height: min(360, displaySize.height)
        )
        let region = CaptureRegion(
            displayID: displayID,
            sourceRect: CGRect(
                x: max(0, (displaySize.width - captureSize.width) / 2),
                y: max(0, (displaySize.height - captureSize.height) / 2),
                width: captureSize.width,
                height: captureSize.height
            ),
            displayScale: screen.backingScaleFactor
        )
        let session = ScreenCaptureRecordingSession()
        var exporter: GIFFileExporter?
        var exportPlan: GIFExportPlan?

        do {
            let output = try await session.start(
                region: region,
                configuration: ScreenCaptureRecordingConfiguration(
                    framesPerSecond: 10,
                    includeCursor: false,
                    maximumOutputWidth: 640
                )
            )
            try await ContinuousClock().sleep(for: .seconds(2))
            let capture = try await session.stop()

            let createdExporter = try GIFFileExporter(
                destinationDirectory: settings.outputDirectoryURL
            )
            let plan = try createdExporter.prepare()
            exporter = createdExporter
            exportPlan = plan
            try await GIFEncodingWorker().encode(
                frames: capture.frames,
                to: plan.workingURL
            )
            let outputURL = try createdExporter.commit(plan)
            exportPlan = nil
            let copied = MacFileClipboardWriter().writeFile(at: outputURL)
            await session.cleanupTemporaryFrames()
            guard copied else {
                NSLog(
                    "GIFJOT_SMOKE_TEST_FAIL reason=clipboard_write_failed output=%@",
                    outputURL.path
                )
                return
            }

            NSLog(
                "GIFJOT_SMOKE_TEST_PASS output=%@ width=%d height=%d frames=%d dropped=%d duplicates=%d clipboard=%@",
                outputURL.path,
                output.width,
                output.height,
                capture.frames.count,
                capture.droppedFrames,
                capture.duplicateFrames,
                "true"
            )
        } catch {
            if let exporter, let exportPlan {
                exporter.discard(exportPlan)
            }
            await session.cancel()
            NSLog(
                "GIFJOT_SMOKE_TEST_FAIL reason=%@",
                error.localizedDescription
            )
        }
    }
#endif
}
