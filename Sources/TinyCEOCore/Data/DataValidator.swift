import Foundation

public struct ValidationIssue: Sendable {
    public let message: String

    public init(_ message: String) {
        self.message = message
    }
}

public struct DataValidator {
    public static let supportedEffectOps: Set<String> = [
        "SET_STRATEGY",
        "SET_FLAG",
        "ADD_FLAG",
        "UNLOCK_POLICY",
        "ENABLE_POLICY",
        "HIRE_RANDOM",
        "ADD_PROJECT",
        "ADD_TEMP_CAPACITY",
        "ADD_CASH",
        "ADD_DEBT",
        "ADD_MRR",
        "ADD_REPUTATION",
        "ADD_TEAM_HEALTH",
        "ADD_TECH_DEBT",
        "ADD_AI_XP",
        "ADD_LEADS",
        "ENDGAME"
    ]

    public static let supportedConditionOps: Set<String> = [
        "==", "!=", ">", ">=", "<", "<=", "CONTAINS", "NOT_CONTAINS"
    ]

    public static func validate(_ data: GameData) -> [ValidationIssue] {
        var issues: [ValidationIssue] = []

        validateUniqueIDs(values: data.roles.roles.map(\.id), context: "roles", into: &issues)
        validateUniqueIDs(values: data.traits.traits.map(\.id), context: "traits", into: &issues)
        validateUniqueIDs(values: data.policies.policies.map(\.id), context: "policies", into: &issues)
        validateUniqueIDs(values: data.facilities.facilities.map(\.id), context: "facilities", into: &issues)
        validateUniqueIDs(values: data.projects.projects.map(\.id), context: "projects", into: &issues)
        validateUniqueIDs(values: data.cards.cards.map(\.id), context: "cards", into: &issues)
        validateUniqueIDs(values: data.progression.chapters.map(\.id), context: "chapters", into: &issues)

        let roleIDs = Set(data.roles.roles.map(\.id))
        let policyIDs = Set(data.policies.policies.map(\.id))
        let projectIDs = Set(data.projects.projects.map(\.id))
        let chapterIDs = Set(data.progression.chapters.map(\.id))
        let disciplineIDs = Set(data.roles.disciplines)

        let unlockedCategories = Set(data.progression.chapters.flatMap { $0.unlocks.cardCategories })
        for card in data.cards.cards where !unlockedCategories.contains(card.category) {
            issues.append(ValidationIssue("Card \(card.id) uses category '\(card.category)' not unlocked by progression"))
        }

        for role in data.roles.roles {
            let invalid = Set(role.baseOutputWorkUnitsPerCompanyDay.keys).subtracting(disciplineIDs)
            if !invalid.isEmpty {
                issues.append(ValidationIssue("Role \(role.id) has invalid disciplines: \(invalid.sorted().joined(separator: ", "))"))
            }
        }

        for project in data.projects.projects {
            let invalid = Set(project.workRequired.keys).subtracting(disciplineIDs)
            if !invalid.isEmpty {
                issues.append(ValidationIssue("Project \(project.id) has invalid work disciplines: \(invalid.sorted().joined(separator: ", "))"))
            }
            for policyId in project.reward.unlockPolicyIds ?? [] where !policyIDs.contains(policyId) {
                issues.append(ValidationIssue("Project \(project.id) references unknown policy \(policyId)"))
            }
        }

        for chapter in data.progression.chapters {
            for condition in chapter.unlockConditions ?? [] {
                if !supportedConditionOps.contains(condition.op) {
                    issues.append(ValidationIssue("Chapter \(chapter.id) uses unsupported condition op \(condition.op)"))
                }
            }
            for policyId in chapter.unlocks.policyIds where !policyIDs.contains(policyId) {
                issues.append(ValidationIssue("Chapter \(chapter.id) unlocks unknown policy \(policyId)"))
            }
        }

        for card in data.cards.cards {
            for condition in card.conditions {
                if !supportedConditionOps.contains(condition.op) {
                    issues.append(ValidationIssue("Card \(card.id) uses unsupported condition op \(condition.op)"))
                }
                if condition.metric == "chapterUnlocked", let id = condition.value.stringValue.split(separator: ":").first.map(String.init) {
                    if !chapterIDs.contains(id) && !chapterIDs.contains(condition.value.stringValue) {
                        issues.append(ValidationIssue("Card \(card.id) references unknown chapter \(condition.value.stringValue)"))
                    }
                }
            }

            if card.options.count != 3 {
                issues.append(ValidationIssue("Card \(card.id) must have exactly 3 options in v0.1"))
            }

            for option in card.options {
                for effect in option.effects {
                    if !supportedEffectOps.contains(effect.op) {
                        issues.append(ValidationIssue("Card \(card.id) uses unsupported effect op \(effect.op)"))
                    }

                    if effect.op == "ADD_PROJECT", let projectId = effect.projectId, !projectIDs.contains(projectId) {
                        issues.append(ValidationIssue("Card \(card.id) references unknown project \(projectId)"))
                    }
                    if ["ENABLE_POLICY", "UNLOCK_POLICY"].contains(effect.op), let policyId = effect.policyId, !policyIDs.contains(policyId) {
                        issues.append(ValidationIssue("Card \(card.id) references unknown policy \(policyId)"))
                    }
                    if effect.op == "HIRE_RANDOM", let roleId = effect.roleId, !roleIDs.contains(roleId) {
                        issues.append(ValidationIssue("Card \(card.id) references unknown role \(roleId)"))
                    }
                }
            }
        }

        return issues
    }

    private static func validateUniqueIDs(values: [String], context: String, into issues: inout [ValidationIssue]) {
        let duplicates = Dictionary(grouping: values, by: { $0 })
            .filter { $1.count > 1 }
            .keys
            .sorted()
        for duplicate in duplicates {
            issues.append(ValidationIssue("Duplicate id in \(context): \(duplicate)"))
        }
    }
}
