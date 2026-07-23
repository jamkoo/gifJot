import AppKit
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
                    storageSection
                    privacyNotice
                }
                .padding(20)
            }

            Divider()

            footer
        }
        .frame(width: 520, height: 620)
        .background(GifJotDesign.opticalBody)
        .tint(GifJotDesign.signal)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 14) {
            CaptureFrameMark(
                color: GifJotDesign.signal,
                lineWidth: 2
            )
            .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 3) {
                Text("GIFJOT / CAMERA SETUP")
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .tracking(0.8)
                    .foregroundStyle(.secondary)

                Text("Capture defaults")
                    .font(.system(size: 20, weight: .semibold))

                Text("Set the starting point once. The shutter flow stays immediate.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(20)
    }

    private var recordingSection: some View {
        SettingsSection(
            index: "01",
            title: "Recording",
            detail: "Balanced is a clear, compact starting point for product demos and documentation."
        ) {
            SettingsRow(title: "Preset") {
                Picker("Preset", selection: $settings.qualityPreset) {
                    ForEach(QualityPreset.allCases) { preset in
                        Text(preset.displayName)
                            .tag(preset)
                            .disabled(preset == .custom)
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
            index: "02",
            title: "Behavior",
            detail: "The shortcut works globally without requesting Accessibility access."
        ) {
            SettingsRow(title: "Shortcut") {
                GifJotKeycap(text: "⌥⌘G")
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

    private var storageSection: some View {
        SettingsSection(
            index: "03",
            title: "Storage",
            detail: "Recordings stay in the folder you choose."
        ) {
            HStack(spacing: 12) {
                Image(systemName: "folder")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(GifJotDesign.signal)
                    .frame(width: 22)

                VStack(alignment: .leading, spacing: 3) {
                    Text("Save recordings to")
                        .font(.system(size: 11, weight: .semibold))

                    Text(settings.outputDirectoryDisplayPath)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .help(settings.outputDirectoryURL.path)
                }

                Spacer(minLength: 12)

                Button("Choose…") {
                    chooseOutputDirectory()
                }
                .accessibilityHint("Selects the folder used for future GIF recordings.")
            }
            .padding(.horizontal, 12)
            .frame(minHeight: 54)
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
        .padding(.vertical, 14)
        .overlay(alignment: .top) {
            Divider()
        }
        .overlay(alignment: .bottom) {
            Divider()
        }
    }

    private var footer: some View {
        HStack {
            Text("Changes apply to your next recording.")
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

    private func chooseOutputDirectory() {
        let panel = NSOpenPanel()
        panel.title = "Choose Recording Folder"
        panel.message = "GifJot will save future GIF recordings in this folder."
        panel.prompt = "Choose"
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false

        var isDirectory: ObjCBool = false
        if FileManager.default.fileExists(
            atPath: settings.outputDirectoryURL.path,
            isDirectory: &isDirectory
        ), isDirectory.boolValue {
            panel.directoryURL = settings.outputDirectoryURL
        } else {
            panel.directoryURL = settings.outputDirectoryURL.deletingLastPathComponent()
        }

        guard panel.runModal() == .OK, let selectedURL = panel.url else {
            return
        }
        settings.setOutputDirectory(selectedURL)
    }
}

private struct SettingsSection<Content: View>: View {
    let index: String
    let title: String
    let detail: String
    let content: Content

    init(
        index: String,
        title: String,
        detail: String,
        @ViewBuilder content: () -> Content
    ) {
        self.index = index
        self.title = title
        self.detail = detail
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(index)
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(GifJotDesign.signal)

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 13, weight: .semibold))

                    Text(detail)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
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
                .font(.system(size: 11, weight: .semibold))

            Spacer()

            control
        }
        .padding(.horizontal, 12)
        .frame(minHeight: 40)
        .overlay(alignment: .bottom) {
            Divider()
                .padding(.leading, 12)
        }
    }
}

@MainActor
final class SettingsWindowController: NSWindowController {
    init(settings: SettingsStore) {
        let hostingController = NSHostingController(
            rootView: SettingsView(settings: settings)
        )
        let window = NSWindow(
            contentRect: CGRect(origin: .zero, size: CGSize(width: 520, height: 620)),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "GifJot Settings"
        window.contentViewController = hostingController
        window.isReleasedWhenClosed = false
        window.collectionBehavior = [.moveToActiveSpace]
        window.setContentSize(CGSize(width: 520, height: 620))

        super.init(window: window)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is unavailable")
    }

    func present() {
        NSApplication.shared.activate(ignoringOtherApps: true)
        showWindow(nil)
        window?.center()
        window?.makeKeyAndOrderFront(nil)
    }
}
