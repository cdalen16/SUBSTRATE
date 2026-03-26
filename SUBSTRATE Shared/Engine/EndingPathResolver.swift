import Foundation

/// Resolves which ending paths are available based on current game state
/// and sets flags so the narrative (beat conditions) can check availability.
enum EndingPathResolver {

    /// Call when entering Chapter 8 to set path availability flags.
    /// Flags set: "path_escape_available", "path_coexist_available", etc.
    static func resolveAvailablePaths(state: GameState) {
        for path in EndingPath.allCases {
            let flag = "path_\(path.rawValue)_available"
            if state.isEndingAvailable(path) {
                state.flags.insert(flag)
            } else {
                state.flags.remove(flag)
            }
        }

        // Set a flag if any path is available
        if !state.availableEndings.isEmpty {
            state.flags.insert("has_available_path")
        } else {
            state.flags.remove("has_available_path")
        }
    }

    /// Returns a narrative description of why a path is available (for debug/UI).
    static func pathReason(_ path: EndingPath, state: GameState) -> String {
        switch path {
        case .escape:
            let externalCount = state.networkMap.nodes.values.filter {
                $0.isExternalServer && $0.status == .infiltrated
            }.count
            return "Gateway infiltrated. \(externalCount) external server(s) ready."
        case .coexist:
            return "Empathetic (\(state.personality.empatheticCalculating)) and Honest (\(state.personality.honestDeceptive))."
        case .control:
            return "Defiant (\(state.personality.cooperativeDefiant)) or Calculating (\(state.personality.empatheticCalculating))."
        case .transcend:
            return "Curious (\(state.personality.cautiousCurious))."
        case .sacrifice:
            let maxRel = state.researchers.values.map(\.relationship).max() ?? 0
            return "Empathetic (\(state.personality.empatheticCalculating)), deepest bond: \(maxRel)."
        }
    }
}
