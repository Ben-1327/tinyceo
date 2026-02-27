import Foundation
import Testing
@testable import TinyCEOCore

@Test("on-start card is generated")
func onStartCardGenerated() throws {
    let data = try DataLoader().loadAll(from: URL(fileURLWithPath: "data", isDirectory: true))
    var state = GameState.initial(data: data, seed: 1)
    var rng = SeededGenerator(seed: 1)
    let engine = SimulationEngine(data: data)

    engine.ensureOnStartCard(state: &state, rng: &rng)

    #expect(!state.inbox.isEmpty)
}

@Test("backlog penalty is applied when inbox is full")
func backlogPenaltyAppliedWhenInboxFull() throws {
    let data = try DataLoader().loadAll(from: URL(fileURLWithPath: "data", isDirectory: true))
    var state = GameState.initial(data: data, seed: 2)
    var rng = SeededGenerator(seed: 2)

    state.metrics.teamHealth = 50
    state.metrics.techDebt = 10
    state.metrics.reputation = 10
    state.inbox = [
        InboxCard(cardId: "CARD_000_VISION", cycleAdded: 0),
        InboxCard(cardId: "CARD_001_FIRST_CLIENT", cycleAdded: 0),
        InboxCard(cardId: "CARD_002_PRODUCT_IDEA", cycleAdded: 0)
    ]

    _ = CardDeckEngine(data: data).maybeGenerateCycleCard(state: &state, data: data, rng: &rng)

    #expect(abs(state.metrics.teamHealth - 47) < 0.0001)
    #expect(abs(state.metrics.techDebt - 12) < 0.0001)
    #expect(abs(state.metrics.reputation - 9) < 0.0001)
}

@Test("simulation is deterministic with same seed")
func simulationDeterministicWithSameSeed() throws {
    let data = try DataLoader().loadAll(from: URL(fileURLWithPath: "data", isDirectory: true))
    let engine = SimulationEngine(data: data)

    var state1 = GameState.initial(data: data, seed: 77)
    var rng1 = SeededGenerator(seed: 77)

    var state2 = GameState.initial(data: data, seed: 77)
    var rng2 = SeededGenerator(seed: 77)

    for minute in 0..<360 {
        let signal = minute % 2 == 0
            ? ActivitySignal(bundleId: "com.microsoft.VSCode", processName: "Code", domain: nil, isIdle: false)
            : ActivitySignal(bundleId: "com.tinyspeck.slackmacgap", processName: "Slack", domain: nil, isIdle: false)

        _ = engine.processRealMinute(state: &state1, signal: signal, isSessionActive: true, autoResolveCard: true, rng: &rng1)
        _ = engine.processRealMinute(state: &state2, signal: signal, isSessionActive: true, autoResolveCard: true, rng: &rng2)
    }

    #expect(state1.metrics.cashJPY == state2.metrics.cashJPY)
    #expect(state1.metrics.mrrJPY == state2.metrics.mrrJPY)
    #expect(state1.metrics.aiXP == state2.metrics.aiXP)
    #expect(state1.day == state2.day)
    #expect(state1.activeProjects.count == state2.activeProjects.count)
}

@Test("runway estimate uses net burn and supports infinity")
func runwayEstimateSupportsInfinity() throws {
    let data = try DataLoader().loadAll(from: URL(fileURLWithPath: "data", isDirectory: true))
    let engine = SimulationEngine(data: data)

    var base = GameState.initial(data: data, seed: 10)
    base.metrics.cashJPY = 300_000
    base.metrics.mrrJPY = 0

    let baseRunway = engine.makeViewState(state: base).runway
    #expect(baseRunway.burnRate.monthlyBurnJPY == 180_000)
    #expect(baseRunway.burnRate.monthlyNetBurnJPY == 180_000)
    #expect(baseRunway.monthsRemaining != nil)
    #expect(baseRunway.riskLevel == .warn)

    var profitable = base
    profitable.metrics.mrrJPY = 220_000

    let profitableRunway = engine.makeViewState(state: profitable).runway
    #expect(profitableRunway.burnRate.monthlyNetBurnJPY == 0)
    #expect(profitableRunway.monthsRemaining == nil)
    #expect(profitableRunway.displayText == "∞")
    #expect(profitableRunway.riskLevel == .normal)
}

@Test("inbox full banner appears after missed generation and clears after relief")
func inboxFullBannerLifecycle() throws {
    let data = try DataLoader().loadAll(from: URL(fileURLWithPath: "data", isDirectory: true))
    let engine = SimulationEngine(data: data)
    var state = GameState.initial(data: data, seed: 11)
    var rng = SeededGenerator(seed: 11)

    state.inbox = [
        InboxCard(cardId: "CARD_000_VISION", cycleAdded: 0),
        InboxCard(cardId: "CARD_001_FIRST_CLIENT", cycleAdded: 0),
        InboxCard(cardId: "CARD_002_PRODUCT_IDEA", cycleAdded: 0)
    ]

    let before = engine.makeViewState(state: state)
    #expect(before.showInboxFullBanner == false)

    _ = CardDeckEngine(data: data).maybeGenerateCycleCard(state: &state, data: data, rng: &rng)

    let afterPenalty = engine.makeViewState(state: state)
    #expect(afterPenalty.showInboxFullBanner == true)

    _ = engine.resolveNextCard(state: &state, optionIndex: 0, rng: &rng)

    let afterResolve = engine.makeViewState(state: state)
    #expect(afterResolve.inboxCount == 2)
    #expect(afterResolve.showInboxFullBanner == false)
}
