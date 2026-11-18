import Foundation
import Testing
@testable import EngHelperKit

/// Records every speech request so tests can assert on count, order
/// and content.
@MainActor
final class SpySpeaker: Speaking {
    enum Call: Equatable {
        case speak(String)
        case sequence([String])
    }

    private(set) var calls: [Call] = []

    func speak(_ text: String) {
        calls.append(.speak(text))
    }

    func speakSequence(_ sentences: [String]) {
        calls.append(.sequence(sentences))
    }
}

@MainActor
@Suite final class PopoverSpeechTests {

    private let root: URL
    private let store: VocabularyStore
    private let speaker = SpySpeaker()

    init() {
        root = FileManager.default.temporaryDirectory
            .appendingPathComponent("PopoverSpeechTests-\(UUID().uuidString)")
        store = VocabularyStore(folderURL: root.appendingPathComponent("EngHelper"))
    }

    deinit {
        try? FileManager.default.removeItem(at: root)
    }

    private func makeModel(_ behaviour: FakeTransport.Behaviour) -> PopoverModel {
        PopoverModel(
            lookup: WordLookup(transport: FakeTransport(behaviour)),
            store: store,
            speaker: speaker
        )
    }

    // BEH-24: the looked-up word is spoken exactly once when its card
    // appears, without any click.
    @Test func testCardPresentationSpeaksWordOnce() async throws {
        let model = makeModel(.respond(try fixture("grouped"), statusCode: 200))
        model.input = "bank"

        await model.submit()

        guard case let .card(card) = model.phase else {
            Issue.record("expected .card, got \(model.phase)")
            return
        }
        #expect(speaker.calls == [.speak(card.word)])
    }

    // BEH-24: a card reopened from the saved list is a new
    // presentation — spoken once as well.
    @Test func testSavedRowCardSpeaksWordOnce() async throws {
        try store.save(WordCard(word: "apple", ipa: nil, gloss: "A fruit.", meanings: []))
        let model = makeModel(.fail(URLError(.notConnectedToInternet)))

        model.show(try #require(model.entries.first))

        #expect(speaker.calls == [.speak("apple")])
    }

    // BEH-24: a failed lookup presents no card and speaks nothing.
    @Test func testFailedLookupSpeaksNothing() async {
        let model = makeModel(.fail(URLError(.notConnectedToInternet)))

        await model.lookUp("river")

        #expect(speaker.calls.isEmpty)
    }

    // BEH-25: each press of the replay button speaks the shown word
    // once more; without a card it does nothing.
    @Test func testReplaySpeaksWordAgainPerPress() async throws {
        let model = makeModel(.respond(try fixture("grouped"), statusCode: 200))

        model.replay()
        #expect(speaker.calls.isEmpty)

        await model.lookUp("bank")
        guard case let .card(card) = model.phase else {
            Issue.record("expected .card, got \(model.phase)")
            return
        }

        model.replay()
        model.replay()

        #expect(speaker.calls == [
            .speak(card.word), .speak(card.word), .speak(card.word),
        ])
    }

    // BEH-26: "Read aloud" speaks the pasted sentences in order, one
    // sequence to the end, and vocabulary.json gets no entry from it.
    @Test func testReadAloudSpeaksAllSentencesAndSavesNothing() throws {
        let model = makeModel(.fail(URLError(.badURL)))
        model.sentencesText = """
        It was late. The rain had stopped. A door opened somewhere. \
        Nobody came in.
        """

        model.readSentencesAloud()

        #expect(speaker.calls == [.sequence([
            "It was late.",
            "The rain had stopped.",
            "A door opened somewhere.",
            "Nobody came in.",
        ])])
        #expect(try store.entries().isEmpty)
        #expect(FileManager.default.fileExists(atPath: store.fileURL.path) == false)
    }

    // BEH-24: a lookup superseded by a tap on a saved row must not
    // speak when it finally completes — only the shown card's word
    // is pronounced.
    @Test func testStaleLookupSpeaksNothing() async throws {
        try store.save(WordCard(word: "apple", ipa: nil, gloss: "A fruit.", meanings: []))
        let transport = GatedTransport(respond: try fixture("grouped"))
        let model = PopoverModel(
            lookup: WordLookup(transport: transport),
            store: store,
            speaker: speaker
        )

        let lookup = Task { await model.lookUp("bank") }
        await transport.started()

        model.show(try #require(model.entries.first))
        transport.release()
        await lookup.value

        #expect(speaker.calls == [.speak("apple")])
    }

    // BEH-24: a lookup that completes after the popover closed must
    // not speak out of a hidden app; the pending spinner resets.
    @Test func testPopoverCloseSilencesInFlightLookup() async throws {
        let transport = GatedTransport(respond: try fixture("grouped"))
        let model = PopoverModel(
            lookup: WordLookup(transport: transport),
            store: store,
            speaker: speaker
        )

        let lookup = Task { await model.lookUp("bank") }
        await transport.started()

        model.popoverClosed()
        transport.release()
        await lookup.value

        #expect(speaker.calls.isEmpty)
        #expect(model.phase == .idle)
    }

    // BEH-26: blank sentences text enqueues nothing.
    @Test func testReadAloudWithBlankTextSpeaksNothing() {
        let model = makeModel(.fail(URLError(.badURL)))
        model.sentencesText = "  \n\t"

        model.readSentencesAloud()

        #expect(speaker.calls.isEmpty)
    }
}
