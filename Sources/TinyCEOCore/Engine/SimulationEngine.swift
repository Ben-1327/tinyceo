import Foundation

public struct SimulationStepResult: Sendable {
    public var generatedCardIDs: [String] = []
    public var resolvedCardID: String?
    public var dayAdvancedBy: Int = 0
    public var classifiedCategory: ActivityCategory?
    public var sampledDomain: String?
    public var logs: [String] = []
}

public struct DailyComputation: Sendable {
    public var producedWorkByDiscipline: [String: Double]
}

public struct ProgressLockReliefResult: Sendable {
    public var blockedDisciplines: [String]
    public var cashBridgeJPY: Int
}

public struct SimulationEngine: Sendable {
    public let data: GameData
    public let classifier: ActivityClassifier
    public let deckEngine: CardDeckEngine
    public let effectExecutor: EffectExecutor

    public init(data: GameData) {
        self.data = data
        self.classifier = ActivityClassifier(rules: data.activityRules)
        self.deckEngine = CardDeckEngine(data: data)
        self.effectExecutor = EffectExecutor(data: data)
    }

    public func ensureOnStartCard(state: inout GameState, rng: inout SeededGenerator) {
        ensureCardCadenceInitialized(state: &state, rng: &rng)

        if state.flags[SystemFlagKeys.onStartCardGenerated]?.boolValue == true {
            return
        }
        _ = deckEngine.maybeGenerateOnStart(state: &state, data: data, rng: &rng)
        state.flags[SystemFlagKeys.onStartCardGenerated] = .bool(true)
    }

    public func applyProgressLockReliefIfNeeded(state: inout GameState) -> ProgressLockReliefResult? {
        if state.flags[SystemFlagKeys.progressLockReliefApplied]?.boolValue == true {
            return nil
        }
        if state.day < 10 || state.teamSize > 1 || !state.completedProjectIDs.isEmpty {
            return nil
        }

        let blocked = blockedDisciplines(state: state).sorted()
        if blocked.isEmpty {
            return nil
        }

        for discipline in blocked {
            if hasSufficientTempCapacity(for: discipline, state: state) {
                continue
            }
            let (workUnits, days) = reliefCapacity(for: discipline)
            state.temporaryCapacityEffects.append(
                TemporaryCapacityEffect(
                    discipline: discipline,
                    workUnitsPerDay: workUnits,
                    remainingDays: days
                )
            )
        }

        let targetCash = 120_000
        let cashBridge = max(0, targetCash - state.metrics.cashJPY)
        if cashBridge > 0 {
            state.metrics.cashJPY += cashBridge
        }

        state.flags[SystemFlagKeys.progressLockReliefApplied] = .bool(true)
        state.clamp(with: data)
        return ProgressLockReliefResult(blockedDisciplines: blocked, cashBridgeJPY: cashBridge)
    }

    @discardableResult
    public func processRealMinute(
        state: inout GameState,
        signal: ActivitySignal?,
        isSessionActive: Bool,
        autoResolveCard: Bool,
        rng: inout SeededGenerator
    ) -> SimulationStepResult {
        var result = SimulationStepResult()

        guard !state.isGameOver else {
            return result
        }

        ensureOnStartCard(state: &state, rng: &rng)

        guard isSessionActive || data.balance.time.advanceTimeWhenIdle else {
            return result
        }

        let category = classifier.classify(signal: signal ?? ActivitySignal(), mode: state.mode)
        result.classifiedCategory = category
        result.sampledDomain = signal?.domain
        accumulateFounderWork(category: category, state: &state)

        ensureProjectPipeline(state: &state, rng: &rng)
        allocateFounderWork(state: &state)
        settleCompletedProjects(state: &state)
        ensureProjectPipeline(state: &state, rng: &rng)

        if category == .ai {
            state.metrics.aiXP += data.balance.dynamics.ai.xpPerRealMinuteInAICategory
            recalculateAIMaturity(state: &state)
        }

        if category == .rest {
            state.metrics.teamHealth += data.balance.workConversion.founder.breakRecoversTeamHealthPerRealMinute
        }

        state.activeRealMinutes += 1
        state.activeRealMinutesSinceCard += 1
        state.companyMinutes += data.balance.time.timeScaleCompanyMinPerRealMin

        let daysToAdvance = state.companyMinutes / 1440
        if daysToAdvance > 0 {
            for _ in 0..<daysToAdvance {
                let daily = processCompanyDay(state: &state, rng: &rng)
                result.logs.append("daily-produced=\(daily.producedWorkByDiscipline)")
                result.dayAdvancedBy += 1
            }
            state.companyMinutes = state.companyMinutes % 1440
        }

        let interval = currentCardCadenceMinutes(state: state)
        while state.activeRealMinutesSinceCard >= interval {
            state.activeRealMinutesSinceCard = 0
            state.cycle += 1

            if let card = deckEngine.maybeGenerateCycleCard(state: &state, data: data, rng: &rng) {
                result.generatedCardIDs.append(card.id)
            }

            if autoResolveCard, let resolved = resolveNextCard(state: &state, optionIndex: 0, rng: &rng) {
                result.resolvedCardID = resolved.id
                result.logs.append("resolved=\(resolved.id)")
            }

            state.nextCardIntervalRealMinutes = sampleNextCardCadenceMinutes(state: state, rng: &rng)
        }

        clearInboxOverflowFlagIfRecovered(state: &state)
        state.clamp(with: data)
        return result
    }

    @discardableResult
    public func resolveNextCard(state: inout GameState, optionIndex: Int, rng: inout SeededGenerator) -> CardDefinition? {
        guard !state.inbox.isEmpty else {
            return nil
        }

        let inboxItem = state.inbox.removeFirst()
        guard let card = deckEngine.card(by: inboxItem.cardId) else {
            return nil
        }

        _ = effectExecutor.apply(card: card, optionIndex: optionIndex, state: &state, data: data, rng: &rng)
        clearInboxOverflowFlagIfRecovered(state: &state)
        state.clamp(with: data)
        return card
    }

    public func estimateRiskLevel(state: GameState) -> RiskLevel {
        if state.metrics.cashJPY <= 80_000 || state.metrics.teamHealth <= 30 || state.metrics.techDebt >= 60 {
            return .danger
        }
        if state.metrics.cashJPY <= 180_000 || state.metrics.teamHealth <= 45 || state.metrics.techDebt >= 35 {
            return .warn
        }
        return .normal
    }

    private func accumulateFounderWork(category: ActivityCategory, state: inout GameState) {
        let rates = data.balance.workConversion.founder.categoryRatesWorkUnitsPerRealMinute[category.rawValue] ?? [:]
        for (discipline, perMinute) in rates {
            state.addWork(perMinute, discipline: discipline, founder: true)
        }
    }

    private func processCompanyDay(state: inout GameState, rng: inout SeededGenerator) -> DailyComputation {
        state.day += 1
        unlockChaptersIfNeeded(state: &state)

        let produced = produceTeamWork(state: &state)
        state.temporaryCapacityEffects = state.temporaryCapacityEffects.compactMap {
            var mutable = $0
            mutable.remainingDays -= 1
            return mutable.remainingDays > 0 ? mutable : nil
        }

        ensureProjectPipeline(state: &state, rng: &rng)
        allocateWork(state: &state)
        settleCompletedProjects(state: &state)
        applyFinance(state: &state)
        applyDynamics(state: &state, producedWork: produced)
        applyBankruptcyRule(state: &state)
        state.clamp(with: data)

        return DailyComputation(producedWorkByDiscipline: produced)
    }

    private func produceTeamWork(state: inout GameState) -> [String: Double] {
        var produced: [String: Double] = [:]

        let aiBoost = 1 + (Double(state.metrics.aiMaturityLevel) * data.balance.dynamics.ai.workEfficiencyBonusPerLevel)

        for employee in state.employees where employee.roleId != "ROLE_FOUNDER" {
            guard let role = data.roles.roles.first(where: { $0.id == employee.roleId }) else {
                continue
            }

            let rampMultiplier: Double
            if employee.rampDaysRemaining > 0 {
                rampMultiplier = 0.6
            } else {
                rampMultiplier = 1
            }

            let speedMultiplier = roleMultiplier(roleID: role.id, traitIDs: employee.traitIds, state: state, op: "SPEED_MULT")
            let roleOutputMultiplier = roleSpecificOutputMultiplier(roleID: role.id, traitIDs: employee.traitIds)
            let finalMultiplier = rampMultiplier * aiBoost * speedMultiplier * roleOutputMultiplier

            for (discipline, baseOutput) in role.baseOutputWorkUnitsPerCompanyDay {
                let producedValue = baseOutput * finalMultiplier
                produced[discipline, default: 0] += producedValue
                state.addWork(producedValue, discipline: discipline, founder: false)
            }
        }

        for temp in state.temporaryCapacityEffects {
            produced[temp.discipline, default: 0] += temp.workUnitsPerDay
            state.addWork(temp.workUnitsPerDay, discipline: temp.discipline, founder: false)
        }

        for index in state.employees.indices {
            if state.employees[index].rampDaysRemaining > 0 {
                state.employees[index].rampDaysRemaining -= 1
            }
        }

        return produced
    }

    private func roleSpecificOutputMultiplier(roleID: String, traitIDs: [String]) -> Double {
        var multiplier = 1.0
        let traitOps = traitIDs.compactMap { traitID in
            data.traits.traits.first(where: { $0.id == traitID })
        }.flatMap { $0.effects }

        for effect in traitOps {
            switch effect.op {
            case "OPS_OUTPUT_MULT" where roleID == "ROLE_OPS":
                multiplier *= effect.value
            case "DESIGN_OUTPUT_MULT" where roleID == "ROLE_DESIGNER":
                multiplier *= effect.value
            default:
                continue
            }
        }
        return multiplier
    }

    private func roleMultiplier(roleID: String, traitIDs: [String], state: GameState, op: String) -> Double {
        var value = 1.0

        let traitEffects = traitIDs.compactMap { traitID in
            data.traits.traits.first(where: { $0.id == traitID })
        }.flatMap { $0.effects }

        for effect in traitEffects where effect.op == op {
            value *= effect.value
        }

        for policyID in state.enabledPolicyIDs {
            guard let policy = data.policies.policies.first(where: { $0.id == policyID }) else { continue }
            for effect in policy.effects where effect.op == op {
                value *= effect.value
            }
        }

        return value
    }

    private func ensureProjectPipeline(state: inout GameState, rng: inout SeededGenerator) {
        let maxProjects = maxConcurrentProjects(state: state)

        while state.activeProjects.count < maxProjects {
            guard let next = generateProjectTemplate(state: state, rng: &rng) else {
                break
            }
            if state.activeProjects.contains(where: { $0.id == next.id }) {
                break
            }
            state.activeProjects.append(ProjectProgress(id: next.id, type: next.type, createdDay: state.day, workRemaining: next.workRequired))
        }
    }

    private func generateProjectTemplate(state: GameState, rng: inout SeededGenerator) -> ProjectTemplate? {
        let weightsByType = data.projects.generationRules.focusWeightsByStrategy[state.strategy.rawValue] ?? [:]
        guard !weightsByType.isEmpty else {
            return nil
        }

        let sortedTypes = weightsByType.keys.sorted()
        let typeWeights = sortedTypes.map { weightsByType[$0] ?? 0 }
        guard let typeIndex = rng.chooseIndex(weights: typeWeights) else {
            return nil
        }

        let chosenType = sortedTypes[typeIndex]
        let activeIDs = Set(state.activeProjects.map(\.id))
        let candidates = data.projects.projects.filter { template in
            template.type == chosenType && !activeIDs.contains(template.id)
        }

        let feasibleCandidates = candidates.filter { isProjectFeasible($0, state: state) }
        if let candidate = rng.chooseElement(feasibleCandidates) {
            return candidate
        }

        if let candidate = rng.chooseElement(candidates) {
            return candidate
        }

        let feasibleByType = data.projects.projects.filter { template in
            template.type == chosenType && isProjectFeasible(template, state: state)
        }
        if let candidate = rng.chooseElement(feasibleByType) {
            return candidate
        }

        return rng.chooseElement(data.projects.projects.filter { $0.type == chosenType })
    }

    private func allocateWork(state: inout GameState) {
        guard !state.activeProjects.isEmpty else {
            state.unassignedFounderWork.removeAll()
            state.unassignedTeamWork.removeAll()
            return
        }

        allocateFounderWork(state: &state)
        allocateTeamWork(state: &state)
        state.unassignedTeamWork.removeAll()
    }

    private func allocateFounderWork(state: inout GameState) {
        guard !state.activeProjects.isEmpty else {
            state.unassignedFounderWork.removeAll()
            return
        }

        let priorityOrder = prioritizedProjectIndices(projects: state.activeProjects, strategy: state.strategy)

        for (discipline, amount) in state.unassignedFounderWork {
            var remaining = amount
            for projectIndex in priorityOrder where remaining > 0 {
                let needed = state.activeProjects[projectIndex].workRemaining[discipline, default: 0]
                guard needed > 0 else { continue }
                let used = min(needed, remaining)
                state.activeProjects[projectIndex].workRemaining[discipline] = needed - used
                remaining -= used
            }
        }

        state.unassignedFounderWork.removeAll()
    }

    private func allocateTeamWork(state: inout GameState) {
        for (discipline, amount) in state.unassignedTeamWork {
            var remaining = amount
            while remaining > 0 {
                guard let targetIndex = state.activeProjects.indices.max(by: {
                    state.activeProjects[$0].workRemaining[discipline, default: 0]
                        < state.activeProjects[$1].workRemaining[discipline, default: 0]
                }) else {
                    break
                }
                let needed = state.activeProjects[targetIndex].workRemaining[discipline, default: 0]
                guard needed > 0 else { break }
                let used = min(remaining, needed)
                state.activeProjects[targetIndex].workRemaining[discipline] = needed - used
                remaining -= used
            }
        }
    }

    private func isProjectFeasible(_ template: ProjectTemplate, state: GameState) -> Bool {
        let availableDisciplines = discoverAvailableDisciplines(state: state)
        for (discipline, required) in template.workRequired where required > 0 {
            if !availableDisciplines.contains(discipline) {
                return false
            }
        }
        return true
    }

    private func discoverAvailableDisciplines(state: GameState) -> Set<String> {
        var disciplines: Set<String> = []

        for ratesByDiscipline in data.balance.workConversion.founder.categoryRatesWorkUnitsPerRealMinute.values {
            for (discipline, rate) in ratesByDiscipline where rate > 0 {
                disciplines.insert(discipline)
            }
        }

        for employee in state.employees where employee.roleId != "ROLE_FOUNDER" {
            guard let role = data.roles.roles.first(where: { $0.id == employee.roleId }) else {
                continue
            }
            for (discipline, output) in role.baseOutputWorkUnitsPerCompanyDay where output > 0 {
                disciplines.insert(discipline)
            }
        }

        for temp in state.temporaryCapacityEffects where temp.workUnitsPerDay > 0 {
            disciplines.insert(temp.discipline)
        }

        return disciplines
    }

    private func blockedDisciplines(state: GameState) -> Set<String> {
        let available = discoverAvailableDisciplines(state: state)
        var blocked: Set<String> = []
        for project in state.activeProjects {
            for (discipline, remaining) in project.workRemaining where remaining > 0.0001 {
                if !available.contains(discipline) {
                    blocked.insert(discipline)
                }
            }
        }
        return blocked
    }

    private func hasSufficientTempCapacity(for discipline: String, state: GameState) -> Bool {
        state.temporaryCapacityEffects.contains { effect in
            effect.discipline == discipline && effect.remainingDays >= 8 && effect.workUnitsPerDay >= 4
        }
    }

    private func reliefCapacity(for discipline: String) -> (Double, Int) {
        switch discipline {
        case "OPS":
            return (8, 20)
        case "DESIGN":
            return (6, 20)
        case "CS":
            return (4, 18)
        default:
            return (5, 16)
        }
    }

    private func prioritizedProjectIndices(projects: [ProjectProgress], strategy: Strategy) -> [Int] {
        projects.indices.sorted { lhs, rhs in
            let left = projects[lhs]
            let right = projects[rhs]
            let leftScore = projectPriorityScore(type: left.type, strategy: strategy)
            let rightScore = projectPriorityScore(type: right.type, strategy: strategy)
            if leftScore == rightScore {
                return left.createdDay < right.createdDay
            }
            return leftScore > rightScore
        }
    }

    private func projectPriorityScore(type: String, strategy: Strategy) -> Int {
        switch strategy {
        case .contractHeavy:
            switch type {
            case "CONTRACT": return 3
            case "INTERNAL": return 2
            case "PRODUCT": return 1
            default: return 0
            }
        case .productHeavy:
            switch type {
            case "PRODUCT": return 3
            case "INTERNAL": return 2
            case "CONTRACT": return 1
            default: return 0
            }
        case .balanced:
            switch type {
            case "PRODUCT", "CONTRACT": return 2
            case "INTERNAL": return 1
            default: return 0
            }
        }
    }

    private func settleCompletedProjects(state: inout GameState) {
        var survivors: [ProjectProgress] = []

        for project in state.activeProjects {
            if !project.isCompleted {
                survivors.append(project)
                continue
            }

            guard let template = data.projects.projects.first(where: { $0.id == project.id }) else {
                continue
            }

            state.completedProjectIDs.insert(project.id)
            state.completedProjectsByType[project.type, default: 0] += 1

            if let cash = template.reward.cashJPY {
                state.metrics.cashJPY += cash
            }
            if let mrr = template.reward.mrrJPY {
                state.metrics.mrrJPY += mrr
                if mrr > 0 {
                    state.flags["hasProductLaunched"] = .bool(true)
                }
            }
            if let reputation = template.reward.reputation {
                state.metrics.reputation += reputation
            }
            if let debt = template.reward.techDebt {
                state.metrics.techDebt += debt
            }
            if let teamHealth = template.reward.teamHealth {
                state.metrics.teamHealth += teamHealth
            }
            for policyID in template.reward.unlockPolicyIds ?? [] {
                state.unlockedPolicyIDs.insert(policyID)
            }
        }

        state.activeProjects = survivors
    }

    private func applyFinance(state: inout GameState) {
        let dailyMRR = Int((Double(state.metrics.mrrJPY) * data.balance.economy.mrrPaidPerCompanyDayFactor).rounded(.down))
        state.metrics.cashJPY += dailyMRR

        state.metrics.cashJPY -= data.balance.economy.overheadJPYPerCompanyDay

        let salaryPerDay = state.employees
            .compactMap { employee -> Int? in
                guard employee.roleId != "ROLE_FOUNDER",
                      let role = data.roles.roles.first(where: { $0.id == employee.roleId }) else {
                    return nil
                }
                return Int((Double(role.monthlySalaryJPY) / 30.0).rounded(.toNearestOrAwayFromZero))
            }
            .reduce(0, +)
        state.metrics.cashJPY -= salaryPerDay

        let policyCostPerDay = state.enabledPolicyIDs
            .compactMap { policyID -> Int? in
                guard let policy = data.policies.policies.first(where: { $0.id == policyID }) else {
                    return nil
                }
                return Int((Double(policy.monthlyCostJPY) / 30.0).rounded(.toNearestOrAwayFromZero))
            }
            .reduce(0, +)
        state.metrics.cashJPY -= policyCostPerDay

        if data.balance.economy.loan.enabled, state.metrics.debtJPY > 0 {
            let dailyInterest = Double(state.metrics.debtJPY) * data.balance.economy.loan.baseInterestAPR / 365.0
            state.metrics.cashJPY -= Int(dailyInterest.rounded(.up))
        }
    }

    private func applyDynamics(state: inout GameState, producedWork: [String: Double]) {
        let maxProjects = maxConcurrentProjects(state: state)
        let overload = max(0, state.activeProjects.count - maxProjects)

        if overload > 0 {
            state.metrics.techDebt += data.balance.dynamics.techDebt.dailyIncreaseFromRushing * Double(overload)
            state.metrics.teamHealth -= data.balance.dynamics.teamHealth.dailyDecreaseFromOverload * Double(overload)
        }

        let opsOutput = producedWork["OPS", default: 0]
        if opsOutput > 0 {
            let reduction = min(data.balance.dynamics.techDebt.dailyDecreaseFromOps, opsOutput * 0.12)
            state.metrics.techDebt -= reduction
        }

        state.metrics.reputation += data.balance.dynamics.reputation.dailyDriftToBaseline

        let cultureRecoveryMult = policyMultiplier(op: "TEAM_HEALTH_DRAIN_MULT", state: state)
        let recovery = data.balance.dynamics.teamHealth.dailyIncreaseFromCulture * max(1, 2 - cultureRecoveryMult)
        state.metrics.teamHealth += recovery * 0.1

        let aiRiskMult = policyMultiplier(op: "AI_RISK_MULT", state: state)
        if state.metrics.aiMaturityLevel > 0 {
            let risk = Double(state.metrics.aiMaturityLevel) * data.balance.dynamics.ai.techDebtRiskBonusPerLevel * aiRiskMult
            state.metrics.techDebt += risk
        }
    }

    private func applyBankruptcyRule(state: inout GameState) {
        let debtLimit = data.balance.economy.loan.maxDebtToMRRRatio * Double(max(state.metrics.mrrJPY, 1))
        if state.metrics.cashJPY < 0 && Double(state.metrics.debtJPY) > debtLimit {
            state.isGameOver = true
            state.endgameType = "BANKRUPT"
        }
    }

    private func unlockChaptersIfNeeded(state: inout GameState) {
        guard state.chapterIndex + 1 < data.progression.chapters.count else {
            return
        }

        var next = state.chapterIndex + 1
        while next < data.progression.chapters.count {
            let chapter = data.progression.chapters[next]
            let conditions = chapter.unlockConditions ?? []
            if ConditionEvaluator.evaluateAll(conditions, state: state, data: data) {
                state.chapterIndex = next
                for policyID in chapter.unlocks.policyIds {
                    state.unlockedPolicyIDs.insert(policyID)
                }
                next += 1
            } else {
                break
            }
        }
    }

    private func maxConcurrentProjects(state: GameState) -> Int {
        var maxCount = data.balance.limits.maxConcurrentProjectsBase

        for policyID in state.enabledPolicyIDs {
            guard let policy = data.policies.policies.first(where: { $0.id == policyID }) else {
                continue
            }
            for effect in policy.effects where effect.op == "MAX_CONCURRENT_PROJECTS" {
                maxCount = max(maxCount, Int(effect.value))
            }
        }

        if let override = state.flags["maxActiveProjectsOverride"]?.intValue {
            maxCount += max(0, override)
        }

        return max(1, maxCount)
    }

    private func recalculateAIMaturity(state: inout GameState) {
        let thresholds = data.balance.dynamics.ai.levelThresholdsXP
        var level = 0
        for (index, threshold) in thresholds.enumerated() where state.metrics.aiXP >= threshold {
            level = index
        }
        state.metrics.aiMaturityLevel = min(level, data.balance.dynamics.ai.maxLevel)
    }

    private func policyMultiplier(op: String, state: GameState) -> Double {
        var value = 1.0
        for policyID in state.enabledPolicyIDs {
            guard let policy = data.policies.policies.first(where: { $0.id == policyID }) else { continue }
            for effect in policy.effects where effect.op == op {
                value *= effect.value
            }
        }
        return value
    }

    private func ensureCardCadenceInitialized(state: inout GameState, rng: inout SeededGenerator) {
        if state.nextCardIntervalRealMinutes != nil {
            return
        }
        state.nextCardIntervalRealMinutes = sampleNextCardCadenceMinutes(state: state, rng: &rng)
    }

    private func currentCardCadenceMinutes(state: GameState) -> Int {
        let fallback = data.balance.time.ceoCardIntervalRealMinutes
        return max(20, state.nextCardIntervalRealMinutes ?? fallback)
    }

    private func sampleNextCardCadenceMinutes(state: GameState, rng: inout SeededGenerator) -> Int {
        let range = cadenceRange(forActiveMinutes: state.activeRealMinutes)
        let span = range.upperBound - range.lowerBound + 1
        let sampled = range.lowerBound + Int(rng.nextUInt64() % UInt64(span))

        let inboxAdjustment = max(0, state.inbox.count - 1) * 12
        let riskAdjustment: Int
        if state.metrics.cashJPY <= 120_000 || state.metrics.teamHealth <= 40 || state.metrics.techDebt >= 45 {
            riskAdjustment = -10
        } else {
            riskAdjustment = 0
        }

        return max(20, sampled + inboxAdjustment + riskAdjustment)
    }

    private func cadenceRange(forActiveMinutes activeMinutes: Int) -> ClosedRange<Int> {
        switch activeMinutes {
        case ..<180:
            return 30...70
        case ..<480:
            return 55...105
        default:
            return 80...160
        }
    }

    private func clearInboxOverflowFlagIfRecovered(state: inout GameState) {
        if state.inbox.count < data.balance.time.maxInboxCards {
            state.flags[SystemFlagKeys.inboxOverflowedSinceLastRelief] = .bool(false)
        }
    }
}
