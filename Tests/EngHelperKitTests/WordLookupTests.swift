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

    // BEH-04: no-connection → offline, HTTP 404 → not found,
    // unparseable payload → not found, other HTTP failure → bad response.
    @Test func testMapsTransportFailuresToLookupErrors() async throws {
        await expectLookup(
            .fail(URLError(.notConnectedToInternet)),
            throwsError: .offline
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
