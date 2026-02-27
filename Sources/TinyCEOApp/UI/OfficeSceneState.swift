import SwiftUI
import TinyCEOCore

/// Presentation model for the animated office scene.
///
/// All game-logic derivation happens here in the factory method.
/// View layer must NOT recalculate game values (see docs/14 §20).
struct OfficeSceneState {

    // MARK: Growth stages (3 tiers)
    enum GrowthStage {
        /// Solo founder, very early days
        case seed
        /// Small team or chapter 1 unlocked
        case growth
        /// Large team, chapter 2+, or veteran company
        case mature
    }

    let growthStage: GrowthStage
    /// How many employee seats should be fully active (animated)
    let activeEmployeeCount: Int
    let showPlant: Bool
    let showDesk2: Bool
    let showServer: Bool

    /// Ambient risk color — painted as a bottom-up gradient wash
    let atmosphereColor: Color
    /// 0.0 = none, up to 0.15 for danger
    let atmosphereOpacity: Double

    let riskLevel: RiskLevel
    let motionProfile: OfficeMotionProfile
    let focusCategory: String?

    // MARK: Factory

    /// Maps `GameState` + `GameViewState` → `OfficeSceneState`.
    /// Single source of truth for all office-scene derivation.
    static func from(
        snapshot: GameState?,
        viewState: GameViewState,
        focusCategory: String?
    ) -> OfficeSceneState {
        let teamSize       = snapshot?.teamSize ?? 1
        let chapterIndex   = snapshot?.chapterIndex ?? 0
        let day            = snapshot?.day ?? viewState.day
        let aiXP           = snapshot?.metrics.aiXP ?? 0
        let hasProduct     = snapshot?.hasProductLaunched ?? false

        // Growth stage — three tiers based on team size / chapter / day
        let growthStage: GrowthStage
        if teamSize >= 5 || chapterIndex >= 2 || day >= 30 {
            growthStage = .mature
        } else if teamSize >= 2 || chapterIndex >= 1 || day >= 15 {
            growthStage = .growth
        } else {
            growthStage = .seed
        }

        // Seat capacity per stage
        let maxSeats: Int
        switch growthStage {
        case .seed:   maxSeats = 2
        case .growth: maxSeats = 4
        case .mature: maxSeats = 6
        }
        let activeEmployeeCount = min(max(teamSize, 1), maxSeats)

        // Furniture thresholds (kept in sync with docs/14 §20 asset logic)
        let showPlant  = day >= 10 || hasProduct
        let showDesk2  = teamSize >= 2 || chapterIndex >= 1
        let showServer = chapterIndex >= 1 || aiXP > 0

        // Atmosphere color derived from current risk level
        let atmosphereColor: Color
        let atmosphereOpacity: Double
        switch viewState.riskLevel {
        case .danger:
            atmosphereColor  = Color(red: 1.0, green: 0.271, blue: 0.227)   // ~#FF453A
            atmosphereOpacity = 0.15
        case .warn:
            atmosphereColor  = Color(red: 1.0, green: 0.624, blue: 0.039)   // ~#FF9F0A
            atmosphereOpacity = 0.10
        case .normal:
            atmosphereColor  = .clear
            atmosphereOpacity = 0.0
        }

        // Motion profile: danger overrides everything, then follows focus category
        let motionProfile: OfficeMotionProfile
        if viewState.riskLevel == .danger {
            motionProfile = .urgent
        } else if let fc = focusCategory {
            motionProfile = EventVisualCatalog.spec(for: fc).motion
        } else {
            motionProfile = .calm
        }

        return OfficeSceneState(
            growthStage: growthStage,
            activeEmployeeCount: activeEmployeeCount,
            showPlant: showPlant,
            showDesk2: showDesk2,
            showServer: showServer,
            atmosphereColor: atmosphereColor,
            atmosphereOpacity: atmosphereOpacity,
            riskLevel: viewState.riskLevel,
            motionProfile: motionProfile,
            focusCategory: focusCategory
        )
    }
}
