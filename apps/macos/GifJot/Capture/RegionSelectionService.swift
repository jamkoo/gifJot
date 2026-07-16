import AppKit
import CoreGraphics

@MainActor
final class RegionSelectionService {
    private var activeWindows: [RegionSelectionWindow] = []
    private var continuation: CheckedContinuation<CaptureRegion?, Never>?

    func selectRegion() async -> CaptureRegion? {
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
        onSelection: @escaping (CaptureRegion) -> Void,
        onCancel: @escaping () -> Void
    ) {
        super.init(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false,
            screen: screen
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
            onSelection: onSelection,
            onCancel: onCancel
        )
    }
}

private final class RegionSelectionView: NSView {
    private let displayID: CGDirectDisplayID
    private let displayScale: CGFloat
    private let onSelection: (CaptureRegion) -> Void
    private let onCancel: () -> Void

    private var dragStart: CGPoint?
    private var selectionRect: CGRect?

    override var acceptsFirstResponder: Bool { true }
    override var isOpaque: Bool { false }

    init(
        displayID: CGDirectDisplayID,
        displayScale: CGFloat,
        onSelection: @escaping (CaptureRegion) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.displayID = displayID
        self.displayScale = displayScale
        self.onSelection = onSelection
        self.onCancel = onCancel
        super.init(frame: .zero)
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

        guard let selection,
              let sourceRect = RegionSelectionGeometry.sourceRect(
                  fromLocalAppKitRect: selection,
                  displaySize: bounds.size
              )
        else {
            selectionRect = nil
            needsDisplay = true
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

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 {
            onCancel()
        } else {
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

        let lineWidth = 1.0 / max(displayScale, 1)
        NSColor(
            red: 217.0 / 255.0,
            green: 74.0 / 255.0,
            blue: 54.0 / 255.0,
            alpha: 1
        ).setStroke()
        let border = NSBezierPath(
            rect: selectionRect.insetBy(
                dx: lineWidth / 2,
                dy: lineWidth / 2
            )
        )
        border.lineWidth = lineWidth
        border.stroke()

        drawSizeLabel(for: selectionRect)
    }

    private func clamped(_ point: CGPoint) -> CGPoint {
        CGPoint(
            x: min(max(point.x, bounds.minX), bounds.maxX),
            y: min(max(point.y, bounds.minY), bounds.maxY)
        )
    }

    private func drawInstruction() {
        let text = "Drag to record an area  •  Esc to cancel"
        drawBadge(
            text,
            centeredAt: CGPoint(x: bounds.midX, y: bounds.midY),
            font: .systemFont(ofSize: 13, weight: .medium)
        )
    }

    private func drawSizeLabel(for rect: CGRect) {
        let pixelWidth = Int((rect.width * displayScale).rounded())
        let pixelHeight = Int((rect.height * displayScale).rounded())
        let center = CGPoint(x: rect.midX, y: max(rect.minY - 24, 18))
        drawBadge(
            "\(pixelWidth) × \(pixelHeight)",
            centeredAt: center,
            font: .monospacedSystemFont(ofSize: 12, weight: .medium)
        )
    }

    private func drawBadge(
        _ text: String,
        centeredAt center: CGPoint,
        font: NSFont
    ) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor(
                red: 251.0 / 255.0,
                green: 250.0 / 255.0,
                blue: 247.0 / 255.0,
                alpha: 1
            ),
        ]
        let attributed = NSAttributedString(string: text, attributes: attributes)
        let textSize = attributed.size()
        let badgeRect = CGRect(
            x: center.x - textSize.width / 2 - 10,
            y: center.y - textSize.height / 2 - 6,
            width: textSize.width + 20,
            height: textSize.height + 12
        )

        NSColor(
            red: 34.0 / 255.0,
            green: 34.0 / 255.0,
            blue: 32.0 / 255.0,
            alpha: 0.94
        ).setFill()
        NSBezierPath(roundedRect: badgeRect, xRadius: 6, yRadius: 6).fill()
        attributed.draw(at: CGPoint(
            x: badgeRect.minX + 10,
            y: badgeRect.minY + 6
        ))
    }
}
