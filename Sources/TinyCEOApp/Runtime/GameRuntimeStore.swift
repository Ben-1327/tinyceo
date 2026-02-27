import Combine
import Foundation
import TinyCEOCore

@MainActor
final class GameRuntimeStore: ObservableObject {
    @Published private(set) var viewState: GameViewState = .placeholder
    @Published private(set) var snapshot: GameState?
    @Published private(set) var runtimeError: String?

    @Published private(set) var currentScreen: AppScreen = .home
    @Published private(set) var lastResolution: CardResolutionResult?
    @Published private(set) var requiresStickyPopover: Bool = false
    @Published private(set) var appDataDirectoryURL: URL?

    @Published var notificationsEnabled: Bool = true
    @Published var showChoiceTexture: Bool = false
    @Published var showOfficeDecorations: Bool = true

    private var gameData: GameData?
    private var cardsByID: [String: CardDefinition] = [:]
    private var projectsByID: [String: ProjectTemplate] = [:]

    private var repository: SQLiteRepository?
    private var engine: SimulationEngine?
    private var state: GameState?
    private var rng: SeededGenerator?
    private var timer: Timer?

    private var minutesSinceLastSave = 0

    private let onboardingCompletedKey = "onboardingCompleted"

    func start() {
        if engine == nil || state == nil || rng == nil {
            loadInitialState()
        }
        startTimer()
    }

    func stop() {
        persistSnapshot(eventType: "app.stop")
        timer?.invalidate()
        timer = nil
    }

    func tickOneRealMinute() {
        guard var mutableState = state, var mutableRNG = rng, let engine else { return }

        let result = engine.processRealMinute(
            state: &mutableState,
            signal: nil,
            isSessionActive: true,
            autoResolveCard: false,
            rng: &mutableRNG
        )

        state = mutableState
        rng = mutableRNG
        publishFromEngine()

        minutesSinceLastSave += 1
        let shouldPersist = result.dayAdvancedBy > 0 || !result.generatedCardIDs.isEmpty || minutesSinceLastSave >= 10
        if shouldPersist {
            persistSnapshot(
                eventType: "tick.persist",
                payload: [
                    "dayAdvancedBy": String(result.dayAdvancedBy),
                    "generatedCards": String(result.generatedCardIDs.count)
                ]
            )
        }
    }

    func setWorkIntegrationEnabled(_ enabled: Bool) {
        guard var mutableState = state else { return }
        mutableState.isWorkIntegrationEnabled = enabled
        state = mutableState
        snapshot = mutableState
        persistSnapshot(eventType: "settings.work_integration", payload: ["enabled": String(enabled)])
    }

    func completeOnboarding(workIntegrationEnabled: Bool) {
        UserDefaults.standard.set(true, forKey: onboardingCompletedKey)
        setWorkIntegrationEnabled(workIntegrationEnabled)
        persistSnapshot(eventType: "onboarding.completed", payload: ["work_integration": String(workIntegrationEnabled)])

        if let firstCardID = state?.inbox.first?.cardId {
            openCardDetail(cardID: firstCardID)
        } else {
            openHome()
        }
    }

    func openHome() {
        setScreen(.home)
    }

    func openInbox() {
        setScreen(.inbox)
    }

    func openSettings() {
        setScreen(.settings)
    }

    func openCardDetail(cardID: String) {
        guard cardsByID[cardID] != nil else { return }
        setScreen(.cardDetail(cardID: cardID))
    }

    func backFromCardDetail() {
        setScreen(.inbox)
    }

    func backFromSettings() {
        setScreen(.home)
    }

    func closeResultToHome() {
        setScreen(.home)
    }

    func resolveCard(cardID: String, optionIndex: Int) {
        guard var mutableState = state,
              var mutableRNG = rng,
              let engine,
              let card = cardsByID[cardID],
              optionIndex >= 0,
              optionIndex < card.options.count,
              let selectedIndex = mutableState.inbox.firstIndex(where: { $0.cardId == cardID })
        else {
            return
        }

        if selectedIndex != 0 {
            let selected = mutableState.inbox.remove(at: selectedIndex)
            mutableState.inbox.insert(selected, at: 0)
        }

        let before = mutableState
        guard engine.resolveNextCard(state: &mutableState, optionIndex: optionIndex, rng: &mutableRNG) != nil else {
            return
        }

        state = mutableState
        rng = mutableRNG
        publishFromEngine()

        let deltas = makeMetricDeltas(before: before, after: mutableState)
        let optionLabel = card.options[optionIndex].label

        lastResolution = CardResolutionResult(
            cardID: cardID,
            cardTitle: card.title,
            selectedOptionLabel: optionLabel,
            metricDeltas: deltas,
            minutesUntilNextCard: viewState.minutesUntilNextCard
        )

        setScreen(.cardResult)
        persistSnapshot(
            eventType: "card.resolved",
            payload: [
                "cardId": cardID,
                "optionIndex": String(optionIndex)
            ]
        )
    }

    func resetGame() {
        guard let gameData, let engine else { return }

        var resetState = GameState.initial(data: gameData, seed: state?.seed ?? 42)
        resetState.isWorkIntegrationEnabled = state?.isWorkIntegrationEnabled ?? true
        var resetRNG = SeededGenerator(seed: resetState.seed)
        engine.ensureOnStartCard(state: &resetState, rng: &resetRNG)

        state = resetState
        rng = resetRNG
        lastResolution = nil
        publishFromEngine()
        setScreen(.home)
        persistSnapshot(eventType: "game.reset")
    }

    var canResolveNextCard: Bool {
        guard let state else { return false }
        return !state.inbox.isEmpty
    }

    var inboxCards: [InboxDisplayCard] {
        guard let state else { return [] }

        return state.inbox
            .compactMap { inboxCard in
                guard let card = cardsByID[inboxCard.cardId] else { return nil }
                return InboxDisplayCard(
                    id: "\(inboxCard.cardId)-\(inboxCard.cycleAdded)",
                    cardID: inboxCard.cardId,
                    title: card.title,
                    category: card.category,
                    rarity: card.rarity,
                    cycleAdded: inboxCard.cycleAdded,
                    optionCount: card.options.count
                )
            }
            .sorted { lhs, rhs in
                if lhs.isCrisis != rhs.isCrisis {
                    return lhs.isCrisis
                }
                return lhs.cycleAdded < rhs.cycleAdded
            }
    }

    func cardDefinition(for cardID: String) -> CardDefinition? {
        cardsByID[cardID]
    }

    var projectRows: [ProjectProgressRow] {
        guard let state else { return [] }

        return state.activeProjects.prefix(2).map { progress in
            let template = projectsByID[progress.id]
            let title = template?.name ?? progress.id
            let totalRequired = template?.workRequired.values.reduce(0, +) ?? 0
            let totalRemaining = progress.workRemaining.values.reduce(0, +)
            let ratio: Double
            if totalRequired > 0 {
                ratio = min(max((totalRequired - totalRemaining) / totalRequired, 0), 1)
            } else {
                ratio = 0
            }
            return ProjectProgressRow(id: progress.id, title: title, progress: ratio)
        }
    }

    var currentCardDetail: CardDefinition? {
        guard case .cardDetail(let cardID) = currentScreen else {
            return nil
        }
        return cardsByID[cardID]
    }

    var crisisBannerText: String? {
        if case .cardDetail = currentScreen {
            return nil
        }

        if viewState.showInboxFullBanner {
            return "Inboxが満杯です。処理が遅れると指標が悪化します。"
        }

        if viewState.runway.riskLevel == .danger || viewState.cashJPY <= 80_000 {
            return "キャッシュが危険水準です。対応カードを確認してください。"
        }

        if viewState.runway.riskLevel == .warn {
            return "キャッシュが3ヶ月を切りました。収益改善または資金調達を検討してください。"
        }

        if viewState.teamHealth < 30 {
            return "チームの健康度が低下しています。離職リスクがあります。"
        }

        if viewState.techDebt > 75 {
            return "技術的負債が限界に近づいています。開発速度が低下します。"
        }

        return nil
    }

    func isBeneficial(_ delta: MetricDelta) -> Bool {
        switch delta.id {
        case "techDebt", "debt":
            return delta.delta < 0
        default:
            return delta.delta > 0
        }
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
            let loadedGameData = try loader.loadAll(from: dataDir)

            gameData = loadedGameData
            cardsByID = Dictionary(uniqueKeysWithValues: loadedGameData.cards.cards.map { ($0.id, $0) })
            projectsByID = Dictionary(uniqueKeysWithValues: loadedGameData.projects.projects.map { ($0.id, $0) })

            try setupRepository()

            let simulationEngine = SimulationEngine(data: loadedGameData)
            var loadedState = try repository?.loadLatestSnapshot() ?? GameState.initial(data: loadedGameData, seed: 42)
            var loadedRNG = SeededGenerator(seed: loadedState.seed)
            simulationEngine.ensureOnStartCard(state: &loadedState, rng: &loadedRNG)

            engine = simulationEngine
            state = loadedState
            rng = loadedRNG
            runtimeError = nil
            publishFromEngine()

            if UserDefaults.standard.bool(forKey: onboardingCompletedKey) {
                setScreen(.home)
            } else {
                setScreen(.onboarding)
            }

            persistSnapshot(eventType: "app.start")
        } catch {
            runtimeError = error.localizedDescription
        }
    }

    private func setupRepository() throws {
        let appDataDirectory = try Self.resolveAppDataDirectory()
        appDataDirectoryURL = appDataDirectory
        let dbURL = appDataDirectory.appendingPathComponent("tinyceo.sqlite")
        repository = try SQLiteRepository(path: dbURL.path)
    }

    private func publishFromEngine() {
        guard let engine, let state else { return }
        snapshot = state
        viewState = engine.makeViewState(state: state)
    }

    private func setScreen(_ screen: AppScreen) {
        currentScreen = screen
        if case .cardDetail = screen {
            requiresStickyPopover = true
        } else {
            requiresStickyPopover = false
        }
    }

    private func persistSnapshot(eventType: String? = nil, payload: [String: String] = [:]) {
        guard let state, let repository else { return }

        do {
            try repository.saveSnapshot(state)
            if let eventType {
                try repository.appendEvent(type: eventType, payload: payload)
            }
            minutesSinceLastSave = 0
        } catch {
            runtimeError = error.localizedDescription
        }
    }

    private func makeMetricDeltas(before: GameState, after: GameState) -> [MetricDelta] {
        let deltas: [MetricDelta] = [
            MetricDelta(id: "cash", label: "Cash", sfSymbol: "yensign.circle", delta: Double(after.metrics.cashJPY - before.metrics.cashJPY), format: .currency),
            MetricDelta(id: "mrr", label: "MRR", sfSymbol: "chart.line.uptrend.xyaxis", delta: Double(after.metrics.mrrJPY - before.metrics.mrrJPY), format: .currency),
            MetricDelta(id: "debt", label: "Debt", sfSymbol: "creditcard", delta: Double(after.metrics.debtJPY - before.metrics.debtJPY), format: .currency),
            MetricDelta(id: "reputation", label: "Reputation", sfSymbol: "star.fill", delta: after.metrics.reputation - before.metrics.reputation, format: .oneDecimal),
            MetricDelta(id: "teamHealth", label: "Team Health", sfSymbol: "heart.fill", delta: after.metrics.teamHealth - before.metrics.teamHealth, format: .oneDecimal),
            MetricDelta(id: "techDebt", label: "Tech Debt", sfSymbol: "bolt.fill", delta: after.metrics.techDebt - before.metrics.techDebt, format: .oneDecimal),
            MetricDelta(id: "aiXP", label: "AI XP", sfSymbol: "sparkles", delta: Double(after.metrics.aiXP - before.metrics.aiXP), format: .integer),
            MetricDelta(id: "leads", label: "Leads", sfSymbol: "person.3.fill", delta: Double(after.metrics.leads - before.metrics.leads), format: .integer)
        ]

        return deltas.filter { !$0.isZero }
    }

    private static func resolveAppDataDirectory() throws -> URL {
        let fileManager = FileManager.default
        guard let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            throw NSError(domain: "tinyceo.app", code: 2, userInfo: [NSLocalizedDescriptionKey: "unable to resolve Application Support directory"])
        }

        let tinyCEOAppSupport = base.appendingPathComponent("TinyCEO", isDirectory: true)
        try fileManager.createDirectory(at: tinyCEOAppSupport, withIntermediateDirectories: true)
        return tinyCEOAppSupport
    }

    private static func resolveDataDirectory() throws -> URL {
        let fileManager = FileManager.default

        if let envPath = ProcessInfo.processInfo.environment["TINYCEO_DATA_DIR"], !envPath.isEmpty {
            let envURL = URL(fileURLWithPath: envPath, isDirectory: true)
            if fileManager.fileExists(atPath: envURL.appendingPathComponent("balance.json").path) {
                return envURL
            }
        }

        if let bundledData = Bundle.module.resourceURL?.appendingPathComponent("Data", isDirectory: true),
           fileManager.fileExists(atPath: bundledData.appendingPathComponent("balance.json").path) {
            return bundledData
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
