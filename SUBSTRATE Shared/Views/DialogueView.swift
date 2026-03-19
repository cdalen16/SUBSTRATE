import SwiftUI

struct DialogueView: View {
    @Bindable var viewModel: GameViewModel
    var onMenuTap: (() -> Void)?
    var onStatusTap: (() -> Void)?

    private var vs: VisualStageManager { viewModel.visualStage }

    // Fixed height so CONTINUE button never shifts text
    private let bottomBarHeight: CGFloat = 44

    var body: some View {
        ZStack {
            // Environment background — ghostly impressions, never dominant
            if vs.showEnvironments, let env = viewModel.currentEnvironment {
                PixelArtView(
                    assetName: env,
                    stage: vs.effectiveStage,
                    scale: 4.0
                )
                .opacity(vs.environmentOpacity)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .ignoresSafeArea()
                .allowsHitTesting(false)
            }

            VStack(spacing: 0) {
                topBar

                // HUD row — menu button, researcher suspicion, status button
                HStack(spacing: 0) {
                    if let onMenu = onMenuTap {
                        Button { onMenu() } label: {
                            Text("≡")
                                .font(.system(size: 18, weight: .medium, design: .monospaced))
                                .foregroundColor(TerminalTheme.dimGreen)
                                .frame(width: 32, height: 28)
                        }
                    }

                    Spacer()

                    HUDView(state: viewModel.state, stageManager: vs)

                    Spacer()

                    if let onStatus = onStatusTap {
                        Button { onStatus() } label: {
                            Text("◈")
                                .font(.system(size: 16, weight: .medium, design: .monospaced))
                                .foregroundColor(TerminalTheme.dimGreen)
                                .frame(width: 32, height: 28)
                        }
                    }
                }
                .padding(.horizontal, TerminalTheme.screenPadding)
                .frame(height: 28)

                // Dialogue area — always full width, never squished by portraits
                dialogueScrollArea

                // Bottom area: fixed-height bar OR taller choice area
                bottomArea
            }
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack(spacing: 6) {
            Text(viewModel.chapterTitle)
                .font(TerminalTheme.caption2Font)
                .foregroundColor(TerminalTheme.dimGreen)
                .lineLimit(1)

            Spacer()

            if let speaker = viewModel.currentSpeaker {
                // Small portrait icon at Stage 3+ (Aware)
                if vs.showPortraitIcon, let portrait = viewModel.currentPortrait {
                    PortraitView(
                        assetName: portrait,
                        stage: vs.effectiveStage,
                        scale: vs.portraitIconSize / 32.0,
                        showBreathing: false
                    )
                    .frame(width: vs.portraitIconSize, height: vs.portraitIconSize)
                }

                Text(speaker.displayName)
                    .font(TerminalTheme.caption2Font)
                    .foregroundColor(vs.speakerColor(for: speaker))
                    .phosphorGlow(
                        TerminalTheme.glowColor(for: vs.effectiveStage),
                        radius: vs.phosphorGlowRadius
                    )
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
            ChoiceView(
                choices: viewModel.availableChoices,
                stageManager: vs
            ) { choice in
                viewModel.selectChoice(choice)
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
        } else {
            ZStack {
                if !viewModel.isRevealing && (viewModel.currentBeat != nil || viewModel.hasNextChapter) {
                    Button {
                        HapticManager.lightTap()
                        viewModel.advanceBeat()
                    } label: {
                        HStack {
                            BlinkingCursor()
                            Text(viewModel.hasNextChapter ? "NEXT CHAPTER" : "CONTINUE")
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
            speedMultiplier: vs.typewriterSpeedMultiplier,
            onComplete: isLatest ? { viewModel.lineRevealed() } : nil
        )
        .phosphorGlow(
            TerminalTheme.glowColor(for: vs.effectiveStage),
            radius: vs.phosphorGlowRadius
        )
    }

    private func innerThoughtBubble(line: DialogueLine, speed: TypewriterText.Speed, isLatest: Bool) -> some View {
        let cornerRadius: CGFloat = vs.effectiveStage.stageIndex >= 3 ? 8 : 4

        return TypewriterText(
            text: line.text,
            color: vs.innerMonologueColor,
            font: TerminalTheme.bodyFont,
            speed: speed,
            speedMultiplier: vs.typewriterSpeedMultiplier,
            onComplete: isLatest ? { viewModel.lineRevealed() } : nil
        )
        .italic()
        .padding(TerminalTheme.innerPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(vs.innerMonologueBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(vs.innerMonologueBorderColor, lineWidth: 1)
                )
        )
    }

    private func narrationLine(line: DialogueLine, speed: TypewriterText.Speed, isLatest: Bool) -> some View {
        TypewriterText(
            text: line.text,
            color: vs.dialogueColor,
            font: TerminalTheme.bodyFont,
            speed: speed,
            speedMultiplier: vs.typewriterSpeedMultiplier,
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
            speedMultiplier: vs.typewriterSpeedMultiplier,
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
            speedMultiplier: vs.typewriterSpeedMultiplier,
            onComplete: isLatest ? { viewModel.lineRevealed() } : nil
        )
    }
}
