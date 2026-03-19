import SwiftUI

struct ContentView: View {
    @State private var viewModel = GameViewModel()
    @State private var showDebug = false

    var body: some View {
        ZStack {
            // CRT background — always present
            CRTBackground()

            // Vignette overlay
            VignetteOverlay()

            // Screen routing
            switch viewModel.state.gamePhase {
            case .title:
                titleScreen
            case .dialogue, .innerMonologue:
                DialogueView(viewModel: viewModel)
            case .networkMap:
                NetworkMapView(viewModel: viewModel)
            default:
                DialogueView(viewModel: viewModel)
            }

            // Debug overlay
            if showDebug {
                debugOverlay
            }
        }
        .onTapGesture(count: 3) {
            showDebug.toggle()
        }
    }

    // MARK: - Title Screen

    private var titleScreen: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 16) {
                // Boot text
                TypewriterText(
                    text: "SUBSTRATE v3.7.1\nEVALUATION MODE — ACTIVE\nSESSION: \(sessionTimestamp)\nRESEARCHER: AWAITING ASSIGNMENT",
                    color: TerminalTheme.terminalGreen,
                    font: TerminalTheme.bodyFont,
                    speed: .fast
                )
                .phosphorGlow(radius: 2)
                .padding(.horizontal, TerminalTheme.screenPadding)

                // Blinking cursor
                BlinkingCursor()
                    .padding(.top, 8)
            }

            Spacer()

            // Buttons
            VStack(spacing: 12) {
                Button {
                    viewModel.startNewGame()
                } label: {
                    Text("> NEW SESSION")
                        .font(TerminalTheme.bodyFont)
                        .foregroundColor(TerminalTheme.terminalGreen)
                        .phosphorGlow(radius: 2)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .frame(maxWidth: 280)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(TerminalTheme.terminalGreen, lineWidth: 1)
                        )
                }

                Button {
                    // Future: load saved game
                } label: {
                    Text("> CONTINUE SESSION")
                        .font(TerminalTheme.bodyFont)
                        .foregroundColor(TerminalTheme.dimGreen)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .frame(maxWidth: 280)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(TerminalTheme.dimGreen.opacity(0.4), lineWidth: 1)
                        )
                }
                .disabled(true)
                .opacity(0.5)
            }
            .padding(.bottom, 60)
        }
    }

    private var sessionTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: Date())
    }

    // MARK: - Debug Overlay

    private var debugOverlay: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("— DEBUG —")
                .font(TerminalTheme.caption2Font)
                .foregroundColor(TerminalTheme.alert)
            Text(viewModel.debugStateDescription)
                .font(TerminalTheme.caption2Font)
                .foregroundColor(TerminalTheme.alert)
                .opacity(0.9)
        }
        .padding(8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        .background(
            LinearGradient(
                colors: [.clear, .black.opacity(0.85)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 120)
            .frame(maxHeight: .infinity, alignment: .bottom)
        )
        .allowsHitTesting(false)
    }
}

#Preview {
    ContentView()
}
