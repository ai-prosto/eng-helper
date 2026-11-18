import Carbon.HIToolbox
import os

/// System-wide Option+Shift+D through Carbon's `RegisterEventHotKey`
/// (design D-06): it fires no matter which app is frontmost (BEH-21)
/// and, unlike a CGEvent tap, needs no permission of its own.
@MainActor
final class HotKeyMonitor {
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private let handler: () -> Void

    init(handler: @escaping () -> Void) {
        self.handler = handler

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        // A C callback cannot capture; `self` travels as userData and
        // the dispatcher target delivers on the main thread.
        let installStatus = InstallEventHandler(
            GetEventDispatcherTarget(),
            { _, _, userData in
                guard let userData else { return noErr }
                let monitor = Unmanaged<HotKeyMonitor>
                    .fromOpaque(userData)
                    .takeUnretainedValue()
                MainActor.assumeIsolated {
                    monitor.handler()
                }
                return noErr
            },
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandler
        )

        let hotKeyID = EventHotKeyID(signature: Self.signature, id: 1)
        let registerStatus = RegisterEventHotKey(
            UInt32(kVK_ANSI_D),
            UInt32(optionKey | shiftKey),
            hotKeyID,
            GetEventDispatcherTarget(),
            0,
            &hotKeyRef
        )
        // A conflict (another app owns Option+Shift+D) would otherwise
        // leave the hotkey silently dead.
        if installStatus != noErr || registerStatus != noErr {
            Logger(subsystem: "EngHelper", category: "hotkey").error(
                "Hotkey registration failed: install=\(installStatus), register=\(registerStatus)"
            )
        }
    }

    deinit {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
        }
        if let eventHandler {
            RemoveEventHandler(eventHandler)
        }
    }

    private static let signature: OSType = {
        var value: OSType = 0
        for scalar in "EngH".unicodeScalars {
            value = (value << 8) + OSType(scalar.value)
        }
        return value
    }()
}
