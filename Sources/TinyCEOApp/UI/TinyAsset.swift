import AppKit
import SwiftUI

enum TinyAsset {
    static func icon(assetName: String?, sfSymbol: String) -> Image {
        guard let assetName else {
            return Image(systemName: sfSymbol)
        }

        if let image = NSImage(named: NSImage.Name(assetName)) {
            image.isTemplate = true
            return Image(nsImage: image).renderingMode(.template)
        }

        print("[TinyAsset] fallback: \(assetName) -> \(sfSymbol)")
        return Image(systemName: sfSymbol)
    }

    static func officeSprite(named assetName: String) -> Image? {
        guard let image = NSImage(named: NSImage.Name(assetName)) else {
            return nil
        }
        return Image(nsImage: image).renderingMode(.original)
    }

    static func choiceTexture() -> Image? {
        guard let image = NSImage(named: NSImage.Name("ui_card_bg")) else {
            return nil
        }
        return Image(nsImage: image).renderingMode(.original)
    }
}
