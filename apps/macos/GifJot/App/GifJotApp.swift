import AppKit
import SwiftUI

@main
@MainActor
struct GifJotApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra {
#if DEBUG
            RecordingPanel(
                coordinator: appDelegate.recordingCoordinator,
                permissionService: appDelegate.permissionService,
                shortcutService: appDelegate.globalShortcutService,
                settings: appDelegate.settings,
                showPermissionWindow: appDelegate.showPermissionWindow,
                showAboutPanel: showAboutPanel,
                regionSelectionService: appDelegate.regionSelectionService,
                diagnosticService: appDelegate.diagnosticCaptureService
            )
#else
            RecordingPanel(
                coordinator: appDelegate.recordingCoordinator,
                permissionService: appDelegate.permissionService,
                shortcutService: appDelegate.globalShortcutService,
                settings: appDelegate.settings,
                showPermissionWindow: appDelegate.showPermissionWindow,
                showAboutPanel: showAboutPanel
            )
#endif
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
        CaptureFrameMark(
            color: (
                coordinator.state == .recording
                    || coordinator.state == .readyToRecord
            )
                ? GifJotDesign.signal
                : .primary,
            isActive: coordinator.state == .recording,
            lineWidth: 1.5
        )
            .frame(width: 15, height: 15)
            .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        "GifJot, \(coordinator.statusText)"
    }
}

@MainActor
private struct RecordingPanel: View {
    @ObservedObject var coordinator: RecordingCoordinator
    @ObservedObject var permissionService: CapturePermissionService
    @ObservedObject var shortcutService: GlobalShortcutService
    @ObservedObject var settings: SettingsStore
    let showPermissionWindow: () -> Void
    let showAboutPanel: () -> Void
#if DEBUG
    let regionSelectionService: RegionSelectionService
    @ObservedObject var diagnosticService: ScreenCaptureDiagnosticService
    @State private var developerToolsExpanded = false
#endif
    @State private var didCopyRecentOutput = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            Divider()
                .overlay(GifJotDesign.opticalHairline)
                .padding(.top, 14)

            VStack(alignment: .leading, spacing: 14) {
                if needsPermissionAttention {
                    permissionNotice
                }

                if !shortcutService.isRegistered {
                    shortcutNotice
                }

                cameraDeck

                if let outputURL = coordinator.lastOutputURL {
                    recentOutput(outputURL)
                }

#if DEBUG
                developerTools
#endif
            }
            .padding(.top, 16)

            Divider()
                .overlay(GifJotDesign.opticalHairline)
                .padding(.top, 14)
                .padding(.bottom, 11)

            footer
        }
        .padding(18)
        .frame(width: GifJotDesign.panelWidth)
        .background(GifJotDesign.opticalBody)
        .tint(GifJotDesign.signal)
        .onChange(of: coordinator.lastOutputURL) { _, _ in
            didCopyRecentOutput = false
        }
    }

    private var header: some View {
        HStack(spacing: 11) {
            CaptureFrameMark(
                color: coordinator.state == .recording
                    ? GifJotDesign.signal
                    : .primary,
                isActive: coordinator.state == .recording
            )
            .frame(width: 25, height: 25)

            VStack(alignment: .leading, spacing: 1) {
                Text("GifJot")
                    .font(.system(size: 16, weight: .bold))
                    .tracking(-0.2)

                Text("POCKET CAPTURE CAMERA")
                    .font(.system(size: 8, weight: .semibold, design: .monospaced))
                    .tracking(0.85)
                    .foregroundStyle(GifJotDesign.mutedInk)
            }

            Spacer()

            headerState

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

    private var cameraDeck: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("CAPTURE / REGION")
                Spacer()
                Text("LOCAL GIF")
            }
            .font(.system(size: 8, weight: .semibold, design: .monospaced))
            .tracking(0.7)
            .foregroundStyle(GifJotDesign.mutedInk)
            .padding(.horizontal, 8)
            .padding(.bottom, 8)

            Divider()
                .overlay(GifJotDesign.opticalHairline)

            primaryAction
                .padding(.top, 2)

            stateSummary
                .padding(.top, 6)
        }
        .padding(9)
        .gifJotGroupSurface()
    }

    private var headerState: some View {
        HStack(spacing: 5) {
            RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                .fill(headerStatusColor)
                .frame(width: 5, height: 5)

            Text(headerStatus.uppercased())
                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                .tracking(0.25)
                .lineLimit(1)
        }
        .foregroundStyle(headerStatusColor)
        .padding(.horizontal, 9)
        .frame(height: 26)
        .background(GifJotDesign.cameraBlack)
        .overlay {
            Capsule()
                .stroke(GifJotDesign.warmChalk.opacity(0.08))
        }
        .clipShape(Capsule())
    }

    private var primaryAction: some View {
        Button {
            performPrimaryAction()
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            coordinator.primaryActionEnabled
                                ? GifJotDesign.signal
                                : GifJotDesign.mutedInk
                        )
                    Circle()
                        .stroke(GifJotDesign.pressedSignal, lineWidth: 1)

                    primaryActionMark
                }
                .frame(
                    width: GifJotDesign.shutterSize,
                    height: GifJotDesign.shutterSize
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text("SHUTTER")
                        .font(.system(size: 8, weight: .semibold, design: .monospaced))
                        .tracking(0.8)
                        .foregroundStyle(GifJotDesign.mutedInk)

                    Text(coordinator.primaryActionTitle)
                        .font(.system(size: 14, weight: .bold))
                        .tracking(-0.1)
                        .foregroundStyle(.primary)
                }

                Spacer()

                if shortcutService.isRegistered {
                    GifJotKeycap(
                        text: GlobalShortcutService.displayName,
                        inverted: false
                    )
                }
            }
            .frame(maxWidth: .infinity, minHeight: 54)
        }
        .buttonStyle(GifJotShutterRowButtonStyle())
        .disabled(!coordinator.primaryActionEnabled)
        .accessibilityHint("Starts, cancels, or stops the current recording")
    }

    @ViewBuilder
    private var primaryActionMark: some View {
        switch coordinator.state {
        case .readyToRecord:
            CaptureFrameMark(
                color: GifJotDesign.warmChalk,
                lineWidth: 1.5
            )
            .frame(width: 18, height: 18)
            .accessibilityLabel("Region ready")
        case .recording:
            Image(systemName: "stop.fill")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(GifJotDesign.warmChalk)
        case .selectingRegion, .countdown, .startingCapture:
            Image(systemName: "xmark")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(GifJotDesign.warmChalk)
        case .finishingCapture, .encoding, .exporting:
            ProgressView()
                .controlSize(.small)
                .tint(GifJotDesign.warmChalk)
        default:
            CaptureFrameMark(
                color: GifJotDesign.warmChalk,
                lineWidth: 1.5
            )
            .frame(width: 18, height: 18)
        }
    }

    private var stateSummary: some View {
        HStack(alignment: .top, spacing: 10) {
            stateSymbol
                .frame(width: 16, height: 16)
                .padding(.top, 20)

            VStack(alignment: .leading, spacing: 0) {
                Text("CAPTURE STATUS")
                    .font(.system(size: 8, weight: .semibold, design: .monospaced))
                    .tracking(0.8)
                    .foregroundStyle(GifJotDesign.mutedChalk)

                Text(coordinator.statusText)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(GifJotDesign.warmChalk)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 6)

                Text(configurationSummary)
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .tracking(0.35)
                    .foregroundStyle(GifJotDesign.mutedChalk)
                    .padding(.top, 7)

                if coordinator.droppedFrames > 0 {
                    Text("Skipped \(coordinator.droppedFrames) frames while keeping the app responsive.")
                        .font(.system(size: 11))
                        .foregroundStyle(GifJotDesign.warning)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 6)
                }

                if coordinator.state == .completed,
                   coordinator.optimizedFrameCount > 0
                {
                    Text("Merged \(coordinator.optimizedFrameCount) unchanged frames automatically.")
                        .font(.system(size: 11))
                        .foregroundStyle(GifJotDesign.mutedChalk)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 6)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .background(GifJotDesign.cameraBlack)
        .overlay {
            RoundedRectangle(
                cornerRadius: GifJotDesign.surfaceRadius,
                style: .continuous
            )
            .stroke(GifJotDesign.warmChalk.opacity(0.09))
        }
        .clipShape(
            RoundedRectangle(
                cornerRadius: GifJotDesign.surfaceRadius,
                style: .continuous
            )
        )
    }

    @ViewBuilder
    private var stateSymbol: some View {
        switch coordinator.state {
        case .recording:
            RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                .fill(GifJotDesign.signal)
                .frame(width: 8, height: 8)
                .accessibilityLabel("Recording")
        case .startingCapture, .finishingCapture, .encoding, .exporting,
             .requestingPermission:
            ProgressView()
                .controlSize(.small)
                .tint(GifJotDesign.warmChalk)
                .accessibilityLabel("Working")
        case .completed:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(GifJotDesign.success)
        case .failed:
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(GifJotDesign.warning)
        case .canceled:
            Image(systemName: "xmark.circle")
                .foregroundStyle(GifJotDesign.mutedChalk)
        default:
            Image(systemName: "circle")
                .font(.system(size: 8, weight: .semibold))
                .foregroundStyle(GifJotDesign.mutedChalk)
        }
    }

    private var permissionNotice: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: permissionService.restartRecommended
                ? "arrow.clockwise"
                : "rectangle.dashed.badge.record")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(GifJotDesign.warning)
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

    private var shortcutNotice: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(GifJotDesign.warning)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 4) {
                Text("Keyboard shortcut unavailable")
                    .font(.system(size: 12, weight: .semibold))

                Text(
                    "Another app may be using "
                        + "\(GlobalShortcutService.displayName). "
                        + "You can still record from this panel."
                )
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .gifJotGroupSurface()
    }

    private func recentOutput(_ outputURL: URL) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                CaptureFrameMark(
                    color: coordinator.state == .completed
                        ? GifJotDesign.success
                        : GifJotDesign.mutedInk,
                    isActive: coordinator.state == .completed,
                    lineWidth: 1.5
                )
                .frame(width: 20, height: 20)

                VStack(alignment: .leading, spacing: 2) {
                    Text("OUTPUT / LATEST CAPTURE")
                        .font(.system(size: 9, weight: .semibold, design: .monospaced))
                        .tracking(0.6)
                        .foregroundStyle(.secondary)

                    Text(outputURL.lastPathComponent)
                        .font(.system(size: 12, weight: .medium))
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                Spacer(minLength: 0)
            }

            HStack(spacing: 0) {
                outputAction(title: "Open", symbol: "arrow.up.right") {
                    NSWorkspace.shared.open(outputURL)
                }

                Divider()
                    .frame(height: 16)

                outputAction(
                    title: didCopyRecentOutput ? "Copied" : "Copy",
                    symbol: didCopyRecentOutput ? "checkmark" : "doc.on.doc"
                ) {
                    coordinator.copyLastOutputToClipboard()
                    withAnimation(.easeOut(duration: 0.16)) {
                        didCopyRecentOutput = true
                    }
                }

                Divider()
                    .frame(height: 16)

                outputAction(title: "Reveal", symbol: "folder") {
                    NSWorkspace.shared.activateFileViewerSelecting([outputURL])
                }
            }
            .background(GifJotDesign.shellHighlight)
            .overlay {
                RoundedRectangle(
                    cornerRadius: GifJotDesign.controlRadius,
                    style: .continuous
                )
                .stroke(GifJotDesign.opticalHairline)
            }
            .clipShape(
                RoundedRectangle(
                    cornerRadius: GifJotDesign.controlRadius,
                    style: .continuous
                )
            )
        }
        .padding(12)
        .gifJotGroupSurface()
    }

    private func outputAction(
        title: String,
        symbol: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: symbol)
                    .font(.system(size: 10, weight: .semibold))
                Text(title)
            }
        }
        .buttonStyle(GifJotInlineActionButtonStyle())
    }

    private var footer: some View {
        HStack(spacing: 8) {
            Image(systemName: "lock.shield")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)

            Text("LOCAL / NO CLOUD")
                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                .tracking(0.65)
                .foregroundStyle(GifJotDesign.mutedInk)

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
        case .readyToRecord:
            "Region ready"
        case .countdown, .startingCapture:
            "Starting soon"
        default:
            needsPermissionAttention ? "Setup needed" : "Ready"
        }
    }

    private var headerStatusColor: Color {
        switch coordinator.state {
        case .readyToRecord, .recording:
            GifJotDesign.signal
        case .completed:
            GifJotDesign.success
        case .failed:
            GifJotDesign.warning
        default:
            GifJotDesign.mutedChalk
        }
    }

    private var configurationSummary: String {
        let cursor = settings.includeCursor ? "Cursor on" : "Cursor off"
        return "\(settings.maximumOutputWidth.displayName) / \(settings.framesPerSecond.displayName) / \(cursor)"
            .uppercased()
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
        alert.informativeText = "Display \(region.displayID)\nSource: \(Int(region.sourceRect.minX)), \(Int(region.sourceRect.minY)); size \(Int(region.sourceRect.width)) × \(Int(region.sourceRect.height)) points\nScale: \(region.displayScale)x"
        alert.addButton(withTitle: "Done")
        alert.runModal()
    }
#endif
}
