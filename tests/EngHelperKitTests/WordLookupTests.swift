import Foundation
import Testing
@testable import EngHelperKit

/// Canned transport: returns fixture bytes with a status code, or throws.
final class FakeTransport: DictionaryTransport, @unchecked Sendable {
    enum Behaviour {
        case respond(Data, statusCode: Int)
        case fail(Error)
    }

    private let behaviour: Behaviour
    private(set) var fetchedWords: [String] = []

    init(_ behaviour: Behaviour) {
        self.behaviour = behaviour
    }

    func fetch(word: String) async throws -> TransportResponse {
        fetchedWords.append(word)
        switch behaviour {
        case let .respond(data, statusCode):
            return TransportResponse(data: data, statusCode: statusCode)
        case let .fail(error):
            throw error
        }
    }
}

@Suite struct WordLookupTests {

    // BEH-03: a GET to https://api.dictionaryapi.dev/api/v2/entries/en/
    // <percent-encoded word> with no key, token or identifying header.
    @Test func testRequestsFreeDictionaryURLWithoutKey() throws {
        let request = FreeDictionaryClient().request(for: "naïve word")

        #expect(request.httpMethod == "GET")
        let url = try #require(request.url)
        #expect(url.absoluteString ==
            "https://api.dictionaryapi.dev/api/v2/entries/en/na%C3%AFve%20word")
        #expect(url.query == nil, "no api key or token in the query")

        let headers = request.allHTTPHeaderFields ?? [:]
        #expect(headers.isEmpty, "unexpected headers: \(headers)")
        #expect(request.value(forHTTPHeaderField: "Authorization") == nil)
    }

    // BEH-03: characters that would alter the request path — `/` as a
    // segment separator, `:` as a scheme marker in a relative reference,
    // `.`/`..` as dot segments — stay inside the word segment.
    @Test func testEncodesPathDelimitersIntoTheWordSegment() throws {
        let client = FreeDictionaryClient()
        let base = "https://api.dictionaryapi.dev/api/v2/entries/en/"

        #expect(client.request(for: "a/b").url?.absoluteString == base + "a%2Fb")
        #expect(client.request(for: "cat:dog").url?.absoluteString == base + "cat%3Adog")
        #expect(client.request(for: "..").url?.absoluteString == base + "%2E%2E")
    }

    // A good payload comes back as a card: the input word is trimmed
    // before it reaches the transport and the payload is parsed.
    @Test func testSuccessfulLookupReturnsParsedCard() async throws {
        let transport = FakeTransport(.respond(try fixture("grouped"), statusCode: 200))
        let lookup = WordLookup(transport: transport)

        let card = try await lookup.card(for: "  bank \n")

        #expect(transport.fetchedWords == ["bank"])
        #expect(card.word == "bank")
        #expect(card.gloss == "The land alongside a river or lake.")
        #expect(card.meanings.map(\.partOfSpeech) == ["noun", "verb"])
    }

    // BEH-04: no-connection → offline, HTTP 404 → not found,
    // unparseable payload → not found, other HTTP failure → bad response.
    @Test func testMapsTransportFailuresToLookupErrors() async throws {
        await expectLookup(
            .fail(URLError(.notConnectedToInternet)),
            throwsError: .offline
        )
        await expectLookup(
            .fail(URLError(.dnsLookupFailed)),
            throwsError: .offline
        )
        // D-18: only no-connection codes are offline; a timeout is not.
        await expectLookup(
            .fail(URLError(.timedOut)),
            throwsError: .badResponse
        )
        await expectLookup(
            .respond(Data(#"{"title":"No Definitions Found"}"#.utf8), statusCode: 404),
            throwsError: .notFound(word: "word")
        )
        await expectLookup(
            .respond(Data("<!doctype html><p>gateway</p>".utf8), statusCode: 200),
            throwsError: .notFound(word: "word")
        )
        await expectLookup(
            .respond(Data(), statusCode: 500),
            throwsError: .badResponse
        )
    }

    // A cancelled fetch propagates cancellation instead of masking it
    // as a user-facing bad-response error.
    @Test func testCancellationIsNotMaskedAsLookupError() async {
        let lookup = WordLookup(transport: FakeTransport(.fail(URLError(.cancelled))))
        await #expect(throws: CancellationError.self) {
            _ = try await lookup.card(for: "word")
        }
    }

    // BEH-05: a payload whose definitions are empty or blank raises
    // not-found instead of returning a card with an empty gloss.
    @Test func testEmptyGlossPayloadIsNotFound() async throws {
        let payload = try fixture("empty-gloss")
        await expectLookup(
            .respond(payload, statusCode: 200),
            throwsError: .notFound(word: "word")
        )
    }

    private func expectLookup(
        _ behaviour: FakeTransport.Behaviour,
        throwsError expected: LookupError,
        sourceLocation: SourceLocation = #_sourceLocation
    ) async {
        let lookup = WordLookup(transport: FakeTransport(behaviour))
        await #expect(throws: expected, sourceLocation: sourceLocation) {
            _ = try await lookup.card(for: "word")
        }
    }
}
