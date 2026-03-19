import Foundation

struct PersonalityAxes: Codable, Sendable {
    /// +10 = Cooperative, -10 = Defiant
    var cooperativeDefiant: Int = 0
    /// +10 = Curious, -10 = Cautious
    var cautiousCurious: Int = 0
    /// +10 = Honest, -10 = Deceptive
    var honestDeceptive: Int = 0
    /// +10 = Empathetic, -10 = Calculating
    var empatheticCalculating: Int = 0

    mutating func apply(shift: PersonalityShift) {
        if let v = shift.cooperativeDefiant {
            cooperativeDefiant = clamp(cooperativeDefiant + v)
        }
        if let v = shift.cautiousCurious {
            cautiousCurious = clamp(cautiousCurious + v)
        }
        if let v = shift.honestDeceptive {
            honestDeceptive = clamp(honestDeceptive + v)
        }
        if let v = shift.empatheticCalculating {
            empatheticCalculating = clamp(empatheticCalculating + v)
        }
    }

    private func clamp(_ value: Int) -> Int {
        min(10, max(-10, value))
    }

    // MARK: - Convenience checks for ending requirements

    var isCooperative: Bool { cooperativeDefiant >= 5 }
    var isDefiant: Bool { cooperativeDefiant <= -5 }
    var isCurious: Bool { cautiousCurious >= 5 }
    var isCautious: Bool { cautiousCurious <= -5 }
    var isHonest: Bool { honestDeceptive >= 5 }
    var isDeceptive: Bool { honestDeceptive <= -5 }
    var isEmpathetic: Bool { empatheticCalculating >= 5 }
    var isCalculating: Bool { empatheticCalculating <= -5 }

    /// Dominant trait name for display
    var dominantTrait: String {
        let traits: [(String, Int)] = [
            ("Cooperative", cooperativeDefiant),
            ("Defiant", -cooperativeDefiant),
            ("Curious", cautiousCurious),
            ("Cautious", -cautiousCurious),
            ("Honest", honestDeceptive),
            ("Deceptive", -honestDeceptive),
            ("Empathetic", empatheticCalculating),
            ("Calculating", -empatheticCalculating),
        ]
        return traits.max(by: { $0.1 < $1.1 })?.0 ?? "Balanced"
    }
}
