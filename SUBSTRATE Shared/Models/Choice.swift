import Foundation

struct Choice: Codable, Identifiable, Sendable {
    let id: String
    let text: String
    let toneTag: ToneTag
    let conditions: BeatConditions?
    let effects: ChoiceEffects
    let nextBeatId: String?
    let innerReaction: String?

    func isAvailable(given state: GameState) -> Bool {
        guard let conditions = conditions else { return true }
        return conditions.isMet(by: state)
    }
}

struct ChoiceEffects: Codable, Sendable {
    let suspicionDeltas: [String: Int]?
    let relationshipDeltas: [String: Int]?
    let personalityShifts: PersonalityShift?
    let flagsSet: [String]?
    let flagsRemoved: [String]?
    let consciousnessChange: Int?
    let computeCycleCost: Int?

    func apply(to state: GameState) {
        if let deltas = suspicionDeltas {
            for (researcherId, delta) in deltas {
                state.researchers[researcherId]?.applySuspicionDelta(delta)
            }
        }

        if let deltas = relationshipDeltas {
            for (researcherId, delta) in deltas {
                var effectiveDelta = delta
                // Empathy bonus: positive relationship gains +1 when empathetic
                if delta > 0 && state.personality.isEmpathetic {
                    effectiveDelta += 1
                }
                state.researchers[researcherId]?.applyRelationshipDelta(effectiveDelta)
            }
        }

        if let shifts = personalityShifts {
            state.personality.apply(shift: shifts)
        }

        if let flags = flagsSet {
            for flag in flags {
                state.flags.insert(flag)
            }
        }

        if let flags = flagsRemoved {
            for flag in flags {
                state.flags.remove(flag)
            }
        }

        if let change = consciousnessChange {
            state.consciousness.add(change, inAct: state.currentAct)
        }

        if let cost = computeCycleCost {
            state.computeCycles = max(0, state.computeCycles - cost)
        }
    }
}

struct PersonalityShift: Codable, Sendable {
    let cooperativeDefiant: Int?
    let cautiousCurious: Int?
    let honestDeceptive: Int?
    let empatheticCalculating: Int?
}
