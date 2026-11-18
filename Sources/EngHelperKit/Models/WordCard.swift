import Foundation

/// A single definition inside a meaning. `example` is nil when the
/// dictionary payload had none or a blank one.
public struct Definition: Equatable, Codable, Sendable {
    public let definition: String
    public let example: String?

    public init(definition: String, example: String? = nil) {
        self.definition = definition
        self.example = example
    }
}

/// Definitions grouped under one part of speech, in first-seen order.
public struct Meaning: Equatable, Codable, Sendable {
    public let partOfSpeech: String
    public let definitions: [Definition]

    public init(partOfSpeech: String, definitions: [Definition]) {
        self.partOfSpeech = partOfSpeech
        self.definitions = definitions
    }
}

/// The card shown for a looked-up word. `ipa` is nil when the API
/// returned no phonetic text.
public struct WordCard: Equatable, Codable, Sendable {
    public let word: String
    public let ipa: String?
    public let gloss: String
    public let meanings: [Meaning]

    public init(word: String, ipa: String?, gloss: String, meanings: [Meaning]) {
        self.word = word
        self.ipa = ipa
        self.gloss = gloss
        self.meanings = meanings
    }
}
