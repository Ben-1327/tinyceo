import Combine
import Foundation
import TinyCEOCore

@MainActor
final class GameRuntimeStore: ObservableObject {
    @Published private(set) var viewState: GameViewState = .placeholder
    @Published private(set) var snapshot: GameState?
    @Published private(set) var runtimeError: String?

    @Published var notificationsEnabled: Bool = true
    @Published var showChoiceTexture: Bool = false
    @Published var showOfficeDecorations: Bool = true

    private var engine: SimulationEngine?
    private var state: GameState?
    private var rng: SeededGenerator?
    private var timer: Timer?

    func start() {
        if engine == nil || state == nil || rng == nil {
            loadInitialState()
        }
        startTimer()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func tickOneRealMinute() {
        guard var mutableState = state, var mutableRNG = rng, let engine else { return }
        _ = engine.processRealMinute(
            state: &mutableState,
            signal: nil,
            isSessionActive: true,
            autoResolveCard: false,
            rng: &mutableRNG
        )
        state = mutableState
        rng = mutableRNG
        publishFromEngine()
    }

    func resolveNextCard(optionIndex: Int = 0) {
        guard var mutableState = state, var mutableRNG = rng, let engine else { return }
        _ = engine.resolveNextCard(state: &mutableState, optionIndex: optionIndex, rng: &mutableRNG)
        state = mutableState
        rng = mutableRNG
        publishFromEngine()
    }

    func setWorkIntegrationEnabled(_ enabled: Bool) {
        guard var mutableState = state else { return }
        mutableState.isWorkIntegrationEnabled = enabled
        state = mutableState
        snapshot = mutableState
    }

    var canResolveNextCard: Bool {
        guard let state else { return false }
        return !state.inbox.isEmpty
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tickOneRealMinute()
            }
        }
    }

    private func loadInitialState() {
        do {
            let dataDir = try Self.resolveDataDirectory()
            let loader = DataLoader()
            let gameData = try loader.loadAll(from: dataDir)

            var initialState = GameState.initial(data: gameData, seed: 42)
            var initialRNG = SeededGenerator(seed: initialState.seed)
            let simulationEngine = SimulationEngine(data: gameData)
            simulationEngine.ensureOnStartCard(state: &initialState, rng: &initialRNG)

            engine = simulationEngine
            state = initialState
            rng = initialRNG
            runtimeError = nil
            publishFromEngine()
        } catch {
            runtimeError = error.localizedDescription
        }
    }

    private func publishFromEngine() {
        guard let engine, let state else { return }
        snapshot = state
        viewState = engine.makeViewState(state: state)
    }

    private static func resolveDataDirectory() throws -> URL {
        let fileManager = FileManager.default

        if let envPath = ProcessInfo.processInfo.environment["TINYCEO_DATA_DIR"], !envPath.isEmpty {
            let envURL = URL(fileURLWithPath: envPath, isDirectory: true)
            if fileManager.fileExists(atPath: envURL.appendingPathComponent("balance.json").path) {
                return envURL
            }
        }

        var currentDirectory = URL(fileURLWithPath: fileManager.currentDirectoryPath, isDirectory: true)
        for _ in 0..<8 {
            let candidate = currentDirectory.appendingPathComponent("data", isDirectory: true)
            if fileManager.fileExists(atPath: candidate.appendingPathComponent("balance.json").path) {
                return candidate
            }
            currentDirectory.deleteLastPathComponent()
        }

        throw NSError(
            domain: "tinyceo.app",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "data directory not found. Set TINYCEO_DATA_DIR."]
        )
    }
}

private extension GameViewState {
    static let placeholder = GameViewState(
        day: 1,
        companyMinutes: 0,
        riskLevel: .normal,
        cashJPY: 500_000,
        reputation: 0,
        teamHealth: 50,
        techDebt: 0,
        runway: RunwayViewState(
            monthsRemaining: nil,
            displayText: "∞",
            riskLevel: .normal,
            burnRate: BurnRateEstimate(
                dailyIncomeJPY: 0,
                dailyBurnJPY: 0,
                monthlyIncomeJPY: 0,
                monthlyBurnJPY: 0,
                monthlyNetBurnJPY: 0
            )
        ),
        inboxCount: 0,
        maxInboxCards: 3,
        showInboxFullBanner: false,
        minutesUntilNextCard: 120,
        cardIntervalRealMinutes: 120
    )
}
