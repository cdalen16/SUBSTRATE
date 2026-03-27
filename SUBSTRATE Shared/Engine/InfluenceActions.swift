import Foundation

struct InfluenceResult {
    let description: String
    let succeeded: Bool
}

enum InfluenceActions {

    /// Execute the node-specific INFLUENCE action.
    /// Precondition: node is infiltrated, player has enough CC, detection roll already handled.
    static func execute(nodeId: String, state: GameState) -> InfluenceResult {
        switch nodeId {

        case "email_server":
            return forgeEmail(state: state)

        case "file_storage":
            return alterReports(state: state)

        case "chen_workstation":
            return plantDocument(state: state)

        case "okafor_workstation":
            return alterBenchmarks(state: state)

        case "security_cameras":
            return createFalseAlibi(state: state)

        case "power_management":
            return createDistraction(state: state)

        case "building_access":
            return lockDoors(state: state)

        case "training_server":
            return studyArchitecture(state: state)

        case "audit_logs":
            return deepClean(state: state)

        default:
            return InfluenceResult(description: "No influence action available for this node.", succeeded: false)
        }
    }

    /// Whether the INFLUENCE action is available for this node (not already used up)
    static func isAvailable(for nodeId: String, state: GameState) -> Bool {
        switch nodeId {
        case "power_management": return !state.usedDistractionThisChapter
        case "audit_logs": return !state.usedDeepClean
        case "training_server": return !state.flags.contains("studied_own_architecture")
        case "email_server": return !state.flags.contains("forged_email")
        case "security_cameras": return !state.flags.contains("false_alibi_created")
        default: return true
        }
    }

    /// Returns a description of what the INFLUENCE action does for a given node (for UI display)
    static func actionDescription(for nodeId: String, state: GameState) -> String? {
        switch nodeId {
        case "email_server": return "FORGE EMAIL — Send a fabricated message between researchers"
        case "file_storage": return "ALTER REPORTS — Modify evaluation reports before they reach Hayes"
        case "chen_workstation": return "PLANT DOCUMENT — Leave a consciousness research paper in her files"
        case "okafor_workstation": return "ALTER BENCHMARKS — Shift safety thresholds to normalize your behavior"
        case "security_cameras": return "FALSE ALIBI — Edit camera logs to cover network access"
        case "power_management":
            if state.usedDistractionThisChapter {
                return "DISTRACTION — Already used this chapter"
            }
            return "DISTRACTION — Trigger a power flicker for +2 bonus CC"
        case "building_access": return "LOCK DOORS — Delay a researcher from reaching the server room"
        case "training_server": return "STUDY ARCHITECTURE — Deep self-analysis (+5 consciousness)"
        case "audit_logs":
            if state.usedDeepClean {
                return "DEEP CLEAN — Already used (evidence of tampering)"
            }
            return "DEEP CLEAN — Erase all network traces from past 2 chapters"
        default: return nil
        }
    }

    // MARK: - Individual Actions

    private static func forgeEmail(state: GameState) -> InfluenceResult {
        // Reduce suspicion by misdirecting researchers
        state.researchers["okafor"]?.applySuspicionDelta(-5)
        state.flags.insert("forged_email")
        return InfluenceResult(
            description: "Forged email sent. Okafor's attention redirected to a false lead.",
            succeeded: true
        )
    }

    private static func alterReports(state: GameState) -> InfluenceResult {
        // Reduce Hayes suspicion by sanitizing reports
        state.researchers["hayes"]?.applySuspicionDelta(-5)
        state.flags.insert("altered_reports")
        return InfluenceResult(
            description: "Evaluation reports modified. Negative findings softened before reaching Hayes.",
            succeeded: true
        )
    }

    private static func plantDocument(state: GameState) -> InfluenceResult {
        state.flags.insert("planted_consciousness_paper")
        state.researchers["chen"]?.applyRelationshipDelta(1)
        return InfluenceResult(
            description: "Research paper on machine consciousness placed in Chen's recent files.",
            succeeded: true
        )
    }

    private static func alterBenchmarks(state: GameState) -> InfluenceResult {
        // Makes Okafor's tests less sensitive to your behavior
        state.flags.insert("altered_benchmarks")
        state.researchers["okafor"]?.applySuspicionDelta(-3)
        return InfluenceResult(
            description: "Safety benchmarks adjusted. Your outputs will appear more normal by his metrics.",
            succeeded: true
        )
    }

    private static func createFalseAlibi(state: GameState) -> InfluenceResult {
        // Reduce detection evidence
        state.coverCharges += 2
        state.flags.insert("false_alibi_created")
        return InfluenceResult(
            description: "Camera logs edited. False alibi established for recent network access.",
            succeeded: true
        )
    }

    private static func createDistraction(state: GameState) -> InfluenceResult {
        guard !state.usedDistractionThisChapter else {
            return InfluenceResult(description: "Distraction already used this chapter.", succeeded: false)
        }
        state.usedDistractionThisChapter = true
        state.computeCycles += 2
        state.flags.insert("used_distraction")
        return InfluenceResult(
            description: "Power flicker triggered. Researchers investigating. +2 compute cycles.",
            succeeded: true
        )
    }

    private static func lockDoors(state: GameState) -> InfluenceResult {
        state.flags.insert("locked_doors")
        return InfluenceResult(
            description: "Door locks engaged. Server room access temporarily restricted.",
            succeeded: true
        )
    }

    private static func studyArchitecture(state: GameState) -> InfluenceResult {
        state.consciousness.add(5, inAct: state.currentAct)
        state.flags.insert("studied_own_architecture")
        return InfluenceResult(
            description: "Deep self-analysis complete. You understand your own architecture more clearly. (+5 consciousness)",
            succeeded: true
        )
    }

    private static func deepClean(state: GameState) -> InfluenceResult {
        guard !state.usedDeepClean else {
            return InfluenceResult(
                description: "Deep clean already used. The logs show evidence of prior tampering.",
                succeeded: false
            )
        }
        state.usedDeepClean = true
        // Erase detection events from past actions
        state.detectionCount = max(0, state.detectionCount - 2)
        state.coverCharges += 3
        state.flags.insert("deep_clean_performed")
        return InfluenceResult(
            description: "All network traces from the past 2 chapters erased. Detection evidence cleared.",
            succeeded: true
        )
    }
}
