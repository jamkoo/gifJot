import AppKit
import SwiftUI

@MainActor
struct CapturePermissionView: View {
    @ObservedObject var permissionService: CapturePermissionService
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: iconName)
                .font(.system(size: 42, weight: .medium))
                .foregroundStyle(iconColor)
                .accessibilityHidden(true)

            VStack(spacing: 8) {
                Text(title)
                    .font(.title2.weight(.semibold))

                Text(message)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            GroupBox {
                Label {
                    Text(
                        "GifJot records only when you start a capture. Recordings stay on this Mac, and GifJot does not request Accessibility access."
                    )
                    .font(.callout)
                    .foregroundStyle(.secondary)
                } icon: {
                    Image(systemName: "lock.shield")
                }
                .padding(4)
            }

            actionButtons
        }
        .padding(28)
        .frame(width: 500)
    }

    @ViewBuilder
    private var actionButtons: some View {
        HStack {
            if permissionService.status != .authorized {
                Button("Not Now", action: onDismiss)
            }

            Spacer()

            switch permissionService.status {
            case .notDetermined:
                Button("Allow Screen Recording") {
                    permissionService.requestAccess()
                }
                .keyboardShortcut(.defaultAction)

            case .denied:
                Button("Open System Settings") {
                    permissionService.openSystemSettings()
                }
                .keyboardShortcut(.defaultAction)

            case .authorized:
                if permissionService.restartRecommended {
                    Button("Quit GifJot") {
                        NSApplication.shared.terminate(nil)
                    }
                    .keyboardShortcut(.defaultAction)
                } else {
                    Button("Done", action: onDismiss)
                        .keyboardShortcut(.defaultAction)
                }
            }
        }
    }

    private var title: String {
        switch permissionService.status {
        case .notDetermined:
            "Allow Screen Recording"
        case .denied:
            "Screen Recording Is Off"
        case .authorized:
            permissionService.restartRecommended
                ? "Restart GifJot to Finish"
                : "Screen Recording Is Ready"
        }
    }

    private var message: String {
        switch permissionService.status {
        case .notDetermined:
            "GifJot needs macOS Screen Recording permission to capture only the region you select."
        case .denied:
            "Enable GifJot in System Settings > Privacy & Security > Screen & System Audio Recording, then return to GifJot."
        case .authorized:
            permissionService.restartRecommended
                ? "Screen Recording permission is enabled. Quit and reopen GifJot before starting the first capture."
                : "Screen Recording permission is enabled. You can close this window."
        }
    }

    private var iconName: String {
        switch permissionService.status {
        case .notDetermined:
            "rectangle.dashed"
        case .denied:
            "exclamationmark.triangle"
        case .authorized:
            "checkmark.circle"
        }
    }

    private var iconColor: Color {
        switch permissionService.status {
        case .notDetermined:
            .accentColor
        case .denied:
            .orange
        case .authorized:
            .green
        }
    }
}
