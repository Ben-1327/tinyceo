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
    @Published private(set) var activityObservation: ActivityObservation = .waiting

    @Published var cardNotificationsEnabled: Bool = true {
        didSet {
            persistPreferenceIfReady(key: cardNotificationsEnabledKey, value: cardNotificationsEnabled)
            if cardNotificationsEnabled {
                notificationManager.requestAuthorizationIfNeeded()
            }
        }
    }
    @Published var crisisNotificationsEnabled: Bool = true {
        didSet {
            persistPreferenceIfReady(key: crisisNotificationsEnabledKey, value: crisisNotificationsEnabled)
            if crisisNotificationsEnabled {
                notificationManager.requestAuthorizationIfNeeded()
            }
        }
    }
    @Published var showChoiceTexture: Bool = false {
        didSet { persistPreferenceIfReady(key: showChoiceTextureKey, value: showChoiceTexture) }
    }
    @Published var showOfficeDecorations: Bool = true {
        didSet { persistPreferenceIfReady(key: showOfficeDecorationsKey, value: showOfficeDecorations) }
    }
    @Published var playerName: String = GameRuntimeStore.defaultPlayerName {
        didSet { persistStringPreferenceIfReady(key: playerNameKey, value: playerName) }
    }
    @Published var companyName: String = GameRuntimeStore.defaultCompanyName {
        didSet { persistStringPreferenceIfReady(key: companyNameKey, value: companyName) }
    }
    @Published var selectedAvatarID: String = GameRuntimeStore.defaultAvatarID {
        didSet { persistStringPreferenceIfReady(key: selectedAvatarIDKey, value: selectedAvatarID) }
    }

    private var gameData: GameData?
    private var cardsByID: [String: CardDefinition] = [:]
    private var projectsByID: [String: ProjectTemplate] = [:]

    private var repository: SQLiteRepository?
    private var engine: SimulationEngine?
    private var state: GameState?
    private var rng: SeededGenerator?
    private var timer: Timer?
    private var lastProcessedMinuteMark: Date?
    private var latestActivitySignal: ActivitySignal?
    private var lastLiveActivitySampleAt: Date?
    private var hasLoadedPreferences = false

    private let signalProvider = SystemActivitySignalProvider()
    private let notificationManager = NotificationCenterManager()

    private let onboardingCompletedKey = "onboardingCompleted"
    private let workIntegrationEnabledKey = "workIntegrationEnabled"
    private let cardNotificationsEnabledKey = "cardNotificationsEnabled"
    private let crisisNotificationsEnabledKey = "crisisNotificationsEnabled"
    private let showChoiceTextureKey = "showChoiceTexture"
    private let showOfficeDecorationsKey = "showOfficeDecorations"
    private let playerNameKey = "playerName"
    private let companyNameKey = "companyName"
    private let selectedAvatarIDKey = "selectedAvatarID"
    private let liveActivitySampleIntervalSeconds: TimeInterval = 2

    static let defaultPlayerName = "あなた"
    static let defaultCompanyName = "TinyCEO"
    static let defaultAvatarID = "founder"

    private static let avatarCatalog: [AvatarOption] = [
        AvatarOption(id: "founder", label: "スタンダード", assetName: "char_founder_01"),
        AvatarOption(id: "dev", label: "エンジニア", assetName: "char_staff_dev_01"),
        AvatarOption(id: "pm", label: "プロデューサー", assetName: "char_staff_pm_01")
    ]

    var avatarOptions: [AvatarOption] {
        Self.avatarCatalog
    }

    var founderAvatarAssetName: String {
        Self.avatarCatalog.first(where: { $0.id == selectedAvatarID })?.assetName ?? "char_founder_01"
    }

    func start() {
        if engine == nil || state == nil || rng == nil {
            loadInitialState()
        }
        lastProcessedMinuteMark = Date()
        startTimer()
    }

    func stop() {
        processElapsedActiveMinutes()
        persistSnapshot(eventType: "app.stop")
        timer?.invalidate()
        timer = nil
        lastProcessedMinuteMark = nil
        latestActivitySignal = nil
        lastLiveActivitySampleAt = nil
    }

    func tickOneRealMinute() {
        guard var mutableState = state, var mutableRNG = rng, let engine else { return }

        let activitySignal: ActivitySignal?

        if mutableState.isWorkIntegrationEnabled {
            let signal = latestActivitySignal
                ?? signalProvider.currentSignal(idleThresholdMinutes: engine.data.balance.time.idleThresholdMinutes)
            activitySignal = signal
        } else {
            activitySignal = nil
        }

        let result = engine.processRealMinute(
            state: &mutableState,
            signal: activitySignal,
            isSessionActive: true,
            autoResolveCard: false,
            rng: &mutableRNG
        )

        state = mutableState
        rng = mutableRNG
        refreshActivityObservation(signal: activitySignal, category: result.classifiedCategory)
        publishFromEngine()

        handleNotifications(generatedCardIDs: result.generatedCardIDs)

        let shouldRecordTickEvent = result.dayAdvancedBy > 0 || !result.generatedCardIDs.isEmpty
        persistSnapshot(
            eventType: shouldRecordTickEvent ? "tick.persist" : nil,
            payload: shouldRecordTickEvent
                ? [
                    "dayAdvancedBy": String(result.dayAdvancedBy),
                    "generatedCards": String(result.generatedCardIDs.count),
                    "sessionActive": "true"
                ]
                : [:]
        )
    }

    func setWorkIntegrationEnabled(_ enabled: Bool) {
        guard var mutableState = state else { return }
        mutableState.isWorkIntegrationEnabled = enabled
        state = mutableState
        snapshot = mutableState
        if enabled {
            activityObservation = .waiting
        } else {
            latestActivitySignal = nil
            lastLiveActivitySampleAt = nil
            activityObservation = .disabled
        }
        UserDefaults.standard.set(enabled, forKey: workIntegrationEnabledKey)
        persistSnapshot(eventType: "settings.work_integration", payload: ["enabled": String(enabled)])
    }

    func completeOnboarding(workIntegrationEnabled: Bool) {
        normalizeProfileFieldsIfNeeded()
        UserDefaults.standard.set(true, forKey: onboardingCompletedKey)
        setWorkIntegrationEnabled(workIntegrationEnabled)

        if workIntegrationEnabled {
            notificationManager.requestAuthorizationIfNeeded()
        }

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

    var focusInboxCategory: String? {
        inboxCards.first?.category
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
            return "受信箱が満杯です。処理が遅れると指標が悪化します。"
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
        let scheduled = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refreshLiveActivityObservation()
                self?.processElapsedActiveMinutes()
            }
        }
        RunLoop.main.add(scheduled, forMode: .common)
        timer = scheduled
    }

    private func processElapsedActiveMinutes(now: Date = Date()) {
        guard let lastProcessedMinuteMark else {
            lastProcessedMinuteMark = now
            return
        }

        let elapsedSeconds = now.timeIntervalSince(lastProcessedMinuteMark)
        guard elapsedSeconds >= 60 else {
            return
        }

        let elapsedMinutes = Int(elapsedSeconds / 60)
        guard elapsedMinutes > 0 else {
            return
        }

        for _ in 0..<elapsedMinutes {
            tickOneRealMinute()
        }

        self.lastProcessedMinuteMark = lastProcessedMinuteMark.addingTimeInterval(Double(elapsedMinutes * 60))
    }

    private func loadInitialState() {
        do {
            loadPreferences()

            let dataDir = try Self.resolveDataDirectory()
            let loader = DataLoader()
            let loadedGameData = try loader.loadAll(from: dataDir)
            let validationIssues = DataValidator.validate(loadedGameData)
            guard validationIssues.isEmpty else {
                throw NSError(
                    domain: "tinyceo.app",
                    code: 3,
                    userInfo: [
                        NSLocalizedDescriptionKey: """
                        data validation failed:
                        \(Self.renderValidationSummary(validationIssues))
                        """
                    ]
                )
            }

            gameData = loadedGameData
            cardsByID = Dictionary(uniqueKeysWithValues: loadedGameData.cards.cards.map { ($0.id, $0) })
            projectsByID = Dictionary(uniqueKeysWithValues: loadedGameData.projects.projects.map { ($0.id, $0) })

            try setupRepository()

            let simulationEngine = SimulationEngine(data: loadedGameData)
            var loadedState = try repository?.loadLatestSnapshot() ?? GameState.initial(data: loadedGameData, seed: 42)
            if UserDefaults.standard.object(forKey: workIntegrationEnabledKey) != nil {
                loadedState.isWorkIntegrationEnabled = UserDefaults.standard.bool(forKey: workIntegrationEnabledKey)
            }

            var loadedRNG = SeededGenerator(seed: loadedState.seed)
            simulationEngine.ensureOnStartCard(state: &loadedState, rng: &loadedRNG)
            let progressRelief = simulationEngine.applyProgressLockReliefIfNeeded(state: &loadedState)

            engine = simulationEngine
            state = loadedState
            rng = loadedRNG
            runtimeError = nil
            publishFromEngine()
            activityObservation = loadedState.isWorkIntegrationEnabled ? .waiting : .disabled

            if UserDefaults.standard.bool(forKey: onboardingCompletedKey) {
                setScreen(.home)
                if loadedState.isWorkIntegrationEnabled {
                    notificationManager.requestAuthorizationIfNeeded()
                }
            } else {
                setScreen(.onboarding)
            }

            persistSnapshot(eventType: "app.start")
            if let progressRelief {
                persistSnapshot(
                    eventType: "recovery.progress_lock_relief",
                    payload: [
                        "blockedDisciplines": progressRelief.blockedDisciplines.joined(separator: ","),
                        "cashBridgeJPY": String(progressRelief.cashBridgeJPY)
                    ]
                )
            }
        } catch {
            runtimeError = error.localizedDescription
        }
    }

    private func loadPreferences() {
        let userDefaults = UserDefaults.standard

        if userDefaults.object(forKey: cardNotificationsEnabledKey) != nil {
            cardNotificationsEnabled = userDefaults.bool(forKey: cardNotificationsEnabledKey)
        }
        if userDefaults.object(forKey: crisisNotificationsEnabledKey) != nil {
            crisisNotificationsEnabled = userDefaults.bool(forKey: crisisNotificationsEnabledKey)
        }
        if userDefaults.object(forKey: showChoiceTextureKey) != nil {
            showChoiceTexture = userDefaults.bool(forKey: showChoiceTextureKey)
        }
        if userDefaults.object(forKey: showOfficeDecorationsKey) != nil {
            showOfficeDecorations = userDefaults.bool(forKey: showOfficeDecorationsKey)
        }
        if let storedPlayerName = userDefaults.string(forKey: playerNameKey), !storedPlayerName.isEmpty {
            playerName = storedPlayerName
        }
        if let storedCompanyName = userDefaults.string(forKey: companyNameKey), !storedCompanyName.isEmpty {
            companyName = storedCompanyName
        }
        if let storedAvatarID = userDefaults.string(forKey: selectedAvatarIDKey),
           Self.avatarCatalog.contains(where: { $0.id == storedAvatarID }) {
            selectedAvatarID = storedAvatarID
        }

        normalizeProfileFieldsIfNeeded()

        hasLoadedPreferences = true
    }

    private func persistPreferenceIfReady(key: String, value: Bool) {
        guard hasLoadedPreferences else {
            return
        }
        UserDefaults.standard.set(value, forKey: key)
    }

    private func persistStringPreferenceIfReady(key: String, value: String) {
        guard hasLoadedPreferences else {
            return
        }
        UserDefaults.standard.set(value, forKey: key)
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
        requiresStickyPopover = {
            if case .cardDetail = screen {
                return true
            }
            return false
        }()
    }

    private func handleNotifications(generatedCardIDs: [String]) {
        guard !generatedCardIDs.isEmpty else {
            return
        }

        let generatedCards = generatedCardIDs.compactMap { cardsByID[$0] }
        notificationManager.notifyCardArrival(
            cardCount: generatedCards.count,
            inboxCount: viewState.inboxCount,
            enabled: cardNotificationsEnabled
        )

        let includesCrisis = generatedCards.contains { $0.category == "CRISIS" }
        if includesCrisis {
            notificationManager.notifyCrisis(enabled: crisisNotificationsEnabled)
        }
    }

    private func persistSnapshot(eventType: String? = nil, payload: [String: String] = [:]) {
        guard let state, let repository else { return }

        do {
            try repository.saveSnapshot(state)
            if let eventType {
                try repository.appendEvent(type: eventType, payload: payload)
            }
        } catch {
            runtimeError = error.localizedDescription
        }
    }

    private func makeMetricDeltas(before: GameState, after: GameState) -> [MetricDelta] {
        let deltas: [MetricDelta] = [
            MetricDelta(id: "cash", label: "資金", sfSymbol: "yensign.circle", delta: Double(after.metrics.cashJPY - before.metrics.cashJPY), format: .currency),
            MetricDelta(id: "mrr", label: "月次売上", sfSymbol: "chart.line.uptrend.xyaxis", delta: Double(after.metrics.mrrJPY - before.metrics.mrrJPY), format: .currency),
            MetricDelta(id: "debt", label: "借入", sfSymbol: "creditcard", delta: Double(after.metrics.debtJPY - before.metrics.debtJPY), format: .currency),
            MetricDelta(id: "reputation", label: "評判", sfSymbol: "star.fill", delta: after.metrics.reputation - before.metrics.reputation, format: .oneDecimal),
            MetricDelta(id: "teamHealth", label: "健康", sfSymbol: "heart.fill", delta: after.metrics.teamHealth - before.metrics.teamHealth, format: .oneDecimal),
            MetricDelta(id: "techDebt", label: "技術負債", sfSymbol: "bolt.fill", delta: after.metrics.techDebt - before.metrics.techDebt, format: .oneDecimal),
            MetricDelta(id: "aiXP", label: "AI経験値", sfSymbol: "sparkles", delta: Double(after.metrics.aiXP - before.metrics.aiXP), format: .integer),
            MetricDelta(id: "leads", label: "見込み客", sfSymbol: "person.3.fill", delta: Double(after.metrics.leads - before.metrics.leads), format: .integer)
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

        if let bundledRoot = Bundle.module.resourceURL,
           fileManager.fileExists(atPath: bundledRoot.appendingPathComponent("balance.json").path) {
            return bundledRoot
        }

        if let bundledDataDir = Bundle.module.resourceURL?.appendingPathComponent("Data", isDirectory: true),
           fileManager.fileExists(atPath: bundledDataDir.appendingPathComponent("balance.json").path) {
            return bundledDataDir
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

    private func normalizeProfileFieldsIfNeeded() {
        let trimmedPlayer = playerName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCompany = companyName.trimmingCharacters(in: .whitespacesAndNewlines)

        let normalizedPlayer = String((trimmedPlayer.isEmpty ? Self.defaultPlayerName : trimmedPlayer).prefix(20))
        let normalizedCompany = String((trimmedCompany.isEmpty ? Self.defaultCompanyName : trimmedCompany).prefix(24))
        let normalizedAvatarID = Self.avatarCatalog.contains(where: { $0.id == selectedAvatarID }) ? selectedAvatarID : Self.defaultAvatarID

        if playerName != normalizedPlayer {
            playerName = normalizedPlayer
        }
        if companyName != normalizedCompany {
            companyName = normalizedCompany
        }
        if selectedAvatarID != normalizedAvatarID {
            selectedAvatarID = normalizedAvatarID
        }
    }

    private static func renderValidationSummary(_ issues: [ValidationIssue], maxItems: Int = 6) -> String {
        let lines = issues.prefix(maxItems).map { "- \($0.message)" }
        let truncatedNote: String
        if issues.count > maxItems {
            truncatedNote = "\n- ...and \(issues.count - maxItems) more"
        } else {
            truncatedNote = ""
        }
        return lines.joined(separator: "\n") + truncatedNote
    }

    private func refreshLiveActivityObservation(now: Date = Date()) {
        guard let state, state.isWorkIntegrationEnabled, let engine else {
            return
        }

        if let lastLiveActivitySampleAt,
           now.timeIntervalSince(lastLiveActivitySampleAt) < liveActivitySampleIntervalSeconds {
            return
        }

        let signal = signalProvider.currentSignal(idleThresholdMinutes: engine.data.balance.time.idleThresholdMinutes)
        latestActivitySignal = signal
        lastLiveActivitySampleAt = now

        let category = engine.classifier.classify(signal: signal, mode: state.mode)
        refreshActivityObservation(signal: signal, category: category)
    }

    private func refreshActivityObservation(signal: ActivitySignal?, category: ActivityCategory?) {
        guard let signal else {
            activityObservation = .disabled
            return
        }

        activityObservation = ActivityObservation(
            status: .sampled,
            appName: signal.processName ?? "不明",
            bundleID: signal.bundleId ?? "不明",
            domain: signal.domain,
            category: category?.rawValue ?? "RESEARCH",
            isIdle: signal.isIdle,
            sampledAt: Date()
        )
    }
}

struct AvatarOption: Identifiable, Equatable {
    let id: String
    let label: String
    let assetName: String
}

struct ActivityObservation: Equatable {
    enum Status: Equatable {
        case waiting
        case disabled
        case sampled
    }

    let status: Status
    let appName: String
    let bundleID: String
    let domain: String?
    let category: String
    let isIdle: Bool
    let sampledAt: Date?

    static let waiting = ActivityObservation(
        status: .waiting,
        appName: "取得待ち",
        bundleID: "-",
        domain: nil,
        category: "-",
        isIdle: false,
        sampledAt: nil
    )

    static let disabled = ActivityObservation(
        status: .disabled,
        appName: "作業連携OFF",
        bundleID: "-",
        domain: nil,
        category: "-",
        isIdle: false,
        sampledAt: nil
    )
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
        minutesUntilNextCard: 70,
        cardIntervalRealMinutes: 70
    )
}
