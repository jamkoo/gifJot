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
        XCTAssertEqual(
            RecordingHUDMetrics.panelSize,
            CGSize(width: 310, height: 50)
        )
        XCTAssertEqual(RecordingHUDMetrics.statusSymbolWidth, 16)
    }
}
