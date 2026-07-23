import AppKit
import SwiftUI

@MainActor
struct CapturePermissionView: View {
    @ObservedObject var permissionService: CapturePermissionService
    let onDismiss: () -> Void
    let onRestart: () -> Void
    let onStartRecording: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            Divider()
                .overlay(GifJotDesign.opticalHairline)
                .padding(.top, 18)

            statusMessage
                .padding(.top, 24)

            privacyNote
                .padding(.top, 22)

            actionButtons
                .padding(.top, 20)
        }
        .padding(24)
        .frame(width: 500)
        .background(GifJotDesign.opticalBody)
        .tint(GifJotDesign.canvasIndigo)
    }

    private var header: some View {
        HStack(spacing: 10) {
            CaptureFrameMark(
                color: GifJotDesign.canvasIndigo,
                isActive: permissionService.status == .authorized
                    && !permissionService.restartRecommended,
                lineWidth: 1.75
            )
            .frame(width: 24, height: 24)
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 1) {
                Text("GifJot")
                    .font(.system(size: 14, weight: .semibold))

                Text("Screen Recording")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Label("Local only", systemImage: "lock.fill")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
        }
    }

    private var statusMessage: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                RoundedRectangle(
                    cornerRadius: 12,
                    style: .continuous
                )
                .fill(statusTint)

                Image(systemName: iconName)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(iconColor)
                    .symbolRenderingMode(.hierarchical)
            }
            .frame(width: 52, height: 52)
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 7) {
                Text(title)
                    .font(.system(size: 22, weight: .bold))
                    .tracking(-0.4)

                Text(message)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: 360, alignment: .leading)
            }

            Spacer(minLength: 0)
        }
    }

    private var privacyNote: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "hand.raised.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(GifJotDesign.canvasIndigo)
                .frame(width: 18)

            Text(
                "GifJot captures only after you press Record. "
                    + "GIFs stay on this Mac—no account, upload, audio, "
                    + "or Accessibility permission."
            )
            .font(.system(size: 12))
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(13)
        .background(GifJotDesign.indigoTint.opacity(0.62))
        .clipShape(
            RoundedRectangle(
                cornerRadius: GifJotDesign.surfaceRadius,
                style: .continuous
            )
        )
    }

    private var actionButtons: some View {
        HStack(spacing: 10) {
            Button("Not Now", action: onDismiss)
                .buttonStyle(GifJotQuietButtonStyle())

            Spacer()

            switch permissionService.status {
            case .notDetermined:
                Button("Allow Screen Recording") {
                    permissionService.requestAccess()
                }
                .buttonStyle(GifJotPrimaryButtonStyle())
                .keyboardShortcut(.defaultAction)

            case .denied:
                Button("Check Again") {
                    permissionService.refreshStatus()
                }
                .buttonStyle(GifJotQuietButtonStyle())

                Button("Open System Settings") {
                    permissionService.openSystemSettings()
                }
                .buttonStyle(GifJotPrimaryButtonStyle())
                .keyboardShortcut(.defaultAction)

            case .authorized:
                if permissionService.restartRecommended {
                    Button("Quit and Reopen GifJot", action: onRestart)
                        .buttonStyle(GifJotPrimaryButtonStyle())
                        .keyboardShortcut(.defaultAction)
                } else {
                    Button("Record an Area", action: onStartRecording)
                        .buttonStyle(GifJotPrimaryButtonStyle())
                        .keyboardShortcut(.defaultAction)
                }
            }
        }
    }

    private var title: String {
        switch permissionService.status {
        case .notDetermined:
            "Allow screen recording"
        case .denied:
            "Screen recording is off"
        case .authorized:
            permissionService.restartRecommended
                ? "One quick restart"
                : "You’re ready"
        }
    }

    private var message: String {
        switch permissionService.status {
        case .notDetermined:
            "macOS needs your permission before GifJot can capture an area of your screen."
        case .denied:
            "Turn on GifJot in Privacy & Security → Screen & System Audio Recording, then return here."
        case .authorized:
            permissionService.restartRecommended
                ? "Permission is on. Reopen GifJot once so macOS can apply it to this app."
                : "Choose an area, adjust the frame directly, and press Record."
        }
    }

    private var iconName: String {
        switch permissionService.status {
        case .notDetermined:
            "rectangle.inset.filled"
        case .denied:
            "exclamationmark.triangle.fill"
        case .authorized:
            permissionService.restartRecommended
                ? "arrow.clockwise"
                : "checkmark"
        }
    }

    private var iconColor: Color {
        if permissionService.restartRecommended {
            return GifJotDesign.warning
        }

        switch permissionService.status {
        case .notDetermined:
            return GifJotDesign.canvasIndigo
        case .denied:
            return GifJotDesign.warning
        case .authorized:
            return GifJotDesign.success
        }
    }

    private var statusTint: Color {
        if permissionService.restartRecommended {
            return GifJotDesign.warning.opacity(0.12)
        }

        switch permissionService.status {
        case .notDetermined:
            return GifJotDesign.indigoTint
        case .denied:
            return GifJotDesign.warning.opacity(0.12)
        case .authorized:
            return GifJotDesign.success.opacity(0.12)
        }
    }
}
