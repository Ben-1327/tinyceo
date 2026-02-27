import AppKit
import Foundation
import SwiftUI

@MainActor
enum TinyAsset {
    private static let cache = NSCache<NSString, NSImage>()

    static func icon(assetName: String?, sfSymbol: String) -> Image {
        guard let assetName else {
            return Image(systemName: sfSymbol)
        }

        if let image = loadImage(named: assetName) {
            image.isTemplate = true
            return Image(nsImage: image).renderingMode(.template)
        }

        print("[TinyAsset] fallback: \(assetName) -> \(sfSymbol)")
        return Image(systemName: sfSymbol)
    }

    static func officeSprite(named assetName: String) -> Image? {
        guard let image = loadImage(named: assetName) else {
            return nil
        }
        return Image(nsImage: image).renderingMode(.original)
    }

    static func characterSprite(named assetName: String) -> Image? {
        guard let image = loadImage(named: assetName) else {
            return nil
        }
        return Image(nsImage: image).renderingMode(.original)
    }

    static func choiceTexture() -> Image? {
        guard let image = loadImage(named: "ui_card_bg") else {
            return nil
        }
        return Image(nsImage: image).renderingMode(.original)
    }

    private static func loadImage(named assetName: String) -> NSImage? {
        if let cached = cache.object(forKey: assetName as NSString) {
            return cached
        }

        if let direct = Bundle.module.image(forResource: NSImage.Name(assetName)) {
            cache.setObject(direct, forKey: assetName as NSString)
            return direct
        }

        if let url = Bundle.module.url(forResource: assetName, withExtension: "png"),
           let directPNG = NSImage(contentsOf: url) {
            cache.setObject(directPNG, forKey: assetName as NSString)
            return directPNG
        }

        if let fromImageset = loadFromImageset(named: assetName) {
            cache.setObject(fromImageset, forKey: assetName as NSString)
            return fromImageset
        }

        return nil
    }

    private static func loadFromImageset(named assetName: String) -> NSImage? {
        guard let resourceURL = Bundle.module.resourceURL else {
            return nil
        }

        let imagesetDir = resourceURL
            .appendingPathComponent("Assets.xcassets", isDirectory: true)
            .appendingPathComponent("\(assetName).imageset", isDirectory: true)
        let contentsURL = imagesetDir.appendingPathComponent("Contents.json")

        guard let data = try? Data(contentsOf: contentsURL),
              let contents = try? JSONDecoder().decode(ImagesetContents.self, from: data) else {
            return loadFirstPNGInDirectory(imagesetDir)
        }

        let preferredFile = contents.images
            .first(where: { $0.scale == "1x" && $0.filename != nil })?.filename
            ?? contents.images.first(where: { $0.filename != nil })?.filename

        guard let preferredFile else {
            return loadFirstPNGInDirectory(imagesetDir)
        }

        let pngURL = imagesetDir.appendingPathComponent(preferredFile)
        return NSImage(contentsOf: pngURL)
    }

    private static func loadFirstPNGInDirectory(_ directory: URL) -> NSImage? {
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) else {
            return nil
        }

        guard let pngURL = files.first(where: { $0.pathExtension.lowercased() == "png" }) else {
            return nil
        }
        return NSImage(contentsOf: pngURL)
    }
}

private struct ImagesetContents: Decodable {
    var images: [ImagesetImageRecord]
}

private struct ImagesetImageRecord: Decodable {
    var filename: String?
    var scale: String?
}
