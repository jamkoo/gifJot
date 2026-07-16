import Foundation

enum QualityPreset: String, CaseIterable, Identifiable, Sendable {
    case github
    case balanced
    case small
    case highQuality

    var id: Self { self }

    var displayName: String {
        switch self {
        case .github: "GitHub"
        case .balanced: "Balanced"
        case .small: "Small"
        case .highQuality: "High Quality"
        }
    }
}

enum MaximumOutputWidth: String, CaseIterable, Identifiable, Sendable {
    case original
    case width1280
    case width960
    case width640

    var id: Self { self }

    var pixels: Int? {
        switch self {
        case .original: nil
        case .width1280: 1_280
        case .width960: 960
        case .width640: 640
        }
    }

    var displayName: String {
        pixels.map { "\($0) px" } ?? "Original"
    }
}

enum RecordingFrameRate: Int, CaseIterable, Identifiable, Sendable {
    case fps10 = 10
    case fps15 = 15
    case fps20 = 20

    var id: Self { self }
    var displayName: String { "\(rawValue) fps" }
}

enum RecordingCountdown: Int, CaseIterable, Identifiable, Sendable {
    case off = 0
    case oneSecond = 1
    case threeSeconds = 3

    var id: Self { self }

    var displayName: String {
        switch self {
        case .off: "Off"
        case .oneSecond: "1 second"
        case .threeSeconds: "3 seconds"
        }
    }
}

struct RecordingConfiguration: Equatable, Sendable {
    let maximumOutputWidth: Int?
    let framesPerSecond: Int
    let includeCursor: Bool
    let countdownSeconds: Int
    let copyAfterRecording: Bool
}
