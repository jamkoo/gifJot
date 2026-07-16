import CoreGraphics
import XCTest
@testable import GifJot

final class OutputDimensionsTests: XCTestCase {
    func testUsesNativeRetinaSizeWhenBelowMaximum() {
        let output = OutputDimensionsCalculator.calculate(
            sourceSizeInPoints: CGSize(width: 320, height: 180),
            displayScale: 2,
            maximumWidth: 960
        )

        XCTAssertEqual(output, OutputDimensions(width: 640, height: 360))
    }

    func testLimitsWidthAndPreservesAspectRatio() {
        let output = OutputDimensionsCalculator.calculate(
            sourceSizeInPoints: CGSize(width: 800, height: 450),
            displayScale: 2,
            maximumWidth: 960
        )

        XCTAssertEqual(output, OutputDimensions(width: 960, height: 540))
    }

    func testOriginalWidthKeepsNativeSize() {
        let output = OutputDimensionsCalculator.calculate(
            sourceSizeInPoints: CGSize(width: 800, height: 450),
            displayScale: 2,
            maximumWidth: nil
        )

        XCTAssertEqual(output, OutputDimensions(width: 1_600, height: 900))
    }
}
