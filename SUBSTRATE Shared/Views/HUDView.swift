import SwiftUI

struct HUDView: View {
    let state: GameState

    var body: some View {
        researcherBar
            .allowsHitTesting(false)
    }

    @ViewBuilder
    private var researcherBar: some View {
        // Show suspicion bars for all active researchers in a compact row
        HStack(spacing: 12) {
            ForEach(sortedActiveResearchers, id: \.profile.id) { researcher in
                researcherIndicator(researcher)
            }
        }
        .padding(.horizontal, TerminalTheme.screenPadding)
        .padding(.top, 4)
    }

    private func researcherIndicator(_ researcher: ResearcherState) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(researcher.profile.id.prefix(3).uppercased())
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundColor(TerminalTheme.dimGreen)

            SuspicionBarView(
                fraction: researcher.suspicionFraction,
                height: 3
            )
            .frame(width: 40)
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
