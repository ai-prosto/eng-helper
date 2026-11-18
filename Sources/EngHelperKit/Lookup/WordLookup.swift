import Foundation

/// Transport + parser → `WordCard`, with every failure mapped to one
/// of the three `LookupError` cases (design D-18):
/// - no-connection transport errors → `.offline`
/// - HTTP 404, an unparseable or empty-definition payload, or a card
///   whose gloss is blank after trimming → `.notFound`
/// - anything else → `.badResponse`
public struct WordLookup: Sendable {
    private let transport: DictionaryTransport

    public init(transport: DictionaryTransport = FreeDictionaryClient()) {
        self.transport = transport
    }

    public func card(for word: String) async throws -> WordCard {
        let word = word.trimmingCharacters(in: .whitespacesAndNewlines)

        let response: TransportResponse
        do {
            response = try await transport.fetch(word: word)
        } catch let error as URLError where Self.offlineCodes.contains(error.code) {
            throw LookupError.offline
        } catch let error as URLError where error.code == .cancelled {
            // A cancelled lookup is flow control, not a failure to show.
            throw CancellationError()
        } catch is CancellationError {
            throw CancellationError()
        } catch let error as LookupError {
            throw error
        } catch {
            throw LookupError.badResponse
        }

        switch response.statusCode {
        case 200..<300:
            break
        case 404:
            throw LookupError.notFound(word: word)
        default:
            throw LookupError.badResponse
        }

        guard let card = try? WordCardParser.card(from: response.data, fallbackWord: word),
              !card.gloss.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            throw LookupError.notFound(word: word)
        }
        return card
    }

    private static let offlineCodes: Set<URLError.Code> = [
        .notConnectedToInternet,
        .cannotFindHost,
        .networkConnectionLost,
        .cannotConnectToHost,
        .dnsLookupFailed,
    ]
}
