import Foundation

/// Decodable mirror of the dictionaryapi.dev JSON payload.
/// Every field is optional: the API omits and blanks fields freely.
struct DictionaryEntryDTO: Decodable {
    let word: String?
    let phonetic: String?
    let phonetics: [PhoneticDTO]?
    let meanings: [MeaningDTO]?
}

struct PhoneticDTO: Decodable {
    let text: String?
}

struct MeaningDTO: Decodable {
    let partOfSpeech: String?
    let definitions: [DefinitionDTO]?
}

struct DefinitionDTO: Decodable {
    let definition: String?
    let example: String?
}
