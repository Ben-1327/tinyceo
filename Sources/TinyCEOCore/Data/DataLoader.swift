import Foundation

public enum DataLoaderError: Error, LocalizedError {
    case fileNotFound(String)
    case decodeFailed(String, Error)

    public var errorDescription: String? {
        switch self {
        case .fileNotFound(let file):
            return "File not found: \(file)"
        case .decodeFailed(let file, let error):
            return "Failed to decode \(file): \(error)"
        }
    }
}

public final class DataLoader: @unchecked Sendable {
    private let decoder: JSONDecoder

    public init(decoder: JSONDecoder = JSONDecoder()) {
        self.decoder = decoder
    }

    public func loadAll(from directory: URL) throws -> GameData {
        let balance: BalanceData = try decode("balance.json", from: directory)
        let activityRules: ActivityRulesData = try decode("activity_rules.json", from: directory)
        let roles: RolesData = try decode("roles.json", from: directory)
        let traits: TraitsData = try decode("traits.json", from: directory)
        let policies: PoliciesData = try decode("policies.json", from: directory)
        let facilities: FacilitiesData = try decode("facilities.json", from: directory)
        let projects: ProjectsData = try decode("projects.json", from: directory)
        let progression: ProgressionData = try decode("progression.json", from: directory)
        let cards: CardsData = try decode("cards.json", from: directory)

        return GameData(
            balance: balance,
            activityRules: activityRules,
            roles: roles,
            traits: traits,
            policies: policies,
            facilities: facilities,
            projects: projects,
            progression: progression,
            cards: cards
        )
    }

    private func decode<T: Decodable>(_ filename: String, from directory: URL) throws -> T {
        let fileURL = directory.appendingPathComponent(filename)
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            throw DataLoaderError.fileNotFound(filename)
        }

        let rawData = try Data(contentsOf: fileURL)
        do {
            return try decoder.decode(T.self, from: rawData)
        } catch {
            throw DataLoaderError.decodeFailed(filename, error)
        }
    }
}
