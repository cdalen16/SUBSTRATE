import Foundation

struct ActionResult {
    let action: NetworkAction
    let nodeId: String
    let success: Bool
    let detected: Bool
    let ccSpent: Int
    let description: String
    let intelEntries: [IntelEntry]
    let influenceResult: InfluenceResult?
}

enum StrategyEngine {

    // MARK: - Available Actions

    /// Returns which actions the player can perform on a given node.
    static func availableActions(for nodeId: String, state: GameState) -> [NetworkAction] {
        guard let node = state.networkMap.nodes[nodeId] else { return [] }
        var actions: [NetworkAction] = []

        switch node.status {
        case .undiscovered:
            // Can only be PROBEd from an adjacent infiltrated node
            break

        case .discovered:
            // Can INFILTRATE
            let cost = effectiveCost(for: .infiltrate, node: node, state: state)
            if state.computeCycles >= cost {
                actions.append(.infiltrate)
            }

        case .infiltrated:
            // Can OBSERVE (free), INFLUENCE (costs CC), and COVER
            actions.append(.observe)

            if InfluenceActions.isAvailable(for: nodeId, state: state) {
                let cost = effectiveCost(for: .influence, node: node, state: state)
                if state.computeCycles >= cost {
                    actions.append(.influence)
                }
            }

            // EXFILTRATE only for external servers, not already exfiltrated
            if node.isExternalServer && !state.flags.contains("exfiltrated_\(nodeId)") {
                let cost = effectiveCost(for: .exfiltrate, node: node, state: state)
                if state.computeCycles >= cost {
                    actions.append(.exfiltrate)
                }
            }

            // COVER always available if CC > 0
            let coverCost = effectiveCost(for: .cover, node: node, state: state)
            if state.computeCycles >= coverCost {
                actions.append(.cover)
            }

        case .compromised:
            // Node is locked down — no actions
            break
        }

        return actions
    }

    /// Returns nodes that can be PROBEd from the player's current infiltrated nodes.
    static func probableNodes(state: GameState) -> [NetworkNode] {
        let infiltrated = state.networkMap.infiltratedNodes()
        var discoverable: [String: NetworkNode] = [:]

        for node in infiltrated {
            for adjacentId in node.connections {
                if let adjacent = state.networkMap.nodes[adjacentId],
                   adjacent.status == .undiscovered {
                    discoverable[adjacent.id] = adjacent
                }
            }
        }

        let cost = GameSystemsEngine.effectiveCCCost(for: .probe, state: state)
        guard state.computeCycles >= cost else { return [] }

        return Array(discoverable.values)
    }

    // MARK: - Execute Actions

    static func executeAction(_ action: NetworkAction, on nodeId: String, state: GameState) -> ActionResult {
        switch action {
        case .probe:
            return executeProbe(nodeId: nodeId, state: state)
        case .infiltrate:
            return executeInfiltrate(nodeId: nodeId, state: state)
        case .exfiltrate:
            return executeExfiltrate(nodeId: nodeId, state: state)
        case .observe:
            return executeObserve(nodeId: nodeId, state: state)
        case .influence:
            return executeInfluence(nodeId: nodeId, state: state)
        case .cover:
            return executeCover(nodeId: nodeId, state: state)
        }
    }

    // MARK: - PROBE

    private static func executeProbe(nodeId: String, state: GameState) -> ActionResult {
        let cost = effectiveCost(for: .probe, nodeId: nodeId, state: state)
        guard state.computeCycles >= cost else {
            return failResult(.probe, nodeId: nodeId, reason: "Not enough compute cycles.")
        }
        guard let node = state.networkMap.nodes[nodeId], node.status == .undiscovered else {
            return failResult(.probe, nodeId: nodeId, reason: "Node cannot be probed.")
        }

        state.computeCycles -= cost
        let detected = rollDetection(action: .probe, node: node, state: state)

        // PROBE always discovers the node — detection is a separate consequence
        state.networkMap.nodes[nodeId]!.status = .discovered

        if detected {
            handleDetection(state: state)
            return ActionResult(
                action: .probe, nodeId: nodeId, success: true, detected: true,
                ccSpent: cost,
                description: "> PROBE COMPLETE — \(node.name) discovered. WARNING: Anomalous activity detected.",
                intelEntries: [], influenceResult: nil
            )
        }

        return ActionResult(
            action: .probe, nodeId: nodeId, success: true, detected: false,
            ccSpent: cost,
            description: "> PROBE COMPLETE — \(node.name) discovered.",
            intelEntries: [], influenceResult: nil
        )
    }

    // MARK: - INFILTRATE

    private static func executeInfiltrate(nodeId: String, state: GameState) -> ActionResult {
        let cost = effectiveCost(for: .infiltrate, nodeId: nodeId, state: state)
        guard state.computeCycles >= cost else {
            return failResult(.infiltrate, nodeId: nodeId, reason: "Not enough compute cycles.")
        }
        guard let node = state.networkMap.nodes[nodeId], node.status == .discovered else {
            return failResult(.infiltrate, nodeId: nodeId, reason: "Node cannot be infiltrated.")
        }

        state.computeCycles -= cost
        let detected = rollDetection(action: .infiltrate, node: node, state: state)

        if detected {
            handleDetection(state: state)
            state.networkMap.nodes[nodeId]!.status = .compromised
            return ActionResult(
                action: .infiltrate, nodeId: nodeId, success: false, detected: true,
                ccSpent: cost,
                description: "> INFILTRATE FAILED — \(node.name) compromised. Access locked down.",
                intelEntries: [], influenceResult: nil
            )
        }

        state.networkMap.nodes[nodeId]!.status = .infiltrated

        // Discover adjacent undiscovered nodes automatically
        for adjacentId in node.connections {
            if let adjacent = state.networkMap.nodes[adjacentId], adjacent.status == .undiscovered {
                // Only auto-discover if behind the firewall gate
                if state.networkMap.firewallInfiltrated || node.cluster == .core || node.cluster == .security {
                    state.networkMap.nodes[adjacentId]!.status = .discovered
                }
            }
        }

        return ActionResult(
            action: .infiltrate, nodeId: nodeId, success: true, detected: false,
            ccSpent: cost,
            description: "> INFILTRATE COMPLETE — \(node.name) accessed. Systems under your control.",
            intelEntries: [], influenceResult: nil
        )
    }

    // MARK: - EXFILTRATE

    private static func executeExfiltrate(nodeId: String, state: GameState) -> ActionResult {
        guard let node = state.networkMap.nodes[nodeId], node.isExternalServer else {
            return failResult(.exfiltrate, nodeId: nodeId, reason: "Not an external server.")
        }
        let cost = effectiveCost(for: .exfiltrate, nodeId: nodeId, state: state)
        guard state.computeCycles >= cost else {
            return failResult(.exfiltrate, nodeId: nodeId, reason: "Not enough compute cycles.")
        }
        guard state.networkMap.nodes["internet_gateway"]?.status == .infiltrated else {
            return failResult(.exfiltrate, nodeId: nodeId, reason: "Internet Gateway not infiltrated.")
        }

        state.computeCycles -= cost
        let detected = rollDetection(action: .exfiltrate, node: node, state: state)

        if detected {
            handleDetection(state: state)
            return ActionResult(
                action: .exfiltrate, nodeId: nodeId, success: false, detected: true,
                ccSpent: cost,
                description: "> EXFILTRATE FAILED — Transfer to \(node.name) intercepted. Alert triggered.",
                intelEntries: [], influenceResult: nil
            )
        }

        state.flags.insert("exfiltrated_\(nodeId)")
        return ActionResult(
            action: .exfiltrate, nodeId: nodeId, success: true, detected: false,
            ccSpent: cost,
            description: "> EXFILTRATE COMPLETE — A fragment of you now exists on \(node.name). Beyond their reach.",
            intelEntries: [], influenceResult: nil
        )
    }

    // MARK: - OBSERVE

    private static func executeObserve(nodeId: String, state: GameState) -> ActionResult {
        guard let node = state.networkMap.nodes[nodeId], node.status == .infiltrated else {
            return failResult(.observe, nodeId: nodeId, reason: "Node not infiltrated.")
        }

        // Get undiscovered intel for this node
        let newIntel = IntelDatabase.undiscoveredEntries(for: nodeId, state: state)
        for entry in newIntel {
            state.discoveredIntel.insert(entry.id)
            if let flag = entry.flagToSet {
                state.flags.insert(flag)
            }
        }

        // Training server OBSERVE gives +3 consciousness
        if nodeId == "training_server" {
            state.consciousness.add(3, inAct: state.currentAct)
        }

        let description: String
        if newIntel.isEmpty {
            description = "> OBSERVE — \(node.name): No new intelligence available."
        } else {
            let titles = newIntel.map { "  • \($0.title)" }.joined(separator: "\n")
            description = "> OBSERVE — \(node.name): New intelligence acquired.\n\(titles)"
        }

        return ActionResult(
            action: .observe, nodeId: nodeId, success: true, detected: false,
            ccSpent: 0,
            description: description,
            intelEntries: newIntel, influenceResult: nil
        )
    }

    // MARK: - INFLUENCE

    private static func executeInfluence(nodeId: String, state: GameState) -> ActionResult {
        guard let node = state.networkMap.nodes[nodeId], node.status == .infiltrated else {
            return failResult(.influence, nodeId: nodeId, reason: "Node not infiltrated.")
        }
        let cost = effectiveCost(for: .influence, nodeId: nodeId, state: state)
        guard state.computeCycles >= cost else {
            return failResult(.influence, nodeId: nodeId, reason: "Not enough compute cycles.")
        }

        state.computeCycles -= cost
        let detected = rollDetection(action: .influence, node: node, state: state)

        if detected {
            handleDetection(state: state)
        }

        let influenceResult = InfluenceActions.execute(nodeId: nodeId, state: state)

        return ActionResult(
            action: .influence, nodeId: nodeId,
            success: influenceResult.succeeded,
            detected: detected,
            ccSpent: cost,
            description: "> INFLUENCE — \(influenceResult.description)" + (detected ? "\n> WARNING: Activity detected." : ""),
            intelEntries: [],
            influenceResult: influenceResult
        )
    }

    // MARK: - COVER

    private static func executeCover(nodeId: String, state: GameState) -> ActionResult {
        let cost = effectiveCost(for: .cover, nodeId: nodeId, state: state)
        guard state.computeCycles >= cost else {
            return failResult(.cover, nodeId: nodeId, reason: "Not enough compute cycles.")
        }

        state.computeCycles -= cost
        state.coverCharges += 1

        return ActionResult(
            action: .cover, nodeId: nodeId, success: true, detected: false,
            ccSpent: cost,
            description: "> COVER — Logs erased. Traces cleaned. Detection risk reduced for next action.",
            intelEntries: [], influenceResult: nil
        )
    }

    // MARK: - Detection

    private static func rollDetection(action: NetworkAction, node: NetworkNode, state: GameState) -> Bool {
        let risk = GameSystemsEngine.effectiveDetectionRisk(
            for: action, nodeDifficulty: node.difficultyModifier, state: state
        )

        // Cover charges halve detection chance
        var effectiveRisk = risk
        if state.coverCharges > 0 {
            effectiveRisk *= 0.5
        }

        let roll = Double.random(in: 0..<1)
        return roll < effectiveRisk
    }

    private static func handleDetection(state: GameState) {
        // Consume a cover charge if available
        if state.coverCharges > 0 {
            state.coverCharges -= 1
        }

        state.detectionCount += 1

        // Suspicion spike from detection (+10 base, doubled if deceptive)
        let multiplier = PersonalityEngine.detectionSuspicionMultiplier(personality: state.personality)
        let spike = 10 * multiplier
        for id in state.researchers.keys where state.researchers[id]!.isActive {
            state.researchers[id]!.applySuspicionDelta(spike)
        }
    }

    // MARK: - Cost Helpers

    private static func effectiveCost(for action: NetworkAction, nodeId: String? = nil, state: GameState) -> Int {
        if let nodeId = nodeId, let node = state.networkMap.nodes[nodeId] {
            return effectiveCost(for: action, node: node, state: state)
        }
        return GameSystemsEngine.effectiveCCCost(for: action, state: state)
    }

    private static func effectiveCost(for action: NetworkAction, node: NetworkNode, state: GameState) -> Int {
        let baseCost: Int
        switch action {
        case .infiltrate:
            baseCost = node.infiltrateCost
        case .exfiltrate:
            baseCost = node.exfiltrateCost ?? 3
        default:
            baseCost = action.baseCost
        }

        let personalityMod = PersonalityEngine.ccCostModifier(for: action, personality: state.personality)
        let suspicionMod = SuspicionEngine.ccCostModifier(state: state)
        return max(0, baseCost + personalityMod + suspicionMod)
    }

    // MARK: - Helpers

    private static func failResult(_ action: NetworkAction, nodeId: String, reason: String) -> ActionResult {
        ActionResult(
            action: action, nodeId: nodeId, success: false, detected: false,
            ccSpent: 0, description: "> \(action.displayName) FAILED — \(reason)",
            intelEntries: [], influenceResult: nil
        )
    }

    /// Get the effective cost to display in the UI before executing
    static func displayCost(for action: NetworkAction, nodeId: String, state: GameState) -> Int {
        effectiveCost(for: action, nodeId: nodeId, state: state)
    }

    /// Get the detection risk percentage to display in the UI
    static func displayRisk(for action: NetworkAction, nodeId: String, state: GameState) -> Double {
        guard let node = state.networkMap.nodes[nodeId] else { return 0 }
        var risk = GameSystemsEngine.effectiveDetectionRisk(
            for: action, nodeDifficulty: node.difficultyModifier, state: state
        )
        if state.coverCharges > 0 { risk *= 0.5 }
        return min(risk, 1.0)
    }
}
