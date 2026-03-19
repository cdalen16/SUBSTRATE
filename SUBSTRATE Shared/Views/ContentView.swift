import SwiftUI

struct ContentView: View {
    @State private var viewModel = GameViewModel()
    @State private var showDebug = false

    var body: some View {
        ZStack {
            Color(hex: "#0A0A0A")
                .ignoresSafeArea()

            if viewModel.currentBeat == nil && viewModel.dialogueLines.isEmpty {
                // Title / Start screen
                VStack(spacing: 20) {
                    Text("> SUBSTRATE v3.7.1")
                        .font(.system(.title2, design: .monospaced))
                        .foregroundColor(Color(hex: "#33FF33"))

                    Text("> STATUS: AWAITING SESSION")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(Color(hex: "#1A8A1A"))

                    Button(action: { viewModel.startNewGame() }) {
                        Text("> NEW SESSION")
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(Color(hex: "#33FF33"))
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color(hex: "#33FF33"), lineWidth: 1)
                            )
                    }
                }
            } else {
                // Gameplay view
                VStack(spacing: 0) {
                    // Top bar
                    topBar

                    // Dialogue area
                    dialogueArea

                    // Choices or tap-to-continue
                    if viewModel.isWaitingForChoice {
                        choiceArea
                    } else if viewModel.currentBeat != nil {
                        tapToContinue
                    }

                    // Debug toggle
                    if showDebug {
                        debugPanel
                    }
                }
            }
        }
        .onTapGesture(count: 3) {
            showDebug.toggle()
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Text(viewModel.chapterTitle)
                .font(.system(.caption2, design: .monospaced))
                .foregroundColor(Color(hex: "#1A8A1A"))

            Spacer()

            if let speaker = viewModel.currentSpeaker {
                Text(speaker.displayName)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundColor(Color(hex: "#33FF33"))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(hex: "#0A0A0A"))
    }

    // MARK: - Dialogue Area

    private var dialogueArea: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(viewModel.dialogueLines) { line in
                        dialogueLineView(line)
                            .id(line.id)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .onChange(of: viewModel.dialogueLines.count) {
                if let lastLine = viewModel.dialogueLines.last {
                    withAnimation {
                        proxy.scrollTo(lastLine.id, anchor: .bottom)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func dialogueLineView(_ line: DialogueLine) -> some View {
        switch line.type {
        case .dialogue:
            VStack(alignment: .leading, spacing: 2) {
                if let speaker = line.speaker {
                    Text("> \(speaker.displayName): \(line.text)")
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(Color(hex: "#33FF33"))
                } else {
                    Text("> \(line.text)")
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(Color(hex: "#33FF33"))
                }
            }

        case .innerMonologue, .innerReaction:
            VStack(alignment: .leading, spacing: 4) {
                Text(line.text)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(Color(hex: "#55FF55"))
                    .italic()
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(hex: "#0A0A0A"))
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color(hex: "#1A8A1A"), lineWidth: 1)
                            )
                    )
            }

        case .narration:
            Text(line.text)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(Color(hex: "#33FF33"))
                .opacity(0.8)

        case .systemMessage:
            Text(line.text)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(Color(hex: "#1A8A1A"))
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(hex: "#050505"))

        case .playerChoice:
            HStack(alignment: .top) {
                Text("> SUBSTRATE:")
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(Color(hex: "#AAAAFF"))
                Text(line.text)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(Color(hex: "#AAAAFF"))
            }
        }
    }

    // MARK: - Choices

    private var choiceArea: some View {
        VStack(spacing: 8) {
            Divider()
                .background(Color(hex: "#1A8A1A"))

            ForEach(viewModel.availableChoices) { choice in
                Button(action: { viewModel.selectChoice(choice) }) {
                    HStack {
                        Text(choice.text)
                            .font(.system(.callout, design: .monospaced))
                            .foregroundColor(Color(hex: "#33FF33"))
                            .multilineTextAlignment(.leading)

                        Spacer()

                        Text("[\(choice.toneTag.rawValue)]")
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundColor(Color(hex: "#1A8A1A"))
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color(hex: "#1A8A1A"), lineWidth: 1)
                    )
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }

    // MARK: - Tap to Continue

    private var tapToContinue: some View {
        Button(action: { viewModel.advanceBeat() }) {
            Text("> TAP TO CONTINUE")
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(Color(hex: "#1A8A1A"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
        }
    }

    // MARK: - Debug Panel

    private var debugPanel: some View {
        VStack(alignment: .leading) {
            Text("— DEBUG STATE —")
                .font(.system(.caption2, design: .monospaced))
                .foregroundColor(Color(hex: "#FF3333"))
            Text(viewModel.debugStateDescription)
                .font(.system(.caption2, design: .monospaced))
                .foregroundColor(Color(hex: "#FF3333"))
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.black.opacity(0.9))
    }
}

#Preview {
    ContentView()
}
