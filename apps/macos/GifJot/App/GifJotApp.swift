import AppKit
import SwiftUI

@main
@MainActor
struct GifJotApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
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

            PermissionStatusMenuLabel(
                permissionService: appDelegate.permissionService
            )

            Button("Screen Recording Access...") {
                appDelegate.showPermissionWindow()
            }

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

@MainActor
private struct PermissionStatusMenuLabel: View {
    @ObservedObject var permissionService: CapturePermissionService

    var body: some View {
        switch permissionService.status {
        case .notDetermined:
            Label("Screen Recording: Not Set Up", systemImage: "circle.dashed")
        case .denied:
            Label("Screen Recording: Off", systemImage: "exclamationmark.triangle")
        case .authorized:
            Label("Screen Recording: Allowed", systemImage: "checkmark.circle")
        }
    }
}
