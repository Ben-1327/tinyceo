import Foundation

public enum Strategy: String, Codable, Sendable {
    case contractHeavy = "CONTRACT_HEAVY"
    case balanced = "BALANCED"
    case productHeavy = "PRODUCT_HEAVY"
}

public enum ActivityCategory: String, CaseIterable, Codable, Sendable {
    case dev = "DEV"
    case comms = "COMMS"
    case ops = "OPS"
    case research = "RESEARCH"
    case ai = "AI"
    case rest = "BREAK"
}

public enum RiskLevel: String, Codable, Sendable {
    case normal
    case warn
    case danger
}

public struct BootstrapConfig: Codable, Sendable {
    public var startingReputation: Double
    public var startingTeamHealth: Double
    public var startingTechDebt: Double
    public var startingMRRJPY: Int
    public var startingDebtJPY: Int
    public var startingLeads: Int
    public var baseEmployeeCapacity: Int
    public var startingStrategy: Strategy
    public var startingFlags: [String: FlagValue]

    public init(
        startingReputation: Double = 0,
        startingTeamHealth: Double = 50,
        startingTechDebt: Double = 0,
        startingMRRJPY: Int = 0,
        startingDebtJPY: Int = 0,
        startingLeads: Int = 0,
        baseEmployeeCapacity: Int = 10,
        startingStrategy: Strategy = .balanced,
        startingFlags: [String: FlagValue] = [:]
    ) {
        self.startingReputation = startingReputation
        self.startingTeamHealth = startingTeamHealth
        self.startingTechDebt = startingTechDebt
        self.startingMRRJPY = startingMRRJPY
        self.startingDebtJPY = startingDebtJPY
        self.startingLeads = startingLeads
        self.baseEmployeeCapacity = baseEmployeeCapacity
        self.startingStrategy = startingStrategy
        self.startingFlags = startingFlags
    }
}

public struct Metrics: Codable, Equatable, Sendable {
    public var cashJPY: Int
    public var mrrJPY: Int
    public var debtJPY: Int
    public var reputation: Double
    public var teamHealth: Double
    public var techDebt: Double
    public var aiXP: Int
    public var aiMaturityLevel: Int
    public var leads: Int
}

public struct Employee: Codable, Equatable, Sendable {
    public var id: String
    public var roleId: String
    public var traitIds: [String]
    public var rampDaysRemaining: Int
}

public struct TemporaryCapacityEffect: Codable, Equatable, Sendable {
    public var discipline: String
    public var workUnitsPerDay: Double
    public var remainingDays: Int
}

public struct ProjectProgress: Codable, Equatable, Sendable {
    public var id: String
    public var type: String
    public var createdDay: Int
    public var workRemaining: [String: Double]

    public var isCompleted: Bool {
        workRemaining.values.allSatisfy { $0 <= 0.0001 }
    }
}

public struct InboxCard: Codable, Equatable, Sendable {
    public var cardId: String
    public var cycleAdded: Int
}

public struct GameSnapshot: Codable, Sendable {
    public var state: GameState
}

public struct GameState: Codable, Sendable {
    public var seed: UInt64
    public var day: Int
    public var companyMinutes: Int
    public var activeRealMinutes: Int
    public var activeRealMinutesSinceCard: Int
    public var cycle: Int

    public var metrics: Metrics
    public var strategy: Strategy
    public var flags: [String: FlagValue]

    public var baseEmployeeCapacity: Int
    public var employees: [Employee]
    public var unlockedPolicyIDs: Set<String>
    public var enabledPolicyIDs: Set<String>
    public var acquiredFacilityIDs: Set<String>
    public var temporaryCapacityEffects: [TemporaryCapacityEffect]

    public var unassignedFounderWork: [String: Double]
    public var unassignedTeamWork: [String: Double]

    public var activeProjects: [ProjectProgress]
    public var completedProjectIDs: Set<String>
    public var completedProjectsByType: [String: Int]

    public var inbox: [InboxCard]
    public var cardCooldownUntilCycle: [String: Int]
    public var cardTitleCooldownUntilCycle: [String: Int]?
    public var recentCardCategories: [String]
    public var recentCardTitleKeys: [String]?

    public var chapterIndex: Int
    public var mode: String

    public var isGameOver: Bool
    public var endgameType: String?

    public static func initial(data: GameData, seed: UInt64 = 42, bootstrap: BootstrapConfig = .init()) -> GameState {
        let founder = Employee(id: UUID().uuidString, roleId: "ROLE_FOUNDER", traitIds: [], rampDaysRemaining: 0)
        return GameState(
            seed: seed,
            day: 1,
            companyMinutes: 0,
            activeRealMinutes: 0,
            activeRealMinutesSinceCard: 0,
            cycle: 0,
            metrics: Metrics(
                cashJPY: data.balance.economy.startingCashJPY,
                mrrJPY: bootstrap.startingMRRJPY,
                debtJPY: bootstrap.startingDebtJPY,
                reputation: bootstrap.startingReputation,
                teamHealth: bootstrap.startingTeamHealth,
                techDebt: bootstrap.startingTechDebt,
                aiXP: 0,
                aiMaturityLevel: 0,
                leads: bootstrap.startingLeads
            ),
            strategy: bootstrap.startingStrategy,
            flags: bootstrap.startingFlags,
            baseEmployeeCapacity: bootstrap.baseEmployeeCapacity,
            employees: [founder],
            unlockedPolicyIDs: [],
            enabledPolicyIDs: [],
            acquiredFacilityIDs: [],
            temporaryCapacityEffects: [],
            unassignedFounderWork: [:],
            unassignedTeamWork: [:],
            activeProjects: [],
            completedProjectIDs: [],
            completedProjectsByType: [:],
            inbox: [],
            cardCooldownUntilCycle: [:],
            cardTitleCooldownUntilCycle: [:],
            recentCardCategories: [],
            recentCardTitleKeys: [],
            chapterIndex: 0,
            mode: data.activityRules.defaultMode,
            isGameOver: false,
            endgameType: nil
        )
    }

    public var teamSize: Int {
        employees.count
    }

    public var hasProductLaunched: Bool {
        if let fromFlag = flags["hasProductLaunched"]?.boolValue {
            return fromFlag
        }
        return metrics.mrrJPY > 0
    }

    public mutating func addWork(_ value: Double, discipline: String, founder: Bool) {
        guard value > 0 else { return }
        if founder {
            unassignedFounderWork[discipline, default: 0] += value
        } else {
            unassignedTeamWork[discipline, default: 0] += value
        }
    }

    public mutating func clamp(with data: GameData) {
        metrics.teamHealth = min(max(metrics.teamHealth, 0), data.balance.dynamics.teamHealth.max)
        metrics.techDebt = min(max(metrics.techDebt, 0), data.balance.dynamics.techDebt.max)
        metrics.reputation = min(max(metrics.reputation, 0), data.balance.dynamics.reputation.max)
        metrics.aiMaturityLevel = min(max(metrics.aiMaturityLevel, 0), data.balance.dynamics.ai.maxLevel)
    }
}
