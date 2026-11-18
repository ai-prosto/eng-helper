import Foundation
import Testing
@testable import EngHelperKit

@Suite final class VocabularyStoreTests {

    private let root: URL

    /// A folder (with a missing parent) that does not exist until the
    /// store's first save creates it.
    private let folder: URL
    private let store: VocabularyStore

    init() {
        root = FileManager.default.temporaryDirectory
            .appendingPathComponent("VocabularyStoreTests-\(UUID().uuidString)")
        folder = root.appendingPathComponent("EngHelper")
        store = VocabularyStore(folderURL: folder)
    }

    deinit {
        try? FileManager.default.removeItem(at: root)
    }

    private func makeCard(
        _ word: String,
        ipa: String? = "/wɜːd/",
        gloss: String = "A unit of language.",
        meanings: [Meaning] = [
            Meaning(partOfSpeech: "noun", definitions: [
                Definition(definition: "A unit of language.", example: "A short word."),
                Definition(definition: "A promise."),
            ]),
            Meaning(partOfSpeech: "verb", definitions: [
                Definition(definition: "To phrase something."),
            ]),
        ]
    ) -> WordCard {
        WordCard(word: word, ipa: ipa, gloss: gloss, meanings: meanings)
    }

    // BEH-06: the first save creates the missing folder (including its
    // parent) and writes vocabulary.json inside it.
    @Test func testCreatesFolderAndWritesVocabularyFile() throws {
        #expect(!FileManager.default.fileExists(atPath: folder.path))

        try store.save(makeCard("bank"))

        var isDirectory: ObjCBool = false
        #expect(FileManager.default.fileExists(atPath: folder.path, isDirectory: &isDirectory))
        #expect(isDirectory.boolValue)
        #expect(store.fileURL == folder.appendingPathComponent("vocabulary.json"))
        #expect(FileManager.default.fileExists(atPath: store.fileURL.path))
    }

    // BEH-07: the entry keeps the word, gloss, save date, IPA and all
    // meanings of the card it was made from.
    @Test func testEntryStoresWordGlossDateIPAAndMeanings() throws {
        let card = makeCard("bank", ipa: "/bæŋk/", gloss: "Land beside a river.")
        let saved = Date(timeIntervalSince1970: 1_700_000_000)

        try store.save(card, at: saved)

        let entry = try #require(try store.entries().first)
        #expect(entry.word == "bank")
        #expect(entry.gloss == "Land beside a river.")
        #expect(entry.addedAt == saved)
        #expect(entry.ipa == "/bæŋk/")
        #expect(entry.meanings == card.meanings)
    }

    // BEH-08: the bytes on disk are a valid, pretty-printed JSON array
    // that any JSON reader can open.
    @Test func testFileIsValidPrettyPrintedJSONArray() throws {
        try store.save(makeCard("bank"))
        try store.save(makeCard("river"))

        let data = try Data(contentsOf: store.fileURL)
        let parsed = try JSONSerialization.jsonObject(with: data)
        let array = try #require(parsed as? [[String: Any]])
        #expect(array.count == 2)
        #expect(array.allSatisfy { $0["word"] is String })

        let text = try #require(String(data: data, encoding: .utf8))
        #expect(text.contains("\n"), "the file is pretty-printed, not one line")
    }

    // BEH-09: when the lookup fails, nothing is written — the file
    // (and even the folder) stays absent.
    @Test func testFailedLookupWritesNothing() async throws {
        let service = VocabularyService(
            lookup: WordLookup(transport: FakeTransport(.fail(URLError(.notConnectedToInternet)))),
            store: store
        )

        await #expect(throws: LookupError.offline) {
            try await service.addWord("bank")
        }

        #expect(!FileManager.default.fileExists(atPath: store.fileURL.path))
        #expect(!FileManager.default.fileExists(atPath: folder.path))
    }

    // BEH-10: saving the same word in another case keeps the one
    // original entry with its first date.
    @Test func testCaseInsensitiveDuplicateKeepsOneEntryAndFirstDate() throws {
        let first = Date(timeIntervalSince1970: 1_700_000_000)
        let later = Date(timeIntervalSince1970: 1_700_100_000)

        try store.save(makeCard("Bank"), at: first)
        try store.save(makeCard("bank"), at: later)
        let returned = try store.save(makeCard("BANK"), at: later)

        let entries = try store.entries()
        #expect(entries.count == 1)
        #expect(entries.first?.word == "Bank")
        #expect(entries.first?.addedAt == first)
        #expect(returned.word == "Bank", "a duplicate save returns the original entry")
        #expect(returned.addedAt == first)
    }

    // BEH-11: inflected forms are different words, not duplicates.
    @Test func testWordFormsAreSeparateEntries() throws {
        try store.save(makeCard("run"))
        try store.save(makeCard("running"))
        try store.save(makeCard("ran"))

        let words = try store.entries().map(\.word)
        #expect(words.sorted() == ["ran", "run", "running"])
    }

    // BEH-12: entries() lists saved words newest first, each with its
    // gloss for the list view.
    @Test func testEntriesNewestFirst() throws {
        try store.save(
            makeCard("first", gloss: "Gloss one."),
            at: Date(timeIntervalSince1970: 1_700_000_000)
        )
        try store.save(
            makeCard("second", gloss: "Gloss two."),
            at: Date(timeIntervalSince1970: 1_700_100_000)
        )
        try store.save(
            makeCard("third", gloss: "Gloss three."),
            at: Date(timeIntervalSince1970: 1_700_200_000)
        )

        let entries = try store.entries()
        #expect(entries.map(\.word) == ["third", "second", "first"])
        #expect(entries.map(\.gloss) == ["Gloss three.", "Gloss two.", "Gloss one."])
    }

    // BEH-12: "newest first" means the save date, even when a caller
    // supplies dates out of order.
    @Test func testEntriesSortByDateNotInsertionOrder() throws {
        try store.save(makeCard("newer"), at: Date(timeIntervalSince1970: 1_700_200_000))
        try store.save(makeCard("older"), at: Date(timeIntervalSince1970: 1_700_000_000))

        #expect(try store.entries().map(\.word) == ["newer", "older"])
    }

    // The file stores whole-second dates; the returned entry already
    // carries the truncated date, so it equals its reloaded copy.
    @Test func testSubSecondDateSurvivesDiskRoundTrip() throws {
        let saved = try store.save(
            makeCard("bank"),
            at: Date(timeIntervalSince1970: 1_700_000_000.75)
        )

        let reloaded = try #require(try store.entries().first)
        #expect(reloaded == saved)
        #expect(saved.addedAt == Date(timeIntervalSince1970: 1_700_000_000))
    }

    // A corrupt vocabulary.json fails loudly on read and on save, and
    // a failed save never clobbers the bytes on disk.
    @Test func testCorruptFileThrowsAndIsNeverClobbered() throws {
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let garbage = Data("not json".utf8)
        try garbage.write(to: store.fileURL)

        #expect(throws: (any Error).self) { try self.store.entries() }
        #expect(throws: (any Error).self) { try self.store.save(self.makeCard("bank")) }
        #expect(try Data(contentsOf: store.fileURL) == garbage)
    }

    // BEH-13: a looked-up card saved once comes back identical from a
    // fresh store reading the file, with no further transport call.
    @Test func testEntryRebuildsCardWithoutNetwork() async throws {
        let transport = FakeTransport(.respond(try fixture("grouped"), statusCode: 200))
        let service = VocabularyService(
            lookup: WordLookup(transport: transport),
            store: store
        )
        let looked = try await service.addWord("bank")

        let reopened = VocabularyStore(folderURL: folder)
        let entry = try #require(try reopened.entries().first)
        #expect(entry.card == looked)
        #expect(transport.fetchedWords == ["bank"], "only the original lookup hit the transport")
    }
}
