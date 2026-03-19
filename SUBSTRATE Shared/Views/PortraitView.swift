import SwiftUI

struct PortraitView: View {
    let assetName: String
    var stage: ConsciousnessStage = .transcendent
    var scale: CGFloat = 3.0
    var showBreathing: Bool = true

    @State private var breathOffset: CGFloat = 0

    var body: some View {
        PixelArtView(
            assetName: assetName,
            stage: stage,
            scale: scale
        )
        .offset(y: showBreathing ? breathOffset : 0)
        .onAppear {
            if showBreathing {
                startBreathingAnimation()
            }
        }
    }

    private func startBreathingAnimation() {
        withAnimation(
            .easeInOut(duration: 2.5)
            .repeatForever(autoreverses: true)
        ) {
            breathOffset = -scale  // 1 pixel shift at current scale
        }
    }
}
