import Foundation

/// Persists saved words as a pretty-printed JSON array in
/// `vocabulary.json` inside the given folder, creating the folder on
/// the first save. Entries are kept newest-first, one per word
/// matched ignoring case; a duplicate save keeps the original entry
/// and its first date.
public struct VocabularyStore: Sendable {
    public static let fileName = "vocabulary.json"

    public let fileURL: URL

    public init(folderURL: URL) {
        self.fileURL = folderURL.appendingPathComponent(Self.fileName)
    }

    /// All saved entries, newest first.
    public func entries() throws -> [VocabularyEntry] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return []
        }
        let data = try Data(contentsOf: fileURL)
        return try Self.decoder.decode([VocabularyEntry].self, from: data)
    }

    /// Saves the card unless the word is already present (compared
    /// ignoring case), and returns the entry that now represents it.
    @discardableResult
    public func save(_ card: WordCard, at date: Date = Date()) throws -> VocabularyEntry {
        var entries = try entries()
        if let existing = entries.first(where: {
            $0.word.caseInsensitiveCompare(card.word) == .orderedSame
        }) {
            return existing
        }

        let entry = VocabularyEntry(card: card, addedAt: date)
        entries.insert(entry, at: 0)
        try write(entries)
        return entry
    }

    private func write(_ entries: [VocabularyEntry]) throws {
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let data = try Self.encoder.encode(entries)
        try data.write(to: fileURL, options: .atomic)
    }

    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}
