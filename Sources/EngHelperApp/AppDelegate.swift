import AppKit
import EngHelperKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItemController: StatusItemController?
    private var model: PopoverModel?
    private var hotKeyMonitor: HotKeyMonitor?

    func applicationDidFinishLaunching(_ notification: Notification) {
        do {
            let folder = try StoragePaths.vocabularyFolder()
            let store = VocabularyStore(folderURL: folder)
            let model = PopoverModel(lookup: WordLookup(), store: store)
            self.model = model
            statusItemController = StatusItemController(model: model)
            hotKeyMonitor = HotKeyMonitor { [weak self] in
                self?.handleHotkey()
            }
        } catch {
            // An .accessory app is never active at launch; without
            // this the alert can open behind other apps.
            NSApp.activate()
            NSApp.presentError(error)
            NSApp.terminate(nil)
        }
    }

    /// Option+Shift+D (BEH-20, BEH-21): the selection is read before
    /// the popover opens — it belongs to the app that is frontmost at
    /// the keystroke, and `show()` activates EngHelper.
    private func handleHotkey() {
        guard let model, let statusItemController else { return }
        let capture = SelectionReader.capture()
        statusItemController.show()
        Task { await model.handleHotkey(capture) }
    }
}
