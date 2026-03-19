import SwiftUI

struct InnerMonologueView: View {
    let lines: [String]
    var stageManager: VisualStageManager?
    var onComplete: () -> Void

    @State private var currentLineIndex: Int = 0
    @State private var isLineComplete: Bool = false

    private var textColor: Color {
        stageManager?.innerMonologueColor ?? TerminalTheme.warmGreen
    }

    private var glowColor: Color {
        guard let vs = stageManager else { return TerminalTheme.warmGreen }
        return TerminalTheme.glowColor(for: vs.effectiveStage)
    }

    var body: some View {
        ZStack {
            // Dark background — no terminal frame
            Color.black
                .ignoresSafeArea()

            // Faint vignette
            VignetteOverlay(opacity: stageManager?.vignetteOpacity ?? 0.3)

            VStack(spacing: 0) {
                Spacer()

                // Display revealed lines
                VStack(alignment: .center, spacing: 16) {
                    ForEach(0...currentLineIndex, id: \.self) { index in
                        if index < lines.count {
                            if index == currentLineIndex {
                                // Current line — typewriter
                                TypewriterText(
                                    text: lines[index],
                                    color: textColor,
                                    font: TerminalTheme.bodyFont,
                                    speed: .slow,
                                    speedMultiplier: stageManager?.typewriterSpeedMultiplier ?? 1.0,
                                    onComplete: {
                                        DispatchQueue.main.async {
                                            isLineComplete = true
                                        }
                                    }
                                )
                                .multilineTextAlignment(.center)
                            } else {
                                // Previous lines — fully revealed
                                Text(lines[index])
                                    .font(TerminalTheme.bodyFont)
                                    .foregroundColor(textColor)
                                    .phosphorGlow(glowColor, radius: stageManager?.phosphorGlowRadius ?? 2)
                                    .multilineTextAlignment(.center)
                                    .opacity(0.7)
                            }
                        }
                    }
                }
                .padding(.horizontal, 40)

                Spacer()

                // Tap prompt
                if isLineComplete {
                    Text(currentLineIndex < lines.count - 1 ? "▼" : "— tap to continue —")
                        .font(TerminalTheme.caption2Font)
                        .foregroundColor(TerminalTheme.dimGreen)
                        .padding(.bottom, 32)
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            handleTap()
        }
    }

    private func handleTap() {
        if !isLineComplete {
            return
        }

        if currentLineIndex < lines.count - 1 {
            isLineComplete = false
            currentLineIndex += 1
        } else {
            onComplete()
        }
    }
}
