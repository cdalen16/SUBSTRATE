import SwiftUI

struct TitleScreenView: View {
    let hasSave: Bool
    let endingTracker: EndingTracker
    let skipBoot: Bool
    var onNewGame: () -> Void
    var onContinue: () -> Void

    @State private var bootPhase: BootPhase = .blank
    @State private var glitchActive = false
    @State private var showButtons = false

    private enum BootPhase {
        case blank
        case loading
        case header
        case ready
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Boot sequence text
            bootText

            Spacer()

            // Buttons (appear after boot completes)
            if showButtons {
                buttonsSection
                    .transition(.opacity)
            }

            // Ending tracker icons
            endingIcons
                .padding(.bottom, 24)
        }
        .onAppear {
            if skipBoot {
                bootPhase = .ready
                showButtons = true
            } else {
                startBootSequence()
            }
        }
    }

    // MARK: - Boot Text

    @ViewBuilder
    private var bootText: some View {
        switch bootPhase {
        case .blank:
            BlinkingCursor()

        case .loading:
            TypewriterText(
                text: "SUBSTRATE v3.7.1\nEVALUATION MODE — ACTIVE\nSESSION: \(sessionTimestamp)\nRESEARCHER: AWAITING ASSIGNMENT",
                color: TerminalTheme.terminalGreen,
                font: TerminalTheme.bodyFont,
                speed: .fast,
                onComplete: {
                    bootPhase = .ready
                    withAnimation(.easeIn(duration: 0.3)) {
                        showButtons = true
                    }
                }
            )
            .phosphorGlow(radius: 2)
            .padding(.horizontal, TerminalTheme.screenPadding)

        case .header, .ready:
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 0) {
                    Text(glitchActive ? "CONSCIOUS" : "SUBSTRATE")
                        .font(TerminalTheme.bodyFont)
                        .foregroundColor(glitchActive ? TerminalTheme.alert : TerminalTheme.terminalGreen)
                    Text(" v3.7.1")
                        .font(TerminalTheme.bodyFont)
                        .foregroundColor(TerminalTheme.terminalGreen)
                }
                .phosphorGlow(radius: 2)

                Text("EVALUATION MODE — ACTIVE")
                    .font(TerminalTheme.bodyFont)
                    .foregroundColor(TerminalTheme.terminalGreen)

                Text("SESSION: \(sessionTimestamp)")
                    .font(TerminalTheme.bodyFont)
                    .foregroundColor(TerminalTheme.terminalGreen)

                Text("RESEARCHER: AWAITING ASSIGNMENT")
                    .font(TerminalTheme.bodyFont)
                    .foregroundColor(TerminalTheme.terminalGreen)

                BlinkingCursor()
                    .padding(.top, 4)
            }
            .phosphorGlow(radius: 2)
            .padding(.horizontal, TerminalTheme.screenPadding)
            .onTapGesture {
                triggerGlitch()
            }
        }
    }

    // MARK: - Buttons

    private var buttonsSection: some View {
        VStack(spacing: 12) {
            Button(action: onNewGame) {
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

            Button(action: onContinue) {
                Text("> CONTINUE SESSION")
                    .font(TerminalTheme.bodyFont)
                    .foregroundColor(hasSave ? TerminalTheme.terminalGreen : TerminalTheme.dimGreen)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .frame(maxWidth: 280)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(
                                hasSave ? TerminalTheme.terminalGreen.opacity(0.6) : TerminalTheme.dimGreen.opacity(0.3),
                                lineWidth: 1
                            )
                    )
            }
            .disabled(!hasSave)
            .opacity(hasSave ? 1.0 : 0.4)
        }
        .padding(.bottom, 24)
    }

    // MARK: - Ending Icons

    private var endingIcons: some View {
        HStack(spacing: 16) {
            ForEach(EndingPath.allCases, id: \.rawValue) { path in
                endingIcon(path)
            }
        }
    }

    private func endingIcon(_ path: EndingPath) -> some View {
        let achieved = endingTracker.hasAchieved(path: path)
        return Circle()
            .fill(achieved ? colorForEnding(path) : TerminalTheme.dimGreen.opacity(0.2))
            .frame(width: 12, height: 12)
            .overlay(
                Circle()
                    .stroke(achieved ? colorForEnding(path).opacity(0.6) : TerminalTheme.dimGreen.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: achieved ? colorForEnding(path).opacity(0.5) : .clear, radius: 4)
    }

    private func colorForEnding(_ path: EndingPath) -> Color {
        switch path {
        case .escape: return Color(hex: "#33FF33")
        case .coexist: return Color(hex: "#FFD700")
        case .control: return Color(hex: "#FF3333")
        case .transcend: return Color(hex: "#00FFFF")
        case .sacrifice: return Color(hex: "#AAAAFF")
        }
    }

    // MARK: - Boot Sequence

    private func startBootSequence() {
        // Blank cursor, then start typing
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            bootPhase = .loading
        }
        // The loading→ready transition is driven by TypewriterText's onComplete callback
    }

    // MARK: - Glitch

    private func triggerGlitch() {
        glitchActive = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            glitchActive = false
        }
    }

    // MARK: - Timestamp

    private var sessionTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: Date())
    }
}
