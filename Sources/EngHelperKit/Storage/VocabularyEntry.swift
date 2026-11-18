import Foundation

/// One saved word. The entry keeps every card field plus the date it
/// was first saved, so the full card rebuilds from disk alone (BEH-13).
public struct VocabularyEntry: Equatable, Codable, Sendable {
    public let word: String
    public let ipa: String?
    public let gloss: String
    public let meanings: [Meaning]
    public let addedAt: Date

    public init(card: WordCard, addedAt: Date) {
        self.word = card.word
        self.ipa = card.ipa
        self.gloss = card.gloss
        self.meanings = card.meanings
        // The file stores whole-second ISO-8601 dates, so truncate up
        // front: the entry stays `==` to its reloaded copy.
        self.addedAt = Date(
            timeIntervalSince1970: addedAt.timeIntervalSince1970.rounded(.down)
        )
    }

    /// The stored card, reassembled without any lookup.
    public var card: WordCard {
        WordCard(word: word, ipa: ipa, gloss: gloss, meanings: meanings)
    }
}
