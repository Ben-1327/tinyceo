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
