import Foundation
import XCTest
@testable import GifJot

final class RecordingStreamStateTests: XCTestCase {
    func testFirstUnexpectedStopIsReportedOnce() {
        let state = RecordingStreamState()
        let error = TestError.streamEnded

        XCTAssertTrue(state.recordUnexpectedStop(error))
        XCTAssertFalse(state.recordUnexpectedStop(error))
        XCTAssertEqual(
            state.unexpectedErrorDescription(),
            error.localizedDescription
        )
    }

    func testExpectedStopDoesNotReportFailure() {
        let state = RecordingStreamState()
        state.markStopping()

        XCTAssertFalse(state.recordUnexpectedStop(TestError.streamEnded))
        XCTAssertNil(state.unexpectedErrorDescription())
    }

    private enum TestError: Error {
        case streamEnded
    }
}
