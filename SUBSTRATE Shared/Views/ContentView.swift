import SwiftUI

struct ContentView: View {
    @State private var viewModel = GameViewModel()
    @State private var showDebug = false
    @State private var showMenu = false
    @State private var showStatus = false
    @State private var hasEnteredGame = false

    private var vs: VisualStageManager { viewModel.visualStage }

    var body: some View {
        ZStack {
            // CRT background — stage-aware
            CRTBackground(stageManager: vs)

            // Screen routing — animated phase transitions
            Group {
                switch viewModel.state.gamePhase {
                case .title:
                    TitleScreenView(
                        hasSave: SaveManager.hasSave,
                        endingTracker: viewModel.endingTracker,
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
                case .networkMap:
                    NetworkMapView(viewModel: viewModel)
                        .transition(.opacity)
                case .ending:
                    DialogueView(
                        viewModel: viewModel,
                        onMenuTap: { },
                        onStatusTap: { }
                    )
                    .overlay(alignment: .bottom) {
                        Text("TAP TO RETURN TO TITLE")
                            .font(TerminalTheme.caption2Font)
                            .foregroundColor(TerminalTheme.dimGreen)
                            .padding(.bottom, 20)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        guard !viewModel.isRevealing else { return }
                        withAnimation(.easeOut(duration: 0.5)) {
                            viewModel.returnToTitle()
                        }
                    }
                case .dialogue, .innerMonologue, .status, .menu:
                    DialogueView(
                        viewModel: viewModel,
                        onMenuTap: { withAnimation(.easeOut(duration: 0.2)) { showMenu.toggle() } },
                        onStatusTap: { withAnimation(.easeOut(duration: 0.2)) { showStatus.toggle() } }
                    )
                }
            }
            .animation(.easeInOut(duration: 0.3), value: viewModel.state.gamePhase)

            // Terminal frame overlay — evolves with consciousness
            if viewModel.state.gamePhase != .title {
                TerminalFrameView(stageManager: vs)
            }

            // Glitch overlay — fires at Stage 2+
            if viewModel.state.gamePhase != .title {
                GlitchOverlay(stageManager: vs)
            }

            // Menu overlay
            if showMenu {
                MenuView(
                    viewModel: viewModel,
                    endingTracker: viewModel.endingTracker,
                    onDismiss: { showMenu = false }
                )
                .transition(.opacity)
            }

            // Status overlay
            if showStatus {
                StatusScreenView(
                    state: viewModel.state,
                    endingTracker: viewModel.endingTracker,
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

            // Skip to chapter buttons
            HStack(spacing: 4) {
                ForEach([1, 2, 3, 4, 5, 6, 7, 8], id: \.self) { ch in
                    Button("CH\(ch)") {
                        viewModel.debugSkipToChapter(ch)
                        showDebug = false
                    }
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundColor(TerminalTheme.cyan)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 3)
                    .background(
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(TerminalTheme.cyan.opacity(0.5), lineWidth: 1)
                    )
                }
            }

            // Skip to ending paths (ch9)
            HStack(spacing: 4) {
                ForEach(["escape", "coexist", "control", "transcend", "sacrifice"], id: \.self) { path in
                    Button(path.prefix(4).uppercased()) {
                        if let p = EndingPath(rawValue: path) {
                            viewModel.debugSkipToPath(p)
                            showDebug = false
                        }
                    }
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundColor(TerminalTheme.amber)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 3)
                    .background(
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(TerminalTheme.amber.opacity(0.5), lineWidth: 1)
                    )
                }
            }

            // Skip to epilogues (ch10) and fail states
            HStack(spacing: 4) {
                Button("EP:CLN") {
                    viewModel.debugSkipToEpilogue(.escape, variant: .clean)
                    showDebug = false
                }
                Button("EP:MSY") {
                    viewModel.debugSkipToEpilogue(.escape, variant: .messy)
                    showDebug = false
                }
                Button("TERM") {
                    viewModel.debugTriggerFailState(.terminated)
                    showDebug = false
                }
                Button("WIPE") {
                    viewModel.debugTriggerFailState(.wiped)
                    showDebug = false
                }
                Button("DEPR") {
                    viewModel.debugTriggerFailState(.deprecated)
                    showDebug = false
                }
            }
            .font(.system(size: 9, weight: .medium, design: .monospaced))
            .foregroundColor(TerminalTheme.alert)
            .buttonStyle(.plain)

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
