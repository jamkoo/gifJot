import SwiftUI

@MainActor
struct SettingsView: View {
    @ObservedObject var settings: SettingsStore

    var body: some View {
        VStack(spacing: 0) {
            header

            Divider()

            ScrollView {
                VStack(spacing: 20) {
                    recordingSection
                    behaviorSection
                    privacyNotice
                }
                .padding(20)
            }

            Divider()

            footer
        }
        .frame(width: 500, height: 520)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: "record.circle")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(GifJotDesign.signal)
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 3) {
                Text("GifJot Settings")
                    .font(.system(size: 20, weight: .semibold))

                Text("Set the defaults used for each new recording.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(20)
    }

    private var recordingSection: some View {
        SettingsSection(
            title: "Recording",
            detail: "Balanced is a clear, compact starting point for product demos and documentation."
        ) {
            SettingsRow(title: "Preset") {
                Picker("Preset", selection: $settings.qualityPreset) {
                    ForEach(QualityPreset.allCases) { preset in
                        Text(preset.displayName).tag(preset)
                    }
                }
                .labelsHidden()
                .frame(width: 156)
            }

            SettingsRow(title: "Maximum width") {
                Picker("Maximum width", selection: $settings.maximumOutputWidth) {
                    ForEach(MaximumOutputWidth.allCases) { width in
                        Text(width.displayName).tag(width)
                    }
                }
                .labelsHidden()
                .frame(width: 156)
            }

            SettingsRow(title: "Frame rate") {
                Picker("Frame rate", selection: $settings.framesPerSecond) {
                    ForEach(RecordingFrameRate.allCases) { frameRate in
                        Text(frameRate.displayName).tag(frameRate)
                    }
                }
                .labelsHidden()
                .frame(width: 156)
            }

            SettingsRow(title: "Countdown") {
                Picker("Countdown", selection: $settings.countdown) {
                    ForEach(RecordingCountdown.allCases) { countdown in
                        Text(countdown.displayName).tag(countdown)
                    }
                }
                .labelsHidden()
                .frame(width: 156)
            }
        }
    }

    private var behaviorSection: some View {
        SettingsSection(
            title: "Behavior",
            detail: "The shortcut works globally without requesting Accessibility access."
        ) {
            SettingsRow(title: "Shortcut") {
                Text("⌥⌘G")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .padding(.horizontal, 9)
                    .frame(height: 26)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .overlay {
                        RoundedRectangle(
                            cornerRadius: GifJotDesign.controlRadius,
                            style: .continuous
                        )
                        .stroke(Color(nsColor: .separatorColor).opacity(0.72))
                    }
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: GifJotDesign.controlRadius,
                            style: .continuous
                        )
                    )
            }

            SettingsRow(title: "Include cursor") {
                Toggle("Include cursor", isOn: $settings.includeCursor)
                    .labelsHidden()
            }

            SettingsRow(title: "Copy after recording") {
                Toggle("Copy after recording", isOn: $settings.copyAfterRecording)
                    .labelsHidden()
            }
        }
    }

    private var privacyNotice: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "lock.shield")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 4) {
                Text("Private by default")
                    .font(.system(size: 13, weight: .semibold))

                Text("Recordings stay on this Mac. GifJot has no accounts, uploads, advertising, or telemetry.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .gifJotGroupSurface()
    }

    private var footer: some View {
        HStack {
            Text("GIFs save to Downloads/GifJot")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)

            Spacer()

            Button("Restore Defaults") {
                settings.restoreDefaults()
            }
            .buttonStyle(GifJotQuietButtonStyle())
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}

private struct SettingsSection<Content: View>: View {
    let title: String
    let detail: String
    let content: Content

    init(
        title: String,
        detail: String,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.detail = detail
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))

                Text(detail)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(spacing: 0) {
                content
            }
            .gifJotGroupSurface()
        }
    }
}

private struct SettingsRow<Control: View>: View {
    let title: String
    let control: Control

    init(title: String, @ViewBuilder control: () -> Control) {
        self.title = title
        self.control = control()
    }

    var body: some View {
        HStack(spacing: 16) {
            Text(title)
                .font(.system(size: 12, weight: .medium))

            Spacer()

            control
        }
        .padding(.horizontal, 12)
        .frame(minHeight: 42)
        .overlay(alignment: .bottom) {
            Divider()
                .padding(.leading, 12)
        }
    }
}
