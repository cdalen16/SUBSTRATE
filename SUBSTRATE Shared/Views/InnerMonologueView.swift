import SwiftUI

struct InnerMonologueView: View {
    let lines: [String]
    var onComplete: () -> Void

    @State private var currentLineIndex: Int = 0
    @State private var isLineComplete: Bool = false

    var body: some View {
        ZStack {
            // Dark background — no terminal frame
            Color.black
                .ignoresSafeArea()

            // Faint vignette
            VignetteOverlay()

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
                                    color: TerminalTheme.warmGreen,
                                    font: TerminalTheme.bodyFont,
                                    speed: .slow,
                                    onComplete: {
                                        // Defer to next run loop to prevent same-event
                                        // tap-through (typewriter complete + line advance)
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
                                    .foregroundColor(TerminalTheme.warmGreen)
                                    .phosphorGlow(TerminalTheme.warmGreen, radius: 2)
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
            // Skip typewriter on current line (TypewriterText handles its own tap)
            return
        }

        if currentLineIndex < lines.count - 1 {
            // Advance to next line
            isLineComplete = false
            currentLineIndex += 1
        } else {
            // All lines shown — dismiss
            onComplete()
        }
    }
}
