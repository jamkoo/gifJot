import Foundation

enum RecordingState: String, CaseIterable, Hashable, Sendable {
    case idle
    case requestingPermission
    case selectingRegion
    case readyToRecord
    case countdown
    case startingCapture
    case recording
    case finishingCapture
    case encoding
    case exporting
    case completed
    case canceled
    case failed
}

enum RecordingTransitionError: Error, Equatable, LocalizedError, Sendable {
    case invalidTransition(from: RecordingState, to: RecordingState)

    var errorDescription: String? {
        switch self {
        case let .invalidTransition(from, to):
            return "Cannot transition from \(from.rawValue) to \(to.rawValue)."
        }
    }
}

struct RecordingStateMachine: Sendable {
    private(set) var state: RecordingState

    init(initialState: RecordingState = .idle) {
        state = initialState
    }

    mutating func transition(to newState: RecordingState) throws {
        guard Self.allowedTransitions[state, default: []].contains(newState) else {
            throw RecordingTransitionError.invalidTransition(from: state, to: newState)
        }

        state = newState
    }

    private static let allowedTransitions: [RecordingState: Set<RecordingState>] = [
        .idle: [.requestingPermission, .selectingRegion],
        .requestingPermission: [.selectingRegion, .canceled, .failed],
        .selectingRegion: [.readyToRecord, .canceled, .failed],
        .readyToRecord: [.countdown, .startingCapture, .canceled, .failed],
        .countdown: [.startingCapture, .canceled, .failed],
        .startingCapture: [.recording, .canceled, .failed],
        .recording: [.finishingCapture, .canceled, .failed],
        .finishingCapture: [.encoding, .canceled, .failed],
        .encoding: [.exporting, .canceled, .failed],
        .exporting: [.completed, .canceled, .failed],
        .completed: [.idle],
        .canceled: [.idle],
        .failed: [.idle],
    ]
}
