import AppKit
import Combine
import SwiftUI

@main
@MainActor
struct GifJotApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            SettingsView(settings: appDelegate.settings)
        }
    }
}

@MainActor
final class GifJotMenuBarController: NSObject {
    private let coordinator: RecordingCoordinator
    private let popover = NSPopover()
    private var statusItem: NSStatusItem?
    private var stateSubscription: AnyCancellable?

    init(appDelegate: AppDelegate) {
        coordinator = appDelegate.recordingCoordinator
        super.init()

#if DEBUG
        let rootView = RecordingPanel(
            coordinator: appDelegate.recordingCoordinator,
            permissionService: appDelegate.permissionService,
            shortcutService: appDelegate.globalShortcutService,
            settings: appDelegate.settings,
            showPermissionWindow: { [weak appDelegate] in
                appDelegate?.showPermissionWindow()
            },
            showSettingsWindow: { [weak appDelegate] in
                appDelegate?.showSettingsWindow()
            },
            showAboutPanel: Self.showAboutPanel,
            regionSelectionService: appDelegate.regionSelectionService,
            diagnosticService: appDelegate.diagnosticCaptureService
        )
#else
        let rootView = RecordingPanel(
            coordinator: appDelegate.recordingCoordinator,
            permissionService: appDelegate.permissionService,
            shortcutService: appDelegate.globalShortcutService,
            settings: appDelegate.settings,
            showPermissionWindow: { [weak appDelegate] in
                appDelegate?.showPermissionWindow()
            },
            showSettingsWindow: { [weak appDelegate] in
                appDelegate?.showSettingsWindow()
            },
            showAboutPanel: Self.showAboutPanel
        )
#endif

        let hostingController = NSHostingController(rootView: rootView)
        hostingController.sizingOptions = [.preferredContentSize]
        popover.contentViewController = hostingController
        popover.behavior = .transient
        popover.animates = true
    }

    func start() {
        guard statusItem == nil else { return }

        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        guard let button = item.button else {
            NSStatusBar.system.removeStatusItem(item)
            return
        }

        statusItem = item
        button.target = self
        button.action = #selector(togglePopover(_:))
        button.imagePosition = .imageOnly
        item.isVisible = true
        updateStatusItem()

        stateSubscription = coordinator.$state
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.updateStatusItem()
            }
    }

    func stop() {
        stateSubscription?.cancel()
        stateSubscription = nil
        popover.close()

        if let statusItem {
            NSStatusBar.system.removeStatusItem(statusItem)
            self.statusItem = nil
        }
    }

    @objc
    private func togglePopover(_ sender: Any?) {
        guard let button = statusItem?.button else { return }

        if popover.isShown {
            popover.performClose(sender)
            return
        }

        popover.show(
            relativeTo: button.bounds,
            of: button,
            preferredEdge: .minY
        )
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    private func updateStatusItem() {
        guard let button = statusItem?.button else { return }

        let isRecording = coordinator.state == .recording
        let symbolName = isRecording ? "record.circle.fill" : "viewfinder"
        let description = "GifJot, \(coordinator.statusText)"

        if let image = NSImage(
            systemSymbolName: symbolName,
            accessibilityDescription: description
        ) {
            image.isTemplate = true
            button.image = image
            button.title = ""
        } else {
            button.image = nil
            button.title = "GJ"
        }

        button.toolTip = description
        button.setAccessibilityLabel(description)
    }

    private static func showAboutPanel() {
        NSApplication.shared.activate(ignoringOtherApps: true)
        NSApplication.shared.orderFrontStandardAboutPanel(options: [
            .applicationName: "GifJot",
            .applicationVersion: "0.1.0",
            .credits: NSAttributedString(
                string: "Free, local-only GIF screen recording."
            ),
        ])
    }
}

@MainActor
private struct RecordingPanel: View {
    @ObservedObject var coordinator: RecordingCoordinator
    @ObservedObject var permissionService: CapturePermissionService
    @ObservedObject var shortcutService: GlobalShortcutService
    @ObservedObject var settings: SettingsStore
    let showPermissionWindow: () -> Void
    let showSettingsWindow: () -> Void
    let showAboutPanel: () -> Void
#if DEBUG
    let regionSelectionService: RegionSelectionService
    @ObservedObject var diagnosticService: ScreenCaptureDiagnosticService
    @State private var developerToolsExpanded = false
#endif
    @State private var didCopyRecentOutput = false
    @State private var moreActionsExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            if moreActionsExpanded {
                moreActionsPanel
                    .padding(.top, 8)
            }

            Divider()
                .overlay(GifJotDesign.opticalHairline)
                .padding(.top, 12)

            VStack(alignment: .leading, spacing: 12) {
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
            .padding(.top, 10)

            Divider()
                .overlay(GifJotDesign.opticalHairline)
                .padding(.top, 12)
                .padding(.bottom, 9)

            footer
        }
        .padding(16)
        .frame(width: GifJotDesign.panelWidth)
        .background(GifJotDesign.opticalBody)
        .tint(GifJotDesign.signal)
        .onChange(of: coordinator.lastOutputURL) { _, _ in
            didCopyRecentOutput = false
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Text("GifJot")
                .font(.system(size: 15, weight: .bold))
                .tracking(-0.15)

            Spacer()

            Button {
                moreActionsExpanded = false
                showSettingsWindow()
            } label: {
                Image(systemName: "gearshape")
                    .accessibilityLabel("Open Settings")
            }
            .buttonStyle(GifJotIconButtonStyle())

            Button {
                withAnimation(.easeOut(duration: 0.12)) {
                    moreActionsExpanded.toggle()
                }
            } label: {
                Image(systemName: "ellipsis")
                    .accessibilityLabel("More GifJot Actions")
            }
            .buttonStyle(GifJotIconButtonStyle())
            .accessibilityValue(moreActionsExpanded ? "Expanded" : "Collapsed")
        }
    }

    private var moreActionsPanel: some View {
        HStack(spacing: 0) {
            Button("About GifJot") {
                moreActionsExpanded = false
                DispatchQueue.main.async {
                    showAboutPanel()
                }
            }
            .buttonStyle(GifJotInlineActionButtonStyle())

            Divider()
                .frame(height: 16)

            Button("Quit GifJot") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(GifJotInlineActionButtonStyle())
            .keyboardShortcut("q")
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

    private var cameraDeck: some View {
        VStack(alignment: .leading, spacing: 0) {
            primaryAction

            if shouldShowStateReadout {
                stateSummary
                    .padding(.top, 8)
            }
        }
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

                VStack(alignment: .leading, spacing: 3) {
                    Text(coordinator.primaryActionTitle)
                        .font(.system(size: 13, weight: .bold))
                        .tracking(-0.1)
                        .foregroundStyle(.primary)

                    Text(compactConfigurationSummary)
                        .font(.system(size: 8, weight: .medium, design: .monospaced))
                        .tracking(0.35)
                        .foregroundStyle(GifJotDesign.mutedInk)
                }

                Spacer()

                if shortcutService.isRegistered {
                    GifJotKeycap(
                        text: GlobalShortcutService.displayName,
                        inverted: false
                    )
                }
            }
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity, minHeight: 60)
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

            Text("LOCAL ONLY")
                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                .tracking(0.65)
                .foregroundStyle(GifJotDesign.mutedInk)

            Spacer()
        }
    }

    private var shouldShowStateReadout: Bool {
        switch coordinator.state {
        case .idle, .completed, .canceled:
            false
        default:
            true
        }
    }

    private var needsPermissionAttention: Bool {
        permissionService.status != .authorized
            || permissionService.restartRecommended
    }

    private var configurationSummary: String {
        let cursor = settings.includeCursor ? "Cursor on" : "Cursor off"
        return "\(settings.maximumOutputWidth.displayName) / \(settings.framesPerSecond.displayName) / \(cursor)"
            .uppercased()
    }

    private var compactConfigurationSummary: String {
        let cursor = settings.includeCursor ? "CURSOR ON" : "CURSOR OFF"
        return "\(settings.framesPerSecond.rawValue) FPS · \(cursor)"
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
