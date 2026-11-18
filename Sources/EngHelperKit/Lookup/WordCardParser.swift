import Foundation

/// Maps a dictionaryapi.dev payload to a `WordCard` (design D-10).
/// Pure: no network, no state — fixtures pin its behaviour in tests.
public enum WordCardParser {

    /// Decodes the array of entries and merges them into one card.
    ///
    /// - `ipa` is the first non-empty `phonetic` / `phonetics[].text`.
    /// - `gloss` is the first definition text of the first meaning;
    ///   empty when the payload has no usable definition.
    /// - `meanings` groups definitions by part of speech in first-seen
    ///   order; blank examples become no example at all.
    ///
    /// Throws `DecodingError` when the bytes are not a dictionary payload.
    public static func card(from data: Data, fallbackWord: String) throws -> WordCard {
        let entries = try JSONDecoder().decode([DictionaryEntryDTO].self, from: data)

        let word = entries.lazy
            .compactMap { $0.word?.trimmed }
            .first { !$0.isEmpty } ?? fallbackWord

        let ipa = entries.lazy
            .flatMap { entry -> [String] in
                [entry.phonetic ?? ""] + (entry.phonetics ?? []).map { $0.text ?? "" }
            }
            .map { $0.trimmed }
            .first { !$0.isEmpty }

        var order: [String] = []
        var grouped: [String: [Definition]] = [:]
        for meaning in entries.flatMap({ $0.meanings ?? [] }) {
            let pos = (meaning.partOfSpeech ?? "").trimmed
            guard !pos.isEmpty else { continue }
            let definitions = (meaning.definitions ?? []).compactMap { dto -> Definition? in
                let text = (dto.definition ?? "").trimmed
                guard !text.isEmpty else { return nil }
                let example = (dto.example ?? "").trimmed
                return Definition(definition: text, example: example.isEmpty ? nil : example)
            }
            guard !definitions.isEmpty else { continue }
            if grouped[pos] == nil { order.append(pos) }
            grouped[pos, default: []].append(contentsOf: definitions)
        }
        let meanings = order.map { Meaning(partOfSpeech: $0, definitions: grouped[$0] ?? []) }

        let gloss = meanings.first?.definitions.first?.definition ?? ""

        return WordCard(word: word, ipa: ipa, gloss: gloss, meanings: meanings)
    }
}

private extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}
