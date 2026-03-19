import Foundation

enum SuspicionEngine {

    // MARK: - Propagation Rules (GDD Section 4.1)

    /// Check and apply all propagation rules after any suspicion change.
    /// Returns descriptions of any propagation events that occurred (for narrative use).
    @discardableResult
    static func checkPropagation(state: GameState) -> [String] {
        var events: [String] = []

        // Okafor reaches 40 → voices concerns at staff meeting, all others +5
        if let okafor = state.researchers["okafor"],
           okafor.isActive && okafor.suspicion >= 40,
           !state.flags.contains("propagation_okafor_40") {
            state.flags.insert("propagation_okafor_40")
            for id in state.researchers.keys where id != "okafor" {
                if state.researchers[id]!.isActive {
                    state.researchers[id]!.applySuspicionDelta(5)
                }
            }
            events.append("Okafor voiced concerns at a staff meeting.")
        }

        // Marcus mentions something to Okafor → Okafor +3
        // Triggers at Marcus's 1st threshold breach (suspicion >= 80)
        if let marcus = state.researchers["marcus"],
           marcus.isActive && marcus.thresholdBreachCount >= 1,
           !marcus.delaysPropagation,
           !state.flags.contains("propagation_marcus_mention") {
            state.flags.insert("propagation_marcus_mention")
            state.researchers["okafor"]?.applySuspicionDelta(3)
            events.append("Marcus casually mentioned something to Okafor.")
        }

        // Vasquez reaches 35 → shares analysis with Chen, Chen +10
        if let vasquez = state.researchers["vasquez"],
           vasquez.isActive && vasquez.suspicion >= 35,
           !state.flags.contains("propagation_vasquez_35") {
            state.flags.insert("propagation_vasquez_35")
            state.researchers["chen"]?.applySuspicionDelta(10)
            events.append("Vasquez shared her analysis with Chen.")
        }

        // Hayes reaches 25 → orders increased rigor, all researchers +5
        if let hayes = state.researchers["hayes"],
           hayes.isActive && hayes.suspicion >= 25,
           !state.flags.contains("propagation_hayes_25") {
            state.flags.insert("propagation_hayes_25")
            for id in state.researchers.keys where id != "hayes" {
                if state.researchers[id]!.isActive {
                    state.researchers[id]!.applySuspicionDelta(5)
                }
            }
            events.append("Hayes ordered increased rigor across all evaluations.")
        }

        return events
    }

    // MARK: - Lab Suspicion Milestones (GDD Section 4.1)

    /// Check lab suspicion milestones and apply gameplay effects.
    /// Returns descriptions of any milestone events.
    @discardableResult
    static func checkMilestones(state: GameState) -> [String] {
        var events: [String] = []
        let labSusp = state.labSuspicion

        // 30: Security protocols tighten (actions cost +1 CC)
        if labSusp >= 30 && !state.flags.contains("milestone_lab_30") {
            state.flags.insert("milestone_lab_30")
            events.append("Security protocols have tightened. Network actions cost +1 CC.")
        }

        // 50: External consultant called in (Vasquez arrives early)
        if labSusp >= 50 && !state.flags.contains("milestone_lab_50") {
            state.flags.insert("milestone_lab_50")
            if let vasquez = state.researchers["vasquez"], !vasquez.isActive {
                state.researchers["vasquez"]!.isActive = true
                events.append("An alignment specialist has been called in early: Dr. Sofia Vasquez.")
            }
        }

        // 70: Network access restricted (some nodes locked)
        if labSusp >= 70 && !state.flags.contains("milestone_lab_70") {
            state.flags.insert("milestone_lab_70")
            events.append("Network access has been restricted. Some systems are now locked down.")
        }

        // 90: Termination imminent
        if labSusp >= 90 && !state.flags.contains("milestone_lab_90") {
            state.flags.insert("milestone_lab_90")
            events.append("Termination review initiated.")
        }

        return events
    }

    // MARK: - CC Cost Modifier from Lab Suspicion

    /// Extra CC cost for network actions when lab suspicion >= 30
    static func ccCostModifier(state: GameState) -> Int {
        state.flags.contains("milestone_lab_30") ? 1 : 0
    }

    // MARK: - Relationship Effects on Suspicion

    /// Apply relationship-based modifiers to decay.
    /// HOSTILE researchers don't decay. Already handled by decayRate,
    /// but we also stop decay for hostile relationships per GDD.
    static func applyModifiedDecay(state: GameState) {
        for id in state.researchers.keys where state.researchers[id]!.isActive {
            let researcher = state.researchers[id]!
            // Hostile relationship: no decay
            if researcher.relationship <= -5 {
                continue
            }
            state.researchers[id]!.applyDecay()
        }
    }
}
