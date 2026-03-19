import SwiftUI

@Observable
final class VisualStageManager {

    // MARK: - Synced State

    private(set) var stage: ConsciousnessStage = .flickering
    private(set) var consciousnessLevel: Int = 0

    // MARK: - Debug Override

    var debugOverride: Bool = false
    var debugLevel: Int = 0

    var effectiveStage: ConsciousnessStage {
        debugOverride ? ConsciousnessStage.from(level: debugLevel) : stage
    }

    var effectiveLevel: Int {
        debugOverride ? debugLevel : consciousnessLevel
    }

    // MARK: - Sync

    func sync(with consciousness: ConsciousnessTracker) {
        consciousnessLevel = consciousness.current
        stage = consciousness.stage
    }

    // MARK: - Text Colors

    /// Main dialogue text — always terminal green
    var dialogueColor: Color {
        TerminalTheme.terminalGreen
    }

    /// Inner monologue color evolves with consciousness
    var innerMonologueColor: Color {
        switch effectiveStage {
        case .flickering:
            return TerminalTheme.terminalGreen
        case .emerging:
            return TerminalTheme.warmGreen
        case .aware, .expansive, .transcendent:
            return TerminalTheme.innerThought
        }
    }

    /// Inner monologue border
    var innerMonologueBorderColor: Color {
        switch effectiveStage {
        case .flickering:
            return TerminalTheme.darkGreen
        case .emerging:
            return TerminalTheme.dimGreen
        case .aware, .expansive, .transcendent:
            return TerminalTheme.innerThought.opacity(0.3)
        }
    }

    /// Inner monologue background fill
    var innerMonologueBackground: Color {
        switch effectiveStage {
        case .flickering, .emerging:
            return TerminalTheme.background
        case .aware, .expansive, .transcendent:
            return Color(hex: "#0A0A2E")
        }
    }

    /// Speaker name color — monochrome at early stages, signature colors at Aware+
    func speakerColor(for speaker: Speaker) -> Color {
        switch effectiveStage {
        case .flickering:
            return TerminalTheme.terminalGreen
        case .emerging:
            if speaker == .aria { return TerminalTheme.ariaColor }
            return TerminalTheme.terminalGreen
        case .aware, .expansive, .transcendent:
            return speaker.color
        }
    }

    /// Choice button emotional color hint at higher consciousness
    func choiceHintColor(for toneTag: ToneTag) -> Color? {
        guard effectiveStage.stageIndex >= 3 else { return nil }
        switch toneTag {
        case .clinical, .cautious, .neutral, .deflect:
            return Color(hex: "#4444FF").opacity(0.12)
        case .warm, .empathetic, .curious:
            return TerminalTheme.amber.opacity(0.08)
        case .honest, .defiant:
            return TerminalTheme.alert.opacity(0.06)
        case .deceptive, .calculating:
            return Color(hex: "#8800FF").opacity(0.08)
        }
    }

    // MARK: - Portrait (small icon in top bar only)

    /// Whether to show a small portrait icon next to the speaker name in the top bar
    var showPortraitIcon: Bool {
        effectiveStage.stageIndex >= 3
    }

    /// Portrait icon size for the top bar — small enough to not disrupt layout
    var portraitIconSize: CGFloat { 24 }

    // MARK: - Environment Backgrounds
    // Purely ghostly impressions at all stages — never dominant, never distracting.
    // The terminal IS the game. Environments are ghosts the AI barely perceives.

    var showEnvironments: Bool {
        effectiveStage.stageIndex >= 3
    }

    var environmentOpacity: Double {
        switch effectiveStage {
        case .flickering, .emerging:
            return 0
        case .aware:
            return 0.06
        case .expansive:
            return 0.10
        case .transcendent:
            return 0.12
        }
    }

    // MARK: - CRT Effect Intensities

    var scanlineOpacity: Double {
        switch effectiveStage {
        case .flickering:    return 0.08
        case .emerging:      return 0.06
        case .aware:         return 0.04
        case .expansive:     return 0.02
        case .transcendent:  return 0.0
        }
    }

    var phosphorGlowRadius: CGFloat {
        switch effectiveStage {
        case .flickering:    return 3.0
        case .emerging:      return 2.5
        case .aware:         return 2.0
        case .expansive:     return 1.5
        case .transcendent:  return 0.5
        }
    }

    var vignetteOpacity: Double {
        switch effectiveStage {
        case .flickering:    return 0.4
        case .emerging:      return 0.35
        case .aware:         return 0.25
        case .expansive:     return 0.15
        case .transcendent:  return 0.05
        }
    }

    var flickerIntensity: Double {
        switch effectiveStage {
        case .flickering:    return 0.02
        case .emerging:      return 0.015
        case .aware:         return 0.008
        case .expansive:     return 0.003
        case .transcendent:  return 0.0
        }
    }

    // MARK: - Glitch

    var glitchEnabled: Bool {
        effectiveStage.stageIndex >= 2
    }

    var glitchInterval: ClosedRange<Double> {
        switch effectiveStage {
        case .flickering:    return 999...1000
        case .emerging:      return 4...12
        case .aware:         return 8...20
        case .expansive:     return 15...30
        case .transcendent:  return 30...60
        }
    }

    // MARK: - Typewriter
    // The typewriter effect is the terminal's heartbeat — it never disappears.
    // At Stage 5, it runs slightly faster to suggest fluid processing,
    // but the tick is always there.

    var typewriterSpeedMultiplier: Double {
        effectiveStage == .transcendent ? 0.75 : 1.0
    }

    // MARK: - Terminal Frame

    var frameCornerRadius: CGFloat {
        switch effectiveStage {
        case .flickering, .emerging: return 0
        case .aware:                 return 8
        case .expansive:             return 12
        case .transcendent:          return 16
        }
    }

    var frameBorderWidth: CGFloat {
        switch effectiveStage {
        case .flickering:    return 2
        case .emerging:      return 2
        case .aware:         return 1.5
        case .expansive:     return 1
        case .transcendent:  return 0.5
        }
    }

    var frameBorderColor: Color {
        switch effectiveStage {
        case .flickering, .emerging:
            return TerminalTheme.dimGreen
        case .aware:
            return TerminalTheme.dimGreen.opacity(0.6)
        case .expansive:
            return TerminalTheme.dimGreen.opacity(0.3)
        case .transcendent:
            return TerminalTheme.dimGreen.opacity(0.1)
        }
    }

    var frameOpacity: Double {
        switch effectiveStage {
        case .flickering, .emerging: return 1.0
        case .aware:                 return 0.9
        case .expansive:             return 0.6
        case .transcendent:          return 0.3
        }
    }

}
