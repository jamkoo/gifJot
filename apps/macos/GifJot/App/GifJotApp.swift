import AppKit
import SwiftUI

@main
@MainActor
struct GifJotApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra {
            RecordingPanel(
                coordinator: appDelegate.recordingCoordinator,
                permissionService: appDelegate.permissionService,
                settings: appDelegate.settings,
                showPermissionWindow: appDelegate.showPermissionWindow,
                showAboutPanel: showAboutPanel
#if DEBUG
                , regionSelectionService: appDelegate.regionSelectionService,
                diagnosticService: appDelegate.diagnosticCaptureService
#endif
            )
        } label: {
            RecordingMenuBarLabel(
                coordinator: appDelegate.recordingCoordinator
            )
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(settings: appDelegate.settings)
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
}

@MainActor
private struct RecordingMenuBarLabel: View {
    @ObservedObject var coordinator: RecordingCoordinator

    var body: some View {
        Label("GifJot", systemImage: symbolName)
            .accessibilityLabel(accessibilityLabel)
    }

    private var symbolName: String {
        switch coordinator.state {
        case .recording:
            "record.circle.fill"
        case .finishingCapture, .encoding, .exporting:
            "ellipsis.circle"
        case .completed:
            "checkmark.circle"
        case .failed:
            "exclamationmark.circle"
        default:
            "record.circle"
        }
    }

    private var accessibilityLabel: String {
        "GifJot, \(coordinator.statusText)"
    }
}

@MainActor
private struct RecordingPanel: View {
    @ObservedObject var coordinator: RecordingCoordinator
    @ObservedObject var permissionService: CapturePermissionService
    @ObservedObject var settings: SettingsStore
    let showPermissionWindow: () -> Void
    let showAboutPanel: () -> Void
#if DEBUG
    let regionSelectionService: RegionSelectionService
    @ObservedObject var diagnosticService: ScreenCaptureDiagnosticService
    @State private var developerToolsExpanded = false
#endif

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            Divider()
                .padding(.vertical, 12)

            VStack(alignment: .leading, spacing: 12) {
                if needsPermissionAttention {
                    permissionNotice
                }

                primaryAction

                stateSummary

                if let outputURL = coordinator.lastOutputURL {
                    recentOutput(outputURL)
                }

#if DEBUG
                developerTools
#endif
            }

            Divider()
                .padding(.vertical, 12)

            footer
        }
        .padding(16)
        .frame(width: GifJotDesign.panelWidth)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "record.circle")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(
                    coordinator.state == .recording
                        ? GifJotDesign.signal
                        : Color.primary
                )

            VStack(alignment: .leading, spacing: 1) {
                Text("GifJot")
                    .font(.system(size: 15, weight: .semibold))

                Text(headerStatus)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(headerStatusColor)
                    .lineLimit(1)
            }

            Spacer()

            SettingsLink {
                Image(systemName: "gearshape")
                    .accessibilityLabel("Open Settings")
            }
            .buttonStyle(GifJotIconButtonStyle())

            Menu {
                Button("About GifJot", action: showAboutPanel)
                Divider()
                Button("Quit GifJot") {
                    NSApplication.shared.terminate(nil)
                }
                .keyboardShortcut("q")
            } label: {
                Image(systemName: "ellipsis")
                    .accessibilityLabel("More GifJot Actions")
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .frame(width: 28, height: 28)
        }
    }

    private var primaryAction: some View {
        Button {
            performPrimaryAction()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: primaryActionSymbol)
                    .font(.system(size: 12, weight: .bold))

                Text(coordinator.primaryActionTitle)

                Spacer()

                Text("⌥⌘G")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(GifJotDesign.softPaper.opacity(0.78))
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(GifJotPrimaryButtonStyle())
        .disabled(!coordinator.primaryActionEnabled)
        .accessibilityHint("Starts, cancels, or stops the current recording")
    }

    private var stateSummary: some View {
        HStack(alignment: .top, spacing: 9) {
            stateSymbol
                .frame(width: 16, height: 16)

            VStack(alignment: .leading, spacing: 3) {
                Text(coordinator.statusText)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(configurationSummary)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)

                if coordinator.droppedFrames > 0 {
                    Text("Skipped \(coordinator.droppedFrames) frames while keeping the app responsive.")
                        .font(.system(size: 11))
                        .foregroundStyle(.orange)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if coordinator.state == .completed,
                   coordinator.optimizedFrameCount > 0
                {
                    Text("Merged \(coordinator.optimizedFrameCount) unchanged frames automatically.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .gifJotGroupSurface()
    }

    @ViewBuilder
    private var stateSymbol: some View {
        switch coordinator.state {
        case .recording:
            Circle()
                .fill(GifJotDesign.signal)
                .frame(width: 8, height: 8)
                .accessibilityLabel("Recording")
        case .finishingCapture, .encoding, .exporting, .requestingPermission:
            ProgressView()
                .controlSize(.small)
                .accessibilityLabel("Working")
        case .completed:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .failed:
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
        case .canceled:
            Image(systemName: "xmark.circle")
                .foregroundStyle(.secondary)
        default:
            Image(systemName: "circle")
                .font(.system(size: 8, weight: .semibold))
                .foregroundStyle(.secondary)
        }
    }

    private var permissionNotice: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: permissionService.restartRecommended
                ? "arrow.clockwise"
                : "rectangle.dashed.badge.record")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.orange)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 5) {
                Text(permissionService.restartRecommended
                    ? "Restart required"
                    : "Screen Recording is off")
                    .font(.system(size: 12, weight: .semibold))

                Text(permissionService.restartRecommended
                    ? "Quit and reopen GifJot to finish enabling capture."
                    : "Allow access before making your first GIF.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)

                Button("Review Access", action: showPermissionWindow)
                    .buttonStyle(.link)
                    .font(.system(size: 11, weight: .medium))
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .gifJotGroupSurface()
    }

    private func recentOutput(_ outputURL: URL) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "photo.stack")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 2) {
                Text("Last GIF")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)

                Text(outputURL.lastPathComponent)
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer(minLength: 6)

            Button("Reveal") {
                NSWorkspace.shared.activateFileViewerSelecting([outputURL])
            }
            .buttonStyle(GifJotQuietButtonStyle())
        }
    }

    private var footer: some View {
        HStack(spacing: 8) {
            Image(systemName: "lock.shield")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)

            Text("Local only")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)

            Spacer()

            Text("v0.1")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(.tertiary)
        }
    }

    private var needsPermissionAttention: Bool {
        permissionService.status != .authorized
            || permissionService.restartRecommended
    }

    private var headerStatus: String {
        switch coordinator.state {
        case .recording:
            "Recording"
        case .finishingCapture, .encoding, .exporting:
            "Creating GIF"
        case .completed:
            "Saved"
        case .failed:
            "Needs attention"
        case .selectingRegion:
            "Select an area"
        case .countdown:
            "Starting soon"
        default:
            needsPermissionAttention ? "Setup needed" : "Ready"
        }
    }

    private var headerStatusColor: Color {
        switch coordinator.state {
        case .recording:
            GifJotDesign.signal
        case .completed:
            .green
        case .failed:
            .orange
        default:
            .secondary
        }
    }

    private var primaryActionSymbol: String {
        switch coordinator.state {
        case .recording:
            "stop.fill"
        case .selectingRegion, .countdown:
            "xmark"
        default:
            "record.circle"
        }
    }

    private var configurationSummary: String {
        let cursor = settings.includeCursor ? "Cursor on" : "Cursor off"
        return "\(settings.maximumOutputWidth.displayName) · \(settings.framesPerSecond.displayName) · \(cursor)"
    }

    private func performPrimaryAction() {
        let isStarting = !coordinator.isBusy
        if isStarting && needsPermissionAttention {
            showPermissionWindow()
            return
        }

        coordinator.performPrimaryAction(
            configuration: settings.recordingConfiguration()
        )
    }

#if DEBUG
    private var developerTools: some View {
        DisclosureGroup(
            "Developer Tools",
            isExpanded: $developerToolsExpanded
        ) {
            VStack(alignment: .leading, spacing: 8) {
                Button("Test Region Selector") {
                    Task {
                        guard let region = await regionSelectionService.selectRegion()
                        else { return }
                        showSelectedRegion(region)
                    }
                }
                .disabled(coordinator.isBusy)

                Button(diagnosticButtonTitle) {
                    Task {
                        await diagnosticService.runFiveSecondCapture(
                            framesPerSecond: settings.framesPerSecond.rawValue,
                            includeCursor: settings.includeCursor
                        )
                    }
                }
                .disabled(
                    diagnosticService.state.isCapturing
                        || coordinator.isBusy
                        || permissionService.status != .authorized
                        || permissionService.restartRecommended
                )

                diagnosticSummary
            }
            .font(.system(size: 11))
            .padding(.top, 8)
        }
        .font(.system(size: 11, weight: .medium))
        .foregroundStyle(.secondary)
    }

    @ViewBuilder
    private var diagnosticSummary: some View {
        switch diagnosticService.state {
        case .idle, .capturing:
            EmptyView()
        case let .completed(report):
            Text("Capture: \(report.completeFrames)/\(report.receivedFrames) complete · \(report.estimatedDroppedFrames) dropped")
                .fixedSize(horizontal: false, vertical: true)
        case let .failed(message):
            Text("Capture test failed: \(message)")
                .foregroundStyle(.orange)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var diagnosticButtonTitle: String {
        diagnosticService.state.isCapturing
            ? "Capturing for 5 Seconds…"
            : "Run 5-Second Capture Test"
    }

    private func showSelectedRegion(_ region: CaptureRegion) {
        let alert = NSAlert()
        alert.messageText = "Region selected"
        alert.informativeText = "Display \(region.displayID)\nSource: \(Int(region.sourceRect.minX)), \(Int(region.sourceRect.minY)) — \(Int(region.sourceRect.width)) × \(Int(region.sourceRect.height)) points\nScale: \(region.displayScale)x"
        alert.addButton(withTitle: "Done")
        alert.runModal()
    }
#endif
}
