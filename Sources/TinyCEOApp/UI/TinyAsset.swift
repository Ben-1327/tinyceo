import SwiftUI

enum TinyAsset {
    private static let knownIconAssets: Set<String> = [
        "ui_cash_icon",
        "ui_reputation_icon",
        "ui_health_icon",
        "ui_techdebt_icon",
        "cat_strategy_icon",
        "cat_hiring_icon",
        "cat_process_icon",
        "cat_sales_icon",
        "cat_product_icon",
        "cat_crisis_icon",
        "cat_culture_icon",
        "cat_ai_icon",
        "cat_investor_icon",
        "cat_exit_icon"
    ]

    private static let knownOfficeAssets: Set<String> = [
        "office_desk_01",
        "office_desk_02",
        "office_monitor_01",
        "office_plant_01",
        "office_server_01"
    ]

    private static let knownCharacterAssets: Set<String> = [
        "char_founder_01",
        "char_staff_dev_01",
        "char_staff_pm_01"
    ]

    static func icon(assetName: String?, sfSymbol: String) -> Image {
        guard let assetName else {
            return Image(systemName: sfSymbol)
        }

        if knownIconAssets.contains(assetName) {
            return Image(assetName, bundle: .module).renderingMode(.template)
        }

        print("[TinyAsset] fallback: \(assetName) -> \(sfSymbol)")
        return Image(systemName: sfSymbol)
    }

    static func officeSprite(named assetName: String) -> Image? {
        guard knownOfficeAssets.contains(assetName) else {
            return nil
        }
        return Image(assetName, bundle: .module).renderingMode(.original)
    }

    static func characterSprite(named assetName: String) -> Image? {
        guard knownCharacterAssets.contains(assetName) else {
            return nil
        }
        return Image(assetName, bundle: .module).renderingMode(.original)
    }

    static func choiceTexture() -> Image? {
        Image("ui_card_bg", bundle: .module).renderingMode(.original)
    }
}
