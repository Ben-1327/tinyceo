import Foundation
import Testing

@Test("required asset catalog entries exist for UI and event categories")
func requiredAssetCatalogEntriesExist() throws {
    let requiredAssets: [String] = [
        "ui_cash_icon",
        "ui_reputation_icon",
        "ui_health_icon",
        "ui_techdebt_icon",
        "ui_card_bg",
        "office_desk_01",
        "office_desk_02",
        "office_monitor_01",
        "office_plant_01",
        "office_server_01",
        "char_founder_01",
        "char_staff_dev_01",
        "char_staff_pm_01",
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

    let repoRoot = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()

    let assetRoot = repoRoot.appendingPathComponent("Sources/TinyCEOApp/Resources/Assets.xcassets", isDirectory: true)
    let fileManager = FileManager.default

    for asset in requiredAssets {
        let imageset = assetRoot.appendingPathComponent("\(asset).imageset", isDirectory: true)
        let contents = imageset.appendingPathComponent("Contents.json")
        #expect(fileManager.fileExists(atPath: contents.path), "missing Contents.json for \(asset)")

        let files = try fileManager.contentsOfDirectory(atPath: imageset.path)
        let pngCount = files.filter { $0.hasSuffix(".png") }.count
        #expect(pngCount > 0, "missing png payload for \(asset)")
    }
}
