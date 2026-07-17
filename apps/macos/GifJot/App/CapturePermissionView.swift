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
            HStack {
                Text("GIFJOT / CAPTURE ACCESS")
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .tracking(0.8)
                    .foregroundStyle(.secondary)

                Spacer()

                HStack(spacing: 5) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 8, weight: .semibold))
                    Text("LOCAL")
                        .font(.system(size: 9, weight: .semibold, design: .monospaced))
                        .tracking(0.5)
                }
                .foregroundStyle(.secondary)
            }

            HStack(alignment: .top, spacing: 24) {
                ZStack {
                    RoundedRectangle(
                        cornerRadius: GifJotDesign.surfaceRadius,
                        style: .continuous
                    )
                    .fill(GifJotDesign.cameraBlack)

                    CaptureFrameMark(
                        color: iconColor,
                        isActive: permissionService.status == .authorized
                            && !permissionService.restartRecommended,
                        lineWidth: 2
                    )
                    .frame(width: 58, height: 58)

                    Image(systemName: iconName)
                        .font(.system(size: 21, weight: .semibold))
                        .foregroundStyle(iconColor)
                        .symbolRenderingMode(.hierarchical)
                }
                .frame(width: 84, height: 84)
                .overlay {
                    RoundedRectangle(
                        cornerRadius: GifJotDesign.surfaceRadius,
                        style: .continuous
                    )
                    .stroke(GifJotDesign.warmChalk.opacity(0.09))
                }
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 7) {
                    Text(title)
                        .font(.system(size: 28, weight: .bold))
                        .tracking(-0.65)

                    Text(message)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: 330, alignment: .leading)
                }

                Spacer(minLength: 0)
            }
            .padding(.top, 22)

            PermissionStepRail(currentStep: currentStep)
                .padding(.top, 26)

            HStack(alignment: .top, spacing: 11) {
                Image(systemName: "lock.shield")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 20)

                Text("GifJot records only when you press the shutter. Everything stays on this Mac. Accessibility access is never requested.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)
            }
            .padding(14)
            .gifJotGroupSurface()
            .padding(.top, 22)

            actionButtons
                .padding(.top, 16)
        }
        .padding(28)
        .frame(width: 560)
        .background(GifJotDesign.opticalBody)
        .tint(GifJotDesign.signal)
    }

    private var actionButtons: some View {
        HStack(spacing: 10) {
            if !permissionService.restartRecommended {
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
                    Button("Quit and Reopen GifJot", action: onRestart)
                    .buttonStyle(GifJotPrimaryButtonStyle())
                    .keyboardShortcut(.defaultAction)
                } else {
                    Button("Start Recording", action: onStartRecording)
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
            "Enable GifJot in System Settings, Privacy & Security, Screen & System Audio Recording."
        case .authorized:
            permissionService.restartRecommended
                ? "Permission is enabled. Reopen GifJot once so macOS can finish applying it."
                : "Screen Recording access is enabled. Start now, or use the GifJot menu-bar icon anytime."
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
            return GifJotDesign.warning
        }

        switch permissionService.status {
        case .notDetermined:
            return GifJotDesign.signal
        case .denied:
            return GifJotDesign.warning
        case .authorized:
            return GifJotDesign.success
        }
    }

    private var currentStep: Int {
        switch permissionService.status {
        case .notDetermined, .denied:
            0
        case .authorized:
            permissionService.restartRecommended ? 1 : 2
        }
    }
}

private struct PermissionStepRail: View {
    let currentStep: Int

    var body: some View {
        HStack(spacing: 0) {
            step(index: 0, label: "ALLOW")
            connector(after: 0)
            step(index: 1, label: "REOPEN")
            connector(after: 1)
            step(index: 2, label: "RECORD")
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Permission setup, step \(currentStep + 1) of 3")
    }

    private func step(index: Int, label: String) -> some View {
        VStack(spacing: 7) {
            ZStack {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(stepFill(index))
                    .frame(width: 22, height: 22)

                if index < currentStep {
                    Image(systemName: "checkmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(GifJotDesign.softPaper)
                } else {
                    Text("\(index + 1)")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(
                            index == currentStep
                                ? GifJotDesign.softPaper
                                : Color.secondary
                        )
                }
            }

            Text(label)
                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                .tracking(0.55)
                .foregroundStyle(index <= currentStep ? Color.primary : Color.secondary)
        }
        .frame(width: 62)
    }

    private func connector(after index: Int) -> some View {
        Rectangle()
            .fill(
                index < currentStep
                    ? GifJotDesign.success
                    : GifJotDesign.opticalHairline
            )
            .frame(height: 1)
            .offset(y: -8)
    }

    private func stepFill(_ index: Int) -> Color {
        if index < currentStep {
            return GifJotDesign.success
        }
        if index == currentStep {
            return GifJotDesign.signal
        }
        return GifJotDesign.vellum
    }
}
