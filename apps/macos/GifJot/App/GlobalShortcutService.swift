import Carbon
import Combine
import Foundation

private let gifJotHotKeySignature: OSType = 0x474A4F54 // GJOT

private func handleGifJotHotKey(
    _ nextHandler: EventHandlerCallRef?,
    _ event: EventRef?,
    _ userData: UnsafeMutableRawPointer?
) -> OSStatus {
    guard let userData else { return OSStatus(eventNotHandledErr) }

    let service = Unmanaged<GlobalShortcutService>
        .fromOpaque(userData)
        .takeUnretainedValue()
    Task { @MainActor in
        service.invoke()
    }
    return noErr
}

@MainActor
final class GlobalShortcutService: ObservableObject {
    @Published private(set) var isRegistered = false

    static let displayName = "⌥⌘G"

    private var hotKeyReference: EventHotKeyRef?
    private var eventHandlerReference: EventHandlerRef?
    private var action: (() -> Void)?

    @discardableResult
    func start(action: @escaping () -> Void) -> Bool {
        stop()
        self.action = action

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        let handlerStatus = InstallEventHandler(
            GetApplicationEventTarget(),
            handleGifJotHotKey,
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandlerReference
        )
        guard handlerStatus == noErr else {
            self.action = nil
            return false
        }

        let hotKeyID = EventHotKeyID(
            signature: gifJotHotKeySignature,
            id: 1
        )
        let modifiers = UInt32(cmdKey) | UInt32(optionKey)
        let registrationStatus = RegisterEventHotKey(
            UInt32(kVK_ANSI_G),
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyReference
        )
        guard registrationStatus == noErr else {
            stop()
            return false
        }

        isRegistered = true
        return true
    }

    func stop() {
        if let hotKeyReference {
            UnregisterEventHotKey(hotKeyReference)
            self.hotKeyReference = nil
        }
        if let eventHandlerReference {
            RemoveEventHandler(eventHandlerReference)
            self.eventHandlerReference = nil
        }
        action = nil
        isRegistered = false
    }

    fileprivate func invoke() {
        action?()
    }
}
