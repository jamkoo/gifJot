import AppKit
import Combine
import QuartzCore
import SwiftUI

/*
 DIRECTION CONTRACT
 THESIS: GifJot is a contextual canvas tool for capturing product work, not camera hardware.
 OWN-WORLD: Neutral adaptive macOS materials, Canvas Indigo selection and actions, Recording Red only during live capture.
 STORY: Select an area, adjust it directly, confirm the exact size, record, then receive a paste-ready local GIF.
 FIRST VIEWPORT: The frame, four corner grips, readable dimensions, More, and Record are immediately findable; one temporary coach teaches movement and resizing.
 FORM: Approved A+C composition—an inspector attached above or below the frame with progressive disclosure. Canva, Figma, and Loom are craft references only; no editor, cloud, audio, or webcam.
 */

enum RecordingHUDPlacement {
    static let gap: CGFloat = 6
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

enum RecordingHUDWindowLevels {
    static let selectionFrame = NSWindow.Level.floating
    static let inspector = NSWindow.Level(
        rawValue: selectionFrame.rawValue + 1
    )
}

enum RecordingHUDMetrics {
    static let panelSize = CGSize(width: 310, height: 50)
    static let controlHeight: CGFloat = 36
    static let verticalInset: CGFloat = 7
    static let readyHorizontalInset: CGFloat = 7
    static let compactHorizontalInset: CGFloat = 12
    static let statusSymbolWidth: CGFloat = 16
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
    private static let panelSize = RecordingHUDMetrics.panelSize
    private static let breathingRoomOutputPixels = 16
    private static let frameCoachDefaultsKey = "captureFrame.didLearnAdjustment"

    private let coordinator: RecordingCoordinator
    private let settings: SettingsStore
    private var panel: NSPanel?
    private var selectionBorderWindow: NSPanel?
    private var subscriptions: Set<AnyCancellable> = []
    private var delayedHideTask: Task<Void, Never>?
    private var appWindowSuspensionTask: Task<Void, Never>?
    private var isSuspendedForAppWindow = false

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
            // @Published emits from willSet. Deliver on the next main-queue turn so
            // SwiftUI reads the stored state instead of the preceding one when the
            // HUD is first created for a completed selection.
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state, region in
                self?.update(for: state, region: region)
            }
            .store(in: &subscriptions)

        [
            NSWindow.didBecomeKeyNotification,
            NSWindow.didResignKeyNotification,
            NSWindow.willCloseNotification,
            NSWindow.didMiniaturizeNotification,
            NSWindow.didDeminiaturizeNotification,
        ].forEach { notificationName in
            NotificationCenter.default.publisher(for: notificationName)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] _ in
                    // Window notifications can arrive before AppKit updates
                    // isVisible. Re-evaluate on the following main-queue turn.
                    DispatchQueue.main.async {
                        self?.refreshAppWindowSuspension()
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        self?.refreshAppWindowSuspension()
                    }
                }
                .store(in: &subscriptions)
        }
    }

    func stop() {
        delayedHideTask?.cancel()
        delayedHideTask = nil
        appWindowSuspensionTask?.cancel()
        appWindowSuspensionTask = nil
        subscriptions.removeAll()
        isSuspendedForAppWindow = false
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

        guard !isSuspendedForAppWindow else {
            hideSelectionBorder()
            hide()
            return
        }

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
        let panelSize = Self.panelSize
        panel.setContentSize(panelSize)
        position(panel, near: region, panelSize: panelSize)

        guard !panel.isVisible else { return }

        if NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
            panel.alphaValue = 1
            panel.orderFrontRegardless()
            if state == .readyToRecord {
                panel.makeKey()
            }
            return
        }

        panel.alphaValue = 0
        panel.orderFrontRegardless()
        if state == .readyToRecord {
            panel.makeKey()
        }
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
            borderView.outputDimensions = OutputDimensionsCalculator.calculate(
                sourceSizeInPoints: region.sourceRect.size,
                displayScale: region.displayScale,
                maximumWidth: settings.maximumOutputWidth.pixels
            )
            borderView.showsCoach = isDraggable
                && !UserDefaults.standard.bool(
                    forKey: Self.frameCoachDefaultsKey
                )
            borderView.needsDisplay = true
        }
        borderWindow.orderFrontRegardless()
    }

    private func hideSelectionBorder() {
        selectionBorderWindow?.orderOut(nil)
    }

    private func refreshAppWindowSuspension() {
        let shouldSuspend = hasActiveAppWindow()
        if shouldSuspend {
            scheduleAppWindowSuspensionRefresh()
        } else {
            appWindowSuspensionTask?.cancel()
            appWindowSuspensionTask = nil
        }

        guard shouldSuspend != isSuspendedForAppWindow else { return }

        isSuspendedForAppWindow = shouldSuspend
        if shouldSuspend {
            hideSelectionBorder()
            hide()
        } else {
            update(
                for: coordinator.state,
                region: coordinator.activeRegion
            )
        }
    }

    private func hasActiveAppWindow() -> Bool {
        NSApplication.shared.windows.contains { window in
            window.isVisible
                && (window.isKeyWindow || window.isMainWindow)
                && window !== panel
                && window !== selectionBorderWindow
        }
    }

    private func scheduleAppWindowSuspensionRefresh() {
        guard appWindowSuspensionTask == nil else { return }

        appWindowSuspensionTask = Task { [weak self] in
            while !Task.isCancelled {
                do {
                    try await ContinuousClock().sleep(
                        for: .milliseconds(250)
                    )
                } catch {
                    return
                }

                guard let self else { return }
                guard self.hasActiveAppWindow() else {
                    self.appWindowSuspensionTask = nil
                    self.refreshAppWindowSuspension()
                    return
                }
            }
        }
    }

    private func makePanelIfNeeded() -> NSPanel {
        if let panel { return panel }

        let rootView = RecordingHUDView(
            coordinator: coordinator,
            settings: settings,
            onApplyFramePreset: { [weak self] preset in
                self?.applyFramePreset(preset)
            },
            breathingRoomOutputPixels: Self.breathingRoomOutputPixels,
            onAddBreathingRoom: { [weak self] in
                self?.addBreathingRoom()
            },
            onAdjustFrame: { [weak self] adjustment, delta in
                self?.adjustSelectedRegion(
                    adjustment,
                    byAppKitDelta: delta
                )
            }
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        let hostingController = NSHostingController(rootView: rootView)
        let panel = InteractiveRecordingHUDPanel(
            contentRect: CGRect(
                origin: .zero,
                size: Self.panelSize
            ),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        panel.contentViewController = hostingController
        panel.level = RecordingHUDWindowLevels.inspector
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
        panel.level = RecordingHUDWindowLevels.selectionFrame
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

        if !UserDefaults.standard.bool(forKey: Self.frameCoachDefaultsKey) {
            UserDefaults.standard.set(
                true,
                forKey: Self.frameCoachDefaultsKey
            )
            if let borderView = selectionBorderWindow?.contentView
                as? RecordingBorderView
            {
                borderView.showsCoach = false
            }
        }

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

    private func addBreathingRoom() {
        guard coordinator.state == .readyToRecord,
              let region = coordinator.activeRegion,
              let screen = screen(for: region)
        else {
            return
        }

        let sourceRect = RegionSelectionGeometry.sourceRect(
            addingOutputPadding: Self.breathingRoomOutputPixels,
            to: region.sourceRect,
            displayScale: region.displayScale,
            maximumOutputWidth: settings.maximumOutputWidth.pixels,
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

private enum CaptureFrameAdjustment: Equatable {
    case move
    case resize(RegionSelectionResizeHandle)
}

private final class RecordingBorderView: NSView {
    private enum Metrics {
        static let resizeHitTarget: CGFloat = 20
        static let handleSize: CGFloat = 7
        static let highlightedHandleSize: CGFloat = 10
        static let coachHeight: CGFloat = 30
        static let coachInset: CGFloat = 12
        static let coachHorizontalPadding: CGFloat = 11
    }

    private static let selectionColor = GifJotDesign.canvasIndigoNS
    private let onAdjust: (CaptureFrameAdjustment, CGPoint) -> Void
    private var lastMouseLocation: CGPoint?
    private var activeAdjustment: CaptureFrameAdjustment?
    private var hoveredAdjustment: CaptureFrameAdjustment?
    private var pointerTrackingArea: NSTrackingArea?

    var displayScale: CGFloat = 1
    var outputDimensions: OutputDimensions? {
        didSet {
            guard outputDimensions != oldValue else { return }
            updateAccessibilityValue()
        }
    }
    var showsCoach = false {
        didSet {
            guard showsCoach != oldValue else { return }
            needsDisplay = true
        }
    }
    var isAdjustable = false {
        didSet {
            if !isAdjustable {
                hoveredAdjustment = nil
                activeAdjustment = nil
            }
            toolTip = isAdjustable
                ? "Drag inside to move. Drag an edge or corner to resize."
                : nil
            refreshPointerTrackingArea()
            window?.invalidateCursorRects(for: self)
            needsDisplay = true
        }
    }

    override var acceptsFirstResponder: Bool { true }
    override var isOpaque: Bool { false }

    init(onAdjust: @escaping (CaptureFrameAdjustment, CGPoint) -> Void) {
        self.onAdjust = onAdjust
        super.init(frame: .zero)
        setAccessibilityElement(true)
        setAccessibilityRole(.group)
        setAccessibilityLabel("Selected recording region")
        setAccessibilityHelp(
            "Drag inside the frame to move it. Drag a handle to resize it. "
                + "Arrow keys move; Option-arrow resizes."
        )
        setAccessibilityCustomActions([
            accessibilityAction(name: "Move left") { view in
                view.onAdjust(.move, CGPoint(x: -10, y: 0))
            },
            accessibilityAction(name: "Move right") { view in
                view.onAdjust(.move, CGPoint(x: 10, y: 0))
            },
            accessibilityAction(name: "Move up") { view in
                view.onAdjust(.move, CGPoint(x: 0, y: 10))
            },
            accessibilityAction(name: "Move down") { view in
                view.onAdjust(.move, CGPoint(x: 0, y: -10))
            },
            accessibilityAction(name: "Make wider") { view in
                view.onAdjust(.resize(.east), CGPoint(x: 10, y: 0))
            },
            accessibilityAction(name: "Make narrower") { view in
                view.onAdjust(.resize(.east), CGPoint(x: -10, y: 0))
            },
            accessibilityAction(name: "Make taller") { view in
                view.onAdjust(.resize(.north), CGPoint(x: 0, y: 10))
            },
            accessibilityAction(name: "Make shorter") { view in
                view.onAdjust(.resize(.north), CGPoint(x: 0, y: -10))
            },
        ])
        updateAccessibilityValue()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        refreshPointerTrackingArea()
    }

    private func refreshPointerTrackingArea() {
        if let pointerTrackingArea {
            removeTrackingArea(pointerTrackingArea)
        }
        guard isAdjustable else {
            pointerTrackingArea = nil
            return
        }

        let trackingArea = NSTrackingArea(
            rect: bounds,
            options: [
                .activeAlways,
                .inVisibleRect,
                .mouseEnteredAndExited,
                .mouseMoved,
            ],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingArea)
        pointerTrackingArea = trackingArea
    }

    override func resetCursorRects() {
        guard isAdjustable else { return }

        let edgeLength = min(
            Metrics.resizeHitTarget,
            min(bounds.width, bounds.height) / 2
        )
        let cornerSize = edgeLength
        let horizontalSpan = max(0, bounds.width - cornerSize * 2)
        let verticalSpan = max(0, bounds.height - cornerSize * 2)

        let moveRect = bounds.insetBy(dx: edgeLength, dy: edgeLength)
        if moveRect.width > 0, moveRect.height > 0 {
            addCursorRect(moveRect, cursor: .openHand)
        }
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
            cursor: Self.diagonalResizeCursor(
                symbolName: "arrow.up.left.and.arrow.down.right"
            )
        )
        addCursorRect(
            CGRect(x: bounds.maxX - cornerSize, y: 0, width: cornerSize, height: cornerSize),
            cursor: Self.diagonalResizeCursor(
                symbolName: "arrow.up.right.and.arrow.down.left"
            )
        )
        addCursorRect(
            CGRect(x: 0, y: bounds.maxY - cornerSize, width: cornerSize, height: cornerSize),
            cursor: Self.diagonalResizeCursor(
                symbolName: "arrow.up.right.and.arrow.down.left"
            )
        )
        addCursorRect(
            CGRect(
                x: bounds.maxX - cornerSize,
                y: bounds.maxY - cornerSize,
                width: cornerSize,
                height: cornerSize
            ),
            cursor: Self.diagonalResizeCursor(
                symbolName: "arrow.up.left.and.arrow.down.right"
            )
        )
    }

    override func mouseMoved(with event: NSEvent) {
        guard isAdjustable else { return }
        let adjustment = adjustment(
            at: convert(event.locationInWindow, from: nil)
        )
        guard adjustment != hoveredAdjustment else { return }
        hoveredAdjustment = adjustment
        needsDisplay = true
    }

    override func mouseExited(with event: NSEvent) {
        hoveredAdjustment = nil
        needsDisplay = true
    }

    override func mouseDown(with event: NSEvent) {
        guard isAdjustable else {
            super.mouseDown(with: event)
            return
        }

        window?.makeFirstResponder(self)
        lastMouseLocation = NSEvent.mouseLocation
        activeAdjustment = adjustment(at: convert(event.locationInWindow, from: nil))
        if case .some(.move) = activeAdjustment {
            NSCursor.closedHand.set()
        }
        needsDisplay = true
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
            needsDisplay = true
        }
        super.mouseUp(with: event)
    }

    private func adjustment(at point: CGPoint) -> CaptureFrameAdjustment {
        let edgeLength = min(
            Metrics.resizeHitTarget,
            min(bounds.width, bounds.height) / 2
        )
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

        let lineWidth = max(1.0 / max(displayScale, 1), 1)
        NSColor.white.withAlphaComponent(0.88).setStroke()
        let contrastPath = NSBezierPath(
            rect: bounds.insetBy(dx: lineWidth, dy: lineWidth)
        )
        contrastPath.lineWidth = lineWidth + 2
        contrastPath.stroke()

        Self.selectionColor.setStroke()
        let path = NSBezierPath(
            rect: bounds.insetBy(dx: lineWidth / 2, dy: lineWidth / 2)
        )
        path.lineWidth = lineWidth
        path.stroke()

        guard isAdjustable else { return }

        drawResizeHandles()
        if showsCoach {
            drawCoach()
        }
    }

    private func drawResizeHandles() {
        guard bounds.width >= Metrics.highlightedHandleSize + 4,
              bounds.height >= Metrics.highlightedHandleSize + 4
        else {
            return
        }

        let inset = Metrics.highlightedHandleSize / 2
        var descriptors: [(CGPoint, CaptureFrameAdjustment)] = [
            (
                CGPoint(x: inset, y: inset),
                .resize(.southWest)
            ),
            (
                CGPoint(x: bounds.maxX - inset, y: inset),
                .resize(.southEast)
            ),
            (
                CGPoint(x: inset, y: bounds.maxY - inset),
                .resize(.northWest)
            ),
            (
                CGPoint(x: bounds.maxX - inset, y: bounds.maxY - inset),
                .resize(.northEast)
            ),
        ]

        if bounds.width >= 72,
           hoveredAdjustment == .resize(.south)
            || activeAdjustment == .resize(.south)
        {
            descriptors.append(
                (CGPoint(x: bounds.midX, y: inset), .resize(.south))
            )
        }
        if bounds.width >= 72,
           hoveredAdjustment == .resize(.north)
            || activeAdjustment == .resize(.north)
        {
            descriptors.append(
                (CGPoint(x: bounds.midX, y: bounds.maxY - inset), .resize(.north))
            )
        }
        if bounds.height >= 72,
           hoveredAdjustment == .resize(.west)
            || activeAdjustment == .resize(.west)
        {
            descriptors.append(
                (CGPoint(x: inset, y: bounds.midY), .resize(.west))
            )
        }
        if bounds.height >= 72,
           hoveredAdjustment == .resize(.east)
            || activeAdjustment == .resize(.east)
        {
            descriptors.append(
                (CGPoint(x: bounds.maxX - inset, y: bounds.midY), .resize(.east))
            )
        }

        for (center, adjustment) in descriptors {
            let highlighted = activeAdjustment == adjustment
                || hoveredAdjustment == adjustment
            let size = highlighted
                ? Metrics.highlightedHandleSize
                : Metrics.handleSize
            let handleRect = CGRect(
                x: center.x - size / 2,
                y: center.y - size / 2,
                width: size,
                height: size
            )

            Self.selectionColor.setFill()
            let handle = NSBezierPath(
                roundedRect: handleRect,
                xRadius: highlighted ? 2 : 1.5,
                yRadius: highlighted ? 2 : 1.5
            )
            handle.fill()

            NSColor.white.withAlphaComponent(0.92).setStroke()
            let outline = NSBezierPath(
                roundedRect: handleRect.insetBy(dx: 0.5, dy: 0.5),
                xRadius: highlighted ? 1.5 : 1,
                yRadius: highlighted ? 1.5 : 1
            )
            outline.lineWidth = 1
            outline.stroke()
        }
    }

    private func drawCoach() {
        let text = "Drag inside to move  ·  Pull a corner to resize"
        let font = NSFont.systemFont(ofSize: 11, weight: .medium)
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.labelColor,
            .paragraphStyle: paragraph,
        ]
        let measured = (text as NSString).size(withAttributes: attributes)
        let width = min(
            measured.width + Metrics.coachHorizontalPadding * 2,
            bounds.width - Metrics.coachInset * 2
        )
        guard width >= 180,
              bounds.height >= Metrics.coachHeight + Metrics.coachInset * 2
        else {
            return
        }

        let coachRect = CGRect(
            x: Metrics.coachInset,
            y: bounds.maxY - Metrics.coachInset - Metrics.coachHeight,
            width: width,
            height: Metrics.coachHeight
        )
        let shadow = NSShadow()
        shadow.shadowBlurRadius = 8
        shadow.shadowOffset = CGSize(width: 0, height: -2)
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.18)
        shadow.set()

        NSColor.windowBackgroundColor.withAlphaComponent(0.96).setFill()
        NSBezierPath(
            roundedRect: coachRect,
            xRadius: 8,
            yRadius: 8
        ).fill()

        NSGraphicsContext.current?.saveGraphicsState()
        NSShadow().set()
        let textRect = CGRect(
            x: coachRect.minX + Metrics.coachHorizontalPadding,
            y: coachRect.midY - measured.height / 2,
            width: coachRect.width - Metrics.coachHorizontalPadding * 2,
            height: measured.height
        )
        (text as NSString).draw(in: textRect, withAttributes: attributes)
        NSGraphicsContext.current?.restoreGraphicsState()
    }

    private static func diagonalResizeCursor(symbolName: String) -> NSCursor {
        guard let image = NSImage(
            systemSymbolName: symbolName,
            accessibilityDescription: "Resize"
        )?.withSymbolConfiguration(
            NSImage.SymbolConfiguration(pointSize: 15, weight: .medium)
        ) else {
            return .crosshair
        }
        image.size = CGSize(width: 18, height: 18)
        return NSCursor(
            image: image,
            hotSpot: CGPoint(x: image.size.width / 2, y: image.size.height / 2)
        )
    }

    private func updateAccessibilityValue() {
        guard let outputDimensions else {
            setAccessibilityValue("No frame size")
            return
        }

        setAccessibilityValue(
            "GIF output \(outputDimensions.width) by "
                + "\(outputDimensions.height) pixels"
        )
    }

    private func accessibilityAction(
        name: String,
        perform: @escaping (RecordingBorderView) -> Void
    ) -> NSAccessibilityCustomAction {
        NSAccessibilityCustomAction(name: name) { [weak self] in
            guard let self, self.isAdjustable else { return false }
            perform(self)
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                NSAccessibility.post(
                    element: self,
                    notification: .valueChanged
                )
            }
            return true
        }
    }
}

private struct RegionReadyRecordButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(Color.white)
            .frame(width: 86, height: 36)
            .background(
                RoundedRectangle(
                    cornerRadius: GifJotDesign.controlRadius,
                    style: .continuous
                ).fill(
                    configuration.isPressed
                        ? GifJotDesign.pressedIndigo
                        : GifJotDesign.canvasIndigo
                )
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: GifJotDesign.controlRadius,
                    style: .continuous
                )
                    .stroke(Color.white.opacity(0.12))
            }
            .opacity(isEnabled ? 1 : 0.48)
            .animation(
                .timingCurve(0.16, 1, 0.3, 1, duration: 0.14),
                value: configuration.isPressed
            )
    }
}

private struct RegionReadyIconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(Color.primary)
            .frame(width: 36, height: 36)
            .background(
                RoundedRectangle(
                    cornerRadius: GifJotDesign.controlRadius,
                    style: .continuous
                )
                .fill(
                    configuration.isPressed
                        ? GifJotDesign.indigoTint
                        : GifJotDesign.hudControl
                )
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: GifJotDesign.controlRadius,
                    style: .continuous
                )
                .stroke(GifJotDesign.hudHairline)
            }
    }
}

@MainActor
private struct RecordingHUDView: View {
    @ObservedObject var coordinator: RecordingCoordinator
    @ObservedObject var settings: SettingsStore
    let onApplyFramePreset: (CaptureFramePreset) -> Void
    let breathingRoomOutputPixels: Int
    let onAddBreathingRoom: () -> Void
    let onAdjustFrame: (CaptureFrameAdjustment, CGPoint) -> Void

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
            coordinator.state == .readyToRecord
                ? RecordingHUDMetrics.readyHorizontalInset
                : RecordingHUDMetrics.compactHorizontalInset
        )
        .padding(.vertical, RecordingHUDMetrics.verticalInset)
        .background(GifJotDesign.hudSurface)
        .overlay {
            RoundedRectangle(
                cornerRadius: GifJotDesign.panelRadius,
                style: .continuous
            )
            .stroke(GifJotDesign.hudHairline)
        }
        .clipShape(
            RoundedRectangle(
                cornerRadius: GifJotDesign.panelRadius,
                style: .continuous
            )
        )
        .onMoveCommand(perform: moveFrame)
        .onExitCommand {
            if coordinator.state == .readyToRecord {
                coordinator.cancelPendingRecording()
            }
        }
    }

    private var compactControls: some View {
        HStack(spacing: 10) {
            leadingSymbol
                .frame(
                    width: RecordingHUDMetrics.statusSymbolWidth,
                    height: RecordingHUDMetrics.controlHeight
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(primaryText)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.primary)
                    .lineLimit(1)

                if coordinator.state == .recording {
                    Text(elapsedTime)
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .monospacedDigit()
                        .foregroundStyle(Color.secondary)
                }
            }
            .layoutPriority(1)

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
        .frame(height: RecordingHUDMetrics.controlHeight)
    }

    private var setupControls: some View {
        HStack(spacing: 6) {
            frameSizeMenu

            Menu {
                Toggle(
                    "Show cursor",
                    isOn: $settings.includeCursor
                )

                Menu("Countdown: \(settings.countdown.displayName)") {
                    ForEach(RecordingCountdown.allCases) { countdown in
                        Button {
                            settings.countdown = countdown
                        } label: {
                            if settings.countdown == countdown {
                                Label(
                                    countdown.displayName,
                                    systemImage: "checkmark"
                                )
                            } else {
                                Text(countdown.displayName)
                            }
                        }
                    }
                }

                Divider()

                Button {
                    coordinator.cancelPendingRecording()
                } label: {
                    Label("Cancel selection", systemImage: "xmark")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .accessibilityLabel("More recording options")
            }
            .buttonStyle(RegionReadyIconButtonStyle())
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .help("Cursor, countdown, and cancel")
            .accessibilityHint(
                "Shows cursor, countdown, and cancel options"
            )

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

    private var frameSizeMenu: some View {
        Menu {
            Section("Frame preset") {
                ForEach(CaptureFramePreset.allCases) { preset in
                    Button(preset.displayName) {
                        onApplyFramePreset(preset)
                    }
                }
            }

            Section("Frame spacing") {
                Button {
                    onAddBreathingRoom()
                } label: {
                    Label(
                        "Add \(breathingRoomOutputPixels) px breathing room",
                        systemImage: "arrow.up.left.and.arrow.down.right"
                    )
                }
            }
        } label: {
            HStack(spacing: 6) {
                Text(selectedRegionDimensions)
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .monospacedDigit()
                    .lineLimit(1)

                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(Color.secondary)
                    .accessibilityHidden(true)
            }
            .foregroundStyle(Color.primary)
            .padding(.horizontal, 10)
            .frame(height: 36)
            .background(
                RoundedRectangle(
                    cornerRadius: GifJotDesign.controlRadius,
                    style: .continuous
                )
                .fill(GifJotDesign.hudControl)
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: GifJotDesign.controlRadius,
                    style: .continuous
                )
                .stroke(GifJotDesign.hudHairline)
            }
            .clipShape(
                RoundedRectangle(
                    cornerRadius: GifJotDesign.controlRadius,
                    style: .continuous
                )
            )
            .contentShape(Rectangle())
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .tint(GifJotDesign.canvasIndigo)
        .fixedSize()
        .help(
            "GIF output size · choose a preset or add breathing room · "
                + "arrow keys move · Option-arrow resizes"
        )
        .accessibilityLabel("GIF output size, \(selectedRegionDimensions)")
        .accessibilityHint(
            "Choose a frame preset or add 16 pixels around the selected content"
        )
    }

    private var selectedRegionDimensions: String {
        guard let region = coordinator.activeRegion else { return "SELECTED" }
        let output = OutputDimensionsCalculator.calculate(
            sourceSizeInPoints: region.sourceRect.size,
            displayScale: region.displayScale,
            maximumWidth: settings.maximumOutputWidth.pixels
        )
        return "\(output.width) × \(output.height) px"
    }

    private func moveFrame(_ direction: MoveCommandDirection) {
        let step: CGFloat = NSEvent.modifierFlags.contains(.shift) ? 10 : 1
        let isResizing = NSEvent.modifierFlags.contains(.option)

        if isResizing {
            switch direction {
            case .left:
                onAdjustFrame(.resize(.east), CGPoint(x: -step, y: 0))
            case .right:
                onAdjustFrame(.resize(.east), CGPoint(x: step, y: 0))
            case .up:
                onAdjustFrame(.resize(.north), CGPoint(x: 0, y: step))
            case .down:
                onAdjustFrame(.resize(.north), CGPoint(x: 0, y: -step))
            @unknown default:
                break
            }
            return
        }

        switch direction {
        case .left:
            onAdjustFrame(.move, CGPoint(x: -step, y: 0))
        case .right:
            onAdjustFrame(.move, CGPoint(x: step, y: 0))
        case .up:
            onAdjustFrame(.move, CGPoint(x: 0, y: step))
        case .down:
            onAdjustFrame(.move, CGPoint(x: 0, y: -step))
        @unknown default:
            break
        }
    }

    @ViewBuilder
    private var leadingSymbol: some View {
        switch coordinator.state {
        case .recording:
            Circle()
                .fill(GifJotDesign.recordingRed)
                .frame(width: 9, height: 9)
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
                .tint(GifJotDesign.canvasIndigo)
                .accessibilityLabel("Creating GIF")
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
