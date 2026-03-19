import UIKit
import SwiftUI

final class PixelRenderer {

    static let shared = PixelRenderer()

    private var imageCache: [String: UIImage] = [:]
    private var assetCache: [String: PixelArtAsset] = [:]

    // MARK: - Load Asset from Bundle

    func loadAsset(named name: String) -> PixelArtAsset? {
        if let cached = assetCache[name] { return cached }

        // Search in PixelArt subdirectories
        let subdirs = ["Portraits", "Icons", "Environments", ""]
        for subdir in subdirs {
            if let url = Bundle.main.url(forResource: name, withExtension: "json", subdirectory: subdir.isEmpty ? "PixelArt" : "PixelArt/\(subdir)") {
                return decodeAsset(at: url)
            }
        }
        // Flat search
        if let url = Bundle.main.url(forResource: name, withExtension: "json") {
            return decodeAsset(at: url)
        }
        return nil
    }

    private func decodeAsset(at url: URL) -> PixelArtAsset? {
        do {
            let data = try Data(contentsOf: url)
            let asset = try JSONDecoder().decode(PixelArtAsset.self, from: data)
            assetCache[asset.name] = asset
            return asset
        } catch {
            print("[PixelRenderer] Failed to decode \(url.lastPathComponent): \(error)")
            return nil
        }
    }

    // MARK: - Render to UIImage

    func render(asset: PixelArtAsset, stage: ConsciousnessStage = .transcendent) -> UIImage {
        let cacheKey = "\(asset.name)_\(stage.rawValue)"
        if let cached = imageCache[cacheKey] {
            return cached
        }

        let w = asset.width
        let h = asset.height

        let renderer = UIGraphicsImageRenderer(size: CGSize(width: w, height: h))
        let image = renderer.image { ctx in
            for row in 0..<min(h, asset.pixels.count) {
                let rowPixels = asset.pixels[row]
                for col in 0..<min(w, rowPixels.count) {
                    let hex = rowPixels[col]
                    let color = PaletteManager.remapColor(hex: hex, stage: stage)
                    color.setFill()
                    ctx.fill(CGRect(x: col, y: row, width: 1, height: 1))
                }
            }
        }

        imageCache[cacheKey] = image
        return image
    }

    /// Render and return as SwiftUI Image
    func renderImage(asset: PixelArtAsset, stage: ConsciousnessStage = .transcendent) -> Image {
        let uiImage = render(asset: asset, stage: stage)
        return Image(uiImage: uiImage)
    }

    /// Load by name and render
    func renderImage(named name: String, stage: ConsciousnessStage = .transcendent) -> Image? {
        guard let asset = loadAsset(named: name) else { return nil }
        return renderImage(asset: asset, stage: stage)
    }

    // MARK: - Cache Management

    func clearCache() {
        imageCache.removeAll()
        assetCache.removeAll()
    }

    func clearCache(for name: String) {
        imageCache = imageCache.filter { !$0.key.hasPrefix(name) }
        // Asset cache is NOT cleared — raw pixel data doesn't change with stage
    }
}
