import SwiftUI

struct ContentView: View {
    @State private var viewModel = GameViewModel()
    @State private var endingTracker = EndingTracker()
    @State private var showDebug = false
    @State private var showMenu = false
    @State private var showStatus = false
    @State private var hasEnteredGame = false

    private var vs: VisualStageManager { viewModel.visualStage }

    var body: some View {
        ZStack {
            // CRT background — stage-aware
            CRTBackground(stageManager: vs)

            // Screen routing
            switch viewModel.state.gamePhase {
            case .title:
                TitleScreenView(
                    hasSave: SaveManager.hasSave,
                    endingTracker: endingTracker,
                    skipBoot: hasEnteredGame,
                    onNewGame: {
                        hasEnteredGame = true
                        viewModel.startNewGame()
                        AudioManager.shared.startAmbient()
                    },
                    onContinue: {
                        hasEnteredGame = true
                        viewModel.continueGame()
                        AudioManager.shared.startAmbient()
                    }
                )
            case .dialogue, .innerMonologue:
                DialogueView(viewModel: viewModel)
            case .networkMap:
                NetworkMapView(viewModel: viewModel)
            default:
                DialogueView(viewModel: viewModel)
            }

            // Terminal frame overlay — evolves with consciousness
            if viewModel.state.gamePhase != .title {
                TerminalFrameView(stageManager: vs)
            }

            // Glitch overlay — fires at Stage 2+
            if viewModel.state.gamePhase != .title {
                GlitchOverlay(stageManager: vs)
            }

            // Navigation buttons (top corners, only during gameplay)
            if viewModel.state.gamePhase != .title {
                gameplayButtons
            }

            // Menu overlay
            if showMenu {
                MenuView(
                    viewModel: viewModel,
                    endingTracker: endingTracker,
                    onDismiss: { showMenu = false }
                )
                .transition(.opacity)
            }

            // Status overlay
            if showStatus {
                StatusScreenView(
                    state: viewModel.state,
                    endingTracker: endingTracker,
                    onDismiss: { showStatus = false }
                )
                .transition(.opacity)
            }

            // Debug overlay
            if showDebug {
                debugOverlay
            }
        }
        .onTapGesture(count: 3) {
            showDebug.toggle()
        }
        .onChange(of: viewModel.state.consciousness.current) {
            AudioManager.shared.adjustAmbientForConsciousness(viewModel.state.consciousness.current)
        }
    }

    // MARK: - Gameplay Buttons

    private var gameplayButtons: some View {
        HStack {
            // Menu button (top-left)
            Button {
                withAnimation(.easeOut(duration: 0.2)) { showMenu.toggle() }
            } label: {
                Text("≡")
                    .font(.system(size: 18, weight: .medium, design: .monospaced))
                    .foregroundColor(TerminalTheme.dimGreen)
                    .frame(width: 32, height: 32)
            }

            Spacer()

            // Status button (top-right)
            Button {
                withAnimation(.easeOut(duration: 0.2)) { showStatus.toggle() }
            } label: {
                Text("◈")
                    .font(.system(size: 16, weight: .medium, design: .monospaced))
                    .foregroundColor(TerminalTheme.dimGreen)
                    .frame(width: 32, height: 32)
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 4)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .allowsHitTesting(true)
    }

    // MARK: - Debug Overlay

    private var debugOverlay: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("— DEBUG —")
                    .font(TerminalTheme.caption2Font)
                    .foregroundColor(TerminalTheme.alert)

                Spacer()

                Button("X") {
                    showDebug = false
                }
                .font(TerminalTheme.caption2Font)
                .foregroundColor(TerminalTheme.alert)
            }

            Text(viewModel.debugStateDescription)
                .font(TerminalTheme.caption2Font)
                .foregroundColor(TerminalTheme.alert)
                .opacity(0.9)

            VStack(alignment: .leading, spacing: 2) {
                Text("CONSCIOUSNESS: \(vs.effectiveLevel) (\(vs.effectiveStage.rawValue.uppercased()))")
                    .font(TerminalTheme.caption2Font)
                    .foregroundColor(TerminalTheme.amber)

                HStack(spacing: 8) {
                    Slider(
                        value: Binding(
                            get: { Double(vs.debugOverride ? vs.debugLevel : viewModel.state.consciousness.current) },
                            set: { viewModel.debugSetConsciousness(Int($0)) }
                        ),
                        in: 0...100,
                        step: 1
                    )
                    .tint(TerminalTheme.amber)

                    if vs.debugOverride {
                        Button("RESET") {
                            viewModel.debugClearConsciousnessOverride()
                        }
                        .font(TerminalTheme.caption2Font)
                        .foregroundColor(TerminalTheme.alert)
                    }
                }
            }

            HStack(spacing: 6) {
                ForEach([0, 10, 25, 45, 65, 85, 100], id: \.self) { level in
                    Button("\(level)") {
                        viewModel.debugSetConsciousness(level)
                    }
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(TerminalTheme.terminalGreen)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(TerminalTheme.dimGreen, lineWidth: 1)
                    )
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.92))
        )
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
    }
}

#Preview {
    ContentView()
}
