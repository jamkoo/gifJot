import XCTest
@testable import GifJot

final class RecordingStateMachineTests: XCTestCase {
    func testFullRecordingFlowReturnsToIdle() throws {
        var machine = RecordingStateMachine()

        try machine.transition(to: .requestingPermission)
        try machine.transition(to: .selectingRegion)
        try machine.transition(to: .readyToRecord)
        try machine.transition(to: .countdown)
        try machine.transition(to: .startingCapture)
        try machine.transition(to: .recording)
        try machine.transition(to: .finishingCapture)
        try machine.transition(to: .encoding)
        try machine.transition(to: .exporting)
        try machine.transition(to: .completed)
        try machine.transition(to: .idle)

        XCTAssertEqual(machine.state, .idle)
    }

    func testArmedSelectionCanSkipCountdownWhileStillShowingCaptureStartup() throws {
        var machine = RecordingStateMachine(initialState: .readyToRecord)

        try machine.transition(to: .startingCapture)
        try machine.transition(to: .recording)

        XCTAssertEqual(machine.state, .recording)
    }

    func testActiveStatesCanFail() throws {
        let activeStates: [RecordingState] = [
            .requestingPermission,
            .selectingRegion,
            .readyToRecord,
            .countdown,
            .startingCapture,
            .recording,
            .finishingCapture,
            .encoding,
            .exporting,
        ]

        for state in activeStates {
            var machine = RecordingStateMachine(initialState: state)
            try machine.transition(to: .failed)
            XCTAssertEqual(machine.state, .failed)
        }
    }

    func testActiveStatesCanCancel() throws {
        let activeStates: [RecordingState] = [
            .requestingPermission,
            .selectingRegion,
            .readyToRecord,
            .countdown,
            .startingCapture,
            .recording,
            .finishingCapture,
            .encoding,
            .exporting,
        ]

        for state in activeStates {
            var machine = RecordingStateMachine(initialState: state)
            try machine.transition(to: .canceled)
            XCTAssertEqual(machine.state, .canceled)
        }
    }

    func testInvalidTransitionLeavesStateUnchanged() {
        var machine = RecordingStateMachine()

        XCTAssertThrowsError(try machine.transition(to: .recording)) { error in
            XCTAssertEqual(
                error as? RecordingTransitionError,
                .invalidTransition(from: .idle, to: .recording)
            )
        }
        XCTAssertEqual(machine.state, .idle)
    }

    func testSelectionCannotStartCaptureBeforeItIsArmed() throws {
        var machine = RecordingStateMachine(initialState: .selectingRegion)

        XCTAssertThrowsError(try machine.transition(to: .countdown))
        XCTAssertThrowsError(try machine.transition(to: .startingCapture))
        XCTAssertEqual(machine.state, .selectingRegion)

        try machine.transition(to: .readyToRecord)
        XCTAssertEqual(machine.state, .readyToRecord)
    }

    func testTerminalStatesCanReturnToIdle() throws {
        for state in [RecordingState.completed, .canceled, .failed] {
            var machine = RecordingStateMachine(initialState: state)
            try machine.transition(to: .idle)
            XCTAssertEqual(machine.state, .idle)
        }
    }
}
