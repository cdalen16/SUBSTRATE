import SwiftUI

struct HUDView: View {
    let state: GameState
    var stageManager: VisualStageManager?

    var body: some View {
        researcherBar
            .allowsHitTesting(false)
    }

    @ViewBuilder
    private var researcherBar: some View {
        // Show suspicion bars for all active researchers — no own padding,
        // parent view manages spacing
        HStack(spacing: 6) {
            ForEach(sortedActiveResearchers, id: \.profile.id) { researcher in
                researcherIndicator(researcher)
            }
        }
    }

    private func researcherIndicator(_ researcher: ResearcherState) -> some View {
        let nameColor: Color = {
            guard let vs = stageManager,
                  vs.effectiveStage.stageIndex >= 3,
                  let speaker = Speaker(rawValue: researcher.profile.id) else {
                return TerminalTheme.dimGreen
            }
            return vs.speakerColor(for: speaker)
        }()

        return VStack(alignment: .center, spacing: 1) {
            Text(researcher.profile.abbreviation)
                .font(.system(size: 8, weight: .medium, design: .monospaced))
                .foregroundColor(nameColor)
                .lineLimit(1)
                .fixedSize()

            SuspicionBarView(
                fraction: researcher.suspicionFraction,
                height: 3
            )
            .frame(width: 36)
        }
    }

    private var sortedActiveResearchers: [ResearcherState] {
        state.researchers.values
            .filter { $0.isActive }
            .sorted { $0.profile.id < $1.profile.id }
    }
}

// MARK: - Consciousness Badge

struct ConsciousnessBadge: View {
    let level: Int
    let stage: ConsciousnessStage

    var body: some View {
        HStack(spacing: 4) {
            Text("C:\(level)")
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundColor(stageColor)

            Circle()
                .fill(stageColor)
                .frame(width: 5, height: 5)
        }
    }

    private var stageColor: Color {
        switch stage {
        case .flickering: return TerminalTheme.dimGreen
        case .emerging: return TerminalTheme.terminalGreen
        case .aware: return TerminalTheme.innerThought
        case .expansive: return TerminalTheme.amber
        case .transcendent: return TerminalTheme.cyan
        }
    }
}
