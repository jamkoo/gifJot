import AppKit
import SwiftUI

@MainActor
final class CapturePermissionWindowController: NSWindowController {
    private let permissionService: CapturePermissionService
    private let hostingController: NSHostingController<CapturePermissionView>

    init(
        permissionService: CapturePermissionService,
        onRestart: @escaping () -> Void,
        onStartRecording: @escaping () -> Void
    ) {
        self.permissionService = permissionService

        let initialView = CapturePermissionView(
            permissionService: permissionService,
            onDismiss: {},
            onRestart: onRestart,
            onStartRecording: {}
        )
        let hostingController = NSHostingController(rootView: initialView)
        self.hostingController = hostingController

        let window = NSWindow(contentViewController: hostingController)
        window.title = "Screen Recording Access"
        window.styleMask = [.titled, .closable]
        window.isReleasedWhenClosed = false
        window.collectionBehavior = [.moveToActiveSpace]

        super.init(window: window)

        hostingController.rootView = CapturePermissionView(
            permissionService: permissionService,
            onDismiss: { [weak self] in
                self?.close()
            },
            onRestart: onRestart,
            onStartRecording: { [weak self] in
                self?.close()
                onStartRecording()
            }
        )
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is unavailable")
    }

    func present() {
        permissionService.refreshStatus()
        NSApplication.shared.activate(ignoringOtherApps: true)
        showWindow(nil)
        window?.center()
        window?.makeKeyAndOrderFront(nil)
    }
}
