import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: SettingsStore

    var body: some View {
        Form {
            Section("Recording Defaults") {
                Picker("Preset", selection: $settings.qualityPreset) {
                    ForEach(QualityPreset.allCases) { preset in
                        Text(preset.displayName).tag(preset)
                    }
                }

                Picker("Maximum width", selection: $settings.maximumOutputWidth) {
                    ForEach(MaximumOutputWidth.allCases) { width in
                        Text(width.displayName).tag(width)
                    }
                }

                Picker("Frame rate", selection: $settings.framesPerSecond) {
                    ForEach(RecordingFrameRate.allCases) { frameRate in
                        Text(frameRate.displayName).tag(frameRate)
                    }
                }

                Picker("Countdown", selection: $settings.countdown) {
                    ForEach(RecordingCountdown.allCases) { countdown in
                        Text(countdown.displayName).tag(countdown)
                    }
                }

                Toggle("Include cursor", isOn: $settings.includeCursor)
                Toggle("Copy after recording", isOn: $settings.copyAfterRecording)
            }

            Section("Privacy") {
                Label {
                    Text("Recordings stay on this Mac. GifJot has no accounts, uploads, or telemetry.")
                        .foregroundStyle(.secondary)
                } icon: {
                    Image(systemName: "lock.shield")
                }
            }

            HStack {
                Spacer()
                Button("Restore Defaults") {
                    settings.restoreDefaults()
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 440, height: 410)
    }
}
