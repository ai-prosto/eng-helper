import Foundation
import Testing
@testable import EngHelperKit

@MainActor
@Suite final class PopoverModelTests {

    private let root: URL
    private let store: VocabularyStore

    init() {
        root = FileManager.default.temporaryDirectory
            .appendingPathComponent("PopoverModelTests-\(UUID().uuidString)")
        store = VocabularyStore(folderURL: root.appendingPathComponent("EngHelper"))
    }

    deinit {
        try? FileManager.default.removeItem(at: root)
    }

    private func makeModel(_ behaviour: FakeTransport.Behaviour) -> (PopoverModel, FakeTransport) {
        let transport = FakeTransport(behaviour)
        let model = PopoverModel(lookup: WordLookup(transport: transport), store: store)
        return (model, transport)
    }

    // BEH-16: Enter on a typed word runs the lookup, shows the card
    // and lands the entry in the store.
    @Test func testSubmitLooksUpShowsCardAndSaves() async throws {
        let (model, _) = makeModel(.respond(try fixture("grouped"), statusCode: 200))
        model.input = "bank"

        await model.submit()

        guard case let .card(card) = model.phase else {
            Issue.record("expected .card, got \(model.phase)")
            return
        }
        let entries = try store.entries()
        #expect(entries.count == 1)
        #expect(entries.first?.card == card)
        // The visible list refreshed with the save.
        #expect(model.entries == entries)
    }

    // BEH-15/16: blank input is not a lookup — nothing runs, nothing
    // changes.
    @Test func testBlankInputDoesNothing() async {
        let (model, transport) = makeModel(.fail(URLError(.badURL)))
        model.input = "   \n"

        await model.submit()

        #expect(model.phase == .idle)
        #expect(transport.fetchedWords.isEmpty)
    }

    // BEH-18: an offline lookup shows one short line and leaves the
    // file byte-identical.
    @Test func testOfflineFailureShowsOneLineAndWritesNothing() async throws {
        try store.save(WordCard(word: "apple", ipa: nil, gloss: "A fruit.", meanings: []))
        let before = try Data(contentsOf: store.fileURL)

        let (model, _) = makeModel(.fail(URLError(.notConnectedToInternet)))
        await model.lookUp("river")

        #expect(model.phase == .error("No network — try again"))
        #expect(try Data(contentsOf: store.fileURL) == before)
        #expect(model.entries.map(\.word) == ["apple"])
    }

    // BEH-18: an unknown word shows the not-found line and leaves the
    // file byte-identical.
    @Test func testNotFoundFailureShowsOneLineAndWritesNothing() async throws {
        try store.save(WordCard(word: "apple", ipa: nil, gloss: "A fruit.", meanings: []))
        let before = try Data(contentsOf: store.fileURL)

        let (model, _) = makeModel(.respond(Data("[]".utf8), statusCode: 404))
        await model.lookUp("qwertyx")

        #expect(model.phase == .error("No dictionary entry for “qwertyx”"))
        #expect(try Data(contentsOf: store.fileURL) == before)
    }

    // BEH-19: the list is newest first and a tapped entry reopens its
    // card with no transport call.
    @Test func testListIsNewestFirstAndReopensCardWithoutTransport() async throws {
        let older = WordCard(word: "apple", ipa: "/ˈæp.əl/", gloss: "A fruit.", meanings: [
            Meaning(partOfSpeech: "noun", definitions: [
                Definition(definition: "A fruit.", example: "An apple a day."),
            ]),
        ])
        let newer = WordCard(word: "river", ipa: nil, gloss: "Flowing water.", meanings: [])
        try store.save(older, at: Date(timeIntervalSince1970: 1_000))
        try store.save(newer, at: Date(timeIntervalSince1970: 2_000))

        let (model, transport) = makeModel(.fail(URLError(.notConnectedToInternet)))

        #expect(model.entries.map(\.word) == ["river", "apple"])

        let tapped = try #require(model.entries.last)
        model.show(tapped)

        #expect(model.phase == .card(older))
        #expect(transport.fetchedWords.isEmpty)
    }

    // Design D-14: the real store folder resolves inside the user's
    // Application Support, named EngHelper.
    @Test func testStoragePathsResolveApplicationSupportEngHelper() throws {
        let folder = try StoragePaths.vocabularyFolder()
        #expect(folder.lastPathComponent == "EngHelper")
        #expect(folder.pathComponents.contains("Application Support"))
    }
}
