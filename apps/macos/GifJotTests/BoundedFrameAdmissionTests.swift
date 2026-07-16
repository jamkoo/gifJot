import XCTest
@testable import GifJot

final class BoundedFrameAdmissionTests: XCTestCase {
    func testRejectsFramesWhenAllSlotsArePending() {
        var admission = BoundedFrameAdmission(capacity: 2)

        XCTAssertTrue(admission.admit())
        XCTAssertTrue(admission.admit())
        XCTAssertFalse(admission.admit())
        XCTAssertEqual(admission.pendingCount, 2)
        XCTAssertEqual(admission.droppedCount, 1)
    }

    func testCompletionReleasesSlotForNextFrame() {
        var admission = BoundedFrameAdmission(capacity: 1)

        XCTAssertTrue(admission.admit())
        admission.complete()

        XCTAssertEqual(admission.pendingCount, 0)
        XCTAssertTrue(admission.admit())
    }

    func testCapacityNeverFallsBelowOne() {
        let admission = BoundedFrameAdmission(capacity: 0)

        XCTAssertEqual(admission.capacity, 1)
    }
}
