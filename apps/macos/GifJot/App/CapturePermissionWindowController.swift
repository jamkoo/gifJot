import AppKit
import SwiftUI

@MainActor
final class CapturePermissionWindowController: NSWindowController {
    private let permissionService: CapturePermissionService
    private let hostingController: NSHostingController<CapturePermissionView>

    init(permissionService: CapturePermissionService) {
        self.permissionService = permissionService

        let initialView = CapturePermissionView(
            permissionService: permissionService,
            onDismiss: {}
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
            }
        )
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is unavailable")
    }

    func present() {
        permissionService.refreshStatus()
        showWindow(nil)
        window?.center()
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
}
