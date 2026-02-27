import SwiftUI

struct EventVisualSpec {
    let category: String
    let label: String
    let iconAssetName: String?
    let fallbackSymbol: String
    let motion: OfficeMotionProfile
}

enum OfficeMotionProfile {
    case calm
    case steady
    case busy
    case urgent
}

enum EventVisualCatalog {
    static func spec(for category: String) -> EventVisualSpec {
        switch category {
        case "STRATEGY":
            return EventVisualSpec(
                category: category,
                label: "戦略",
                iconAssetName: "cat_strategy_icon",
                fallbackSymbol: "target",
                motion: .steady
            )
        case "HIRING":
            return EventVisualSpec(
                category: category,
                label: "採用",
                iconAssetName: "cat_hiring_icon",
                fallbackSymbol: "person.2.fill",
                motion: .busy
            )
        case "PROCESS":
            return EventVisualSpec(
                category: category,
                label: "業務改善",
                iconAssetName: "cat_process_icon",
                fallbackSymbol: "wrench.and.screwdriver.fill",
                motion: .steady
            )
        case "SALES":
            return EventVisualSpec(
                category: category,
                label: "営業",
                iconAssetName: "cat_sales_icon",
                fallbackSymbol: "chart.line.uptrend.xyaxis",
                motion: .busy
            )
        case "PRODUCT":
            return EventVisualSpec(
                category: category,
                label: "プロダクト",
                iconAssetName: "cat_product_icon",
                fallbackSymbol: "shippingbox.fill",
                motion: .steady
            )
        case "FINANCE":
            return EventVisualSpec(
                category: category,
                label: "資金",
                iconAssetName: "ui_cash_icon",
                fallbackSymbol: "yensign.circle.fill",
                motion: .calm
            )
        case "CRISIS":
            return EventVisualSpec(
                category: category,
                label: "危機対応",
                iconAssetName: "cat_crisis_icon",
                fallbackSymbol: "exclamationmark.triangle.fill",
                motion: .urgent
            )
        case "CULTURE":
            return EventVisualSpec(
                category: category,
                label: "文化",
                iconAssetName: "cat_culture_icon",
                fallbackSymbol: "heart.fill",
                motion: .calm
            )
        case "AI":
            return EventVisualSpec(
                category: category,
                label: "AI",
                iconAssetName: "cat_ai_icon",
                fallbackSymbol: "sparkles",
                motion: .busy
            )
        case "INVESTOR":
            return EventVisualSpec(
                category: category,
                label: "投資家",
                iconAssetName: "cat_investor_icon",
                fallbackSymbol: "person.3.fill",
                motion: .steady
            )
        case "EXIT":
            return EventVisualSpec(
                category: category,
                label: "イグジット",
                iconAssetName: "cat_exit_icon",
                fallbackSymbol: "flag.checkered",
                motion: .urgent
            )
        default:
            return EventVisualSpec(
                category: category,
                label: category,
                iconAssetName: nil,
                fallbackSymbol: "square.grid.2x2.fill",
                motion: .steady
            )
        }
    }
}
