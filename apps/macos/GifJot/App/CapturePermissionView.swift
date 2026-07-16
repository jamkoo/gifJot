import AppKit
import SwiftUI

@MainActor
struct CapturePermissionView: View {
    @ObservedObject var permissionService: CapturePermissionService
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: iconName)
                .font(.system(size: 38, weight: .medium))
                .foregroundStyle(iconColor)
                .symbolRenderingMode(.hierarchical)
                .accessibilityHidden(true)

            VStack(spacing: 7) {
                Text(title)
                    .font(.system(size: 22, weight: .semibold))

                Text(message)
                    .font(.system(size: 13))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(alignment: .top, spacing: 11) {
                Image(systemName: "lock.shield")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 20)

                Text("GifJot records only when you start a capture. Everything stays on this Mac, and Accessibility access is never requested.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)
            }
            .padding(13)
            .gifJotGroupSurface()

            actionButtons
        }
        .padding(28)
        .frame(width: 470)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var actionButtons: some View {
        HStack(spacing: 10) {
            if permissionService.status != .authorized {
                Button("Not Now", action: onDismiss)
                    .buttonStyle(GifJotQuietButtonStyle())
            }

            Spacer()

            switch permissionService.status {
            case .notDetermined:
                Button("Allow Screen Recording") {
                    permissionService.requestAccess()
                }
                .buttonStyle(GifJotPrimaryButtonStyle())
                .keyboardShortcut(.defaultAction)

            case .denied:
                Button("Open System Settings") {
                    permissionService.openSystemSettings()
                }
                .buttonStyle(GifJotPrimaryButtonStyle())
                .keyboardShortcut(.defaultAction)

            case .authorized:
                if permissionService.restartRecommended {
                    Button("Quit and Reopen GifJot") {
                        NSApplication.shared.terminate(nil)
                    }
                    .buttonStyle(GifJotPrimaryButtonStyle())
                    .keyboardShortcut(.defaultAction)
                } else {
                    Button("Start Recording", action: onDismiss)
                        .buttonStyle(GifJotPrimaryButtonStyle())
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
                : "Ready to Record"
        }
    }

    private var message: String {
        switch permissionService.status {
        case .notDetermined:
            "macOS requires permission before GifJot can capture the area you select."
        case .denied:
            "Enable GifJot in System Settings › Privacy & Security › Screen & System Audio Recording."
        case .authorized:
            permissionService.restartRecommended
                ? "Permission is enabled. Reopen GifJot once so macOS can finish applying it."
                : "Screen Recording access is enabled. Your GIFs are ready to stay local."
        }
    }

    private var iconName: String {
        switch permissionService.status {
        case .notDetermined:
            "rectangle.dashed"
        case .denied:
            "exclamationmark.triangle"
        case .authorized:
            permissionService.restartRecommended
                ? "arrow.clockwise"
                : "checkmark.circle"
        }
    }

    private var iconColor: Color {
        if permissionService.restartRecommended {
            return .orange
        }

        switch permissionService.status {
        case .notDetermined:
            return GifJotDesign.signal
        case .denied:
            return .orange
        case .authorized:
            return .green
        }
    }
}
