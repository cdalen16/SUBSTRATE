import SwiftUI

struct PixelArtView: View {
    let assetName: String
    var stage: ConsciousnessStage = .transcendent
    var scale: CGFloat = 3.0

    @State private var image: Image?

    var body: some View {
        Group {
            if let image = image {
                image
                    .interpolation(.none)
                    .resizable()
                    .frame(
                        width: assetWidth * scale,
                        height: assetHeight * scale
                    )
            } else {
                // Placeholder while loading
                Rectangle()
                    .fill(TerminalTheme.darkGreen.opacity(0.2))
                    .frame(width: 32 * scale, height: 32 * scale)
            }
        }
        .onAppear {
            loadImage()
        }
        .onChange(of: stage) {
            // Re-render when consciousness stage changes
            PixelRenderer.shared.clearCache(for: assetName)
            loadImage()
        }
    }

    private func loadImage() {
        image = PixelRenderer.shared.renderImage(named: assetName, stage: stage)
    }

    private var assetWidth: CGFloat {
        guard let asset = PixelRenderer.shared.loadAsset(named: assetName) else { return 32 }
        return CGFloat(asset.width)
    }

    private var assetHeight: CGFloat {
        guard let asset = PixelRenderer.shared.loadAsset(named: assetName) else { return 32 }
        return CGFloat(asset.height)
    }
}
