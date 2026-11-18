import Combine
import Foundation

/// The popover's state machine (design D-04, D-15, D-17, D-18).
///
/// One lookup phase — idle, loading, card or a one-line error — plus
/// the independent sentences text and the saved list. The save happens
/// inside the single transition that presents a fresh card, so a
/// failed lookup cannot write; a saved entry reopens its card with no
/// transport call.
@MainActor
public final class PopoverModel: ObservableObject {
    public enum Phase: Equatable, Sendable {
        case idle
        case loading
        case card(WordCard)
        case error(String)
    }

    /// What the Option+Shift+D path captured from the frontmost app
    /// (BEH-20, BEH-22, design D-07, D-08).
    public enum HotkeyCapture: Equatable, Sendable {
        case selection(String)
        case empty
        case accessibilityMissing
    }

    @Published public var input = ""
    @Published public var sentencesText = ""
    @Published public private(set) var phase = Phase.idle
    @Published public private(set) var entries: [VocabularyEntry] = []
    @Published public private(set) var showAccessibilityHint = false

    private let service: VocabularyService
    private let store: VocabularyStore
    // Only the newest lookup may write `phase`; a tap on a saved row
    // also invalidates anything still in flight.
    private var lookupGeneration = 0

    public init(lookup: WordLookup, store: VocabularyStore) {
        self.service = VocabularyService(lookup: lookup, store: store)
        self.store = store
        refreshEntries()
    }

    /// Enter in the word field: look the typed word up and save it
    /// (BEH-16). Blank input does nothing.
    public func submit() async {
        await lookUp(input)
    }

    public func lookUp(_ word: String) async {
        let word = word.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !word.isEmpty else { return }

        lookupGeneration += 1
        let generation = lookupGeneration

        phase = .loading
        do {
            let card = try await service.addWord(word)
            refreshEntries()
            guard generation == lookupGeneration else { return }
            phase = .card(card)
        } catch is CancellationError {
            guard generation == lookupGeneration else { return }
            phase = .idle
        } catch {
            guard generation == lookupGeneration else { return }
            phase = .error(Self.message(for: error, word: word))
        }
    }

    /// Option+Shift+D: look the captured selection up (BEH-20), or
    /// present an empty, focused field with no lookup when nothing
    /// was selected (BEH-22). A missing Accessibility grant adds the
    /// one-line hint (design D-08) and otherwise behaves like an
    /// empty capture; the hint clears on the next successful capture.
    public func handleHotkey(_ capture: HotkeyCapture) async {
        switch capture {
        case .accessibilityMissing:
            showAccessibilityHint = true
            clearForTyping()
        case .empty:
            showAccessibilityHint = false
            clearForTyping()
        case let .selection(text):
            let word = text.trimmingCharacters(in: .whitespacesAndNewlines)
            showAccessibilityHint = false
            guard !word.isEmpty else {
                clearForTyping()
                return
            }
            input = word
            await lookUp(word)
        }
    }

    /// Empty field, idle phase; also invalidates anything still in
    /// flight so a stale card cannot repaint over the fresh field.
    private func clearForTyping() {
        lookupGeneration += 1
        input = ""
        phase = .idle
    }

    /// A tap on a saved row: reopen the stored card — no lookup, no
    /// save, no network (BEH-19).
    public func show(_ entry: VocabularyEntry) {
        lookupGeneration += 1
        phase = .card(entry.card)
    }

    /// Reloads the saved list from disk, newest first.
    public func refreshEntries() {
        entries = (try? store.entries()) ?? []
    }

    /// One short line per failure (design D-18).
    static func message(for error: Error, word: String) -> String {
        switch error {
        case LookupError.offline:
            return "No network — try again"
        case let LookupError.notFound(word):
            return "No dictionary entry for “\(word)”"
        case LookupError.badResponse:
            return "Unexpected dictionary reply — try again"
        default:
            return "Could not save “\(word)”"
        }
    }
}
