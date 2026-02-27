import SwiftUI
import TinyCEOCore

/// Scene-facing view state derived from GameState and GameViewState.
/// Keep game-logic derivation out of SwiftUI View bodies.
struct OfficeSceneState {
    enum GrowthStage {
        case seed
        case growth
        case mature
    }

    let growthStage: GrowthStage
    let totalEmployeeCount: Int
    let activeEmployeeCount: Int
    let seatCapacity: Int
    let showPlant: Bool
    let showDesk2: Bool
    let showServer: Bool
    let teamHealth: Double
    let riskLevel: RiskLevel
    let motionProfile: OfficeMotionProfile
    let focusCategory: String?
    let atmosphereColor: Color
    let atmosphereOpacity: Double
    let wallStripOpacity: Double
    let inactiveSeatOpacity: Double
    let ghostDecorOpacity: Double

    var showActivityDots: Bool {
        motionProfile == .busy || motionProfile == .urgent || riskLevel == .warn
    }

    static func from(
        snapshot: GameState?,
        viewState: GameViewState,
        focusCategory: String?
    ) -> OfficeSceneState {
        let teamSize = snapshot?.teamSize ?? 1
        let chapterIndex = snapshot?.chapterIndex ?? 0
        let day = snapshot?.day ?? viewState.day
        let hasProduct = snapshot?.hasProductLaunched ?? false
        let teamHealth = snapshot?.metrics.teamHealth ?? viewState.teamHealth

        let growthStage: GrowthStage
        if teamSize >= 5 || chapterIndex >= 2 || day >= 30 {
            growthStage = .mature
        } else if teamSize >= 2 || chapterIndex >= 1 || day >= 15 {
            growthStage = .growth
        } else {
            growthStage = .seed
        }

        let maxSeats: Int
        switch growthStage {
        case .seed:
            maxSeats = 2
        case .growth:
            maxSeats = 4
        case .mature:
            maxSeats = 6
        }

        let totalEmployeeCount = max(teamSize, 1)
        let activeEmployeeCount = min(totalEmployeeCount, maxSeats)

        let showPlant: Bool
        let showDesk2: Bool
        let showServer: Bool
        switch growthStage {
        case .seed:
            showPlant = false
            showDesk2 = false
            showServer = false
        case .growth:
            showPlant = day >= 10 || hasProduct
            showDesk2 = false
            showServer = false
        case .mature:
            showPlant = true
            showDesk2 = true
            showServer = true
        }

        let atmosphereColor: Color
        let atmosphereOpacity: Double
        switch viewState.riskLevel {
        case .danger:
            atmosphereColor = Color(red: 1.0, green: 0.271, blue: 0.227)
            atmosphereOpacity = 0.15
        case .warn:
            atmosphereColor = Color(red: 1.0, green: 0.624, blue: 0.039)
            atmosphereOpacity = 0.10
        case .normal:
            atmosphereColor = .clear
            atmosphereOpacity = 0.0
        }

        let motionProfile: OfficeMotionProfile
        if viewState.riskLevel == .danger {
            motionProfile = .urgent
        } else if let focusCategory {
            motionProfile = EventVisualCatalog.spec(for: focusCategory).motion
        } else {
            motionProfile = .calm
        }

        let wallStripOpacity: Double
        let inactiveSeatOpacity: Double
        let ghostDecorOpacity: Double
        switch growthStage {
        case .seed:
            wallStripOpacity = 0.20
            inactiveSeatOpacity = 0.20
            ghostDecorOpacity = 0.18
        case .growth:
            wallStripOpacity = 0.50
            inactiveSeatOpacity = 0.24
            ghostDecorOpacity = 0.16
        case .mature:
            wallStripOpacity = 0.80
            inactiveSeatOpacity = 0.30
            ghostDecorOpacity = 0.0
        }

        return OfficeSceneState(
            growthStage: growthStage,
            totalEmployeeCount: totalEmployeeCount,
            activeEmployeeCount: activeEmployeeCount,
            seatCapacity: 6,
            showPlant: showPlant,
            showDesk2: showDesk2,
            showServer: showServer,
            teamHealth: teamHealth,
            riskLevel: viewState.riskLevel,
            motionProfile: motionProfile,
            focusCategory: focusCategory,
            atmosphereColor: atmosphereColor,
            atmosphereOpacity: atmosphereOpacity,
            wallStripOpacity: wallStripOpacity,
            inactiveSeatOpacity: inactiveSeatOpacity,
            ghostDecorOpacity: ghostDecorOpacity
        )
    }
}

extension OfficeMotionProfile {
    var speedMultiplier: Double {
        switch self {
        case .calm:
            return 0.85
        case .steady:
            return 1.00
        case .busy:
            return 1.20
        case .urgent:
            return 1.45
        }
    }
}
