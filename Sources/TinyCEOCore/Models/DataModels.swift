import Foundation

public enum FlagValue: Codable, Equatable, Sendable {
    case bool(Bool)
    case int(Int)
    case double(Double)
    case string(String)

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let bool = try? container.decode(Bool.self) {
            self = .bool(bool)
            return
        }
        if let int = try? container.decode(Int.self) {
            self = .int(int)
            return
        }
        if let double = try? container.decode(Double.self) {
            self = .double(double)
            return
        }
        if let string = try? container.decode(String.self) {
            self = .string(string)
            return
        }
        throw DecodingError.typeMismatch(
            FlagValue.self,
            DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unsupported value type")
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .bool(let value):
            try container.encode(value)
        case .int(let value):
            try container.encode(value)
        case .double(let value):
            try container.encode(value)
        case .string(let value):
            try container.encode(value)
        }
    }

    public var intValue: Int? {
        switch self {
        case .int(let value):
            return value
        case .double(let value):
            return Int(value)
        case .string(let value):
            return Int(value)
        case .bool:
            return nil
        }
    }

    public var doubleValue: Double? {
        switch self {
        case .int(let value):
            return Double(value)
        case .double(let value):
            return value
        case .string(let value):
            return Double(value)
        case .bool:
            return nil
        }
    }

    public var boolValue: Bool? {
        switch self {
        case .bool(let value):
            return value
        case .string(let value):
            return Bool(value)
        case .int(let value):
            return value != 0
        case .double(let value):
            return value != 0
        }
    }

    public var stringValue: String {
        switch self {
        case .bool(let value):
            return String(value)
        case .int(let value):
            return String(value)
        case .double(let value):
            return String(value)
        case .string(let value):
            return value
        }
    }
}

public struct BalanceData: Codable, Sendable {
    public let schemaVersion: Int
    public let time: TimeSettings
    public let economy: EconomySettings
    public let workConversion: WorkConversionSettings
    public let dynamics: DynamicsSettings
    public let limits: LimitSettings
}

public struct TimeSettings: Codable, Sendable {
    public let timeScaleCompanyMinPerRealMin: Int
    public let ceoCardIntervalRealMinutes: Int
    public let maxInboxCards: Int
    public let idleThresholdMinutes: Int
    public let advanceTimeWhenIdle: Bool
}

public struct EconomySettings: Codable, Sendable {
    public let startingCashJPY: Int
    public let overheadJPYPerCompanyDay: Int
    public let mrrPaidPerCompanyDayFactor: Double
    public let loan: LoanSettings
}

public struct LoanSettings: Codable, Sendable {
    public let enabled: Bool
    public let baseInterestAPR: Double
    public let maxDebtToMRRRatio: Double
}

public struct WorkConversionSettings: Codable, Sendable {
    public let founder: FounderWorkConversion
    public let company: CompanyWorkConversion
}

public struct FounderWorkConversion: Codable, Sendable {
    public let categoryRatesWorkUnitsPerRealMinute: [String: [String: Double]]
    public let breakRecoversTeamHealthPerRealMinute: Double
}

public struct CompanyWorkConversion: Codable, Sendable {
    public let baseEfficiencyMultiplier: Double
    public let techDebtSpeedPenaltyPerPoint: Double
    public let teamHealthSpeedBonusPerPointFrom50: Double
}

public struct DynamicsSettings: Codable, Sendable {
    public let techDebt: TechDebtDynamics
    public let teamHealth: TeamHealthDynamics
    public let reputation: ReputationDynamics
    public let ai: AIDynamics
}

public struct TechDebtDynamics: Codable, Sendable {
    public let max: Double
    public let dailyIncreaseFromRushing: Double
    public let dailyDecreaseFromOps: Double
}

public struct TeamHealthDynamics: Codable, Sendable {
    public let max: Double
    public let dailyDecreaseFromOverload: Double
    public let dailyIncreaseFromCulture: Double
}

public struct ReputationDynamics: Codable, Sendable {
    public let max: Double
    public let dailyDriftToBaseline: Double
}

public struct AIDynamics: Codable, Sendable {
    public let maxLevel: Int
    public let xpPerRealMinuteInAICategory: Int
    public let levelThresholdsXP: [Int]
    public let workEfficiencyBonusPerLevel: Double
    public let techDebtRiskBonusPerLevel: Double
}

public struct LimitSettings: Codable, Sendable {
    public let maxConcurrentProjectsBase: Int
    public let maxConcurrentProjectsWithPMPolicy: Int
}

public struct ActivityRulesData: Codable, Sendable {
    public let schemaVersion: Int
    public let modes: [String]
    public let defaultMode: String
    public let appCategoryRules: [AppCategoryRule]
    public let browserDomainOverrides: [BrowserDomainOverride]
    public let notes: String
}

public struct AppCategoryRule: Codable, Sendable {
    public let match: String
    public let pattern: String
    public let category: String
}

public struct BrowserDomainOverride: Codable, Sendable {
    public let domain: String
    public let modeToCategory: [String: String]
}

public struct RolesData: Codable, Sendable {
    public let schemaVersion: Int
    public let disciplines: [String]
    public let roles: [RoleDefinition]
}

public struct RoleDefinition: Codable, Sendable {
    public let id: String
    public let name: String
    public let monthlySalaryJPY: Int
    public let baseOutputWorkUnitsPerCompanyDay: [String: Double]
}

public struct TraitsData: Codable, Sendable {
    public let schemaVersion: Int
    public let traits: [TraitDefinition]
}

public struct TraitDefinition: Codable, Sendable {
    public let id: String
    public let name: String
    public let effects: [ModifierEffect]
}

public struct PoliciesData: Codable, Sendable {
    public let schemaVersion: Int
    public let policies: [PolicyDefinition]
}

public struct PolicyDefinition: Codable, Sendable {
    public let id: String
    public let name: String
    public let unlockChapter: Int
    public let upfrontCostJPY: Int
    public let monthlyCostJPY: Int
    public let effects: [ModifierEffect]
}

public struct FacilitiesData: Codable, Sendable {
    public let schemaVersion: Int
    public let facilities: [FacilityDefinition]
}

public struct FacilityDefinition: Codable, Sendable {
    public let id: String
    public let name: String
    public let upfrontCostJPY: Int
    public let effects: [ModifierEffect]
}

public struct ModifierEffect: Codable, Sendable {
    public let op: String
    public let value: Double
}

public struct ProjectsData: Codable, Sendable {
    public let schemaVersion: Int
    public let projects: [ProjectTemplate]
    public let generationRules: ProjectGenerationRules
}

public struct ProjectTemplate: Codable, Sendable {
    public let id: String
    public let type: String
    public let name: String
    public let workRequired: [String: Double]
    public let reward: ProjectReward
}

public struct ProjectReward: Codable, Sendable {
    public let cashJPY: Int?
    public let reputation: Double?
    public let techDebt: Double?
    public let mrrJPY: Int?
    public let teamHealth: Double?
    public let unlockPolicyIds: [String]?
}

public struct ProjectGenerationRules: Codable, Sendable {
    public let maxActiveProjectsBase: Int
    public let focusWeightsByStrategy: [String: [String: Double]]
}

public struct ProgressionData: Codable, Sendable {
    public let schemaVersion: Int
    public let chapters: [ChapterDefinition]
}

public struct ChapterDefinition: Codable, Sendable {
    public let id: String
    public let name: String
    public let unlockConditions: [CardCondition]?
    public let unlocks: ChapterUnlocks
}

public struct ChapterUnlocks: Codable, Sendable {
    public let cardCategories: [String]
    public let policyIds: [String]
}

public struct CardsData: Codable, Sendable {
    public let schemaVersion: Int
    public let cards: [CardDefinition]
    public let notes: String
}

public struct CardDefinition: Codable, Sendable {
    public let id: String
    public let title: String
    public let category: String
    public let rarity: String
    public let baseWeight: Double
    public let cooldownCycles: Int
    public let trigger: String
    public let conditions: [CardCondition]
    public let weightMultipliers: [CardWeightMultiplier]
    public let options: [CardOption]
}

public struct CardWeightMultiplier: Codable, Sendable {
    public let metric: String
    public let op: String
    public let value: FlagValue
    public let multiplier: Double
}

public struct CardCondition: Codable, Sendable {
    public let metric: String?
    public let flag: String?
    public let op: String
    public let value: FlagValue
}

public struct CardOption: Codable, Sendable {
    public let label: String
    public let effects: [CardEffect]
}

public struct CardEffect: Codable, Sendable {
    public let op: String
    public let value: FlagValue?
    public let key: String?
    public let projectId: String?
    public let policyId: String?
    public let roleId: String?
    public let traitsRoll: Int?
    public let discipline: String?
    public let workUnitsPerDay: Double?
    public let days: Int?
    public let type: String?
}

public struct GameData: Sendable {
    public let balance: BalanceData
    public let activityRules: ActivityRulesData
    public let roles: RolesData
    public let traits: TraitsData
    public let policies: PoliciesData
    public let facilities: FacilitiesData
    public let projects: ProjectsData
    public let progression: ProgressionData
    public let cards: CardsData

    public init(
        balance: BalanceData,
        activityRules: ActivityRulesData,
        roles: RolesData,
        traits: TraitsData,
        policies: PoliciesData,
        facilities: FacilitiesData,
        projects: ProjectsData,
        progression: ProgressionData,
        cards: CardsData
    ) {
        self.balance = balance
        self.activityRules = activityRules
        self.roles = roles
        self.traits = traits
        self.policies = policies
        self.facilities = facilities
        self.projects = projects
        self.progression = progression
        self.cards = cards
    }
}
