import AppKit
import Foundation

@MainActor
final class ApplicationRelauncher {
    typealias LaunchReplacement = @MainActor (URL) throws -> Void
    typealias TerminateApplication = @MainActor () -> Void
    typealias LaunchFailureHandler = @MainActor (Error) -> Void

    private let bundleURL: URL
    private let launchReplacement: LaunchReplacement
    private let terminateApplication: TerminateApplication
    private let launchFailureHandler: LaunchFailureHandler

    init(
        bundleURL: URL = Bundle.main.bundleURL,
        launchReplacement: LaunchReplacement? = nil,
        terminateApplication: TerminateApplication? = nil,
        launchFailureHandler: LaunchFailureHandler? = nil
    ) {
        self.bundleURL = bundleURL
        self.launchReplacement = launchReplacement
            ?? Self.launchReplacementApplication
        self.terminateApplication = terminateApplication ?? {
            NSApplication.shared.terminate(nil)
        }
        self.launchFailureHandler = launchFailureHandler
            ?? Self.presentLaunchFailure
    }

    func relaunch() {
        do {
            try launchReplacement(bundleURL)
            terminateApplication()
        } catch {
            launchFailureHandler(error)
        }
    }

    private static func launchReplacementApplication(at bundleURL: URL) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = [
            "-c",
            "sleep 0.5; exec /usr/bin/open \"$1\"",
            "gifjot-relaunch",
            bundleURL.path,
        ]
        try process.run()
    }

    private static func presentLaunchFailure(_ error: Error) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "GifJot Could Not Reopen"
        alert.informativeText = "GifJot is still running. "
            + "Reopen it manually after quitting.\n\n"
            + error.localizedDescription
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
