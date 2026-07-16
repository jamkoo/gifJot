import Combine
import Foundation

@MainActor
final class SettingsStore: ObservableObject {
    private enum Key: String {
        case qualityPreset
        case maximumOutputWidth
        case framesPerSecond
        case includeCursor
        case countdown
        case copyAfterRecording
    }

    private let defaults: UserDefaults

    @Published var qualityPreset: QualityPreset {
        didSet { defaults.set(qualityPreset.rawValue, forKey: Key.qualityPreset.rawValue) }
    }

    @Published var maximumOutputWidth: MaximumOutputWidth {
        didSet { defaults.set(maximumOutputWidth.rawValue, forKey: Key.maximumOutputWidth.rawValue) }
    }

    @Published var framesPerSecond: RecordingFrameRate {
        didSet { defaults.set(framesPerSecond.rawValue, forKey: Key.framesPerSecond.rawValue) }
    }

    @Published var includeCursor: Bool {
        didSet { defaults.set(includeCursor, forKey: Key.includeCursor.rawValue) }
    }

    @Published var countdown: RecordingCountdown {
        didSet { defaults.set(countdown.rawValue, forKey: Key.countdown.rawValue) }
    }

    @Published var copyAfterRecording: Bool {
        didSet { defaults.set(copyAfterRecording, forKey: Key.copyAfterRecording.rawValue) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        qualityPreset = QualityPreset(
            rawValue: defaults.string(forKey: Key.qualityPreset.rawValue) ?? ""
        ) ?? .balanced

        maximumOutputWidth = MaximumOutputWidth(
            rawValue: defaults.string(forKey: Key.maximumOutputWidth.rawValue) ?? ""
        ) ?? .width960

        framesPerSecond = RecordingFrameRate(
            rawValue: Self.integerValue(
                forKey: Key.framesPerSecond.rawValue,
                defaultValue: RecordingFrameRate.fps15.rawValue,
                defaults: defaults
            )
        ) ?? .fps15

        includeCursor = Self.booleanValue(
            forKey: Key.includeCursor.rawValue,
            defaultValue: true,
            defaults: defaults
        )

        countdown = RecordingCountdown(
            rawValue: Self.integerValue(
                forKey: Key.countdown.rawValue,
                defaultValue: RecordingCountdown.oneSecond.rawValue,
                defaults: defaults
            )
        ) ?? .oneSecond

        copyAfterRecording = Self.booleanValue(
            forKey: Key.copyAfterRecording.rawValue,
            defaultValue: true,
            defaults: defaults
        )
    }

    func restoreDefaults() {
        qualityPreset = .balanced
        maximumOutputWidth = .width960
        framesPerSecond = .fps15
        includeCursor = true
        countdown = .oneSecond
        copyAfterRecording = true
    }

    private static func integerValue(
        forKey key: String,
        defaultValue: Int,
        defaults: UserDefaults
    ) -> Int {
        guard defaults.object(forKey: key) != nil else { return defaultValue }
        return defaults.integer(forKey: key)
    }

    private static func booleanValue(
        forKey key: String,
        defaultValue: Bool,
        defaults: UserDefaults
    ) -> Bool {
        guard defaults.object(forKey: key) != nil else { return defaultValue }
        return defaults.bool(forKey: key)
    }
}
