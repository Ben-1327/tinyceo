import Foundation

public struct BurnRateEstimate: Sendable {
    public var dailyIncomeJPY: Int
    public var dailyBurnJPY: Int
    public var monthlyIncomeJPY: Int
    public var monthlyBurnJPY: Int
    public var monthlyNetBurnJPY: Int

    public init(
        dailyIncomeJPY: Int,
        dailyBurnJPY: Int,
        monthlyIncomeJPY: Int,
        monthlyBurnJPY: Int,
        monthlyNetBurnJPY: Int
    ) {
        self.dailyIncomeJPY = dailyIncomeJPY
        self.dailyBurnJPY = dailyBurnJPY
        self.monthlyIncomeJPY = monthlyIncomeJPY
        self.monthlyBurnJPY = monthlyBurnJPY
        self.monthlyNetBurnJPY = monthlyNetBurnJPY
    }
}

public struct RunwayViewState: Sendable {
    public var monthsRemaining: Double?
    public var displayText: String
    public var riskLevel: RiskLevel
    public var burnRate: BurnRateEstimate

    public init(monthsRemaining: Double?, displayText: String, riskLevel: RiskLevel, burnRate: BurnRateEstimate) {
        self.monthsRemaining = monthsRemaining
        self.displayText = displayText
        self.riskLevel = riskLevel
        self.burnRate = burnRate
    }
}

public struct GameViewState: Sendable {
    public var day: Int
    public var companyMinutes: Int
    public var riskLevel: RiskLevel

    public var cashJPY: Int
    public var reputation: Double
    public var teamHealth: Double
    public var techDebt: Double

    public var runway: RunwayViewState

    public var inboxCount: Int
    public var maxInboxCards: Int
    public var showInboxFullBanner: Bool
    public var minutesUntilNextCard: Int
    public var cardIntervalRealMinutes: Int

    public init(
        day: Int,
        companyMinutes: Int,
        riskLevel: RiskLevel,
        cashJPY: Int,
        reputation: Double,
        teamHealth: Double,
        techDebt: Double,
        runway: RunwayViewState,
        inboxCount: Int,
        maxInboxCards: Int,
        showInboxFullBanner: Bool,
        minutesUntilNextCard: Int,
        cardIntervalRealMinutes: Int
    ) {
        self.day = day
        self.companyMinutes = companyMinutes
        self.riskLevel = riskLevel
        self.cashJPY = cashJPY
        self.reputation = reputation
        self.teamHealth = teamHealth
        self.techDebt = techDebt
        self.runway = runway
        self.inboxCount = inboxCount
        self.maxInboxCards = maxInboxCards
        self.showInboxFullBanner = showInboxFullBanner
        self.minutesUntilNextCard = minutesUntilNextCard
        self.cardIntervalRealMinutes = cardIntervalRealMinutes
    }
}

public extension SimulationEngine {
    func makeViewState(state: GameState) -> GameViewState {
        let riskLevel = estimateRiskLevel(state: state)
        let maxInboxCards = data.balance.time.maxInboxCards
        let cardIntervalRealMinutes = max(20, state.nextCardIntervalRealMinutes ?? data.balance.time.ceoCardIntervalRealMinutes)

        let countdown = max(0, cardIntervalRealMinutes - state.activeRealMinutesSinceCard)
        let showInboxFullBanner = state.inbox.count >= maxInboxCards && state.hasMissedCardGenerationDueToFullInbox

        return GameViewState(
            day: state.day,
            companyMinutes: state.companyMinutes,
            riskLevel: riskLevel,
            cashJPY: state.metrics.cashJPY,
            reputation: state.metrics.reputation,
            teamHealth: state.metrics.teamHealth,
            techDebt: state.metrics.techDebt,
            runway: runwayViewState(state: state),
            inboxCount: state.inbox.count,
            maxInboxCards: maxInboxCards,
            showInboxFullBanner: showInboxFullBanner,
            minutesUntilNextCard: countdown,
            cardIntervalRealMinutes: cardIntervalRealMinutes
        )
    }

    func estimateBurnRate(state: GameState) -> BurnRateEstimate {
        let dailyIncomeJPY = Int((Double(state.metrics.mrrJPY) * data.balance.economy.mrrPaidPerCompanyDayFactor).rounded(.down))

        let overheadPerDayJPY = data.balance.economy.overheadJPYPerCompanyDay
        let salaryPerDayJPY = state.employees
            .compactMap { employee -> Int? in
                guard employee.roleId != "ROLE_FOUNDER",
                      let role = data.roles.roles.first(where: { $0.id == employee.roleId }) else {
                    return nil
                }
                return Int((Double(role.monthlySalaryJPY) / 30.0).rounded(.toNearestOrAwayFromZero))
            }
            .reduce(0, +)
        let policyPerDayJPY = state.enabledPolicyIDs
            .compactMap { policyID -> Int? in
                guard let policy = data.policies.policies.first(where: { $0.id == policyID }) else {
                    return nil
                }
                return Int((Double(policy.monthlyCostJPY) / 30.0).rounded(.toNearestOrAwayFromZero))
            }
            .reduce(0, +)
        let debtInterestPerDayJPY: Int
        if data.balance.economy.loan.enabled, state.metrics.debtJPY > 0 {
            let dailyInterest = Double(state.metrics.debtJPY) * data.balance.economy.loan.baseInterestAPR / 365.0
            debtInterestPerDayJPY = Int(dailyInterest.rounded(.up))
        } else {
            debtInterestPerDayJPY = 0
        }

        let dailyBurnJPY = overheadPerDayJPY + salaryPerDayJPY + policyPerDayJPY + debtInterestPerDayJPY
        let monthlyIncomeJPY = dailyIncomeJPY * 30
        let monthlyBurnJPY = dailyBurnJPY * 30
        let monthlyNetBurnJPY = max(0, monthlyBurnJPY - monthlyIncomeJPY)

        return BurnRateEstimate(
            dailyIncomeJPY: dailyIncomeJPY,
            dailyBurnJPY: dailyBurnJPY,
            monthlyIncomeJPY: monthlyIncomeJPY,
            monthlyBurnJPY: monthlyBurnJPY,
            monthlyNetBurnJPY: monthlyNetBurnJPY
        )
    }

    func estimateRunwayMonths(state: GameState) -> Double? {
        let burnRate = estimateBurnRate(state: state)
        guard state.metrics.cashJPY > 0 else {
            return 0
        }
        guard burnRate.monthlyNetBurnJPY > 0 else {
            return nil
        }
        return Double(state.metrics.cashJPY) / Double(burnRate.monthlyNetBurnJPY)
    }

    private func runwayViewState(state: GameState) -> RunwayViewState {
        let burnRate = estimateBurnRate(state: state)
        let months = estimateRunwayMonths(state: state)
        let riskLevel: RiskLevel

        if let months {
            if months < 1 {
                riskLevel = .danger
            } else if months < 3 {
                riskLevel = .warn
            } else {
                riskLevel = .normal
            }
        } else {
            riskLevel = .normal
        }

        let displayText: String
        if let months {
            if months < 1 {
                displayText = "< 1ヶ月"
            } else {
                displayText = String(format: "%.1fヶ月", months)
            }
        } else {
            displayText = "∞"
        }

        return RunwayViewState(
            monthsRemaining: months,
            displayText: displayText,
            riskLevel: riskLevel,
            burnRate: burnRate
        )
    }
}
