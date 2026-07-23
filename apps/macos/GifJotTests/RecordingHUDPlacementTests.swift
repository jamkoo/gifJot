import AppKit
import CoreGraphics
import XCTest
@testable import GifJot

final class RecordingHUDPlacementTests: XCTestCase {
    func testConvertsTopLeftCaptureCoordinatesToGlobalAppKitCoordinates() {
        let result = RecordingHUDPlacement.globalSelectionRect(
            sourceRect: CGRect(x: 40, y: 100, width: 300, height: 200),
            screenFrame: CGRect(x: -1_440, y: 0, width: 1_440, height: 900)
        )

        XCTAssertEqual(
            result,
            CGRect(x: -1_400, y: 600, width: 300, height: 200)
        )
    }

    func testPlacesHUDAboveSelectionWhenSpaceIsAvailable() {
        let result = RecordingHUDPlacement.panelOrigin(
            selectionRect: CGRect(x: 200, y: 200, width: 400, height: 300),
            availableFrame: CGRect(x: 0, y: 0, width: 1_440, height: 875),
            panelSize: CGSize(width: 278, height: 48)
        )

        XCTAssertEqual(result, CGPoint(x: 261, y: 506))
    }

    func testPlacesRegionReadyControllerBesideSelection() {
        let result = RecordingHUDPlacement.panelOrigin(
            selectionRect: CGRect(x: 200, y: 200, width: 400, height: 300),
            availableFrame: CGRect(x: 0, y: 0, width: 1_440, height: 875),
            panelSize: CGSize(width: 344, height: 52)
        )

        XCTAssertEqual(result, CGPoint(x: 228, y: 506))
    }

    func testFallsBelowSelectionNearTopOfScreen() {
        let result = RecordingHUDPlacement.panelOrigin(
            selectionRect: CGRect(x: 200, y: 600, width: 400, height: 260),
            availableFrame: CGRect(x: 0, y: 0, width: 1_440, height: 875),
            panelSize: CGSize(width: 278, height: 48)
        )

        XCTAssertEqual(result, CGPoint(x: 261, y: 546))
    }

    func testParksHUDAtTopRightVisibleFrameInset() {
        let result = RecordingHUDPlacement.parkedOrigin(
            availableFrame: CGRect(
                x: -1_920,
                y: 24,
                width: 1_920,
                height: 1_056
            ),
            panelSize: CGSize(width: 310, height: 50)
        )

        XCTAssertEqual(result, CGPoint(x: -322, y: 1_018))
    }

    func testClampsHUDToAvailableHorizontalFrame() {
        let result = RecordingHUDPlacement.panelOrigin(
            selectionRect: CGRect(x: 5, y: 200, width: 40, height: 40),
            availableFrame: CGRect(x: 0, y: 0, width: 1_000, height: 700),
            panelSize: CGSize(width: 278, height: 48)
        )

        XCTAssertEqual(result.x, RecordingHUDPlacement.screenInset)
    }

    func testInspectorWindowStaysAboveTheDraggableSelectionFrame() {
        XCTAssertGreaterThan(
            RecordingHUDWindowLevels.inspector.rawValue,
            RecordingHUDWindowLevels.selectionFrame.rawValue
        )
        XCTAssertLessThan(
            RecordingHUDWindowLevels.inspector.rawValue,
            NSWindow.Level.modalPanel.rawValue
        )
    }

    func testEveryHUDStateUsesOneBalancedControlLane() {
        XCTAssertEqual(
            RecordingHUDMetrics.panelSize.height,
            RecordingHUDMetrics.controlHeight
                + RecordingHUDMetrics.verticalInset * 2
        )
        XCTAssertGreaterThanOrEqual(
            RecordingHUDMetrics.panelSize.width,
            310
        )
        XCTAssertLessThanOrEqual(
            RecordingHUDMetrics.panelSize.width,
            419
        )
        XCTAssertGreaterThanOrEqual(
            RecordingHUDMetrics.panelSize.height,
            50
        )
        XCTAssertGreaterThanOrEqual(
            RecordingHUDMetrics.statusSymbolWidth,
            16
        )
        XCTAssertGreaterThanOrEqual(
            RecordingHUDMetrics.recordButtonWidth,
            86
        )
    }

    func testHUDPreferredTextScaleHasStableBounds() {
        XCTAssertEqual(
            RecordingHUDMetrics.scale(forPreferredPointSize: 10),
            1
        )
        XCTAssertEqual(
            RecordingHUDMetrics.scale(forPreferredPointSize: 13),
            1
        )
        XCTAssertEqual(
            RecordingHUDMetrics.scale(forPreferredPointSize: 17.55),
            1.35,
            accuracy: 0.0001
        )
        XCTAssertEqual(
            RecordingHUDMetrics.scale(forPreferredPointSize: 26),
            1.35
        )
    }

    func testFrameOverlayAddsGrabSpaceOutsideTheCaptureBoundary() {
        let selection = CGRect(x: 100, y: 80, width: 500, height: 320)
        let overlay = RecordingFrameInteractionGeometry.overlayRect(
            for: selection
        )

        XCTAssertEqual(
            overlay,
            CGRect(x: 86, y: 66, width: 528, height: 348)
        )
        XCTAssertEqual(
            RecordingFrameInteractionGeometry.selectionRect(
                in: CGRect(origin: .zero, size: overlay.size)
            ),
            CGRect(x: 14, y: 14, width: 500, height: 320)
        )
    }

    func testFrameCornersHaveGenerousTwoAxisGrabTargets() {
        let frame = CGRect(x: 14, y: 14, width: 500, height: 320)

        XCTAssertEqual(
            RecordingFrameInteractionGeometry.adjustment(
                at: CGPoint(x: 2, y: 2),
                in: frame
            ),
            .resize(.southWest)
        )
        XCTAssertEqual(
            RecordingFrameInteractionGeometry.adjustment(
                at: CGPoint(x: 526, y: 346),
                in: frame
            ),
            .resize(.northEast)
        )
    }

    func testFrameEdgesRemainResizableWhileInteriorPassesThrough() {
        let frame = CGRect(x: 14, y: 14, width: 500, height: 320)

        XCTAssertEqual(
            RecordingFrameInteractionGeometry.adjustment(
                at: CGPoint(x: frame.maxX + 12, y: frame.midY),
                in: frame
            ),
            .resize(.east)
        )
        XCTAssertEqual(
            RecordingFrameInteractionGeometry.adjustment(
                at: CGPoint(x: frame.midX, y: frame.maxY - 12),
                in: frame
            ),
            .resize(.north)
        )
        XCTAssertEqual(
            RecordingFrameInteractionGeometry.adjustment(
                at: CGPoint(x: frame.midX, y: frame.midY),
                in: frame
            ),
            nil
        )
    }

    func testOnlyMoveHandleRepositionsTheFrame() {
        let frame = CGRect(x: 14, y: 14, width: 500, height: 320)
        let moveHandle =
            RecordingFrameInteractionGeometry.moveHandleHitRect(in: frame)

        XCTAssertEqual(
            RecordingFrameInteractionGeometry.adjustment(
                at: CGPoint(x: moveHandle.midX, y: moveHandle.midY),
                in: frame
            ),
            .move
        )

        let moveTargets =
            RecordingFrameInteractionGeometry.interactionTargets(for: frame)
                .filter { $0.adjustment == .move }
        XCTAssertEqual(moveTargets.count, 1)
        XCTAssertEqual(moveTargets.first?.frame, moveHandle)
        XCTAssertFalse(moveHandle.contains(
            CGPoint(x: frame.midX, y: frame.midY)
        ))
    }

    func testInteractionTargetsDoNotCoverFrameCenter() {
        let frame = CGRect(x: 14, y: 14, width: 500, height: 320)
        let center = CGPoint(x: frame.midX, y: frame.midY)

        XCTAssertFalse(
            RecordingFrameInteractionGeometry.interactionTargets(for: frame)
                .contains { $0.frame.contains(center) }
        )
    }
}
