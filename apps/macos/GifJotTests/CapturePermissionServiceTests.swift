import Foundation
import XCTest
@testable import GifJot

@MainActor
final class CapturePermissionServiceTests: XCTestCase {
    func testAuthorizedWhenPreflightSucceeds() {
        withIsolatedDefaults { defaults in
            let service = CapturePermissionService(
                defaults: defaults,
                authorizationCheck: { true },
                authorizationRequest: { false }
            )

            XCTAssertEqual(service.status, .authorized)
        }
    }

    func testNotDeterminedBeforeFirstRequest() {
        withIsolatedDefaults { defaults in
            let service = CapturePermissionService(
                defaults: defaults,
                authorizationCheck: { false },
                authorizationRequest: { false }
            )

            XCTAssertEqual(service.status, .notDetermined)
        }
    }

    func testDeniedAfterUnsuccessfulRequest() {
        withIsolatedDefaults { defaults in
            let service = CapturePermissionService(
                defaults: defaults,
                authorizationCheck: { false },
                authorizationRequest: { false }
            )

            XCTAssertEqual(service.requestAccess(), .denied)

            let restoredService = CapturePermissionService(
                defaults: defaults,
                authorizationCheck: { false },
                authorizationRequest: { false }
            )
            XCTAssertEqual(restoredService.status, .denied)
        }
    }

    func testSuccessfulRequestBecomesAuthorized() {
        withIsolatedDefaults { defaults in
            let service = CapturePermissionService(
                defaults: defaults,
                authorizationCheck: { false },
                authorizationRequest: { true }
            )

            XCTAssertEqual(service.requestAccess(), .authorized)
        }
    }

    func testRefreshDetectsPermissionRevocation() {
        withIsolatedDefaults { defaults in
            var isAuthorized = true
            let service = CapturePermissionService(
                defaults: defaults,
                authorizationCheck: { isAuthorized },
                authorizationRequest: { false }
            )
            XCTAssertEqual(service.status, .authorized)

            isAuthorized = false

            XCTAssertEqual(service.refreshStatus(), .denied)
        }
    }

    func testOpenSettingsUsesInjectedOpener() {
        withIsolatedDefaults { defaults in
            var didOpenSettings = false
            let service = CapturePermissionService(
                defaults: defaults,
                authorizationCheck: { false },
                authorizationRequest: { false },
                settingsOpener: { didOpenSettings = true }
            )

            service.openSystemSettings()

            XCTAssertTrue(didOpenSettings)
        }
    }

    private func withIsolatedDefaults(_ body: (UserDefaults) -> Void) {
        let suiteName = "GifJotTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        body(defaults)
    }
}
