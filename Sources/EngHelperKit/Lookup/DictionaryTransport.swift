import Foundation

/// Raw bytes and HTTP status for one dictionary request.
public struct TransportResponse: Equatable, Sendable {
    public let data: Data
    public let statusCode: Int

    public init(data: Data, statusCode: Int) {
        self.data = data
        self.statusCode = statusCode
    }
}

/// Abstracts the network so tests can inject canned fixture bytes
/// or thrown errors (design D-09, D-19).
public protocol DictionaryTransport: Sendable {
    func fetch(word: String) async throws -> TransportResponse
}
