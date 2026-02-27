import Foundation

public struct CardDeckEngine: Sendable {
    private let cardsByID: [String: CardDefinition]
    private let allCards: [CardDefinition]

    public init(data: GameData) {
        self.allCards = data.cards.cards
        self.cardsByID = Dictionary(uniqueKeysWithValues: data.cards.cards.map { ($0.id, $0) })
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
            && !state.inbox.contains(where: { $0.cardId == card.id })
            && ConditionEvaluator.evaluateAll(card.conditions, state: state, data: data)
        }

        guard !candidates.isEmpty else {
            return nil
        }

        let weights = candidates.map { card in
            effectiveWeight(for: card, state: state, data: data)
        }

        guard let chosenIndex = rng.chooseIndex(weights: weights) else {
            return nil
        }

        let chosen = candidates[chosenIndex]
        state.inbox.append(InboxCard(cardId: chosen.id, cycleAdded: state.cycle))
        state.cardCooldownUntilCycle[chosen.id] = state.cycle + chosen.cooldownCycles
        state.recentCardCategories.append(chosen.category)
        if state.recentCardCategories.count > 3 {
            state.recentCardCategories.removeFirst(state.recentCardCategories.count - 3)
        }

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

    private func effectiveWeight(for card: CardDefinition, state: GameState, data: GameData) -> Double {
        var weight = max(0, card.baseWeight)

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

        for multiplier in card.weightMultipliers {
            let condition = CardCondition(metric: multiplier.metric, flag: nil, op: multiplier.op, value: multiplier.value)
            if ConditionEvaluator.evaluate(condition, state: state, data: data) {
                weight *= multiplier.multiplier
            }
        }

        return weight
    }

    private func applyBacklogPenalty(state: inout GameState, data: GameData) {
        state.metrics.teamHealth -= 3
        state.metrics.techDebt += 2
        state.metrics.reputation -= 1
        state.clamp(with: data)
    }
}
