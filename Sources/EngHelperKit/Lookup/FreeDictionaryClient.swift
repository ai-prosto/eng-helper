import Foundation

/// Plain URLSession GET to the Free Dictionary API — no key, no
/// identifying headers, 10-second timeout (design D-09). The only
/// network code in the project.
public struct FreeDictionaryClient: DictionaryTransport {
    static let endpoint = URL(string: "https://api.dictionaryapi.dev/api/v2/entries/en/")!

    private let session: URLSession

    public init(session: URLSession = FreeDictionaryClient.defaultSession()) {
        self.session = session
    }

    public static func defaultSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 10
        return URLSession(configuration: configuration)
    }

    /// The exact request `fetch` sends; exposed so tests can inspect
    /// it without touching the network.
    public func request(for word: String) -> URLRequest {
        // Beyond `/`: a `:` in the first segment of a relative reference
        // reads as a scheme and discards the base URL, and literal `.`/`..`
        // segments resolve against the base path.
        var allowed = CharacterSet.urlPathAllowed
        allowed.remove(charactersIn: "/:.")
        let encoded = word.addingPercentEncoding(withAllowedCharacters: allowed) ?? word
        let url = URL(string: encoded, relativeTo: Self.endpoint) ?? Self.endpoint
        var request = URLRequest(url: url.absoluteURL)
        request.httpMethod = "GET"
        return request
    }

    public func fetch(word: String) async throws -> TransportResponse {
        let (data, response) = try await session.data(for: request(for: word))
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
        return TransportResponse(data: data, statusCode: statusCode)
    }
}
