import AppKit
import ApplicationServices
import Carbon.HIToolbox
import EngHelperKit

/// Reads the frontmost app's selected text for the hotkey path
/// (design D-07): the focused element's `AXSelectedText` first, a
/// synthesized ⌘C with pasteboard restore when that attribute is
/// unavailable (many browsers and video players). Must run before
/// EngHelper activates — the selection belongs to whichever app is
/// frontmost at the keystroke.
@MainActor
enum SelectionReader {
    static func capture() -> PopoverModel.HotkeyCapture {
        // One OS prompt on first hotkey use (design D-08); until the
        // grant lands, the popover shows the hint instead.
        guard isTrusted(promptingIfNeeded: true) else {
            return .accessibilityMissing
        }
        // An AX answer — even an empty one — is authoritative: the
        // attribute exists and nothing is selected (BEH-22). Only an
        // unsupported attribute falls through to the copy path.
        let text = axSelectedText() ?? pasteboardSelectedText() ?? ""
        let word = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return word.isEmpty ? .empty : .selection(word)
    }

    private static func isTrusted(promptingIfNeeded prompt: Bool) -> Bool {
        let options = [
            kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: prompt,
        ] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    /// `kAXFocusedUIElement` → `kAXSelectedText`; nil when either
    /// attribute is unsupported, "" when supported with no selection.
    private static func axSelectedText() -> String? {
        var focused: CFTypeRef?
        guard AXUIElementCopyAttributeValue(
            AXUIElementCreateSystemWide(),
            kAXFocusedUIElementAttribute as CFString,
            &focused
        ) == .success,
            let focused,
            CFGetTypeID(focused) == AXUIElementGetTypeID()
        else { return nil }

        var selected: CFTypeRef?
        guard AXUIElementCopyAttributeValue(
            focused as! AXUIElement,
            kAXSelectedTextAttribute as CFString,
            &selected
        ) == .success,
            let text = selected as? String
        else { return nil }
        return text
    }

    /// Synthesizes ⌘C into the frontmost app, reads the general
    /// pasteboard, then restores its previous contents.
    private static func pasteboardSelectedText() -> String? {
        let pasteboard = NSPasteboard.general
        let saved = snapshot(of: pasteboard)
        let changeCount = pasteboard.changeCount
        defer { restore(saved, to: pasteboard) }

        synthesizeCopy()

        // The copy lands asynchronously in the other app; an app with
        // no selection never bumps the change count.
        let deadline = Date().addingTimeInterval(0.3)
        while pasteboard.changeCount == changeCount, Date() < deadline {
            usleep(20_000)
        }
        guard pasteboard.changeCount != changeCount else { return nil }
        return pasteboard.string(forType: .string)
    }

    private static func synthesizeCopy() {
        let source = CGEventSource(stateID: .combinedSessionState)
        let down = CGEvent(
            keyboardEventSource: source,
            virtualKey: CGKeyCode(kVK_ANSI_C),
            keyDown: true
        )
        let up = CGEvent(
            keyboardEventSource: source,
            virtualKey: CGKeyCode(kVK_ANSI_C),
            keyDown: false
        )
        down?.flags = .maskCommand
        up?.flags = .maskCommand
        down?.post(tap: .cghidEventTap)
        up?.post(tap: .cghidEventTap)
    }

    private static func snapshot(of pasteboard: NSPasteboard) -> [NSPasteboardItem] {
        (pasteboard.pasteboardItems ?? []).map { item in
            let copy = NSPasteboardItem()
            for type in item.types {
                if let data = item.data(forType: type) {
                    copy.setData(data, forType: type)
                }
            }
            return copy
        }
    }

    private static func restore(_ items: [NSPasteboardItem], to pasteboard: NSPasteboard) {
        pasteboard.clearContents()
        if !items.isEmpty {
            pasteboard.writeObjects(items)
        }
    }
}
