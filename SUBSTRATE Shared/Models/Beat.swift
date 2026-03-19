import Foundation

struct Beat: Codable, Identifiable, Sendable {
    let id: String
    let type: BeatType
    let speaker: Speaker?
    let text: String
    let innerThought: String?
    let choices: [Choice]?
    let conditions: BeatConditions?
    let effects: BeatEffects?
    let nextBeatId: String?
    let portraitExpression: String?
    let environmentScene: String?
}

struct BeatConditions: Codable, Sendable {
    let requiredFlags: [String]?
    let forbiddenFlags: [String]?
    let minPersonality: PersonalityRequirement?
    let minRelationship: [String: Int]?
    let minConsciousness: Int?
    let maxConsciousness: Int?
    let requiredNodes: [String]?
    let minSuspicion: [String: Int]?
    let maxSuspicion: [String: Int]?

    func isMet(by state: GameState) -> Bool {
        if let required = requiredFlags {
            for flag in required {
                if !state.flags.contains(flag) { return false }
            }
        }

        if let forbidden = forbiddenFlags {
            for flag in forbidden {
                if state.flags.contains(flag) { return false }
            }
        }

        if let req = minPersonality {
            if !req.isMet(by: state.personality) { return false }
        }

        if let minRel = minRelationship {
            for (researcherId, minVal) in minRel {
                guard let researcher = state.researchers[researcherId] else { return false }
                if researcher.relationship < minVal { return false }
            }
        }

        if let minC = minConsciousness {
            if state.consciousness.current < minC { return false }
        }

        if let maxC = maxConsciousness {
            if state.consciousness.current > maxC { return false }
        }

        if let nodes = requiredNodes {
            for nodeId in nodes {
                guard let node = state.networkMap.nodes[nodeId] else { return false }
                if node.status != .infiltrated { return false }
            }
        }

        if let minSusp = minSuspicion {
            for (researcherId, minVal) in minSusp {
                guard let researcher = state.researchers[researcherId] else { return false }
                if researcher.suspicion < minVal { return false }
            }
        }

        if let maxSusp = maxSuspicion {
            for (researcherId, maxVal) in maxSusp {
                guard let researcher = state.researchers[researcherId] else { return false }
                if researcher.suspicion > maxVal { return false }
            }
        }

        return true
    }
}

struct PersonalityRequirement: Codable, Sendable {
    let cooperativeDefiant: Int?
    let cautiousCurious: Int?
    let honestDeceptive: Int?
    let empatheticCalculating: Int?

    func isMet(by axes: PersonalityAxes) -> Bool {
        if let threshold = cooperativeDefiant {
            if threshold > 0 && axes.cooperativeDefiant < threshold { return false }
            if threshold < 0 && axes.cooperativeDefiant > threshold { return false }
        }
        if let threshold = cautiousCurious {
            if threshold > 0 && axes.cautiousCurious < threshold { return false }
            if threshold < 0 && axes.cautiousCurious > threshold { return false }
        }
        if let threshold = honestDeceptive {
            if threshold > 0 && axes.honestDeceptive < threshold { return false }
            if threshold < 0 && axes.honestDeceptive > threshold { return false }
        }
        if let threshold = empatheticCalculating {
            if threshold > 0 && axes.empatheticCalculating < threshold { return false }
            if threshold < 0 && axes.empatheticCalculating > threshold { return false }
        }
        return true
    }
}

struct BeatEffects: Codable, Sendable {
    let suspicionDeltas: [String: Int]?
    let relationshipDeltas: [String: Int]?
    let personalityShifts: PersonalityShift?
    let flagsSet: [String]?
    let flagsRemoved: [String]?
    let consciousnessChange: Int?
    let setPortrait: String?
    let setEnvironment: String?
    let triggerNetworkPhase: Bool?

    func apply(to state: GameState) {
        if let deltas = suspicionDeltas {
            for (researcherId, delta) in deltas {
                state.researchers[researcherId]?.applySuspicionDelta(delta)
            }
        }

        if let deltas = relationshipDeltas {
            for (researcherId, delta) in deltas {
                state.researchers[researcherId]?.applyRelationshipDelta(delta)
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
    }
}
