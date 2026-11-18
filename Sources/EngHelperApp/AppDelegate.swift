import AppKit
import EngHelperKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItemController: StatusItemController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        do {
            let folder = try StoragePaths.vocabularyFolder()
            let store = VocabularyStore(folderURL: folder)
            let model = PopoverModel(lookup: WordLookup(), store: store)
            statusItemController = StatusItemController(model: model)
        } catch {
            // An .accessory app is never active at launch; without
            // this the alert can open behind other apps.
            NSApp.activate()
            NSApp.presentError(error)
            NSApp.terminate(nil)
        }
    }
}
