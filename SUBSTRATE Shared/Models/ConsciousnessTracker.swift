import Foundation

struct ConsciousnessTracker: Codable, Sendable {
    var current: Int = 0
    var pending: Int = 0

    var stage: ConsciousnessStage {
        ConsciousnessStage.from(level: current)
    }

    static func capForAct(_ act: Int) -> Int {
        switch act {
        case 1: return 25
        case 2: return 65
        default: return 100
        }
    }

    mutating func add(_ value: Int, inAct act: Int) {
        guard value != 0 else { return }

        let cap = Self.capForAct(act)

        if value > 0 {
            let newValue = current + value
            if newValue > cap {
                current = cap
                pending += newValue - cap
            } else {
                current = newValue
            }
        } else {
            // Negative changes (rare but possible) — don't go below 0, no pending
            current = max(0, current + value)
        }
    }

    mutating func applyPending() {
        guard pending > 0 else { return }
        current = min(current + pending, 100)
        pending = 0
    }

    var progressFraction: Double {
        Double(current) / 100.0
    }
}
