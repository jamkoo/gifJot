import CoreGraphics
import XCTest
@testable import GifJot

final class RegionSelectionGeometryTests: XCTestCase {
    func testNormalizesReverseDrag() {
        let rect = RegionSelectionGeometry.normalizedRect(
            from: CGPoint(x: 300, y: 250),
            to: CGPoint(x: 100, y: 50)
        )

        XCTAssertEqual(rect, CGRect(x: 100, y: 50, width: 200, height: 200))
    }

    func testClampsDragToOriginDisplay() {
        let rect = RegionSelectionGeometry.clampedAppKitRect(
            from: CGPoint(x: 100, y: 100),
            to: CGPoint(x: 900, y: -50),
            within: CGRect(x: 0, y: 0, width: 800, height: 600)
        )

        XCTAssertEqual(rect, CGRect(x: 100, y: 0, width: 700, height: 100))
    }

    func testRejectsClickWithoutMeaningfulDrag() {
        let rect = RegionSelectionGeometry.clampedAppKitRect(
            from: CGPoint(x: 10, y: 10),
            to: CGPoint(x: 11, y: 11),
            within: CGRect(x: 0, y: 0, width: 800, height: 600)
        )

        XCTAssertNil(rect)
    }

    func testConvertsBottomLeftAppKitRectToTopLeftSourceRect() {
        let sourceRect = RegionSelectionGeometry.sourceRect(
            fromLocalAppKitRect: CGRect(x: 100, y: 50, width: 300, height: 200),
            displaySize: CGSize(width: 800, height: 600)
        )

        XCTAssertEqual(sourceRect, CGRect(x: 100, y: 350, width: 300, height: 200))
    }

    func testConvertsSelectionOnDisplayWithNegativeGlobalOrigin() {
        let sourceRect = RegionSelectionGeometry.sourceRect(
            fromGlobalAppKitRect: CGRect(x: -1_800, y: 700, width: 640, height: 200),
            displayFrame: CGRect(x: -1_920, y: -100, width: 1_920, height: 1_080)
        )

        XCTAssertEqual(sourceRect, CGRect(x: 120, y: 80, width: 640, height: 200))
    }

    func testClampsGlobalSelectionThatCrossesDisplays() {
        let sourceRect = RegionSelectionGeometry.sourceRect(
            fromGlobalAppKitRect: CGRect(x: 700, y: 100, width: 300, height: 200),
            displayFrame: CGRect(x: 0, y: 0, width: 800, height: 600)
        )

        XCTAssertEqual(sourceRect, CGRect(x: 700, y: 300, width: 100, height: 200))
    }

    func testMovesSourceRectUsingAppKitDirectionAndKeepsItOnDisplay() {
        let moved = RegionSelectionGeometry.movedSourceRect(
            CGRect(x: 100, y: 350, width: 300, height: 200),
            byAppKitDelta: CGPoint(x: 80, y: -40),
            within: CGSize(width: 800, height: 600)
        )

        XCTAssertEqual(moved, CGRect(x: 180, y: 390, width: 300, height: 200))
    }

    func testClampsMovedSourceRectAtDisplayEdges() {
        let moved = RegionSelectionGeometry.movedSourceRect(
            CGRect(x: 100, y: 350, width: 300, height: 200),
            byAppKitDelta: CGPoint(x: 900, y: -900),
            within: CGSize(width: 800, height: 600)
        )

        XCTAssertEqual(moved, CGRect(x: 500, y: 400, width: 300, height: 200))
    }

    func testResizesFromTopLeftUsingAppKitCoordinates() {
        let resized = RegionSelectionGeometry.resizedSourceRect(
            CGRect(x: 100, y: 350, width: 300, height: 200),
            byAppKitDelta: CGPoint(x: 50, y: 30),
            handle: .northWest,
            within: CGSize(width: 800, height: 600)
        )

        XCTAssertEqual(resized, CGRect(x: 150, y: 320, width: 250, height: 230))
    }

    func testClampsResizeToMinimumSizeAndDisplayBounds() {
        let resized = RegionSelectionGeometry.resizedSourceRect(
            CGRect(x: 100, y: 350, width: 300, height: 200),
            byAppKitDelta: CGPoint(x: -900, y: -900),
            handle: .southWest,
            within: CGSize(width: 800, height: 600)
        )

        XCTAssertEqual(resized, CGRect(x: 0, y: 350, width: 400, height: 250))
    }

    func testAppliesFullScreenPresetToTheCurrentDisplay() {
        let result = RegionSelectionGeometry.sourceRect(
            applying: .fullScreen,
            to: CGRect(x: 100, y: 120, width: 300, height: 180),
            within: CGSize(width: 1_440, height: 900)
        )

        XCTAssertEqual(result, CGRect(x: 0, y: 0, width: 1_440, height: 900))
    }

    func testAppliesAspectPresetAroundTheCurrentSelectionCenter() {
        let result = RegionSelectionGeometry.sourceRect(
            applying: .widescreen,
            to: CGRect(x: 100, y: 100, width: 400, height: 400),
            within: CGSize(width: 800, height: 600)
        )

        XCTAssertEqual(result, CGRect(x: 100, y: 187.5, width: 400, height: 225))
    }
}
