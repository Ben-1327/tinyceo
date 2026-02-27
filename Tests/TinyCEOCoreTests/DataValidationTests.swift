import Foundation
import Testing
@testable import TinyCEOCore

@Test("data files load and validate")
func dataLoadsAndValidates() throws {
    let loader = DataLoader()
    let data = try loader.loadAll(from: URL(fileURLWithPath: "data", isDirectory: true))
    let issues = DataValidator.validate(data)
    #expect(issues.isEmpty, "Expected no validation issues, got: \(issues.map(\.message))")
}
