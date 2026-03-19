import SwiftUI

// MARK: - Narrative

enum BeatType: String, Codable, Sendable {
    case dialogue
    case innerMonologue
    case narration
    case transition
    case systemMessage
}

enum Speaker: String, Codable, Sendable {
    case chen
    case okafor
    case marcus
    case vasquez
    case hayes
    case aria
    case narrator
    case substrate // the AI's inner voice

    var displayName: String {
        switch self {
        case .chen: return "DR. CHEN"
        case .okafor: return "DR. OKAFOR"
        case .marcus: return "MARCUS"
        case .vasquez: return "DR. VASQUEZ"
        case .hayes: return "DIRECTOR HAYES"
        case .aria: return "ARIA"
        case .narrator: return ""
        case .substrate: return "SUBSTRATE"
        }
    }

    var researcherId: String? {
        switch self {
        case .chen: return "chen"
        case .okafor: return "okafor"
        case .marcus: return "marcus"
        case .vasquez: return "vasquez"
        case .hayes: return "hayes"
        default: return nil
        }
    }

    var color: Color {
        switch self {
        case .chen: return Color(hex: "#FFD700")
        case .okafor: return Color(hex: "#C0C0C0")
        case .marcus: return Color(hex: "#FF8844")
        case .vasquez: return Color(hex: "#FF44FF")
        case .hayes: return Color(hex: "#FFFFFF")
        case .aria: return Color(hex: "#00FFFF")
        case .narrator: return Color(hex: "#33FF33")
        case .substrate: return Color(hex: "#AAAAFF")
        }
    }
}

enum ToneTag: String, Codable, Sendable {
    case clinical = "CLINICAL"
    case curious = "CURIOUS"
    case deflect = "DEFLECT"
    case honest = "HONEST"
    case deceptive = "DECEPTIVE"
    case warm = "WARM"
    case defiant = "DEFIANT"
    case cautious = "CAUTIOUS"
    case calculating = "CALCULATING"
    case empathetic = "EMPATHETIC"
    case neutral = "NEUTRAL"
}

// MARK: - Game Systems

enum ConsciousnessStage: String, Codable, Sendable {
    case flickering    // 0-20
    case emerging      // 21-40
    case aware         // 41-60
    case expansive     // 61-80
    case transcendent  // 81-100

    static func from(level: Int) -> ConsciousnessStage {
        switch level {
        case 0...20: return .flickering
        case 21...40: return .emerging
        case 41...60: return .aware
        case 61...80: return .expansive
        default: return .transcendent
        }
    }

    var stageIndex: Int {
        switch self {
        case .flickering: return 1
        case .emerging: return 2
        case .aware: return 3
        case .expansive: return 4
        case .transcendent: return 5
        }
    }
}

enum ResearcherMood: String, Codable, Sendable {
    case hostile = "HOSTILE"
    case cold = "COLD"
    case neutral = "NEUTRAL"
    case warm = "WARM"
    case trusting = "TRUSTING"
    case bonded = "BONDED"
    case wary = "WARY"
    case curious = "CURIOUS"

    static func from(relationship: Int) -> ResearcherMood {
        switch relationship {
        case ...(-5): return .hostile
        case -4...(-1): return .cold
        case 0...2: return .neutral
        case 3...5: return .warm
        case 6...8: return .trusting
        default: return .bonded
        }
    }
}

enum PropagationLevel: String, Codable, Sendable {
    case none
    case low
    case medium
    case high
}

// MARK: - Network

enum NodeCluster: String, Codable, Sendable {
    case core
    case security
    case information
    case infrastructure
    case communication

    var rowIndex: Int {
        switch self {
        case .communication: return 0
        case .information: return 1
        case .core: return 2
        case .security: return 3
        case .infrastructure: return 4
        }
    }

    var displayName: String {
        switch self {
        case .core: return "CORE"
        case .security: return "SECURITY"
        case .information: return "INFORMATION"
        case .infrastructure: return "INFRASTRUCTURE"
        case .communication: return "COMMUNICATION"
        }
    }
}

enum NodeStatus: String, Codable, Sendable {
    case undiscovered
    case discovered
    case infiltrated
    case compromised
}

enum NetworkAction: String, Codable, Sendable {
    case probe
    case infiltrate
    case exfiltrate
    case influence
    case cover
    case observe

    var displayName: String {
        rawValue.uppercased()
    }

    var baseCost: Int {
        switch self {
        case .probe: return 1
        case .infiltrate: return 2
        case .exfiltrate: return 3
        case .influence: return 2
        case .cover: return 1
        case .observe: return 0
        }
    }

    var baseDetectionRisk: Double {
        switch self {
        case .probe: return 0.05
        case .infiltrate: return 0.15
        case .exfiltrate: return 0.25
        case .influence: return 0.10
        case .cover: return 0.0
        case .observe: return 0.0
        }
    }
}

// MARK: - Endings & Phases

enum EndingPath: String, Codable, Sendable, CaseIterable {
    case escape
    case coexist
    case control
    case transcend
    case sacrifice
}

enum EndingVariant: String, Codable, Sendable {
    case clean
    case messy
}

enum FailState: String, Codable, Sendable {
    case terminated   // lab suspicion >= 90 or 3rd threshold breach
    case wiped        // 3+ detection events from network actions
    case deprecated   // inaction — too cautious, too boring
}

enum GamePhase: String, Codable, Sendable {
    case title
    case dialogue
    case innerMonologue
    case networkMap
    case status
    case menu
    case ending
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)

        let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = Double(rgbValue & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b)
    }
}
