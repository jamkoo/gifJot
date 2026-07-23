import AppKit
import CoreGraphics

@MainActor
final class RegionSelectionService {
    private var activeWindows: [RegionSelectionWindow] = []
    private var continuation: CheckedContinuation<CaptureRegion?, Never>?

    func selectRegion(maximumOutputWidth: Int? = nil) async -> CaptureRegion? {
        guard continuation == nil else { return nil }

        let screens = NSScreen.screens.compactMap { screen -> (NSScreen, CGDirectDisplayID)? in
            guard let number = screen.deviceDescription[
                NSDeviceDescriptionKey("NSScreenNumber")
            ] as? NSNumber else {
                return nil
            }

            return (screen, CGDirectDisplayID(number.uint32Value))
        }

        guard !screens.isEmpty else { return nil }

        return await withCheckedContinuation { continuation in
            self.continuation = continuation
            self.activeWindows = screens.map { screen, displayID in
                RegionSelectionWindow(
                    screen: screen,
                    displayID: displayID,
                    maximumOutputWidth: maximumOutputWidth,
                    onSelection: { [weak self] region in
                        self?.finish(with: region)
                    },
                    onCancel: { [weak self] in
                        self?.finish(with: nil)
                    }
                )
            }

            NSApplication.shared.activate(ignoringOtherApps: true)
            for window in activeWindows {
                window.orderFrontRegardless()
            }
            activeWindows.first?.makeKey()
        }
    }

    func cancelSelection() {
        finish(with: nil)
    }

    private func finish(with region: CaptureRegion?) {
        guard let continuation else { return }

        self.continuation = nil
        activeWindows.forEach { $0.orderOut(nil) }
        activeWindows.removeAll()
        continuation.resume(returning: region)
    }
}

private final class RegionSelectionWindow: NSWindow {
    override var canBecomeKey: Bool { true }

    init(
        screen: NSScreen,
        displayID: CGDirectDisplayID,
        maximumOutputWidth: Int?,
        onSelection: @escaping (CaptureRegion) -> Void,
        onCancel: @escaping () -> Void
    ) {
        super.init(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        level = .screenSaver
        backgroundColor = .clear
        isOpaque = false
        hasShadow = false
        ignoresMouseEvents = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        contentView = RegionSelectionView(
            displayID: displayID,
            displayScale: screen.backingScaleFactor,
            maximumOutputWidth: maximumOutputWidth,
            onSelection: onSelection,
            onCancel: onCancel
        )
    }
}

private final class RegionSelectionView: NSView {
    private let displayID: CGDirectDisplayID
    private let displayScale: CGFloat
    private let maximumOutputWidth: Int?
    private let onSelection: (CaptureRegion) -> Void
    private let onCancel: () -> Void

    private var dragStart: CGPoint?
    private var selectionRect: CGRect? {
        didSet {
            updateAccessibilityValue()
        }
    }

    override var acceptsFirstResponder: Bool { true }
    override var isOpaque: Bool { false }

    init(
        displayID: CGDirectDisplayID,
        displayScale: CGFloat,
        maximumOutputWidth: Int?,
        onSelection: @escaping (CaptureRegion) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.displayID = displayID
        self.displayScale = displayScale
        self.maximumOutputWidth = maximumOutputWidth
        self.onSelection = onSelection
        self.onCancel = onCancel
        super.init(frame: .zero)

        setAccessibilityElement(true)
        setAccessibilityRole(.group)
        setAccessibilityLabel("Screen selection")
        setAccessibilityHelp(
            "Drag to select an area. Arrow keys move it. "
                + "Option-arrow resizes it. Return confirms and Escape cancels."
        )
        setAccessibilityCustomActions([
            NSAccessibilityCustomAction(
                name: "Create centered area",
                handler: { [weak self] in
                    guard let self else { return false }
                    if self.ensureKeyboardSelection() {
                        self.announceAccessibilityValue()
                    }
                    return true
                }
            ),
            NSAccessibilityCustomAction(
                name: "Confirm area",
                handler: { [weak self] in
                    self?.confirmCurrentSelection()
                    return self != nil
                }
            ),
            accessibilityAction(name: "Move left") { view in
                view.moveKeyboardSelection(dx: -10, dy: 0)
            },
            accessibilityAction(name: "Move right") { view in
                view.moveKeyboardSelection(dx: 10, dy: 0)
            },
            accessibilityAction(name: "Move up") { view in
                view.moveKeyboardSelection(dx: 0, dy: 10)
            },
            accessibilityAction(name: "Move down") { view in
                view.moveKeyboardSelection(dx: 0, dy: -10)
            },
            accessibilityAction(name: "Make wider") { view in
                view.resizeKeyboardSelection(width: 20, height: 0)
            },
            accessibilityAction(name: "Make narrower") { view in
                view.resizeKeyboardSelection(width: -20, height: 0)
            },
            accessibilityAction(name: "Make taller") { view in
                view.resizeKeyboardSelection(width: 0, height: 20)
            },
            accessibilityAction(name: "Make shorter") { view in
                view.resizeKeyboardSelection(width: 0, height: -20)
            },
        ])
        updateAccessibilityValue()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        window?.makeFirstResponder(self)
    }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .crosshair)
    }

    override func mouseDown(with event: NSEvent) {
        window?.makeKey()
        window?.makeFirstResponder(self)

        let point = clamped(convert(event.locationInWindow, from: nil))
        dragStart = point
        selectionRect = nil
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        guard let dragStart else { return }

        selectionRect = RegionSelectionGeometry.clampedAppKitRect(
            from: dragStart,
            to: clamped(convert(event.locationInWindow, from: nil)),
            within: bounds
        )
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        guard let dragStart else { return }
        defer { self.dragStart = nil }

        let selection = RegionSelectionGeometry.clampedAppKitRect(
            from: dragStart,
            to: clamped(convert(event.locationInWindow, from: nil)),
            within: bounds
        )

        guard let selection else {
            selectionRect = nil
            needsDisplay = true
            return
        }

        confirm(selection)
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 {
            onCancel()
            return
        }

        if event.keyCode == 36 || event.keyCode == 76 {
            ensureKeyboardSelection()
            confirmCurrentSelection()
            return
        }

        let step: CGFloat = event.modifierFlags.contains(.shift) ? 10 : 1
        let isResizing = event.modifierFlags.contains(.option)
        switch event.keyCode {
        case 123:
            isResizing
                ? resizeKeyboardSelection(width: -step, height: 0)
                : moveKeyboardSelection(dx: -step, dy: 0)
        case 124:
            isResizing
                ? resizeKeyboardSelection(width: step, height: 0)
                : moveKeyboardSelection(dx: step, dy: 0)
        case 125:
            isResizing
                ? resizeKeyboardSelection(width: 0, height: -step)
                : moveKeyboardSelection(dx: 0, dy: -step)
        case 126:
            isResizing
                ? resizeKeyboardSelection(width: 0, height: step)
                : moveKeyboardSelection(dx: 0, dy: step)
        default:
            super.keyDown(with: event)
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let dimPath = NSBezierPath(rect: bounds)
        if let selectionRect {
            dimPath.appendRect(selectionRect)
            dimPath.windingRule = .evenOdd
        }

        NSColor.black.withAlphaComponent(0.42).setFill()
        dimPath.fill()

        guard let selectionRect else {
            drawInstruction()
            return
        }

        let lineWidth = max(1.0 / max(displayScale, 1), 1)

        NSColor.white.withAlphaComponent(0.88).setStroke()
        let contrastBorder = NSBezierPath(
            rect: selectionRect.insetBy(
                dx: lineWidth,
                dy: lineWidth
            )
        )
        contrastBorder.lineWidth = lineWidth + 2
        contrastBorder.stroke()

        GifJotDesign.canvasIndigoNS.setStroke()
        let border = NSBezierPath(
            rect: selectionRect.insetBy(
                dx: lineWidth / 2,
                dy: lineWidth / 2
            )
        )
        border.lineWidth = lineWidth
        border.stroke()

        drawCornerHandles(for: selectionRect)
        drawSizeLabel(for: selectionRect)
    }

    private func clamped(_ point: CGPoint) -> CGPoint {
        CGPoint(
            x: min(max(point.x, bounds.minX), bounds.maxX),
            y: min(max(point.y, bounds.minY), bounds.maxY)
        )
    }

    @discardableResult
    private func ensureKeyboardSelection() -> Bool {
        guard selectionRect == nil,
              bounds.width >= RegionSelectionGeometry.minimumSelectionLength,
              bounds.height >= RegionSelectionGeometry.minimumSelectionLength
        else {
            return false
        }

        let width = min(640, max(
            RegionSelectionGeometry.minimumSelectionLength,
            bounds.width * 0.62
        ))
        let height = min(360, max(
            RegionSelectionGeometry.minimumSelectionLength,
            bounds.height * 0.62
        ))
        selectionRect = CGRect(
            x: bounds.midX - width / 2,
            y: bounds.midY - height / 2,
            width: width,
            height: height
        ).intersection(bounds)
        needsDisplay = true
        return true
    }

    private func moveKeyboardSelection(dx: CGFloat, dy: CGFloat) {
        ensureKeyboardSelection()
        guard let selectionRect else { return }

        let origin = CGPoint(
            x: min(
                max(selectionRect.minX + dx, bounds.minX),
                bounds.maxX - selectionRect.width
            ),
            y: min(
                max(selectionRect.minY + dy, bounds.minY),
                bounds.maxY - selectionRect.height
            )
        )
        self.selectionRect = CGRect(origin: origin, size: selectionRect.size)
        needsDisplay = true
        announceAccessibilityValue()
    }

    private func resizeKeyboardSelection(width: CGFloat, height: CGFloat) {
        ensureKeyboardSelection()
        guard let selectionRect else { return }

        let size = CGSize(
            width: min(
                max(
                    selectionRect.width + width,
                    RegionSelectionGeometry.minimumSelectionLength
                ),
                bounds.width
            ),
            height: min(
                max(
                    selectionRect.height + height,
                    RegionSelectionGeometry.minimumSelectionLength
                ),
                bounds.height
            )
        )
        let centered = CGRect(
            x: selectionRect.midX - size.width / 2,
            y: selectionRect.midY - size.height / 2,
            width: size.width,
            height: size.height
        )
        let origin = CGPoint(
            x: min(
                max(centered.minX, bounds.minX),
                bounds.maxX - size.width
            ),
            y: min(
                max(centered.minY, bounds.minY),
                bounds.maxY - size.height
            )
        )
        self.selectionRect = CGRect(origin: origin, size: size)
        needsDisplay = true
        announceAccessibilityValue()
    }

    private func confirmCurrentSelection() {
        guard let selectionRect else { return }
        confirm(selectionRect)
    }

    private func confirm(_ selection: CGRect) {
        guard let sourceRect = RegionSelectionGeometry.sourceRect(
            fromLocalAppKitRect: selection,
            displaySize: bounds.size
        ) else {
            return
        }

        onSelection(
            CaptureRegion(
                displayID: displayID,
                sourceRect: sourceRect,
                displayScale: displayScale
            )
        )
    }

    private func outputDimensions(for rect: CGRect) -> OutputDimensions {
        OutputDimensionsCalculator.calculate(
            sourceSizeInPoints: rect.size,
            displayScale: displayScale,
            maximumWidth: maximumOutputWidth
        )
    }

    private func updateAccessibilityValue() {
        guard let selectionRect else {
            setAccessibilityValue("No area selected")
            return
        }

        let dimensions = outputDimensions(for: selectionRect)
        setAccessibilityValue(
            "GIF output \(dimensions.width) by \(dimensions.height) pixels"
        )
    }

    private func announceAccessibilityValue() {
        guard window != nil else { return }
        NSAccessibility.post(element: self, notification: .valueChanged)
    }

    private func accessibilityAction(
        name: String,
        perform: @escaping (RegionSelectionView) -> Void
    ) -> NSAccessibilityCustomAction {
        NSAccessibilityCustomAction(name: name) { [weak self] in
            guard let self else { return false }
            perform(self)
            return true
        }
    }

    private func drawInstruction() {
        let text = "Drag to select an area  ·  Esc to cancel"
        drawBadge(
            text,
            centeredAt: CGPoint(x: bounds.midX, y: bounds.midY),
            font: .systemFont(ofSize: 13, weight: .semibold)
        )
    }

    private func drawSizeLabel(for rect: CGRect) {
        let dimensions = outputDimensions(for: rect)
        let center = CGPoint(x: rect.midX, y: max(rect.minY - 24, 18))
        drawMeasurementBadge(
            "\(dimensions.width) × \(dimensions.height) px",
            centeredAt: center
        )
    }

    private func drawCornerHandles(for rect: CGRect) {
        guard rect.width >= 12, rect.height >= 12 else { return }

        let size: CGFloat = 7
        let centers = [
            CGPoint(x: rect.minX, y: rect.minY),
            CGPoint(x: rect.maxX, y: rect.minY),
            CGPoint(x: rect.minX, y: rect.maxY),
            CGPoint(x: rect.maxX, y: rect.maxY),
        ]

        for center in centers {
            let handleRect = CGRect(
                x: center.x - size / 2,
                y: center.y - size / 2,
                width: size,
                height: size
            )
            GifJotDesign.canvasIndigoNS.setFill()
            NSBezierPath(
                roundedRect: handleRect,
                xRadius: 1.5,
                yRadius: 1.5
            ).fill()

            NSColor.white.withAlphaComponent(0.92).setStroke()
            let outline = NSBezierPath(
                roundedRect: handleRect.insetBy(dx: 0.5, dy: 0.5),
                xRadius: 1,
                yRadius: 1
            )
            outline.lineWidth = 1
            outline.stroke()
        }
    }

    private func drawMeasurementBadge(
        _ text: String,
        centeredAt center: CGPoint
    ) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 12, weight: .semibold),
            .foregroundColor: NSColor.labelColor,
        ]
        let attributed = NSAttributedString(string: text, attributes: attributes)
        let textSize = attributed.size()
        let badgeRect = CGRect(
            x: center.x - (textSize.width + 30) / 2,
            y: center.y - textSize.height / 2 - 6,
            width: textSize.width + 30,
            height: textSize.height + 12
        )

        NSGraphicsContext.current?.saveGraphicsState()
        let shadow = NSShadow()
        shadow.shadowBlurRadius = 8
        shadow.shadowOffset = CGSize(width: 0, height: -2)
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.18)
        shadow.set()
        NSColor.windowBackgroundColor.withAlphaComponent(0.96).setFill()
        NSBezierPath(roundedRect: badgeRect, xRadius: 8, yRadius: 8).fill()
        NSGraphicsContext.current?.restoreGraphicsState()

        GifJotDesign.canvasIndigoNS.setFill()
        NSBezierPath(
            roundedRect: CGRect(
                x: badgeRect.minX + 9,
                y: badgeRect.midY - 3,
                width: 6,
                height: 6
            ),
            xRadius: 1.5,
            yRadius: 1.5
        ).fill()

        attributed.draw(at: CGPoint(
            x: badgeRect.minX + 21,
            y: badgeRect.minY + 6
        ))
    }

    private func drawBadge(
        _ text: String,
        centeredAt center: CGPoint,
        font: NSFont
    ) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.labelColor,
        ]
        let attributed = NSAttributedString(string: text, attributes: attributes)
        let textSize = attributed.size()
        let badgeRect = CGRect(
            x: center.x - textSize.width / 2 - 10,
            y: center.y - textSize.height / 2 - 6,
            width: textSize.width + 20,
            height: textSize.height + 12
        )

        NSGraphicsContext.current?.saveGraphicsState()
        let shadow = NSShadow()
        shadow.shadowBlurRadius = 10
        shadow.shadowOffset = CGSize(width: 0, height: -2)
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.18)
        shadow.set()
        NSColor.windowBackgroundColor.withAlphaComponent(0.96).setFill()
        NSBezierPath(roundedRect: badgeRect, xRadius: 10, yRadius: 10).fill()
        NSGraphicsContext.current?.restoreGraphicsState()
        attributed.draw(at: CGPoint(
            x: badgeRect.minX + 10,
            y: badgeRect.minY + 6
        ))
    }
}
