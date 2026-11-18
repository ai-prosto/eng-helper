import Foundation

/// Resolves the real home of `vocabulary.json`:
/// `~/Library/Application Support/EngHelper/` (design D-14). Tests
/// never use this — stores take their folder as an init parameter.
public enum StoragePaths {
    public static let folderName = "EngHelper"

    public static func vocabularyFolder(
        fileManager: FileManager = .default
    ) throws -> URL {
        try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ).appendingPathComponent(folderName, isDirectory: true)
    }
}
