import CoreGraphics
import Foundation

struct CaptureDiagnosticReport: Equatable, Sendable {
    let displayID: CGDirectDisplayID
    let configuredWidth: Int
    let configuredHeight: Int
    let requestedFramesPerSecond: Int
    let receivedFrames: Int
    let completeFrames: Int
    let nonCompleteFrames: Int
    let invalidFrames: Int
    let observedWidth: Int?
    let observedHeight: Int?
    let firstPresentationTimeSeconds: Double?
    let lastPresentationTimeSeconds: Double?

    var timestampSpanSeconds: Double? {
        guard
            let firstPresentationTimeSeconds,
            let lastPresentationTimeSeconds
        else {
            return nil
        }
        return max(0, lastPresentationTimeSeconds - firstPresentationTimeSeconds)
    }

    var estimatedDroppedFrames: Int {
        guard let timestampSpanSeconds else {
            return nonCompleteFrames
        }
        let expectedFrames = Int(
            (timestampSpanSeconds * Double(requestedFramesPerSecond)).rounded()
        ) + 1
        return max(
            nonCompleteFrames,
            max(expectedFrames - completeFrames, 0)
        )
    }
}

enum CaptureFrameObservation: Equatable, Sendable {
    case complete(
        width: Int,
        height: Int,
        presentationTimeSeconds: Double?
    )
    case nonComplete
    case invalid
}

struct CaptureDiagnosticAccumulator: Sendable {
    private(set) var receivedFrames = 0
    private(set) var completeFrames = 0
    private(set) var nonCompleteFrames = 0
    private(set) var invalidFrames = 0
    private(set) var observedWidth: Int?
    private(set) var observedHeight: Int?
    private(set) var firstPresentationTimeSeconds: Double?
    private(set) var lastPresentationTimeSeconds: Double?

    mutating func record(_ observation: CaptureFrameObservation) {
        receivedFrames += 1

        switch observation {
        case let .complete(width, height, presentationTimeSeconds):
            completeFrames += 1
            observedWidth = width
            observedHeight = height

            if let presentationTimeSeconds {
                if firstPresentationTimeSeconds == nil {
                    firstPresentationTimeSeconds = presentationTimeSeconds
                }
                lastPresentationTimeSeconds = presentationTimeSeconds
            }

        case .nonComplete:
            nonCompleteFrames += 1

        case .invalid:
            invalidFrames += 1
        }
    }

    func makeReport(
        displayID: CGDirectDisplayID,
        configuredWidth: Int,
        configuredHeight: Int,
        requestedFramesPerSecond: Int
    ) -> CaptureDiagnosticReport {
        CaptureDiagnosticReport(
            displayID: displayID,
            configuredWidth: configuredWidth,
            configuredHeight: configuredHeight,
            requestedFramesPerSecond: requestedFramesPerSecond,
            receivedFrames: receivedFrames,
            completeFrames: completeFrames,
            nonCompleteFrames: nonCompleteFrames,
            invalidFrames: invalidFrames,
            observedWidth: observedWidth,
            observedHeight: observedHeight,
            firstPresentationTimeSeconds: firstPresentationTimeSeconds,
            lastPresentationTimeSeconds: lastPresentationTimeSeconds
        )
    }
}
