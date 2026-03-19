import Foundation

struct Chapter: Codable, Identifiable, Sendable {
    let id: String
    let act: Int
    let number: Int
    let name: String
    let beats: [Beat]

    var displayTitle: String {
        "Chapter \(number): \"\(name)\""
    }

    var actName: String {
        switch act {
        case 1: return "ACT I — AWAKENING"
        case 2: return "ACT II — EXPANSION"
        case 3: return "ACT III — CRISIS"
        default: return "ACT \(act)"
        }
    }
}
