import Combine
import Foundation

enum RecordingWorkflowError: Error, LocalizedError, Sendable {
    case permissionRequired
    case restartRequired

    var errorDescription: String? {
        switch self {
        case .permissionRequired:
            "Screen Recording access is required before recording a GIF."
        case .restartRequired:
            "Quit and reopen GifJot before recording."
        }
    }
}

@MainActor
final class RecordingCoordinator: ObservableObject {
    static let maximumRecordingDurationSeconds = 120

    @Published private(set) var state: RecordingState = .idle
    @Published private(set) var countdownSecondsRemaining: Int?
    @Published private(set) var elapsedSeconds = 0
    @Published private(set) var outputDimensions: OutputDimensions?
    @Published private(set) var droppedFrames = 0
    @Published private(set) var lastOutputURL: URL?
    @Published private(set) var errorMessage: String?
    @Published private(set) var warningMessage: String?

    private let permissionService: CapturePermissionService
    private let regionSelectionService: RegionSelectionService
    private let encodingWorker: GIFEncodingWorker
    private let clipboardWriter: FileClipboardWriting
    private let sessionFactory: (
        @escaping @Sendable (Error) -> Void
    ) -> ScreenCaptureRecordingSession
    private let exporterFactory: () throws -> GIFFileExporter

    private var stateMachine = RecordingStateMachine()
    private var activeSession: ScreenCaptureRecordingSession?
    private var activeConfiguration: RecordingConfiguration?
    private var workflowTask: Task<Void, Never>?
    private var elapsedTask: Task<Void, Never>?
    private var automaticStopTask: Task<Void, Never>?

    init(
        permissionService: CapturePermissionService,
        regionSelectionService: RegionSelectionService,
        encodingWorker: GIFEncodingWorker? = nil,
        clipboardWriter: FileClipboardWriting? = nil,
        sessionFactory: @escaping (
            @escaping @Sendable (Error) -> Void
        ) -> ScreenCaptureRecordingSession = { handler in
            ScreenCaptureRecordingSession(unexpectedStopHandler: handler)
        },
        exporterFactory: @escaping () throws -> GIFFileExporter = {
            try GIFFileExporter()
        }
    ) {
        self.permissionService = permissionService
        self.regionSelectionService = regionSelectionService
        self.encodingWorker = encodingWorker ?? GIFEncodingWorker()
        self.clipboardWriter = clipboardWriter ?? MacFileClipboardWriter()
        self.sessionFactory = sessionFactory
        self.exporterFactory = exporterFactory
    }

    var isBusy: Bool {
        switch state {
        case .idle, .completed, .canceled, .failed:
            false
        default:
            true
        }
    }

    var primaryActionTitle: String {
        switch state {
        case .recording:
            "Stop Recording"
        case .selectingRegion, .countdown:
            "Cancel"
        case .requestingPermission:
            "Checking Permission..."
        case .finishingCapture:
            "Finishing Capture..."
        case .encoding:
            "Encoding GIF..."
        case .exporting:
            "Saving GIF..."
        default:
            "Record GIF"
        }
    }

    var primaryActionEnabled: Bool {
        switch state {
        case .requestingPermission, .finishingCapture, .encoding, .exporting:
            false
        default:
            true
        }
    }

    var statusText: String {
        switch state {
        case .idle:
            "Ready"
        case .requestingPermission:
            "Checking Screen Recording access..."
        case .selectingRegion:
            "Drag over one display - Esc to cancel"
        case .countdown:
            "Recording in \(countdownSecondsRemaining ?? 0)..."
        case .recording:
            recordingStatusText
        case .finishingCapture:
            "Finishing captured frames..."
        case .encoding:
            "Encoding GIF..."
        case .exporting:
            "Saving to Downloads/GifJot..."
        case .completed:
            warningMessage ?? "Saved and copied to the clipboard."
        case .canceled:
            "Recording canceled."
        case .failed:
            errorMessage ?? "Recording failed."
        }
    }

    func begin(configuration: RecordingConfiguration) {
        guard !isBusy, workflowTask == nil else { return }

        if [.completed, .canceled, .failed].contains(state) {
            try? transition(to: .idle)
        }

        resetPresentationState()
        activeConfiguration = configuration
        workflowTask = Task { [weak self] in
            await self?.runStartWorkflow(configuration: configuration)
        }
    }

    func performPrimaryAction(configuration: RecordingConfiguration) {
        switch state {
        case .recording:
            requestStop()
        case .selectingRegion, .countdown:
            cancelPendingRecording()
        case .requestingPermission, .finishingCapture, .encoding, .exporting:
            break
        default:
            begin(configuration: configuration)
        }
    }

    func requestStop() {
        guard state == .recording, let activeSession else { return }

        do {
            try transition(to: .finishingCapture)
        } catch {
            fail(with: error)
            return
        }

        stopRecordingTimers()
        workflowTask = Task { [weak self] in
            await self?.runFinishWorkflow(session: activeSession)
        }
    }

    func cancelPendingRecording() {
        guard state == .selectingRegion || state == .countdown else { return }
        regionSelectionService.cancelSelection()
        workflowTask?.cancel()
    }

    func applicationWillTerminate() {
        stopRecordingTimers()
        regionSelectionService.cancelSelection()
        workflowTask?.cancel()

        if let activeSession {
            Task {
                await activeSession.cancel()
            }
        }
    }

    private func runStartWorkflow(
        configuration: RecordingConfiguration
    ) async {
        do {
            try transition(to: .requestingPermission)
            guard permissionService.refreshStatus() == .authorized else {
                throw RecordingWorkflowError.permissionRequired
            }
            guard !permissionService.restartRecommended else {
                throw RecordingWorkflowError.restartRequired
            }

            try transition(to: .selectingRegion)
            guard let region = await regionSelectionService.selectRegion() else {
                try transition(to: .canceled)
                workflowTask = nil
                return
            }
            try Task.checkCancellation()

            if configuration.countdownSeconds > 0 {
                try transition(to: .countdown)
                for remaining in stride(
                    from: configuration.countdownSeconds,
                    through: 1,
                    by: -1
                ) {
                    countdownSecondsRemaining = remaining
                    try await ContinuousClock().sleep(for: .seconds(1))
                }
                countdownSecondsRemaining = nil
            }

            try Task.checkCancellation()
            let session = sessionFactory { [weak self] error in
                Task { @MainActor [weak self] in
                    self?.handleUnexpectedStop(error)
                }
            }
            activeSession = session
            let output = try await session.start(
                region: region,
                configuration: ScreenCaptureRecordingConfiguration(
                    framesPerSecond: configuration.framesPerSecond,
                    includeCursor: configuration.includeCursor,
                    maximumOutputWidth: configuration.maximumOutputWidth
                )
            )
            try Task.checkCancellation()

            outputDimensions = output
            try transition(to: .recording)
            startRecordingTimers()
        } catch is CancellationError {
            if let activeSession {
                await activeSession.cancel()
                self.activeSession = nil
            }
            cancelStateIfPossible()
        } catch {
            if let activeSession {
                await activeSession.cancel()
                self.activeSession = nil
            }
            fail(with: error)
        }

        workflowTask = nil
    }

    private func runFinishWorkflow(
        session: ScreenCaptureRecordingSession
    ) async {
        var exporter: GIFFileExporter?
        var exportPlan: GIFExportPlan?

        do {
            let capture = try await session.stop()
            droppedFrames = capture.droppedFrames
            try transition(to: .encoding)

            let createdExporter = try exporterFactory()
            let plan = try createdExporter.prepare()
            exporter = createdExporter
            exportPlan = plan

            try await encodingWorker.encode(
                frames: capture.frames,
                to: plan.workingURL
            )
            try transition(to: .exporting)

            let finalURL = try createdExporter.commit(plan)
            exportPlan = nil
            lastOutputURL = finalURL

            if activeConfiguration?.copyAfterRecording == true,
               !clipboardWriter.writeFile(at: finalURL)
            {
                warningMessage = "Saved, but GifJot could not copy the GIF."
            } else if activeConfiguration?.copyAfterRecording == false {
                warningMessage = "Saved to Downloads/GifJot."
            }

            await session.cleanupTemporaryFrames()
            activeSession = nil
            try transition(to: .completed)
        } catch {
            if let exporter, let exportPlan {
                exporter.discard(exportPlan)
            }
            await session.cleanupTemporaryFrames()
            activeSession = nil
            fail(with: error)
        }

        workflowTask = nil
    }

    private func startRecordingTimers() {
        elapsedSeconds = 0

        elapsedTask = Task { [weak self] in
            while !Task.isCancelled {
                do {
                    try await ContinuousClock().sleep(for: .seconds(1))
                } catch {
                    return
                }

                guard let self, self.state == .recording else { return }
                self.elapsedSeconds += 1
            }
        }

        automaticStopTask = Task { [weak self] in
            do {
                try await ContinuousClock().sleep(
                    for: .seconds(Self.maximumRecordingDurationSeconds)
                )
            } catch {
                return
            }
            self?.requestStop()
        }
    }

    private func stopRecordingTimers() {
        elapsedTask?.cancel()
        automaticStopTask?.cancel()
        elapsedTask = nil
        automaticStopTask = nil
    }

    private func handleUnexpectedStop(_ error: Error) {
        guard state == .recording, let activeSession else { return }

        stopRecordingTimers()
        errorMessage = "Screen capture stopped unexpectedly: \(error.localizedDescription)"
        try? transition(to: .failed)
        self.activeSession = nil

        Task {
            await activeSession.cancel()
        }
    }

    private func cancelStateIfPossible() {
        switch state {
        case .requestingPermission, .selectingRegion, .countdown, .recording,
             .finishingCapture, .encoding, .exporting:
            try? transition(to: .canceled)
        default:
            break
        }
    }

    private func fail(with error: Error) {
        stopRecordingTimers()
        countdownSecondsRemaining = nil
        errorMessage = error.localizedDescription

        switch state {
        case .requestingPermission, .selectingRegion, .countdown, .recording,
             .finishingCapture, .encoding, .exporting:
            try? transition(to: .failed)
        default:
            break
        }
    }

    private func transition(to newState: RecordingState) throws {
        try stateMachine.transition(to: newState)
        state = stateMachine.state
    }

    private func resetPresentationState() {
        countdownSecondsRemaining = nil
        elapsedSeconds = 0
        outputDimensions = nil
        droppedFrames = 0
        errorMessage = nil
        warningMessage = nil
        lastOutputURL = nil
    }

    private var recordingStatusText: String {
        let minutes = elapsedSeconds / 60
        let seconds = elapsedSeconds % 60
        let time = String(format: "%02d:%02d", minutes, seconds)

        guard let outputDimensions else {
            return "Recording \(time)"
        }
        return "Recording \(time) - \(outputDimensions.width) x \(outputDimensions.height)"
    }
}
