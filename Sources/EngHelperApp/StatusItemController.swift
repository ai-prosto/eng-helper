import AppKit
import EngHelperKit
import SwiftUI

/// Owns the status item and its popover (design D-03). The button
/// toggles the popover; `show(prefill:)` also serves the hotkey path
/// arriving with TASK-004.
@MainActor
final class StatusItemController: NSObject {
    private let statusItem: NSStatusItem
    private let popover: NSPopover
    private let model: PopoverModel

    init(model: PopoverModel) {
        self.model = model
        self.statusItem = NSStatusBar.system.statusItem(
            withLength: NSStatusItem.squareLength
        )
        self.popover = NSPopover()
        super.init()

        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: PopoverRootView(model: model)
        )

        if let button = statusItem.button {
            button.image = NSImage(
                systemSymbolName: "character.book.closed.fill",
                accessibilityDescription: "EngHelper"
            )
            button.target = self
            button.action = #selector(togglePopover)
        }
    }

    @objc private func togglePopover() {
        if popover.isShown {
            popover.performClose(nil)
        } else {
            show()
        }
    }

    /// Opens the popover over the status item, list refreshed and the
    /// word field ready for typing (BEH-15, design D-05).
    func show(prefill: String? = nil) {
        guard let button = statusItem.button else { return }
        if let prefill {
            model.input = prefill
        }
        model.refreshEntries()
        NSApp.activate()
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        if let view = popover.contentViewController?.view {
            view.window?.makeFirstResponder(view)
        }
    }
}
