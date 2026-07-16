import Combine
import Foundation
import OSLog

enum CaptureDiagnosticState: Equatable, Sendable {
    case idle
    case capturing
    case completed(CaptureDiagnosticReport)
    case failed(String)

    var isCapturing: Bool {
        self == .capturing
    }
}

@MainActor
final class ScreenCaptureDiagnosticService: ObservableObject {
    @Published private(set) var state: CaptureDiagnosticState = .idle

    private let permissionService: CapturePermissionService
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.gifjot.GifJot",
        category: "CaptureDiagnostic"
    )
    private var activeSession: ScreenCaptureDiagnosticSession?

    init(permissionService: CapturePermissionService) {
        self.permissionService = permissionService
    }

    func runFiveSecondCapture(
        framesPerSecond: Int,
        includeCursor: Bool
    ) async {
        guard !state.isCapturing else { return }

        guard permissionService.refreshStatus() == .authorized else {
            state = .failed("Screen Recording permission is required.")
            return
        }

        let session = ScreenCaptureDiagnosticSession()
        activeSession = session
        state = .capturing

        do {
            let report = try await session.capture(
                framesPerSecond: framesPerSecond,
                includeCursor: includeCursor
            )
            state = .completed(report)
            log(report)
        } catch {
            state = .failed(error.localizedDescription)
            logger.error(
                "capture_diagnostic_failed message=\(error.localizedDescription)"
            )
        }

        activeSession = nil
    }

    private func log(_ report: CaptureDiagnosticReport) {
        logger.info(
            "capture_diagnostic_complete display=\(report.displayID, privacy: .public) configured_width=\(report.configuredWidth, privacy: .public) configured_height=\(report.configuredHeight, privacy: .public) requested_fps=\(report.requestedFramesPerSecond, privacy: .public) received=\(report.receivedFrames, privacy: .public) complete=\(report.completeFrames, privacy: .public) non_complete=\(report.nonCompleteFrames, privacy: .public) estimated_dropped=\(report.estimatedDroppedFrames, privacy: .public) invalid=\(report.invalidFrames, privacy: .public) observed_width=\(report.observedWidth ?? -1, privacy: .public) observed_height=\(report.observedHeight ?? -1, privacy: .public) first_pts=\(report.firstPresentationTimeSeconds ?? -1, privacy: .public) last_pts=\(report.lastPresentationTimeSeconds ?? -1, privacy: .public)"
        )
    }
}
