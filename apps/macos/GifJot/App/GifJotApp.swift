import AppKit
import SwiftUI

@main
struct GifJotApp: App {
    @StateObject private var settings: SettingsStore

    init() {
        _settings = StateObject(wrappedValue: SettingsStore())
    }

    var body: some Scene {
        MenuBarExtra("GifJot", systemImage: "record.circle") {
            Button("Record GIF") {}
                .disabled(true)
                .help("Screen capture is not implemented yet.")

            Divider()

            Text("Ready")

            Divider()

            SettingsLink {
                Text("Settings...")
            }

            Button("About GifJot") {
                showAboutPanel()
            }

            Divider()

            Button("Quit GifJot") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        .menuBarExtraStyle(.menu)

        Settings {
            SettingsView(settings: settings)
        }
    }

    private func showAboutPanel() {
        NSApplication.shared.orderFrontStandardAboutPanel(options: [
            .applicationName: "GifJot",
            .applicationVersion: "0.1.0",
            .credits: NSAttributedString(
                string: "Free, local-only GIF screen recording."
            ),
        ])
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
}
