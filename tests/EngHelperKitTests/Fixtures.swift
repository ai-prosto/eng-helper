import Foundation

struct MissingFixture: Error {
    let name: String
}

func fixture(_ name: String) throws -> Data {
    guard let url = Bundle.module.url(
        forResource: name, withExtension: "json", subdirectory: "Fixtures"
    ) else {
        throw MissingFixture(name: name)
    }
    return try Data(contentsOf: url)
}
