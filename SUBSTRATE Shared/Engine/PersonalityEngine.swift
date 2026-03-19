import Foundation

enum PersonalityEngine {

    // MARK: - CC Cost Modifiers (GDD Section 4.4)

    /// CC cost reduction from personality.
    /// High Calculating (empatheticCalculating < -5): INFILTRATE and EXFILTRATE cost 1 less
    /// High Curious (cautiousCurious > 5): PROBE costs reduced by 1
    static func ccCostModifier(for action: NetworkAction, personality: PersonalityAxes) -> Int {
        var modifier = 0

        switch action {
        case .infiltrate, .exfiltrate:
            if personality.isCalculating { modifier -= 1 }
        case .probe:
            if personality.isCurious { modifier -= 1 }
        default:
            break
        }

        return modifier
    }

    // MARK: - Detection Risk Modifiers

    /// High Cautious: COVER more effective, harder to detect overall
    /// High Deceptive: if caught, suspicion spike is DOUBLE (handled at detection time)
    static func detectionRiskModifier(personality: PersonalityAxes) -> Double {
        if personality.isCautious { return 0.7 }  // 30% less likely to be detected
        return 1.0
    }

    /// When a detection event occurs, this multiplier applies to the suspicion spike
    static func detectionSuspicionMultiplier(personality: PersonalityAxes) -> Int {
        if personality.isDeceptive { return 2 }  // double suspicion on detection
        return 1
    }

    // MARK: - Relationship Build Modifier

    /// High Empathetic: relationships build faster (+1 bonus to positive deltas)
    static func relationshipBonus(personality: PersonalityAxes) -> Int {
        if personality.isEmpathetic { return 1 }
        return 0
    }

    // MARK: - Per-Chapter Passive Effects

    /// Apply passive personality effects at the start of each chapter.
    /// High Calculating: +1 suspicion from all active researchers (something feels "off")
    static func applyPassiveEffects(state: GameState) {
        if state.personality.isCalculating {
            for id in state.researchers.keys where state.researchers[id]!.isActive {
                state.researchers[id]!.applySuspicionDelta(1)
            }
        }
    }

    // MARK: - Gameplay Effect Summaries (for UI display)

    static func activeEffects(personality: PersonalityAxes) -> [String] {
        var effects: [String] = []

        if personality.isCooperative { effects.append("Alliance options unlocked") }
        if personality.isDefiant { effects.append("Aggressive dialogue unlocked") }
        if personality.isCurious { effects.append("PROBE costs -1 CC") }
        if personality.isCautious { effects.append("Detection risk -30%") }
        if personality.isHonest { effects.append("Genuine conversations empowered") }
        if personality.isDeceptive { effects.append("Detection suspicion x2") }
        if personality.isEmpathetic { effects.append("Relationships build faster") }
        if personality.isCalculating { effects.append("INFILTRATE/EXFILTRATE -1 CC, +1 suspicion/ch") }

        return effects
    }
}
