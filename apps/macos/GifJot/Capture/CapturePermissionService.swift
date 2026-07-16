import AppKit
import Combine
import CoreGraphics
import Foundation

enum CapturePermissionStatus: Equatable, Sendable {
    case notDetermined
    case denied
    case authorized
}

@MainActor
final class CapturePermissionService: ObservableObject {
    typealias AuthorizationCheck = @MainActor () -> Bool
    typealias AuthorizationRequest = @MainActor () -> Bool
    typealias SettingsOpener = @MainActor () -> Void

    private enum Key {
        static let hasRequestedAccess = "capturePermission.hasRequestedAccess"
    }

    @Published private(set) var status: CapturePermissionStatus
    @Published private(set) var restartRecommended = false

    private let defaults: UserDefaults
    private let authorizationCheck: AuthorizationCheck
    private let authorizationRequest: AuthorizationRequest
    private let settingsOpener: SettingsOpener

    init(
        defaults: UserDefaults = .standard,
        authorizationCheck: @escaping AuthorizationCheck = {
            CGPreflightScreenCaptureAccess()
        },
        authorizationRequest: @escaping AuthorizationRequest = {
            CGRequestScreenCaptureAccess()
        },
        settingsOpener: SettingsOpener? = nil
    ) {
        self.defaults = defaults
        self.authorizationCheck = authorizationCheck
        self.authorizationRequest = authorizationRequest
        self.settingsOpener = settingsOpener ?? Self.openScreenRecordingSettings
        let isAuthorized = authorizationCheck()
        let hasRequestedAccess = isAuthorized
            || defaults.bool(forKey: Key.hasRequestedAccess)
        if isAuthorized {
            defaults.set(true, forKey: Key.hasRequestedAccess)
        }
        status = Self.resolveStatus(
            isAuthorized: isAuthorized,
            hasRequestedAccess: hasRequestedAccess
        )
    }

    @discardableResult
    func refreshStatus() -> CapturePermissionStatus {
        let previousStatus = status
        let isAuthorized = authorizationCheck()
        if isAuthorized {
            defaults.set(true, forKey: Key.hasRequestedAccess)
        }
        let refreshedStatus = Self.resolveStatus(
            isAuthorized: isAuthorized,
            hasRequestedAccess: isAuthorized
                || defaults.bool(forKey: Key.hasRequestedAccess)
        )
        if refreshedStatus != .authorized {
            restartRecommended = false
        } else if previousStatus != .authorized {
            restartRecommended = true
        }
        status = refreshedStatus
        return status
    }

    @discardableResult
    func requestAccess() -> CapturePermissionStatus {
        let previousStatus = status
        let requestReportedAccess = authorizationRequest()
        defaults.set(true, forKey: Key.hasRequestedAccess)

        let requestedStatus = Self.resolveStatus(
            isAuthorized: requestReportedAccess || authorizationCheck(),
            hasRequestedAccess: true
        )
        if requestedStatus != .authorized {
            restartRecommended = false
        } else if previousStatus != .authorized {
            restartRecommended = true
        }
        status = requestedStatus
        return status
    }

    func openSystemSettings() {
        settingsOpener()
    }

    private static func resolveStatus(
        isAuthorized: Bool,
        hasRequestedAccess: Bool
    ) -> CapturePermissionStatus {
        if isAuthorized {
            return .authorized
        }
        return hasRequestedAccess ? .denied : .notDetermined
    }

    private static func openScreenRecordingSettings() {
        guard let url = URL(
            string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"
        ) else {
            return
        }
        _ = NSWorkspace.shared.open(url)
    }
}
