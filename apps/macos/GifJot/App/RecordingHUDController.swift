import AppKit
import Combine
import QuartzCore
import SwiftUI

enum RecordingHUDPlacement {
    static let gap: CGFloat = 10
    static let screenInset: CGFloat = 12

    static func globalSelectionRect(
        sourceRect: CGRect,
        screenFrame: CGRect
    ) -> CGRect {
        CGRect(
            x: screenFrame.minX + sourceRect.minX,
            y: screenFrame.minY + screenFrame.height - sourceRect.maxY,
            width: sourceRect.width,
            height: sourceRect.height
        )
    }

    static func panelOrigin(
        selectionRect: CGRect,
        availableFrame: CGRect,
        panelSize: CGSize
    ) -> CGPoint {
        let preferredX = selectionRect.midX - panelSize.width / 2
        let minX = availableFrame.minX + screenInset
        let maxX = availableFrame.maxX - panelSize.width - screenInset
        let x = min(max(preferredX, minX), maxX)

        let aboveY = selectionRect.maxY + gap
        if aboveY + panelSize.height <= availableFrame.maxY - screenInset {
            return CGPoint(x: x, y: aboveY)
        }

        let belowY = selectionRect.minY - panelSize.height - gap
        if belowY >= availableFrame.minY + screenInset {
            return CGPoint(x: x, y: belowY)
        }

        let insideY = min(
            max(
                selectionRect.maxY - panelSize.height - gap,
                availableFrame.minY + screenInset
            ),
            availableFrame.maxY - panelSize.height - screenInset
        )
        return CGPoint(x: x, y: insideY)
    }
}

private final class InteractiveRecordingHUDPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    override func sendEvent(_ event: NSEvent) {
        if event.type == .leftMouseDown {
            NSApplication.shared.activate(ignoringOtherApps: true)
            makeKey()
        }

        super.sendEvent(event)
    }
}

@MainActor
final class RecordingHUDController {
    private static let compactPanelSize = CGSize(width: 306, height: 60)
    private static let setupPanelSize = CGSize(width: 392, height: 52)

    private let coordinator: RecordingCoordinator
    private let settings: SettingsStore
    private var panel: NSPanel?
    private var selectionBorderWindow: NSPanel?
    private var subscriptions: Set<AnyCancellable> = []
    private var delayedHideTask: Task<Void, Never>?

    init(
        coordinator: RecordingCoordinator,
        settings: SettingsStore
    ) {
        self.coordinator = coordinator
        self.settings = settings
    }

    func start() {
        guard subscriptions.isEmpty else { return }

        coordinator.$state
            .combineLatest(coordinator.$activeRegion)
            .sink { [weak self] state, region in
                self?.update(for: state, region: region)
            }
            .store(in: &subscriptions)
    }

    func stop() {
        delayedHideTask?.cancel()
        delayedHideTask = nil
        subscriptions.removeAll()
        panel?.orderOut(nil)
        panel = nil
        selectionBorderWindow?.orderOut(nil)
        selectionBorderWindow = nil
    }

    private func update(
        for state: RecordingState,
        region: CaptureRegion?
    ) {
        delayedHideTask?.cancel()
        delayedHideTask = nil

        switch state {
        case .readyToRecord, .countdown, .startingCapture, .recording:
            present(near: region, state: state)
            presentSelectionBorder(
                for: region,
                isDraggable: state == .readyToRecord
            )
        case .finishingCapture, .encoding, .exporting:
            hideSelectionBorder()
            present(near: region, state: state)
        case .completed:
            hideSelectionBorder()
            present(near: region, state: state)
            delayedHideTask = Task { [weak self] in
                do {
                    try await ContinuousClock().sleep(for: .seconds(3))
                } catch {
                    return
                }
                guard let self, self.coordinator.state == .completed else {
                    return
                }
                self.hide()
            }
        case .failed:
            hideSelectionBorder()
            present(near: region, state: state)
            delayedHideTask = Task { [weak self] in
                do {
                    try await ContinuousClock().sleep(for: .seconds(5))
                } catch {
                    return
                }
                guard let self, self.coordinator.state == .failed else {
                    return
                }
                self.hide()
            }
        default:
            hideSelectionBorder()
            hide()
        }
    }

    private func present(
        near region: CaptureRegion?,
        state: RecordingState
    ) {
        let panel = makePanelIfNeeded()
        let panelSize = Self.panelSize(for: state)
        panel.setContentSize(panelSize)
        position(panel, near: region, panelSize: panelSize)

        guard !panel.isVisible else { return }

        if NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
            panel.alphaValue = 1
            panel.orderFrontRegardless()
            return
        }

        panel.alphaValue = 0
        panel.orderFrontRegardless()
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.18
            context.timingFunction = CAMediaTimingFunction(
                controlPoints: 0.16,
                1,
                0.3,
                1
            )
            panel.animator().alphaValue = 1
        }
    }

    private func hide() {
        guard let panel, panel.isVisible else { return }
        panel.orderOut(nil)
    }

    private func presentSelectionBorder(
        for region: CaptureRegion?,
        isDraggable: Bool
    ) {
        guard let region,
              let screen = screen(for: region)
        else {
            hideSelectionBorder()
            return
        }

        let borderWindow = makeSelectionBorderWindowIfNeeded()
        let selectionRect = RecordingHUDPlacement.globalSelectionRect(
            sourceRect: region.sourceRect,
            screenFrame: screen.frame
        )
        borderWindow.setFrame(selectionRect, display: true)
        borderWindow.ignoresMouseEvents = !isDraggable
        if let borderView = borderWindow.contentView as? RecordingBorderView {
            borderView.displayScale = region.displayScale
            borderView.isAdjustable = isDraggable
            borderView.needsDisplay = true
        }
        borderWindow.orderFrontRegardless()
    }

    private func hideSelectionBorder() {
        selectionBorderWindow?.orderOut(nil)
    }

    private func makePanelIfNeeded() -> NSPanel {
        if let panel { return panel }

        let rootView = RecordingHUDView(
            coordinator: coordinator,
            settings: settings,
            onApplyFramePreset: { [weak self] preset in
                self?.applyFramePreset(preset)
            }
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        let hostingController = NSHostingController(rootView: rootView)
        let panel = InteractiveRecordingHUDPanel(
            contentRect: CGRect(
                origin: .zero,
                size: Self.compactPanelSize
            ),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        panel.contentViewController = hostingController
        panel.level = .floating
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .transient,
        ]
        panel.animationBehavior = .none
        self.panel = panel
        return panel
    }

    private func makeSelectionBorderWindowIfNeeded() -> NSPanel {
        if let selectionBorderWindow { return selectionBorderWindow }

        let panel = NSPanel(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.contentView = RecordingBorderView { [weak self] adjustment, delta in
            self?.adjustSelectedRegion(adjustment, byAppKitDelta: delta)
        }
        panel.level = .floating
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.hidesOnDeactivate = false
        panel.ignoresMouseEvents = true
        panel.acceptsMouseMovedEvents = true
        panel.isReleasedWhenClosed = false
        panel.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .transient,
        ]
        panel.animationBehavior = .none
        selectionBorderWindow = panel
        return panel
    }

    private func adjustSelectedRegion(
        _ adjustment: CaptureFrameAdjustment,
        byAppKitDelta delta: CGPoint
    ) {
        guard coordinator.state == .readyToRecord,
              let region = coordinator.activeRegion,
              let screen = screen(for: region)
        else {
            return
        }

        let adjustedSourceRect: CGRect
        switch adjustment {
        case .move:
            adjustedSourceRect = RegionSelectionGeometry.movedSourceRect(
                region.sourceRect,
                byAppKitDelta: delta,
                within: screen.frame.size
            )
        case let .resize(handle):
            adjustedSourceRect = RegionSelectionGeometry.resizedSourceRect(
                region.sourceRect,
                byAppKitDelta: delta,
                handle: handle,
                within: screen.frame.size
            )
        }
        guard adjustedSourceRect != region.sourceRect else { return }

        coordinator.updateSelectedRegion(
            CaptureRegion(
                displayID: region.displayID,
                sourceRect: adjustedSourceRect,
                displayScale: region.displayScale
            )
        )
    }

    private func applyFramePreset(_ preset: CaptureFramePreset) {
        guard coordinator.state == .readyToRecord,
              let region = coordinator.activeRegion,
              let screen = screen(for: region)
        else {
            return
        }

        let sourceRect = RegionSelectionGeometry.sourceRect(
            applying: preset,
            to: region.sourceRect,
            within: screen.frame.size
        )
        guard sourceRect != region.sourceRect else { return }

        coordinator.updateSelectedRegion(
            CaptureRegion(
                displayID: region.displayID,
                sourceRect: sourceRect,
                displayScale: region.displayScale
            )
        )
    }

    private func position(
        _ panel: NSPanel,
        near region: CaptureRegion?,
        panelSize: CGSize
    ) {
        let screen = screen(for: region) ?? NSScreen.main ?? NSScreen.screens.first
        guard let screen else { return }

        let selectionRect: CGRect
        if let region {
            selectionRect = RecordingHUDPlacement.globalSelectionRect(
                sourceRect: region.sourceRect,
                screenFrame: screen.frame
            )
        } else {
            selectionRect = CGRect(
                x: screen.visibleFrame.midX,
                y: screen.visibleFrame.midY,
                width: 1,
                height: 1
            )
        }

        let origin = RecordingHUDPlacement.panelOrigin(
            selectionRect: selectionRect,
            availableFrame: screen.visibleFrame,
            panelSize: panelSize
        )
        panel.setFrameOrigin(origin)
    }

    private static func panelSize(for state: RecordingState) -> CGSize {
        state == .readyToRecord ? setupPanelSize : compactPanelSize
    }

    private func screen(for region: CaptureRegion?) -> NSScreen? {
        guard let region else { return nil }
        return NSScreen.screens.first { screen in
            guard let number = screen.deviceDescription[
                NSDeviceDescriptionKey("NSScreenNumber")
            ] as? NSNumber else {
                return false
            }
            return CGDirectDisplayID(number.uint32Value) == region.displayID
        }
    }
}

private enum CaptureFrameAdjustment {
    case move
    case resize(RegionSelectionResizeHandle)
}

private final class RecordingBorderView: NSView {
    private let onAdjust: (CaptureFrameAdjustment, CGPoint) -> Void
    private var lastMouseLocation: CGPoint?
    private var activeAdjustment: CaptureFrameAdjustment?

    var displayScale: CGFloat = 1
    var isAdjustable = false {
        didSet {
            toolTip = isAdjustable
                ? "Drag inside to move. Drag an edge or corner to resize."
                : nil
            window?.invalidateCursorRects(for: self)
        }
    }

    override var acceptsFirstResponder: Bool { true }
    override var isOpaque: Bool { false }

    init(onAdjust: @escaping (CaptureFrameAdjustment, CGPoint) -> Void) {
        self.onAdjust = onAdjust
        super.init(frame: .zero)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func resetCursorRects() {
        guard isAdjustable else { return }

        let edgeLength = min(12, min(bounds.width, bounds.height) / 2)
        let cornerSize = edgeLength
        let horizontalSpan = max(0, bounds.width - cornerSize * 2)
        let verticalSpan = max(0, bounds.height - cornerSize * 2)

        addCursorRect(bounds.insetBy(dx: edgeLength, dy: edgeLength), cursor: .openHand)
        addCursorRect(
            CGRect(x: cornerSize, y: 0, width: horizontalSpan, height: edgeLength),
            cursor: .resizeUpDown
        )
        addCursorRect(
            CGRect(
                x: cornerSize,
                y: bounds.maxY - edgeLength,
                width: horizontalSpan,
                height: edgeLength
            ),
            cursor: .resizeUpDown
        )
        addCursorRect(
            CGRect(x: 0, y: cornerSize, width: edgeLength, height: verticalSpan),
            cursor: .resizeLeftRight
        )
        addCursorRect(
            CGRect(
                x: bounds.maxX - edgeLength,
                y: cornerSize,
                width: edgeLength,
                height: verticalSpan
            ),
            cursor: .resizeLeftRight
        )
        addCursorRect(
            CGRect(x: 0, y: 0, width: cornerSize, height: cornerSize),
            cursor: .crosshair
        )
        addCursorRect(
            CGRect(x: bounds.maxX - cornerSize, y: 0, width: cornerSize, height: cornerSize),
            cursor: .crosshair
        )
        addCursorRect(
            CGRect(x: 0, y: bounds.maxY - cornerSize, width: cornerSize, height: cornerSize),
            cursor: .crosshair
        )
        addCursorRect(
            CGRect(
                x: bounds.maxX - cornerSize,
                y: bounds.maxY - cornerSize,
                width: cornerSize,
                height: cornerSize
            ),
            cursor: .crosshair
        )
    }

    override func mouseDown(with event: NSEvent) {
        guard isAdjustable else {
            super.mouseDown(with: event)
            return
        }

        window?.makeKey()
        window?.makeFirstResponder(self)
        lastMouseLocation = NSEvent.mouseLocation
        activeAdjustment = adjustment(at: convert(event.locationInWindow, from: nil))
        if case .some(.move) = activeAdjustment {
            NSCursor.closedHand.set()
        }
    }

    override func mouseDragged(with event: NSEvent) {
        guard isAdjustable,
              let lastMouseLocation,
              let activeAdjustment
        else {
            super.mouseDragged(with: event)
            return
        }

        let currentMouseLocation = NSEvent.mouseLocation
        let delta = CGPoint(
            x: currentMouseLocation.x - lastMouseLocation.x,
            y: currentMouseLocation.y - lastMouseLocation.y
        )
        guard delta != .zero else { return }

        onAdjust(activeAdjustment, delta)
        self.lastMouseLocation = currentMouseLocation
    }

    override func mouseUp(with event: NSEvent) {
        defer {
            lastMouseLocation = nil
            activeAdjustment = nil
            if isAdjustable {
                window?.invalidateCursorRects(for: self)
            }
        }
        super.mouseUp(with: event)
    }

    private func adjustment(at point: CGPoint) -> CaptureFrameAdjustment {
        let edgeLength = min(12, min(bounds.width, bounds.height) / 2)
        let isWest = point.x <= bounds.minX + edgeLength
        let isEast = point.x >= bounds.maxX - edgeLength
        let isSouth = point.y <= bounds.minY + edgeLength
        let isNorth = point.y >= bounds.maxY - edgeLength

        switch (isNorth, isSouth, isEast, isWest) {
        case (true, false, true, false):
            return CaptureFrameAdjustment.resize(.northEast)
        case (true, false, false, true):
            return CaptureFrameAdjustment.resize(.northWest)
        case (false, true, true, false):
            return CaptureFrameAdjustment.resize(.southEast)
        case (false, true, false, true):
            return CaptureFrameAdjustment.resize(.southWest)
        case (true, false, false, false):
            return CaptureFrameAdjustment.resize(.north)
        case (false, true, false, false):
            return CaptureFrameAdjustment.resize(.south)
        case (false, false, true, false):
            return CaptureFrameAdjustment.resize(.east)
        case (false, false, false, true):
            return CaptureFrameAdjustment.resize(.west)
        default:
            return CaptureFrameAdjustment.move
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let lineWidth = 1.0 / max(displayScale, 1)
        NSColor(
            red: 242.0 / 255.0,
            green: 74.0 / 255.0,
            blue: 29.0 / 255.0,
            alpha: 1
        ).setStroke()
        let path = NSBezierPath(
            rect: bounds.insetBy(dx: lineWidth / 2, dy: lineWidth / 2)
        )
        path.lineWidth = lineWidth
        path.stroke()

        drawCornerBrackets(lineWidth: lineWidth)
    }

    private func drawCornerBrackets(lineWidth: CGFloat) {
        let length: CGFloat = 15
        let rect = bounds.insetBy(dx: lineWidth / 2, dy: lineWidth / 2)
        let corners = [
            [
                CGPoint(x: rect.minX, y: rect.minY + length),
                CGPoint(x: rect.minX, y: rect.minY),
                CGPoint(x: rect.minX + length, y: rect.minY),
            ],
            [
                CGPoint(x: rect.maxX - length, y: rect.minY),
                CGPoint(x: rect.maxX, y: rect.minY),
                CGPoint(x: rect.maxX, y: rect.minY + length),
            ],
            [
                CGPoint(x: rect.maxX, y: rect.maxY - length),
                CGPoint(x: rect.maxX, y: rect.maxY),
                CGPoint(x: rect.maxX - length, y: rect.maxY),
            ],
            [
                CGPoint(x: rect.minX + length, y: rect.maxY),
                CGPoint(x: rect.minX, y: rect.maxY),
                CGPoint(x: rect.minX, y: rect.maxY - length),
            ],
        ]

        for points in corners {
            guard let first = points.first else { continue }
            let path = NSBezierPath()
            path.move(to: first)
            for point in points.dropFirst() {
                path.line(to: point)
            }
            path.lineWidth = max(lineWidth * 2.5, 1.5 / max(displayScale, 1))
            path.lineCapStyle = .square
            path.lineJoinStyle = .miter
            path.stroke()
        }
    }
}

private struct RegionReadyRecordButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(GifJotDesign.warmChalk)
            .frame(width: 82, height: 40)
            .background(
                RoundedRectangle(
                    cornerRadius: 9,
                    style: .continuous
                ).fill(
                    configuration.isPressed
                        ? GifJotDesign.pressedSignal
                        : GifJotDesign.signal
                )
            )
            .overlay {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .stroke(GifJotDesign.pressedSignal)
            }
            .opacity(isEnabled ? 1 : 0.48)
    }
}

@MainActor
private struct RecordingHUDView: View {
    @ObservedObject var coordinator: RecordingCoordinator
    @ObservedObject var settings: SettingsStore
    let onApplyFramePreset: (CaptureFramePreset) -> Void

    var body: some View {
        Group {
            if coordinator.state == .readyToRecord {
                setupControls
            } else {
                compactControls
            }
        }
        .padding(
            .horizontal,
            coordinator.state == .readyToRecord ? 8 : 11
        )
        .padding(
            .vertical,
            coordinator.state == .readyToRecord ? 6 : 0
        )
        .background(GifJotDesign.cameraBlack)
        .overlay {
            RoundedRectangle(
                cornerRadius: GifJotDesign.surfaceRadius,
                style: .continuous
            )
            .stroke(Color.white.opacity(0.12))
        }
        .clipShape(
            RoundedRectangle(
                cornerRadius: GifJotDesign.surfaceRadius,
                style: .continuous
            )
        )
    }

    private var compactControls: some View {
        HStack(spacing: 10) {
            leadingSymbol

            VStack(alignment: .leading, spacing: 2) {
                Text(stateLabel)
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .tracking(0.65)
                    .foregroundStyle(GifJotDesign.softPaper.opacity(0.62))

                Text(coordinator.state == .recording ? elapsedTime : primaryText)
                    .font(
                        .system(
                            size: coordinator.state == .recording ? 16 : 12,
                            weight: .semibold,
                            design: coordinator.state == .recording
                                ? .monospaced
                                : .default
                        )
                    )
                    .monospacedDigit()
                    .foregroundStyle(GifJotDesign.softPaper)
                    .lineLimit(1)
            }

            Spacer(minLength: 4)

            if coordinator.state == .recording {
                Button {
                    coordinator.requestStop()
                } label: {
                    Label("Stop", systemImage: "stop.fill")
                }
                .buttonStyle(GifJotSignalButtonStyle())
                .accessibilityHint("Stops recording and creates the GIF")
            } else if coordinator.state == .countdown || coordinator.state == .startingCapture {
                Button("Cancel") {
                    coordinator.cancelPendingRecording()
                }
                .buttonStyle(GifJotDarkQuietButtonStyle())
                .accessibilityHint("Cancels this recording before capture begins")
            } else if coordinator.state == .completed,
                      let outputURL = coordinator.lastOutputURL
            {
                Button("Reveal") {
                    NSWorkspace.shared.activateFileViewerSelecting([outputURL])
                }
                .buttonStyle(GifJotDarkQuietButtonStyle())
            }
        }
    }

    private var setupControls: some View {
        HStack(spacing: 5) {
            outputSizeMenu

            Button {
                settings.includeCursor.toggle()
            } label: {
                HStack(spacing: 5) {
                    Image(
                        systemName: settings.includeCursor
                            ? "cursorarrow"
                            : "cursorarrow.slash"
                    )
                    .accessibilityHidden(true)

                    Text("Cursor")
                    Text(settings.includeCursor ? "On" : "Off")
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundStyle(GifJotDesign.mutedChalk)
                }
            }
            .buttonStyle(GifJotDarkQuietButtonStyle())
            .help(
                settings.includeCursor
                    ? "Cursor is included. Click to hide it."
                    : "Cursor is hidden. Click to include it."
            )
            .accessibilityLabel(
                settings.includeCursor
                    ? "Cursor included"
                    : "Cursor hidden"
            )
            .accessibilityHint("Toggles whether the cursor appears in the GIF")

            Rectangle()
                .fill(GifJotDesign.warmChalk.opacity(0.14))
                .frame(width: 1, height: 24)
                .accessibilityHidden(true)

            Button("Cancel") {
                coordinator.cancelPendingRecording()
            }
            .buttonStyle(GifJotDarkQuietButtonStyle())
            .help("Cancel and discard this selection")
            .accessibilityHint("Discards the selected region")

            Button {
                coordinator.confirmSelectedRegion(
                    configuration: settings.recordingConfiguration()
                )
            } label: {
                Label("Record", systemImage: "circle.fill")
            }
            .buttonStyle(RegionReadyRecordButtonStyle())
            .keyboardShortcut(.defaultAction)
            .help("Start recording this region")
            .accessibilityLabel("Record selected region")
            .accessibilityHint("Starts recording the selected region")
        }
    }

    private var outputSizeMenu: some View {
        Menu {
            Section("Capture area") {
                ForEach(CaptureFramePreset.allCases) { preset in
                    Button(preset.displayName) {
                        onApplyFramePreset(preset)
                    }
                }
            }

        } label: {
            HStack(spacing: 5) {
                CaptureFrameMark(
                    color: GifJotDesign.signal,
                    lineWidth: 1.5
                )
                .frame(width: 18, height: 18)
                .accessibilityHidden(true)

                Text(selectedRegionDimensions)
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .monospacedDigit()
                    .lineLimit(1)

                Image(systemName: "chevron.down")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundStyle(GifJotDesign.mutedChalk)
            }
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(GifJotDesign.warmChalk)
            .padding(.horizontal, 8)
            .frame(height: 32)
            .background(GifJotDesign.warmChalk.opacity(0.1))
            .overlay {
                RoundedRectangle(
                    cornerRadius: GifJotDesign.controlRadius,
                    style: .continuous
                )
                .stroke(GifJotDesign.warmChalk.opacity(0.16))
            }
            .clipShape(
                RoundedRectangle(
                    cornerRadius: GifJotDesign.controlRadius,
                    style: .continuous
                )
            )
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
        .help("Frame size. Click to choose a preset.")
        .accessibilityLabel("Frame size, \(selectedRegionDimensions) pixels")
    }

    private var selectedRegionDimensions: String {
        guard let region = coordinator.activeRegion else { return "SELECTED" }
        let width = Int((region.sourceRect.width * region.displayScale).rounded())
        let height = Int((region.sourceRect.height * region.displayScale).rounded())
        return "\(width) × \(height)"
    }

    @ViewBuilder
    private var leadingSymbol: some View {
        switch coordinator.state {
        case .recording:
            CaptureFrameMark(
                color: GifJotDesign.signal,
                isActive: true,
                lineWidth: 1.5
            )
                .frame(width: 20, height: 20)
                .accessibilityLabel("Recording")
        case .completed:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(GifJotDesign.success)
        case .failed:
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(GifJotDesign.warning)
        default:
            ProgressView()
                .controlSize(.small)
                .tint(GifJotDesign.softPaper)
                .accessibilityLabel("Creating GIF")
        }
    }

    private var stateLabel: String {
        switch coordinator.state {
        case .countdown, .startingCapture:
            "GETTING READY"
        case .recording:
            "RECORDING"
        case .finishingCapture, .encoding, .exporting:
            "PROCESSING"
        case .completed:
            "COMPLETE"
        case .failed:
            "ATTENTION"
        default:
            "GIFJOT"
        }
    }

    private var primaryText: String {
        switch coordinator.state {
        case .countdown:
            "Starting in \(coordinator.countdownSecondsRemaining ?? 1)"
        case .startingCapture:
            "Starting recording..."
        case .recording:
            "Recording"
        case .finishingCapture:
            "Finishing capture…"
        case .encoding:
            "Creating GIF…"
        case .exporting:
            "Saving…"
        case .completed:
            coordinator.warningMessage ?? "Saved and copied"
        case .failed:
            coordinator.errorMessage ?? "Recording failed"
        default:
            coordinator.statusText
        }
    }

    private var elapsedTime: String {
        let minutes = coordinator.elapsedSeconds / 60
        let seconds = coordinator.elapsedSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
