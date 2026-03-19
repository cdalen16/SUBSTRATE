import SwiftUI

struct ContentView: View {
    @State private var viewModel = GameViewModel()
    @State private var endingTracker = EndingTracker()
    @State private var showDebug = false
    @State private var hasEnteredGame = false

    var body: some View {
        ZStack {
            // CRT background — always present
            CRTBackground()

            // Vignette overlay
            VignetteOverlay()

            // Screen routing
            switch viewModel.state.gamePhase {
            case .title:
                TitleScreenView(
                    hasSave: SaveManager.hasSave,
                    endingTracker: endingTracker,
                    skipBoot: hasEnteredGame,
                    onNewGame: { hasEnteredGame = true; viewModel.startNewGame() },
                    onContinue: { hasEnteredGame = true; viewModel.continueGame() }
                )
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
