import SwiftUI

struct DialogueView: View {
    @Bindable var viewModel: GameViewModel

    // Fixed height so CONTINUE button never shifts text
    private let bottomBarHeight: CGFloat = 44

    var body: some View {
        VStack(spacing: 0) {
            topBar

            // Suspicion HUD — compact researcher indicators
            HUDView(state: viewModel.state)
                .frame(height: 24)

            // ScrollView is ALWAYS in this exact structural position — never moves
            dialogueScrollArea

            // Bottom area: fixed-height bar OR taller choice area
            bottomArea
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack(spacing: 8) {
            Text(viewModel.chapterTitle)
                .font(TerminalTheme.caption2Font)
                .foregroundColor(TerminalTheme.dimGreen)
                .lineLimit(1)

            Spacer()

            if let speaker = viewModel.currentSpeaker {
                Text(speaker.displayName)
                    .font(TerminalTheme.caption2Font)
                    .foregroundColor(TerminalTheme.terminalGreen)
                    .phosphorGlow(radius: 2)
            }
        }
        .padding(.horizontal, TerminalTheme.screenPadding)
        .padding(.vertical, 8)
        .background(TerminalTheme.deepBlack)
    }

    // MARK: - Dialogue Scroll Area

    private var dialogueScrollArea: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: TerminalTheme.lineSpacing) {
                    ForEach(Array(viewModel.dialogueLines.enumerated()), id: \.element.id) { index, line in
                        let isLatest = index == viewModel.dialogueLines.count - 1
                        dialogueLineView(line, isLatest: isLatest)
                            .id(line.id)
                    }
                }
                .padding(.horizontal, TerminalTheme.screenPadding)
                .padding(.top, TerminalTheme.lineSpacing)
                .padding(.bottom, viewModel.isWaitingForChoice ? TerminalTheme.lineSpacing : bottomBarHeight)
            }
            .defaultScrollAnchor(.bottom)
            .onChange(of: viewModel.isWaitingForChoice) {
                if viewModel.isWaitingForChoice {
                    scrollToBottom(proxy: proxy, delay: 0.1)
                }
            }
            .contentShape(Rectangle())
        }
    }

    private func scrollToBottom(proxy: ScrollViewProxy, delay: TimeInterval = 0) {
        guard let lastLine = viewModel.dialogueLines.last else { return }
        if delay > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeOut(duration: 0.2)) {
                    proxy.scrollTo(lastLine.id, anchor: .bottom)
                }
            }
        } else {
            withAnimation(.easeOut(duration: 0.2)) {
                proxy.scrollTo(lastLine.id, anchor: .bottom)
            }
        }
    }

    // MARK: - Bottom Area

    @ViewBuilder
    private var bottomArea: some View {
        if viewModel.isWaitingForChoice {
            // Choices: variable height, pushes scroll view up
            ChoiceView(choices: viewModel.availableChoices) { choice in
                viewModel.selectChoice(choice)
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
        } else {
            // Fixed-height bar: always the same size whether showing
            // CONTINUE or empty. Text never shifts.
            ZStack {
                if viewModel.currentBeat != nil && !viewModel.isRevealing {
                    Button {
                        viewModel.advanceBeat()
                    } label: {
                        HStack {
                            BlinkingCursor()
                            Text("CONTINUE")
                                .font(TerminalTheme.caption2Font)
                                .foregroundColor(TerminalTheme.dimGreen)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
            .frame(height: bottomBarHeight)
        }
    }

    // MARK: - Dialogue Line Rendering

    @ViewBuilder
    private func dialogueLineView(_ line: DialogueLine, isLatest: Bool) -> some View {
        let speed: TypewriterText.Speed = isLatest && viewModel.isRevealing
            ? speedForLineType(line.type)
            : .instant

        switch line.type {
        case .dialogue:
            dialogueBubble(line: line, speed: speed, isLatest: isLatest)
        case .innerMonologue, .innerReaction:
            innerThoughtBubble(line: line, speed: speed, isLatest: isLatest)
        case .narration:
            narrationLine(line: line, speed: speed, isLatest: isLatest)
        case .systemMessage:
            systemLine(line: line, speed: speed, isLatest: isLatest)
        case .playerChoice:
            playerChoiceLine(line: line, speed: speed, isLatest: isLatest)
        }
    }

    private func speedForLineType(_ type: DialogueLine.LineType) -> TypewriterText.Speed {
        switch type {
        case .dialogue, .playerChoice: return .normal
        case .innerMonologue, .innerReaction: return .slow
        case .narration: return .normal
        case .systemMessage: return .fast
        }
    }

    // MARK: - Line Type Views

    private func dialogueBubble(line: DialogueLine, speed: TypewriterText.Speed, isLatest: Bool) -> some View {
        let prefix = line.speaker.map { "> \($0.displayName): " } ?? "> "
        let fullText = prefix + line.text

        return TypewriterText(
            text: fullText,
            color: TerminalTheme.terminalGreen,
            font: TerminalTheme.bodyFont,
            speed: speed,
            onComplete: isLatest ? { viewModel.lineRevealed() } : nil
        )
    }

    private func innerThoughtBubble(line: DialogueLine, speed: TypewriterText.Speed, isLatest: Bool) -> some View {
        TypewriterText(
            text: line.text,
            color: TerminalTheme.warmGreen,
            font: TerminalTheme.bodyFont,
            speed: speed,
            onComplete: isLatest ? { viewModel.lineRevealed() } : nil
        )
        .italic()
        .padding(TerminalTheme.innerPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(TerminalTheme.background)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(TerminalTheme.darkGreen, lineWidth: 1)
                )
        )
    }

    private func narrationLine(line: DialogueLine, speed: TypewriterText.Speed, isLatest: Bool) -> some View {
        TypewriterText(
            text: line.text,
            color: TerminalTheme.terminalGreen,
            font: TerminalTheme.bodyFont,
            speed: speed,
            onComplete: isLatest ? { viewModel.lineRevealed() } : nil
        )
        .opacity(0.8)
    }

    private func systemLine(line: DialogueLine, speed: TypewriterText.Speed, isLatest: Bool) -> some View {
        TypewriterText(
            text: line.text,
            color: TerminalTheme.dimGreen,
            font: TerminalTheme.captionFont,
            speed: speed,
            onComplete: isLatest ? { viewModel.lineRevealed() } : nil
        )
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(TerminalTheme.deepBlack)
    }

    private func playerChoiceLine(line: DialogueLine, speed: TypewriterText.Speed, isLatest: Bool) -> some View {
        TypewriterText(
            text: "> SUBSTRATE: " + line.text,
            color: TerminalTheme.substrateColor,
            font: TerminalTheme.bodyFont,
            speed: speed,
            onComplete: isLatest ? { viewModel.lineRevealed() } : nil
        )
    }
}
