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

@MainActor
final class RecordingHUDController {
    private static let panelSize = CGSize(width: 278, height: 48)

    private let coordinator: RecordingCoordinator
    private var panel: NSPanel?
    private var selectionBorderWindow: NSPanel?
    private var subscriptions: Set<AnyCancellable> = []
    private var delayedHideTask: Task<Void, Never>?

    init(coordinator: RecordingCoordinator) {
        self.coordinator = coordinator
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
        case .countdown, .recording:
            present(near: region)
            presentSelectionBorder(for: region)
        case .finishingCapture, .encoding, .exporting:
            hideSelectionBorder()
            present(near: region)
        case .completed:
            hideSelectionBorder()
            present(near: region)
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
        default:
            hideSelectionBorder()
            hide()
        }
    }

    private func present(near region: CaptureRegion?) {
        let panel = makePanelIfNeeded()
        position(panel, near: region)

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

    private func presentSelectionBorder(for region: CaptureRegion?) {
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
        if let borderView = borderWindow.contentView as? RecordingBorderView {
            borderView.displayScale = region.displayScale
            borderView.needsDisplay = true
        }
        borderWindow.orderFrontRegardless()
    }

    private func hideSelectionBorder() {
        selectionBorderWindow?.orderOut(nil)
    }

    private func makePanelIfNeeded() -> NSPanel {
        if let panel { return panel }

        let rootView = RecordingHUDView(coordinator: coordinator)
            .frame(
                width: Self.panelSize.width,
                height: Self.panelSize.height
            )
        let hostingController = NSHostingController(rootView: rootView)
        let panel = NSPanel(
            contentRect: CGRect(origin: .zero, size: Self.panelSize),
            styleMask: [.borderless, .nonactivatingPanel],
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
        panel.contentView = RecordingBorderView()
        panel.level = .floating
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.hidesOnDeactivate = false
        panel.ignoresMouseEvents = true
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

    private func position(_ panel: NSPanel, near region: CaptureRegion?) {
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
            panelSize: Self.panelSize
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

private final class RecordingBorderView: NSView {
    var displayScale: CGFloat = 1

    override var isOpaque: Bool { false }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let lineWidth = 1.0 / max(displayScale, 1)
        NSColor(
            red: 217.0 / 255.0,
            green: 74.0 / 255.0,
            blue: 54.0 / 255.0,
            alpha: 1
        ).setStroke()
        let path = NSBezierPath(
            rect: bounds.insetBy(dx: lineWidth / 2, dy: lineWidth / 2)
        )
        path.lineWidth = lineWidth
        path.stroke()
    }
}

@MainActor
private struct RecordingHUDView: View {
    @ObservedObject var coordinator: RecordingCoordinator

    var body: some View {
        HStack(spacing: 10) {
            leadingSymbol

            Text(primaryText)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(GifJotDesign.softPaper)
                .lineLimit(1)

            Spacer(minLength: 4)

            if coordinator.state == .recording {
                Text(elapsedTime)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .monospacedDigit()
                    .foregroundStyle(GifJotDesign.softPaper.opacity(0.76))

                Button("Stop") {
                    coordinator.requestStop()
                }
                .buttonStyle(GifJotPrimaryButtonStyle())
                .accessibilityHint("Stops recording and creates the GIF")
            } else if coordinator.state == .completed,
                      let outputURL = coordinator.lastOutputURL
            {
                Button("Reveal") {
                    NSWorkspace.shared.activateFileViewerSelecting([outputURL])
                }
                .buttonStyle(GifJotQuietButtonStyle())
            }
        }
        .padding(.horizontal, 10)
        .background(GifJotDesign.carbon)
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

    @ViewBuilder
    private var leadingSymbol: some View {
        switch coordinator.state {
        case .recording:
            Circle()
                .fill(GifJotDesign.signal)
                .frame(width: 8, height: 8)
                .accessibilityLabel("Recording")
        case .completed:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        default:
            ProgressView()
                .controlSize(.small)
                .tint(GifJotDesign.softPaper)
                .accessibilityLabel("Creating GIF")
        }
    }

    private var primaryText: String {
        switch coordinator.state {
        case .countdown:
            "Starting in \(coordinator.countdownSecondsRemaining ?? 1)"
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
