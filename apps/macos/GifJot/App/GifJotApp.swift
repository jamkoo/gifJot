import AppKit
import SwiftUI

@main
@MainActor
struct GifJotApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var settings: SettingsStore

    init() {
        _settings = StateObject(wrappedValue: SettingsStore())
    }

    var body: some Scene {
        MenuBarExtra {
            RecordingControlsMenu(
                coordinator: appDelegate.recordingCoordinator,
                permissionService: appDelegate.permissionService,
                settings: settings,
                showPermissionWindow: appDelegate.showPermissionWindow
            )

            Divider()

            PermissionStatusMenuLabel(
                permissionService: appDelegate.permissionService
            )

            Button("Screen Recording Access...") {
                appDelegate.showPermissionWindow()
            }

#if DEBUG
            Divider()

            Button("Test Region Selector") {
                Task {
                    guard let region = await appDelegate.regionSelectionService.selectRegion()
                    else { return }

                    showSelectedRegion(region)
                }
            }
            .disabled(appDelegate.recordingCoordinator.isBusy)

            DiagnosticCaptureMenu(
                permissionService: appDelegate.permissionService,
                diagnosticService: appDelegate.diagnosticCaptureService,
                settings: settings,
                recordingIsBusy: appDelegate.recordingCoordinator.isBusy
            )
#endif

            Divider()

            SettingsLink {
                Text("Settings...")
            }

            Button("About GifJot") {
                showAboutPanel()
            }

            Divider()

            Button("Quit GifJot") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        } label: {
            RecordingMenuBarLabel(
                coordinator: appDelegate.recordingCoordinator
            )
        }
        .menuBarExtraStyle(.menu)

        Settings {
            SettingsView(settings: settings)
        }
    }

    private func showAboutPanel() {
        NSApplication.shared.orderFrontStandardAboutPanel(options: [
            .applicationName: "GifJot",
            .applicationVersion: "0.1.0",
            .credits: NSAttributedString(
                string: "Free, local-only GIF screen recording."
            ),
        ])
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

#if DEBUG
    private func showSelectedRegion(_ region: CaptureRegion) {
        let alert = NSAlert()
        alert.messageText = "Region selected"
        alert.informativeText = "Display \(region.displayID)\nSource: \(Int(region.sourceRect.minX)), \(Int(region.sourceRect.minY)) - \(Int(region.sourceRect.width)) x \(Int(region.sourceRect.height)) points\nScale: \(region.displayScale)x"
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
#endif
}

@MainActor
private struct RecordingMenuBarLabel: View {
    @ObservedObject var coordinator: RecordingCoordinator

    var body: some View {
        Label(
            "GifJot",
            systemImage: coordinator.state == .recording
                ? "record.circle.fill"
                : "record.circle"
        )
    }
}

@MainActor
private struct RecordingControlsMenu: View {
    @ObservedObject var coordinator: RecordingCoordinator
    @ObservedObject var permissionService: CapturePermissionService
    @ObservedObject var settings: SettingsStore
    let showPermissionWindow: () -> Void

    var body: some View {
        Button(coordinator.primaryActionTitle) {
            performPrimaryAction()
        }
        .disabled(!coordinator.primaryActionEnabled)

        Text(coordinator.statusText)

        if coordinator.droppedFrames > 0 {
            Text("Dropped \(coordinator.droppedFrames) frames while processing")
        }

        if let outputURL = coordinator.lastOutputURL {
            Button("Show Last GIF in Finder") {
                NSWorkspace.shared.activateFileViewerSelecting([outputURL])
            }
        }
    }

    private func performPrimaryAction() {
        let isStarting = !coordinator.isBusy
        if isStarting && (
            permissionService.refreshStatus() != .authorized
                || permissionService.restartRecommended
        ) {
            showPermissionWindow()
            return
        }

        coordinator.performPrimaryAction(
            configuration: settings.recordingConfiguration()
        )
    }
}

#if DEBUG
@MainActor
private struct DiagnosticCaptureMenu: View {
    @ObservedObject var permissionService: CapturePermissionService
    @ObservedObject var diagnosticService: ScreenCaptureDiagnosticService
    @ObservedObject var settings: SettingsStore
    let recordingIsBusy: Bool

    var body: some View {
        Button(buttonTitle) {
            Task {
                await diagnosticService.runFiveSecondCapture(
                    framesPerSecond: settings.framesPerSecond.rawValue,
                    includeCursor: settings.includeCursor
                )
            }
        }
        .disabled(
            diagnosticService.state.isCapturing
                || recordingIsBusy
                || permissionService.status != .authorized
                || permissionService.restartRecommended
        )

        if permissionService.restartRecommended {
            Text("Quit and reopen GifJot before running the capture test.")
        } else if permissionService.status != .authorized {
            Text("Grant Screen Recording access to run the capture test.")
        }

        switch diagnosticService.state {
        case .idle, .capturing:
            EmptyView()

        case let .completed(report):
            Text(
                "Frames: \(report.completeFrames) complete / \(report.receivedFrames) received"
            )
            Text(
                "Estimated dropped: \(report.estimatedDroppedFrames) / Non-complete: \(report.nonCompleteFrames)"
            )
            Text("Invalid: \(report.invalidFrames)")
            Text(
                "Observed size: \(report.observedWidth ?? 0) x \(report.observedHeight ?? 0)"
            )
            Text(
                "Timestamp span: \(formattedSpan(report.timestampSpanSeconds))"
            )

        case let .failed(message):
            Text("Capture test failed: \(message)")
        }
    }

    private var buttonTitle: String {
        diagnosticService.state.isCapturing
            ? "Capturing for 5 Seconds..."
            : "Run 5-Second Capture Test"
    }

    private func formattedSpan(_ seconds: Double?) -> String {
        guard let seconds else { return "Unavailable" }
        return String(format: "%.3f seconds", seconds)
    }
}
#endif

@MainActor
private struct PermissionStatusMenuLabel: View {
    @ObservedObject var permissionService: CapturePermissionService

    var body: some View {
        switch permissionService.status {
        case .notDetermined:
            Label("Screen Recording: Not Set Up", systemImage: "circle.dashed")
        case .denied:
            Label("Screen Recording: Off", systemImage: "exclamationmark.triangle")
        case .authorized:
            if permissionService.restartRecommended {
                Label("Screen Recording: Restart Required", systemImage: "arrow.clockwise")
            } else {
                Label("Screen Recording: Allowed", systemImage: "checkmark.circle")
            }
        }
    }
}
