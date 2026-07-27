import Carbon
import Foundation

@MainActor
final class HotKeyManager {
    var action: (() -> Void)?
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?

    init() {
        installHandler()
        registerDefault()
    }

    deinit {
        if let hotKeyRef { UnregisterEventHotKey(hotKeyRef) }
        if let eventHandler { RemoveEventHandler(eventHandler) }
    }

    private func installHandler() {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let pointer = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(GetApplicationEventTarget(), { _, _, userData in
            guard let userData else { return noErr }
            let manager = Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue()
            Task { @MainActor in manager.action?() }
            return noErr
        }, 1, &eventType, pointer, &eventHandler)
    }

    private func registerDefault() {
        let identifier = EventHotKeyID(signature: OSType(0x4E4F5857), id: 1)
        RegisterEventHotKey(UInt32(kVK_ANSI_D), UInt32(optionKey | cmdKey), identifier, GetApplicationEventTarget(), 0, &hotKeyRef)
    }
}
