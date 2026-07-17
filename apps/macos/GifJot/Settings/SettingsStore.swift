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
    private var isSynchronizingPreset = false

    @Published var qualityPreset: QualityPreset {
        didSet {
            defaults.set(qualityPreset.rawValue, forKey: Key.qualityPreset.rawValue)
            applyPresetIfNeeded()
        }
    }

    @Published var maximumOutputWidth: MaximumOutputWidth {
        didSet {
            defaults.set(maximumOutputWidth.rawValue, forKey: Key.maximumOutputWidth.rawValue)
            synchronizePresetWithRecordingOptions()
        }
    }

    @Published var framesPerSecond: RecordingFrameRate {
        didSet {
            defaults.set(framesPerSecond.rawValue, forKey: Key.framesPerSecond.rawValue)
            synchronizePresetWithRecordingOptions()
        }
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

        synchronizePresetWithRecordingOptions()
    }

    func restoreDefaults() {
        qualityPreset = .balanced
        maximumOutputWidth = .width960
        framesPerSecond = .fps15
        includeCursor = true
        countdown = .oneSecond
        copyAfterRecording = true
    }

    func recordingConfiguration() -> RecordingConfiguration {
        RecordingConfiguration(
            maximumOutputWidth: maximumOutputWidth.pixels,
            framesPerSecond: framesPerSecond.rawValue,
            includeCursor: includeCursor,
            countdownSeconds: countdown.rawValue,
            copyAfterRecording: copyAfterRecording
        )
    }

    private func applyPresetIfNeeded() {
        guard !isSynchronizingPreset,
              let width = qualityPreset.maximumOutputWidth,
              let frameRate = qualityPreset.frameRate
        else {
            return
        }

        isSynchronizingPreset = true
        maximumOutputWidth = width
        framesPerSecond = frameRate
        isSynchronizingPreset = false
    }

    private func synchronizePresetWithRecordingOptions() {
        guard !isSynchronizingPreset else { return }

        let matchingPreset = QualityPreset.matching(
            maximumOutputWidth: maximumOutputWidth,
            frameRate: framesPerSecond
        )
        guard qualityPreset != matchingPreset else { return }

        isSynchronizingPreset = true
        qualityPreset = matchingPreset
        isSynchronizingPreset = false
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
