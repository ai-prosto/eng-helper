import Foundation
import Testing
@testable import EngHelperKit

@Suite struct WordCardParserTests {

    // BEH-01: word, first non-empty phonetic text as IPA, first definition
    // of the first meaning as gloss, definitions grouped by part of speech
    // in first-seen order.
    @Test func testBuildsCardWithIPAGlossAndGroupedMeanings() throws {
        let card = try WordCardParser.card(from: fixture("grouped"), fallbackWord: "bank")

        #expect(card.word == "bank")
        #expect(card.ipa == "/bæŋk/")
        #expect(card.gloss == "The land alongside a river or lake.")

        #expect(card.meanings.map(\.partOfSpeech) == ["noun", "verb"])
        #expect(card.meanings[0].definitions.map(\.definition) == [
            "The land alongside a river or lake.",
            "An institution where money is kept and lent.",
            "A row of similar things arranged together.",
        ])
        #expect(card.meanings[1].definitions.map(\.definition) == [
            "To tilt an aircraft sideways in flight."
        ])
    }

    // The payload's own word wins over the fallback; the fallback is
    // used only when the payload carries no non-empty word.
    @Test func testFallbackWordOnlyFillsAMissingPayloadWord() throws {
        let fromPayload = try WordCardParser.card(from: fixture("grouped"), fallbackWord: "Bank!!")
        #expect(fromPayload.word == "bank")

        let wordless = Data(
            #"[{"meanings":[{"partOfSpeech":"noun","definitions":[{"definition":"A thing."}]}]}]"#
                .utf8)
        let fromFallback = try WordCardParser.card(from: wordless, fallbackWord: "serendipity")
        #expect(fromFallback.word == "serendipity")
    }

    // BEH-02: definitions with an example expose its text; definitions
    // with no example or a blank one expose no example at all.
    @Test func testExamplePresentOnlyWhenPayloadHasOne() throws {
        let card = try WordCardParser.card(from: fixture("examples"), fallbackWord: "glow")

        let definitions = try #require(card.meanings.first?.definitions)
        #expect(definitions.count == 3)
        #expect(definitions[0].example == "The lamp glowed softly in the corner.")
        #expect(definitions[1].example == nil, "a blank example must be absent, not empty")
        #expect(definitions[2].example == nil, "a missing example must stay absent")
    }
}
