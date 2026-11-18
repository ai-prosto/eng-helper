import Foundation

/// Looks a word up and saves the resulting card. The save happens
/// only after a successful lookup, so a failed lookup leaves
/// `vocabulary.json` untouched (BEH-09).
public struct VocabularyService: Sendable {
    private let lookup: WordLookup
    private let store: VocabularyStore

    public init(lookup: WordLookup, store: VocabularyStore) {
        self.lookup = lookup
        self.store = store
    }

    @discardableResult
    public func addWord(_ word: String, at date: Date = Date()) async throws -> WordCard {
        let card = try await lookup.card(for: word)
        try store.save(card, at: date)
        return card
    }
}
