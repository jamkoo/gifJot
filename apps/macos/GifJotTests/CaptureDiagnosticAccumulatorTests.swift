import XCTest
@testable import GifJot

final class CaptureDiagnosticAccumulatorTests: XCTestCase {
    func testCompleteFramesPreserveDimensionsAndTiming() throws {
        var accumulator = CaptureDiagnosticAccumulator()
        accumulator.record(
            .complete(
                width: 1_920,
                height: 1_080,
                presentationTimeSeconds: 10
            )
        )
        accumulator.record(
            .complete(
                width: 1_920,
                height: 1_080,
                presentationTimeSeconds: 10.2
            )
        )

        let report = accumulator.makeReport(
            displayID: 7,
            configuredWidth: 1_920,
            configuredHeight: 1_080,
            requestedFramesPerSecond: 10
        )

        XCTAssertEqual(report.receivedFrames, 2)
        XCTAssertEqual(report.completeFrames, 2)
        XCTAssertEqual(report.observedWidth, 1_920)
        XCTAssertEqual(report.observedHeight, 1_080)
        XCTAssertEqual(report.firstPresentationTimeSeconds, 10)
        XCTAssertEqual(report.lastPresentationTimeSeconds, 10.2)
        let timestampSpanSeconds = try XCTUnwrap(report.timestampSpanSeconds)
        XCTAssertEqual(timestampSpanSeconds, 0.2, accuracy: 0.000_001)
        XCTAssertEqual(report.estimatedDroppedFrames, 1)
    }

    func testNonCompleteAndInvalidFramesAreCounted() {
        var accumulator = CaptureDiagnosticAccumulator()
        accumulator.record(.nonComplete)
        accumulator.record(.invalid)
        accumulator.record(
            .complete(
                width: 640,
                height: 480,
                presentationTimeSeconds: nil
            )
        )

        let report = accumulator.makeReport(
            displayID: 1,
            configuredWidth: 640,
            configuredHeight: 480,
            requestedFramesPerSecond: 15
        )

        XCTAssertEqual(report.receivedFrames, 3)
        XCTAssertEqual(report.completeFrames, 1)
        XCTAssertEqual(report.nonCompleteFrames, 1)
        XCTAssertEqual(report.invalidFrames, 1)
        XCTAssertNil(report.firstPresentationTimeSeconds)
        XCTAssertNil(report.lastPresentationTimeSeconds)
        XCTAssertNil(report.timestampSpanSeconds)
        XCTAssertEqual(report.estimatedDroppedFrames, 1)
    }
}
