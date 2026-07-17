import Foundation
import XCTest
@testable import GifJot

@MainActor
final class ApplicationRelauncherTests: XCTestCase {
    func testRelaunchSchedulesReplacementBeforeTerminatingCurrentApp() {
        let bundleURL = URL(fileURLWithPath: "/Applications/GifJot.app")
        var receivedBundleURL: URL?
        var events: [String] = []

        let relauncher = ApplicationRelauncher(
            bundleURL: bundleURL,
            launchReplacement: { receivedURL in
                receivedBundleURL = receivedURL
                events.append("launch")
            },
            terminateApplication: {
                events.append("terminate")
            },
            launchFailureHandler: { error in
                XCTFail("Unexpected relaunch failure: \(error)")
            }
        )

        relauncher.relaunch()

        XCTAssertEqual(receivedBundleURL, bundleURL)
        XCTAssertEqual(events, ["launch", "terminate"])
    }

    func testLaunchFailureKeepsCurrentAppRunning() {
        struct RelaunchFailure: Error {}

        var didTerminate = false
        var didHandleFailure = false
        let relauncher = ApplicationRelauncher(
            launchReplacement: { _ in
                throw RelaunchFailure()
            },
            terminateApplication: {
                didTerminate = true
            },
            launchFailureHandler: { error in
                XCTAssertTrue(error is RelaunchFailure)
                didHandleFailure = true
            }
        )

        relauncher.relaunch()

        XCTAssertFalse(didTerminate)
        XCTAssertTrue(didHandleFailure)
    }
}
