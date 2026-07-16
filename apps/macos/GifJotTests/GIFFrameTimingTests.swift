import Foundation
import XCTest
@testable import GifJot

final class GIFFrameTimingTests: XCTestCase {
    func testUsesMeasuredPresentationTimeForEachCompletedFrame() {
        let frames = GIFFrameTiming.makeFrames(
            from: [
                storedFrame(index: 0, time: 10),
                storedFrame(index: 1, time: 10.1),
                storedFrame(index: 2, time: 10.3),
            ],
            defaultDelay: 1.0 / 15.0
        )

        XCTAssertEqual(frames[0].delay, 0.1, accuracy: 0.000_001)
        XCTAssertEqual(frames[1].delay, 0.2, accuracy: 0.000_001)
        XCTAssertEqual(frames[2].delay, 1.0 / 15.0, accuracy: 0.000_001)
    }

    func testFallsBackForNonIncreasingTimestamps() {
        let frames = GIFFrameTiming.makeFrames(
            from: [
                storedFrame(index: 0, time: 10),
                storedFrame(index: 1, time: 10),
            ],
            defaultDelay: 0.05
        )

        XCTAssertEqual(frames[0].delay, 0.05)
    }

    func testLastFrameUsesRecordingEndTimestamp() {
        let frames = GIFFrameTiming.makeFrames(
            from: [storedFrame(index: 0, time: 10)],
            defaultDelay: 0.05,
            endingPresentationTime: 12.5
        )

        XCTAssertEqual(frames[0].delay, 2.5)
    }

    func testClampsVeryShortDelaysForGifPlayback() {
        let frames = GIFFrameTiming.makeFrames(
            from: [
                storedFrame(index: 0, time: 10),
                storedFrame(index: 1, time: 10.001),
            ],
            defaultDelay: 0.001
        )

        XCTAssertEqual(frames[0].delay, GIFFrameTiming.minimumDelay)
        XCTAssertEqual(frames[1].delay, GIFFrameTiming.minimumDelay)
    }

    private func storedFrame(index: Int, time: TimeInterval) -> StoredCaptureFrame {
        StoredCaptureFrame(
            fileURL: URL(fileURLWithPath: "/tmp/\(index).png"),
            presentationTime: time
        )
    }
}
