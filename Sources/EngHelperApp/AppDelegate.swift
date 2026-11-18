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
            NSApp.presentError(error)
            NSApp.terminate(nil)
        }
    }
}
