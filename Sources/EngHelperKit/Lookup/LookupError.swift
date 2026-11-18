import Foundation

/// The three failures a lookup can surface (design D-18).
public enum LookupError: Error, Equatable, Sendable {
    /// The network is unreachable.
    case offline
    /// The dictionary has no usable entry for the word.
    case notFound(word: String)
    /// The server answered with something other than a dictionary entry.
    case badResponse
}
