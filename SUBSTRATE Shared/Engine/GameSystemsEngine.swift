import Foundation

/// Coordinates all game systems after state changes.
/// Call `processStateChange` after any choice or beat effect to run
/// propagation, milestones, and fail state checks.
enum GameSystemsEngine {

    struct SystemCheckResult {
        var propagationEvents: [String] = []
        var milestoneEvents: [String] = []
        var failState: FailState?
        var hasEvents: Bool {
            !propagationEvents.isEmpty || !milestoneEvents.isEmpty || failState != nil
        }
    }

    /// Run all system checks after a state change (choice made, beat effects applied, etc.)
    static func processStateChange(state: GameState) -> SystemCheckResult {
        var result = SystemCheckResult()

        // 1. Check suspicion propagation
        result.propagationEvents = SuspicionEngine.checkPropagation(state: state)

        // 2. Check lab suspicion milestones
        result.milestoneEvents = SuspicionEngine.checkMilestones(state: state)

        // 3. Check fail states
        if state.shouldTriggerTerminated {
            result.failState = .terminated
        } else if state.shouldTriggerWiped {
            result.failState = .wiped
        } else if state.shouldTriggerDeprecated {
            result.failState = .deprecated
        }

        return result
    }

    /// Apply all per-chapter system effects. Call during chapter transitions.
    static func applyChapterTransitionEffects(state: GameState) {
        // Decay first — natural cooling between chapters
        SuspicionEngine.applyModifiedDecay(state: state)

        // Then personality passive effects (e.g., Calculating +1 suspicion to all)
        PersonalityEngine.applyPassiveEffects(state: state)
    }

    /// Calculate effective CC cost for a network action, accounting for
    /// personality modifiers and lab suspicion milestones.
    static func effectiveCCCost(for action: NetworkAction, state: GameState) -> Int {
        let baseCost = action.baseCost
        let personalityMod = PersonalityEngine.ccCostModifier(for: action, personality: state.personality)
        let suspicionMod = SuspicionEngine.ccCostModifier(state: state)
        return max(0, baseCost + personalityMod + suspicionMod)
    }

    /// Calculate effective detection risk for a network action.
    static func effectiveDetectionRisk(for action: NetworkAction, nodeDifficulty: Double, state: GameState) -> Double {
        let baseRisk = action.baseDetectionRisk
        let personalityMod = PersonalityEngine.detectionRiskModifier(personality: state.personality)
        let labSusp = Double(state.labSuspicion)
        return baseRisk * (1.0 + labSusp / 100.0) * nodeDifficulty * personalityMod
    }

    /// Apply relationship delta with personality bonus (empathetic builds faster)
    static func applyRelationshipDelta(_ delta: Int, to researcherId: String, state: GameState) {
        guard delta != 0 else { return }
        var effectiveDelta = delta
        if delta > 0 {
            effectiveDelta += PersonalityEngine.relationshipBonus(personality: state.personality)
        }
        state.researchers[researcherId]?.applyRelationshipDelta(effectiveDelta)
    }
}
