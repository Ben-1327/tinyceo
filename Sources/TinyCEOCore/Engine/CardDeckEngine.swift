import Foundation

public struct CardDeckEngine: Sendable {
    private let cardsByID: [String: CardDefinition]
    private let allCards: [CardDefinition]
    private let duplicateTitleCounts: [String: Int]

    public init(data: GameData) {
        self.allCards = data.cards.cards
        self.cardsByID = Dictionary(uniqueKeysWithValues: data.cards.cards.map { ($0.id, $0) })
        self.duplicateTitleCounts = Dictionary(grouping: data.cards.cards, by: { Self.normalizeTitle($0.title) })
            .mapValues(\.count)
    }

    public func card(by id: String) -> CardDefinition? {
        cardsByID[id]
    }

    @discardableResult
    public func maybeGenerateOnStart(state: inout GameState, data: GameData, rng: inout SeededGenerator) -> CardDefinition? {
        maybeGenerate(trigger: "ON_START", state: &state, data: data, rng: &rng)
    }

    @discardableResult
    public func maybeGenerateCycleCard(state: inout GameState, data: GameData, rng: inout SeededGenerator) -> CardDefinition? {
        maybeGenerate(trigger: "CYCLE", state: &state, data: data, rng: &rng)
    }

    @discardableResult
    private func maybeGenerate(trigger: String, state: inout GameState, data: GameData, rng: inout SeededGenerator) -> CardDefinition? {
        guard !state.isGameOver else {
            return nil
        }

        if state.inbox.count >= data.balance.time.maxInboxCards {
            applyBacklogPenalty(state: &state, data: data)
            return nil
        }

        let unlockedCategories = unlockedCardCategories(state: state, data: data)
        let candidates = allCards.filter { card in
            card.trigger == trigger
            && unlockedCategories.contains(card.category)
            && isCooldownFinished(cardID: card.id, state: state)
            && isTitleCooldownFinished(card: card, state: state)
            && !state.inbox.contains(where: { $0.cardId == card.id })
            && ConditionEvaluator.evaluateAll(card.conditions, state: state, data: data)
        }

        guard !candidates.isEmpty else {
            return nil
        }

        let diversifiedCandidates = diversified(candidates: candidates, state: state)

        let weights = diversifiedCandidates.map { card in
            effectiveWeight(for: card, state: state, data: data)
        }

        guard let chosenIndex = rng.chooseIndex(weights: weights) else {
            return nil
        }

        let chosen = diversifiedCandidates[chosenIndex]
        let titleKey = Self.normalizeTitle(chosen.title)
        state.inbox.append(InboxCard(cardId: chosen.id, cycleAdded: state.cycle))
        state.cardCooldownUntilCycle[chosen.id] = state.cycle + chosen.cooldownCycles
        var titleCooldowns = state.cardTitleCooldownUntilCycle ?? [:]
        titleCooldowns[titleKey] = state.cycle + titleCooldownCycles(for: chosen, titleKey: titleKey)
        state.cardTitleCooldownUntilCycle = titleCooldowns
        state.recentCardCategories.append(chosen.category)
        if state.recentCardCategories.count > 5 {
            state.recentCardCategories.removeFirst(state.recentCardCategories.count - 5)
        }
        var recentTitleKeys = state.recentCardTitleKeys ?? []
        recentTitleKeys.append(titleKey)
        if recentTitleKeys.count > 8 {
            recentTitleKeys.removeFirst(recentTitleKeys.count - 8)
        }
        state.recentCardTitleKeys = recentTitleKeys

        return chosen
    }

    private func unlockedCardCategories(state: GameState, data: GameData) -> Set<String> {
        let index = min(max(0, state.chapterIndex), data.progression.chapters.count - 1)
        let unlocked = data.progression.chapters[0...index].flatMap { $0.unlocks.cardCategories }
        return Set(unlocked)
    }

    private func isCooldownFinished(cardID: String, state: GameState) -> Bool {
        guard let untilCycle = state.cardCooldownUntilCycle[cardID] else {
            return true
        }
        return state.cycle >= untilCycle
    }

    private func isTitleCooldownFinished(card: CardDefinition, state: GameState) -> Bool {
        let titleKey = Self.normalizeTitle(card.title)
        guard let untilCycle = state.cardTitleCooldownUntilCycle?[titleKey] else {
            return true
        }
        return state.cycle >= untilCycle
    }

    private func diversified(candidates: [CardDefinition], state: GameState) -> [CardDefinition] {
        guard !candidates.isEmpty else {
            return []
        }
        let recentTitles = state.recentCardTitleKeys ?? []
        guard let lastTitle = recentTitles.last else {
            return candidates
        }
        let filtered = candidates.filter { Self.normalizeTitle($0.title) != lastTitle }
        return filtered.isEmpty ? candidates : filtered
    }

    private func effectiveWeight(for card: CardDefinition, state: GameState, data: GameData) -> Double {
        var weight = max(0, card.baseWeight)
        let titleKey = Self.normalizeTitle(card.title)

        weight *= introPhaseMultiplier(for: card, state: state)

        if card.category == "HIRING" {
            weight *= hiringDemandMultiplier(state: state)
        }
        if state.metrics.mrrJPY == 0, state.day >= 12, card.category == "PRODUCT" {
            weight *= 1.3
        }
        if state.metrics.cashJPY <= 120_000, ["FINANCE", "SALES"].contains(card.category) {
            weight *= 1.4
        }
        if state.metrics.techDebt >= 35, ["PROCESS", "CRISIS"].contains(card.category) {
            weight *= 1.4
        }
        if state.metrics.teamHealth <= 40, ["CULTURE", "PROCESS"].contains(card.category) {
            weight *= 1.4
        }
        if state.metrics.aiMaturityLevel >= 2, card.category == "AI" {
            weight *= 1.2
        }

        let recentCount = state.recentCardCategories.filter { $0 == card.category }.count
        if recentCount > 0 {
            weight *= pow(0.6, Double(recentCount))
        }
        let recentTitleCount = (state.recentCardTitleKeys ?? []).filter { $0 == titleKey }.count
        if recentTitleCount > 0 {
            weight *= pow(0.45, Double(recentTitleCount))
        }
        let duplicateCount = duplicateTitleCounts[titleKey, default: 1]
        if duplicateCount > 1 {
            weight /= Double(duplicateCount)
        }

        for multiplier in card.weightMultipliers {
            let condition = CardCondition(metric: multiplier.metric, flag: nil, op: multiplier.op, value: multiplier.value)
            if ConditionEvaluator.evaluate(condition, state: state, data: data) {
                weight *= multiplier.multiplier
            }
        }

        return weight
    }

    private func introPhaseMultiplier(for card: CardDefinition, state: GameState) -> Double {
        let introProgress = min(1.0, Double(state.activeRealMinutes) / 360.0)
        let introStrength = 1.0 - introProgress

        var multiplier = 1.0
        switch card.category {
        case "STRATEGY", "SALES", "PRODUCT", "PROCESS", "HIRING":
            multiplier *= 1.0 + (0.9 * introStrength)
        case "CULTURE":
            multiplier *= 1.0 + (0.35 * introStrength)
        case "FINANCE":
            multiplier *= 1.0 - (0.30 * introStrength)
        case "CRISIS":
            multiplier *= 1.0 - (0.40 * introStrength)
        case "AI":
            multiplier *= 1.0 - (0.60 * introStrength)
        case "INVESTOR", "EXIT":
            multiplier *= max(0.05, 1.0 - (0.9 * introStrength))
        default:
            break
        }

        if state.activeRealMinutes < 240, card.category == "CRISIS" {
            let severeCondition = state.metrics.cashJPY <= 90_000
                || state.metrics.teamHealth <= 32
                || state.metrics.techDebt >= 58
            if !severeCondition {
                multiplier *= 0.35
            }
        }

        if state.activeRealMinutes < 180, card.category == "AI", state.metrics.aiXP == 0 {
            multiplier *= 0.2
        }

        return max(0.01, multiplier)
    }

    private func titleCooldownCycles(for card: CardDefinition, titleKey: String) -> Int {
        let duplicateCount = duplicateTitleCounts[titleKey, default: 1]
        let duplicatePenalty = max(0, duplicateCount - 1)
        let derived = card.cooldownCycles + min(12, duplicatePenalty)
        return min(24, max(card.cooldownCycles, derived))
    }

    private func hiringDemandMultiplier(state: GameState) -> Double {
        let nonFounderCount = max(0, state.teamSize - 1)
        let estimatedMonthlyBurn = 180_000 + (nonFounderCount * 420_000)
        let netBurn = max(0, estimatedMonthlyBurn - state.metrics.mrrJPY)
        let runwayMonths: Double
        if netBurn <= 0 {
            runwayMonths = 24
        } else {
            runwayMonths = Double(max(0, state.metrics.cashJPY)) / Double(netBurn)
        }

        switch state.teamSize {
        case ...1:
            return runwayMonths >= 2.0 ? 1.35 : 0.70
        case 2...3:
            if runwayMonths >= 2.2, state.metrics.mrrJPY >= 50_000 {
                return 1.2
            }
            return 0.75
        default:
            return runwayMonths >= 4.0 ? 0.55 : 0.25
        }
    }

    private static func normalizeTitle(_ title: String) -> String {
        title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private func applyBacklogPenalty(state: inout GameState, data: GameData) {
        state.flags[SystemFlagKeys.inboxOverflowedSinceLastRelief] = .bool(true)
        state.metrics.teamHealth -= 3
        state.metrics.techDebt += 2
        state.metrics.reputation -= 1
        state.clamp(with: data)
    }
}
