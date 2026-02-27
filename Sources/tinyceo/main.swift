import Foundation
import TinyCEOCore

@main
struct TinyCEOCLI {
    static func main() {
        do {
            try run()
        } catch {
            fputs("error: \(error)\n", stderr)
            exit(1)
        }
    }

    private static func run() throws {
        let args = Array(CommandLine.arguments.dropFirst())
        guard let command = args.first else {
            printHelp()
            return
        }

        switch command {
        case "validate-data":
            let options = parseOptions(Array(args.dropFirst()))
            let dataDir = URL(fileURLWithPath: options["--data-dir"] ?? "data", isDirectory: true)
            try validateData(dataDir: dataDir)

        case "simulate":
            let options = parseOptions(Array(args.dropFirst()))
            let dataDir = URL(fileURLWithPath: options["--data-dir"] ?? "data", isDirectory: true)
            let minutes = Int(options["--real-minutes"] ?? "480") ?? 480
            let seed = UInt64(options["--seed"] ?? "42") ?? 42
            let dbPath = options["--db"]
            let mode = options["--mode"]
            let bootstrapPath = options["--bootstrap"]
            try simulate(dataDir: dataDir, realMinutes: minutes, seed: seed, dbPath: dbPath, mode: mode, bootstrapPath: bootstrapPath)

        default:
            printHelp()
        }
    }

    private static func validateData(dataDir: URL) throws {
        let loader = DataLoader()
        let gameData = try loader.loadAll(from: dataDir)
        let issues = DataValidator.validate(gameData)

        if issues.isEmpty {
            print("data validation: OK")
            return
        }

        print("data validation: \(issues.count) issue(s)")
        for issue in issues {
            print("- \(issue.message)")
        }
        throw NSError(domain: "tinyceo", code: 1, userInfo: [NSLocalizedDescriptionKey: "data validation failed"])
    }

    private static func simulate(
        dataDir: URL,
        realMinutes: Int,
        seed: UInt64,
        dbPath: String?,
        mode: String?,
        bootstrapPath: String?
    ) throws {
        let loader = DataLoader()
        let gameData = try loader.loadAll(from: dataDir)
        let issues = DataValidator.validate(gameData)
        guard issues.isEmpty else {
            for issue in issues {
                print("- \(issue.message)")
            }
            throw NSError(domain: "tinyceo", code: 2, userInfo: [NSLocalizedDescriptionKey: "data validation failed"])
        }

        let bootstrap = try loadBootstrap(path: bootstrapPath)
        var state = GameState.initial(data: gameData, seed: seed, bootstrap: bootstrap)
        if let mode, !mode.isEmpty {
            state.mode = mode
        }

        let engine = SimulationEngine(data: gameData)
        var rng = SeededGenerator(seed: seed)
        let cardsByID = Dictionary(uniqueKeysWithValues: gameData.cards.cards.map { ($0.id, $0) })
        let policyByID = Dictionary(uniqueKeysWithValues: gameData.policies.policies.map { ($0.id, $0) })

        engine.ensureOnStartCard(state: &state, rng: &rng)

        var generated = 0
        var resolved = 0

        resolved += resolveInbox(
            state: &state,
            engine: engine,
            cardsByID: cardsByID,
            policyByID: policyByID,
            rng: &rng
        )

        for minute in 0..<realMinutes {
            let signal = syntheticSignal(minute: minute)
            let result = engine.processRealMinute(
                state: &state,
                signal: signal,
                isSessionActive: true,
                autoResolveCard: false,
                rng: &rng
            )
            generated += result.generatedCardIDs.count
            resolved += resolveInbox(
                state: &state,
                engine: engine,
                cardsByID: cardsByID,
                policyByID: policyByID,
                rng: &rng
            )
        }

        if let dbPath {
            let repository = try SQLiteRepository(path: dbPath)
            try repository.saveSnapshot(state)
            try repository.appendEvent(type: "simulation.completed", payload: [
                "real_minutes": String(realMinutes),
                "generated_cards": String(generated),
                "resolved_cards": String(resolved),
                "day": String(state.day)
            ])
        }

        let risk = engine.estimateRiskLevel(state: state)

        print("simulation complete")
        print("- day: \(state.day)")
        print("- cycle: \(state.cycle)")
        print("- cashJPY: \(state.metrics.cashJPY)")
        print("- mrrJPY: \(state.metrics.mrrJPY)")
        print("- debtJPY: \(state.metrics.debtJPY)")
        print("- reputation: \(String(format: "%.2f", state.metrics.reputation))")
        print("- teamHealth: \(String(format: "%.2f", state.metrics.teamHealth))")
        print("- techDebt: \(String(format: "%.2f", state.metrics.techDebt))")
        print("- aiLevel: \(state.metrics.aiMaturityLevel)")
        print("- teamSize: \(state.teamSize)")
        print("- activeProjects: \(state.activeProjects.count)")
        print("- generatedCards: \(generated)")
        print("- resolvedCards: \(resolved)")
        print("- risk: \(risk.rawValue)")
        if let endType = state.endgameType {
            print("- endgame: \(endType)")
        }
    }

    private static func loadBootstrap(path: String?) throws -> BootstrapConfig {
        guard let path else {
            return BootstrapConfig()
        }
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        return try JSONDecoder().decode(BootstrapConfig.self, from: data)
    }

    private static func parseOptions(_ args: [String]) -> [String: String] {
        var options: [String: String] = [:]
        var index = 0

        while index < args.count {
            let current = args[index]
            if current.hasPrefix("--") {
                if index + 1 < args.count, !args[index + 1].hasPrefix("--") {
                    options[current] = args[index + 1]
                    index += 2
                } else {
                    options[current] = "true"
                    index += 1
                }
            } else {
                index += 1
            }
        }

        return options
    }

    private static func resolveInbox(
        state: inout GameState,
        engine: SimulationEngine,
        cardsByID: [String: CardDefinition],
        policyByID: [String: PolicyDefinition],
        rng: inout SeededGenerator
    ) -> Int {
        var resolved = 0

        while let next = state.inbox.first, let card = cardsByID[next.cardId], !state.isGameOver {
            let optionIndex = chooseOptionIndex(card: card, state: state, policyByID: policyByID)
            if engine.resolveNextCard(state: &state, optionIndex: optionIndex, rng: &rng) != nil {
                resolved += 1
            } else {
                break
            }
        }

        return resolved
    }

    private static func chooseOptionIndex(
        card: CardDefinition,
        state: GameState,
        policyByID: [String: PolicyDefinition]
    ) -> Int {
        var bestIndex = 0
        var bestScore = -Double.greatestFiniteMagnitude

        for (index, option) in card.options.enumerated() {
            let score = score(option: option, state: state, policyByID: policyByID)
            if score > bestScore {
                bestScore = score
                bestIndex = index
            }
        }

        return bestIndex
    }

    private static func score(
        option: CardOption,
        state: GameState,
        policyByID: [String: PolicyDefinition]
    ) -> Double {
        var score = 0.0
        var projectedCash = Double(state.metrics.cashJPY)
        var projectedHealth = state.metrics.teamHealth
        var projectedDebt = state.metrics.techDebt

        for effect in option.effects {
            switch effect.op {
            case "ADD_CASH":
                let v = Double(effect.value?.intValue ?? 0)
                projectedCash += v
                score += v / 10_000.0
            case "ADD_DEBT":
                let v = Double(effect.value?.intValue ?? 0)
                projectedCash += v
                if state.metrics.cashJPY < 120_000 {
                    score += v / 20_000.0
                } else {
                    score -= v / 28_000.0
                }
            case "ADD_MRR":
                let v = Double(effect.value?.intValue ?? 0)
                score += v / 1_800.0
            case "ADD_REPUTATION":
                let v = effect.value?.doubleValue ?? 0
                score += v * 2.0
            case "ADD_TEAM_HEALTH":
                let v = effect.value?.doubleValue ?? 0
                projectedHealth += v
                score += (state.metrics.teamHealth < 45 ? v * 2.0 : v * 0.7)
            case "ADD_TECH_DEBT":
                let v = effect.value?.doubleValue ?? 0
                projectedDebt += v
                let penaltyMultiplier = state.metrics.techDebt >= 35 ? 2.2 : 1.0
                score -= v * penaltyMultiplier
            case "ADD_AI_XP":
                let v = Double(effect.value?.intValue ?? 0)
                score += v / 150.0
            case "ADD_LEADS":
                let v = Double(effect.value?.intValue ?? 0)
                score += v * 0.5
            case "HIRE_RANDOM":
                if state.teamSize < 4 && state.metrics.cashJPY >= 160_000 {
                    score += 4.5
                } else if state.metrics.cashJPY < 120_000 {
                    score -= 2.5
                } else {
                    score += 1.8
                }
            case "ENABLE_POLICY":
                if let policyID = effect.policyId, let policy = policyByID[policyID] {
                    projectedCash -= Double(policy.upfrontCostJPY)
                    if state.metrics.cashJPY >= policy.upfrontCostJPY + 90_000 {
                        score += 1.5
                    } else {
                        score -= 0.7
                    }
                } else {
                    score += 0.4
                }
            case "UNLOCK_POLICY":
                score += 0.7
            case "ADD_PROJECT":
                score += state.activeProjects.count <= 1 ? 1.4 : 0.5
            case "ADD_TEMP_CAPACITY":
                score += 1.2
            case "SET_STRATEGY":
                let strategy = effect.value?.stringValue ?? ""
                if state.day <= 3 {
                    if strategy == "BALANCED" { score += 1.8 }
                    if strategy == "CONTRACT_HEAVY" { score += 1.2 }
                } else if state.metrics.cashJPY < 150_000 {
                    if strategy == "CONTRACT_HEAVY" { score += 1.6 }
                } else if state.metrics.mrrJPY < 30_000 {
                    if strategy == "PRODUCT_HEAVY" { score += 0.9 }
                }
            case "SET_FLAG", "ADD_FLAG":
                if effect.key == "maxActiveProjectsOverride" {
                    score += 0.8
                }
            case "ENDGAME":
                score -= 10_000
            default:
                break
            }
        }

        if projectedCash < 0 {
            score -= 8
        } else if projectedCash < 80_000 {
            score -= 3
        }
        if projectedHealth < 30 {
            score -= 3
        }
        if projectedDebt > 45 {
            score -= 2.5
        }

        return score
    }

    private static func syntheticSignal(minute: Int) -> ActivitySignal {
        let bucket = minute % 60
        switch bucket {
        case 0..<24:
            return ActivitySignal(bundleId: "com.microsoft.VSCode", processName: "Code", domain: nil, isIdle: false)
        case 24..<34:
            return ActivitySignal(bundleId: "com.tinyspeck.slackmacgap", processName: "Slack", domain: nil, isIdle: false)
        case 34..<44:
            return ActivitySignal(bundleId: "com.microsoft.Excel", processName: "Excel", domain: nil, isIdle: false)
        case 44..<54:
            return ActivitySignal(bundleId: "com.google.Chrome", processName: "codex", domain: "chatgpt.com", isIdle: false)
        default:
            return ActivitySignal(bundleId: "com.google.Chrome", processName: "Chrome", domain: "youtube.com", isIdle: false)
        }
    }

    private static func printHelp() {
        print("""
        tinyceo commands:
          validate-data [--data-dir ./data]
          simulate [--data-dir ./data] [--real-minutes 480] [--seed 42] [--mode FOCUS] [--bootstrap /path/bootstrap.json] [--db /path/tinyceo.sqlite]
        """)
    }
}
