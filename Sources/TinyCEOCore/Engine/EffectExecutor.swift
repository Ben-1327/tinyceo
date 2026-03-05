import Foundation

public struct EffectExecutor: Sendable {
    private let roleByID: [String: RoleDefinition]
    private let traitByID: [String: TraitDefinition]
    private let policyByID: [String: PolicyDefinition]
    private let projectByID: [String: ProjectTemplate]
    private let facilitiesByID: [String: FacilityDefinition]

    public init(data: GameData) {
        self.roleByID = Dictionary(uniqueKeysWithValues: data.roles.roles.map { ($0.id, $0) })
        self.traitByID = Dictionary(uniqueKeysWithValues: data.traits.traits.map { ($0.id, $0) })
        self.policyByID = Dictionary(uniqueKeysWithValues: data.policies.policies.map { ($0.id, $0) })
        self.projectByID = Dictionary(uniqueKeysWithValues: data.projects.projects.map { ($0.id, $0) })
        self.facilitiesByID = Dictionary(uniqueKeysWithValues: data.facilities.facilities.map { ($0.id, $0) })
    }

    @discardableResult
    public func apply(
        card: CardDefinition,
        optionIndex: Int,
        state: inout GameState,
        data: GameData,
        rng: inout SeededGenerator
    ) -> [String] {
        guard card.options.indices.contains(optionIndex) else {
            return ["invalid-option-index"]
        }

        let option = card.options[optionIndex]
        let ordered = option.effects.sorted { phase(of: $0.op) < phase(of: $1.op) }
        var logs: [String] = []

        for effect in ordered {
            apply(effect: effect, card: card, state: &state, data: data, rng: &rng, logs: &logs)
        }

        state.clamp(with: data)
        return logs
    }

    private func phase(of op: String) -> Int {
        switch op {
        case "SET_STRATEGY", "SET_FLAG", "ADD_FLAG":
            return 1
        case "UNLOCK_POLICY", "ENABLE_POLICY":
            return 2
        case "HIRE_RANDOM", "ADD_PROJECT", "ADD_TEMP_CAPACITY":
            return 3
        case "ADD_CASH", "ADD_DEBT", "ADD_MRR", "ADD_REPUTATION", "ADD_TEAM_HEALTH", "ADD_TECH_DEBT", "ADD_AI_XP", "ADD_LEADS":
            return 4
        case "ENDGAME":
            return 5
        default:
            return 99
        }
    }

    private func apply(
        effect: CardEffect,
        card: CardDefinition,
        state: inout GameState,
        data: GameData,
        rng: inout SeededGenerator,
        logs: inout [String]
    ) {
        switch effect.op {
        case "SET_STRATEGY":
            guard let raw = effect.value?.stringValue, let strategy = Strategy(rawValue: raw) else {
                logs.append("set-strategy-skipped")
                return
            }
            state.strategy = strategy
            logs.append("strategy=\(strategy.rawValue)")

        case "SET_FLAG", "ADD_FLAG":
            guard let key = effect.key else {
                logs.append("flag-key-missing")
                return
            }
            state.flags[key] = effect.value ?? .bool(true)
            logs.append("flag:\(key)=\(state.flags[key]?.stringValue ?? "")")

        case "UNLOCK_POLICY":
            guard let policyID = effect.policyId else {
                logs.append("unlock-policy-id-missing")
                return
            }
            state.unlockedPolicyIDs.insert(policyID)
            logs.append("policy-unlocked:\(policyID)")

        case "ENABLE_POLICY":
            guard let policyID = effect.policyId, let policy = policyByID[policyID] else {
                logs.append("enable-policy-missing")
                return
            }
            if !state.unlockedPolicyIDs.contains(policyID) {
                state.unlockedPolicyIDs.insert(policyID)
            }
            if state.enabledPolicyIDs.contains(policyID) {
                logs.append("policy-already-enabled:\(policyID)")
                return
            }
            guard state.metrics.cashJPY >= policy.upfrontCostJPY else {
                logs.append("policy-enable-no-cash:\(policyID)")
                return
            }
            state.metrics.cashJPY -= policy.upfrontCostJPY
            state.enabledPolicyIDs.insert(policyID)
            logs.append("policy-enabled:\(policyID)")

        case "HIRE_RANDOM":
            guard let roleID = resolveHireRole(effect: effect, state: state, data: data, rng: &rng), let role = roleByID[roleID] else {
                logs.append("hire-role-not-found")
                return
            }
            if state.teamSize >= maxEmployees(state: state) {
                logs.append("hire-capacity-full")
                return
            }
            if !canAffordHire(role: role, state: state, data: data) {
                logs.append("hire-runway-short")
                return
            }
            let traitCount = max(0, effect.traitsRoll ?? 1)
            let traits = pickTraits(count: traitCount, rng: &rng)
            let rampDays = max(0, Int(policyModifier(op: "NEW_HIRE_RAMP_DAYS", state: state) ?? 5))
            state.employees.append(Employee(id: UUID().uuidString, roleId: role.id, traitIds: traits, rampDaysRemaining: rampDays))
            logs.append("hire:\(role.id)")

        case "ADD_PROJECT":
            guard let projectID = effect.projectId, let template = projectByID[projectID] else {
                logs.append("project-missing")
                return
            }
            if state.activeProjects.contains(where: { $0.id == projectID }) {
                logs.append("project-already-active:\(projectID)")
                return
            }
            state.activeProjects.append(ProjectProgress(id: template.id, type: template.type, createdDay: state.day, workRemaining: template.workRequired))
            logs.append("project-added:\(projectID)")

        case "ADD_TEMP_CAPACITY":
            let discipline = effect.discipline ?? "DEV"
            let workUnits = effect.workUnitsPerDay ?? (effect.value?.doubleValue ?? 1)
            let days = max(1, effect.days ?? 2)
            state.temporaryCapacityEffects.append(
                TemporaryCapacityEffect(discipline: discipline, workUnitsPerDay: workUnits, remainingDays: days)
            )
            logs.append("temp-capacity:\(discipline)+\(workUnits)x\(days)d")

        case "ADD_CASH":
            state.metrics.cashJPY += effect.value?.intValue ?? 0
        case "ADD_DEBT":
            let amount = effect.value?.intValue ?? 0
            state.metrics.debtJPY += amount
            state.metrics.cashJPY += amount
        case "ADD_MRR":
            state.metrics.mrrJPY += effect.value?.intValue ?? 0
        case "ADD_REPUTATION":
            state.metrics.reputation += effect.value?.doubleValue ?? 0
        case "ADD_TEAM_HEALTH":
            state.metrics.teamHealth += effect.value?.doubleValue ?? 0
        case "ADD_TECH_DEBT":
            state.metrics.techDebt += effect.value?.doubleValue ?? 0
        case "ADD_AI_XP":
            let added = effect.value?.intValue ?? 0
            state.metrics.aiXP += added
            recalculateAIMaturity(state: &state, data: data)
        case "ADD_LEADS":
            state.metrics.leads += effect.value?.intValue ?? 0

        case "ENDGAME":
            state.isGameOver = true
            state.endgameType = resolveEndgameType(effect: effect, cardID: card.id)
            logs.append("endgame:\(state.endgameType ?? "GENERIC_END")")

        default:
            logs.append("unsupported-op:\(effect.op)")
        }
    }

    private func resolveHireRole(effect: CardEffect, state: GameState, data: GameData, rng: inout SeededGenerator) -> String? {
        if let roleID = effect.roleId {
            return roleID
        }

        let pool = data.roles.roles.filter { $0.id != "ROLE_FOUNDER" }
        guard !pool.isEmpty else {
            return nil
        }

        let remainingByDiscipline = state.activeProjects.reduce(into: [String: Double]()) { partial, project in
            for (discipline, remaining) in project.workRemaining where remaining > 0 {
                partial[discipline, default: 0] += remaining
            }
        }

        let weights: [Double] = pool.map { role in
            var weight = 1.0
            for (discipline, output) in role.baseOutputWorkUnitsPerCompanyDay {
                let deficit = remainingByDiscipline[discipline, default: 0]
                weight += output * (deficit / 10)
            }

            switch state.strategy {
            case .contractHeavy:
                if role.id == "ROLE_SALES" || role.id == "ROLE_OPS" {
                    weight *= 1.25
                }
            case .productHeavy:
                if role.id.contains("ENGINEER") || role.id == "ROLE_DESIGNER" {
                    weight *= 1.25
                }
            case .balanced:
                break
            }

            return max(0.001, weight)
        }

        if let idx = rng.chooseIndex(weights: weights) {
            return pool[idx].id
        }
        return pool.first?.id
    }

    private func pickTraits(count: Int, rng: inout SeededGenerator) -> [String] {
        guard count > 0 else { return [] }

        var available = Array(traitByID.keys).sorted()
        var picked: [String] = []

        while picked.count < count, !available.isEmpty {
            let index = Int(rng.nextUInt64() % UInt64(available.count))
            let candidate = available.remove(at: index)
            if conflicts(candidate, picked: picked) {
                continue
            }
            picked.append(candidate)
        }

        return picked
    }

    private func conflicts(_ candidate: String, picked: [String]) -> Bool {
        let invalidPairs: Set<Set<String>> = [
            ["TR_PERFECTIONIST", "TR_SHIP_FAST"],
            ["TR_CALM", "TR_BURNOUT_RISK"]
        ]

        for trait in picked {
            if invalidPairs.contains([candidate, trait]) {
                return true
            }
        }
        return false
    }

    private func recalculateAIMaturity(state: inout GameState, data: GameData) {
        let thresholds = data.balance.dynamics.ai.levelThresholdsXP
        var level = 0
        for (index, threshold) in thresholds.enumerated() where state.metrics.aiXP >= threshold {
            level = index
        }
        state.metrics.aiMaturityLevel = min(level, data.balance.dynamics.ai.maxLevel)
    }

    private func resolveEndgameType(effect: CardEffect, cardID: String) -> String {
        if let type = effect.type {
            return type
        }
        if cardID.contains("_MA") {
            return "MA_EXIT"
        }
        if cardID.contains("_IPO") {
            return "IPO_EXIT"
        }
        return "GENERIC_END"
    }

    private func maxEmployees(state: GameState) -> Int {
        let facilityBonus = state.acquiredFacilityIDs.reduce(0) { partial, facilityID in
            guard let facility = facilitiesByID[facilityID] else {
                return partial
            }
            let bonus = facility.effects.first(where: { $0.op == "CAPACITY_EMPLOYEES" })?.value ?? 0
            return partial + Int(bonus)
        }
        return max(1, state.baseEmployeeCapacity + facilityBonus)
    }

    private func canAffordHire(role: RoleDefinition, state: GameState, data: GameData) -> Bool {
        let monthlyFixedCostBeforeHire = monthlyFixedCost(state: state, data: data)
        let projectedMonthlyFixedCost = monthlyFixedCostBeforeHire + role.monthlySalaryJPY
        let monthlyNetBurn = max(0, projectedMonthlyFixedCost - state.metrics.mrrJPY)

        if monthlyNetBurn == 0 {
            return true
        }

        let cash = Double(max(0, state.metrics.cashJPY))
        let runwayMonths = cash / Double(monthlyNetBurn)
        if state.teamSize <= 2 {
            return runwayMonths >= 1.4
        }
        return runwayMonths >= 2.0
    }

    private func monthlyFixedCost(state: GameState, data: GameData) -> Int {
        let monthlyOverhead = data.balance.economy.overheadJPYPerCompanyDay * 30
        let employeeSalaries = state.employees.reduce(0) { partial, employee in
            guard employee.roleId != "ROLE_FOUNDER",
                  let role = roleByID[employee.roleId] else {
                return partial
            }
            return partial + role.monthlySalaryJPY
        }
        let policyCosts = state.enabledPolicyIDs.reduce(0) { partial, policyID in
            partial + (policyByID[policyID]?.monthlyCostJPY ?? 0)
        }
        return monthlyOverhead + employeeSalaries + policyCosts
    }

    private func policyModifier(op: String, state: GameState) -> Double? {
        let values = state.enabledPolicyIDs.compactMap { policyID -> Double? in
            policyByID[policyID]?.effects.first(where: { $0.op == op })?.value
        }
        guard !values.isEmpty else {
            return nil
        }
        return values.last
    }
}
