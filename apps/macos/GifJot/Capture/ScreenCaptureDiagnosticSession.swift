import CoreGraphics
import CoreMedia
import CoreVideo
import Foundation
import ScreenCaptureKit

enum ScreenCaptureDiagnosticError: Error, LocalizedError, Sendable {
    case noDisplayAvailable
    case noCompleteFrames
    case streamStopped(String)

    var errorDescription: String? {
        switch self {
        case .noDisplayAvailable:
            "No capturable display is available."
        case .noCompleteFrames:
            "The stream completed without delivering a complete video frame."
        case let .streamStopped(message):
            "The capture stream stopped unexpectedly: \(message)"
        }
    }
}

final class ScreenCaptureDiagnosticSession: NSObject, @unchecked Sendable {
    private let sampleQueue = DispatchQueue(
        label: "com.gifjot.capture-diagnostic.frames",
        qos: .userInitiated
    )
    private let streamState = DiagnosticStreamState()

    private var accumulator = CaptureDiagnosticAccumulator()
    private var stream: SCStream?

    func capture(
        duration: Duration = .seconds(5),
        framesPerSecond: Int,
        includeCursor: Bool
    ) async throws -> CaptureDiagnosticReport {
        let content = try await SCShareableContent.excludingDesktopWindows(
            false,
            onScreenWindowsOnly: true
        )

        let mainDisplayID = CGMainDisplayID()
        guard let display = content.displays.first(where: {
            $0.displayID == mainDisplayID
        }) ?? content.displays.first else {
            throw ScreenCaptureDiagnosticError.noDisplayAvailable
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

        let configuredWidth = max(
            Int(CGDisplayPixelsWide(display.displayID)),
            display.width
        )
        let configuredHeight = max(
            Int(CGDisplayPixelsHigh(display.displayID)),
            display.height
        )

        let configuration = SCStreamConfiguration()
        configuration.width = configuredWidth
        configuration.height = configuredHeight
        configuration.minimumFrameInterval = CMTime(
            value: 1,
            timescale: CMTimeScale(max(1, framesPerSecond))
        )
        configuration.queueDepth = 3
        configuration.pixelFormat = kCVPixelFormatType_32BGRA
        configuration.showsCursor = includeCursor
        configuration.capturesAudio = false
        configuration.scalesToFit = false

        let stream = SCStream(
            filter: filter,
            configuration: configuration,
            delegate: self
        )
        try stream.addStreamOutput(
            self,
            type: .screen,
            sampleHandlerQueue: sampleQueue
        )
        self.stream = stream

        var didStart = false
        do {
            try await stream.startCapture()
            didStart = true

            try await ContinuousClock().sleep(for: duration)

            streamState.markStopping()
            try await stream.stopCapture()
            didStart = false
        } catch {
            if didStart {
                streamState.markStopping()
                try? await stream.stopCapture()
            }
            self.stream = nil

            if let message = streamState.unexpectedErrorDescription() {
                throw ScreenCaptureDiagnosticError.streamStopped(message)
            }
            throw error
        }

        self.stream = nil

        if let message = streamState.unexpectedErrorDescription() {
            throw ScreenCaptureDiagnosticError.streamStopped(message)
        }

        let report = sampleQueue.sync {
            accumulator.makeReport(
                displayID: display.displayID,
                configuredWidth: configuredWidth,
                configuredHeight: configuredHeight,
                requestedFramesPerSecond: framesPerSecond
            )
        }

        guard report.completeFrames > 0 else {
            throw ScreenCaptureDiagnosticError.noCompleteFrames
        }
        return report
    }
}

extension ScreenCaptureDiagnosticSession: SCStreamOutput {
    func stream(
        _ stream: SCStream,
        didOutputSampleBuffer sampleBuffer: CMSampleBuffer,
        of outputType: SCStreamOutputType
    ) {
        guard outputType == .screen else { return }
        accumulator.record(Self.observation(for: sampleBuffer))
    }

    private static func observation(
        for sampleBuffer: CMSampleBuffer
    ) -> CaptureFrameObservation {
        guard
            CMSampleBufferIsValid(sampleBuffer),
            CMSampleBufferDataIsReady(sampleBuffer)
        else {
            return .invalid
        }

        guard
            let attachmentArrays = CMSampleBufferGetSampleAttachmentsArray(
                sampleBuffer,
                createIfNecessary: false
            ) as? [[SCStreamFrameInfo: Any]],
            let attachments = attachmentArrays.first,
            let statusRawValue = attachments[SCStreamFrameInfo.status] as? Int,
            let status = SCFrameStatus(rawValue: statusRawValue)
        else {
            return .invalid
        }

        guard status == .complete else {
            return .nonComplete
        }

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return .invalid
        }

        let presentationTime = CMTimeGetSeconds(
            CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        )
        let finitePresentationTime = presentationTime.isFinite
            ? presentationTime
            : nil

        return .complete(
            width: CVPixelBufferGetWidth(pixelBuffer),
            height: CVPixelBufferGetHeight(pixelBuffer),
            presentationTimeSeconds: finitePresentationTime
        )
    }
}

extension ScreenCaptureDiagnosticSession: SCStreamDelegate {
    func stream(_ stream: SCStream, didStopWithError error: Error) {
        streamState.recordUnexpectedStop(error)
    }
}

private final class DiagnosticStreamState: @unchecked Sendable {
    private let lock = NSLock()
    private var isStopping = false
    private var unexpectedError: Error?

    func markStopping() {
        lock.lock()
        isStopping = true
        lock.unlock()
    }

    func recordUnexpectedStop(_ error: Error) {
        lock.lock()
        if !isStopping, unexpectedError == nil {
            unexpectedError = error
        }
        lock.unlock()
    }

    func unexpectedErrorDescription() -> String? {
        lock.lock()
        defer { lock.unlock() }
        return unexpectedError?.localizedDescription
    }
}
