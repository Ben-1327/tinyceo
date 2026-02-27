import Foundation

enum AppScreen: Equatable {
    case onboarding
    case home
    case inbox
    case cardDetail(cardID: String)
    case cardResult
    case settings
}

struct InboxDisplayCard: Identifiable, Equatable {
    let id: String
    let cardID: String
    let title: String
    let category: String
    let rarity: String
    let cycleAdded: Int
    let optionCount: Int

    var isCrisis: Bool {
        category == "CRISIS"
    }
}

struct ProjectProgressRow: Identifiable, Equatable {
    let id: String
    let title: String
    let progress: Double
}

struct MetricDelta: Identifiable, Equatable {
    let id: String
    let label: String
    let sfSymbol: String
    let delta: Double
    let format: MetricFormat

    enum MetricFormat: Equatable {
        case integer
        case currency
        case oneDecimal
    }

    var isZero: Bool {
        abs(delta) < 0.0001
    }
}

struct CardResolutionResult: Equatable {
    let cardID: String
    let cardTitle: String
    let selectedOptionLabel: String
    let metricDeltas: [MetricDelta]
    let minutesUntilNextCard: Int
}
