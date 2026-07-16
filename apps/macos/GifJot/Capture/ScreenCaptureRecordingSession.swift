import CoreMedia
import CoreVideo
import Foundation
import ScreenCaptureKit

enum ScreenCaptureRecordingError: Error, LocalizedError, Sendable {
    case displayUnavailable
    case notRecording
    case streamStopped(String)

    var errorDescription: String? {
        switch self {
        case .displayUnavailable:
            "The selected display is no longer available."
        case .notRecording:
            "There is no active recording to stop."
        case let .streamStopped(message):
            "Screen capture stopped unexpectedly: \(message)"
        }
    }
}

struct ScreenCaptureRecordingConfiguration: Equatable, Sendable {
    let framesPerSecond: Int
    let includeCursor: Bool
    let maximumOutputWidth: Int?
}

final class ScreenCaptureRecordingSession: NSObject, @unchecked Sendable {
    private let sampleQueue = DispatchQueue(
        label: "com.gifjot.screen-capture.frames",
        qos: .userInteractive
    )
    private let pipeline: RecordingFramePipeline
    private let streamState = RecordingStreamState()
    private let unexpectedStopHandler: (@Sendable (Error) -> Void)?

    private var stream: SCStream?
    private var defaultFrameDelay: TimeInterval = 1.0 / 15.0

    init(
        pipeline: RecordingFramePipeline = RecordingFramePipeline(),
        unexpectedStopHandler: (@Sendable (Error) -> Void)? = nil
    ) {
        self.pipeline = pipeline
        self.unexpectedStopHandler = unexpectedStopHandler
    }

    func start(
        region: CaptureRegion,
        configuration: ScreenCaptureRecordingConfiguration
    ) async throws -> OutputDimensions {
        let content = try await SCShareableContent.excludingDesktopWindows(
            false,
            onScreenWindowsOnly: true
        )
        guard let display = content.displays.first(where: {
            $0.displayID == region.displayID
        }) else {
            throw ScreenCaptureRecordingError.displayUnavailable
        }

        let excludedApplications: [SCRunningApplication]
        if let bundleIdentifier = Bundle.main.bundleIdentifier {
            excludedApplications = content.applications.filter {
                $0.bundleIdentifier == bundleIdentifier
            }
        } else {
            excludedApplications = []
        }
        let filter = SCContentFilter(
            display: display,
            excludingApplications: excludedApplications,
            exceptingWindows: []
        )

        let output = OutputDimensionsCalculator.calculate(
            sourceSizeInPoints: region.sourceRect.size,
            displayScale: region.displayScale,
            maximumWidth: configuration.maximumOutputWidth
        )
        let framesPerSecond = max(1, configuration.framesPerSecond)
        defaultFrameDelay = 1.0 / Double(framesPerSecond)

        let streamConfiguration = SCStreamConfiguration()
        streamConfiguration.sourceRect = region.sourceRect
        streamConfiguration.width = output.width
        streamConfiguration.height = output.height
        streamConfiguration.minimumFrameInterval = CMTime(
            value: 1,
            timescale: CMTimeScale(framesPerSecond)
        )
        streamConfiguration.queueDepth = 3
        streamConfiguration.pixelFormat = kCVPixelFormatType_32BGRA
        streamConfiguration.showsCursor = configuration.includeCursor
        streamConfiguration.capturesAudio = false
        streamConfiguration.scalesToFit = true

        try await pipeline.prepare()

        let stream = SCStream(
            filter: filter,
            configuration: streamConfiguration,
            delegate: self
        )
        do {
            try stream.addStreamOutput(
                self,
                type: .screen,
                sampleHandlerQueue: sampleQueue
            )
            self.stream = stream
            try await stream.startCapture()
            return output
        } catch {
            self.stream = nil
            await pipeline.cleanup()
            throw error
        }
    }

    func stop() async throws -> RecordingFramePipelineResult {
        guard let stream else {
            throw ScreenCaptureRecordingError.notRecording
        }

        streamState.markStopping()
        do {
            try await stream.stopCapture()
        } catch {
            self.stream = nil
            await pipeline.cleanup()
            throw error
        }
        self.stream = nil

        if let message = streamState.unexpectedErrorDescription() {
            await pipeline.cleanup()
            throw ScreenCaptureRecordingError.streamStopped(message)
        }

        return try await pipeline.finish(
            defaultFrameDelay: defaultFrameDelay
        )
    }

    func cancel() async {
        if let stream {
            streamState.markStopping()
            try? await stream.stopCapture()
            self.stream = nil
        }
        await pipeline.cleanup()
    }

    func cleanupTemporaryFrames() async {
        await pipeline.cleanup()
    }
}

extension ScreenCaptureRecordingSession: SCStreamOutput {
    func stream(
        _ stream: SCStream,
        didOutputSampleBuffer sampleBuffer: CMSampleBuffer,
        of outputType: SCStreamOutputType
    ) {
        guard outputType == .screen else { return }
        pipeline.submit(sampleBuffer)
    }
}

extension ScreenCaptureRecordingSession: SCStreamDelegate {
    func stream(_ stream: SCStream, didStopWithError error: Error) {
        if streamState.recordUnexpectedStop(error) {
            unexpectedStopHandler?(error)
        }
    }
}

final class RecordingStreamState: @unchecked Sendable {
    private let lock = NSLock()
    private var isStopping = false
    private var unexpectedError: Error?

    func markStopping() {
        lock.lock()
        isStopping = true
        lock.unlock()
    }

    @discardableResult
    func recordUnexpectedStop(_ error: Error) -> Bool {
        lock.lock()
        defer { lock.unlock() }

        if !isStopping, unexpectedError == nil {
            unexpectedError = error
            return true
        }
        return false
    }

    func unexpectedErrorDescription() -> String? {
        lock.lock()
        defer { lock.unlock() }
        return unexpectedError?.localizedDescription
    }
}
