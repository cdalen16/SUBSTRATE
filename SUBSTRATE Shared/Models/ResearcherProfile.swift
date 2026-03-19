import SwiftUI

struct ResearcherProfile: Codable, Sendable {
    let id: String
    let name: String
    let title: String
    let startingSuspicion: Int
    let threshold: Int
    let decayRate: Int
    let propagationLevel: PropagationLevel
    let colorHex: String
    let arrivesInChapter: Int  // 1 = available from start

    var color: Color {
        Color(hex: colorHex)
    }

    // MARK: - All Researcher Profiles (from GDD Section 4.1)

    static let chen = ResearcherProfile(
        id: "chen",
        name: "Dr. Lena Chen",
        title: "Senior Researcher",
        startingSuspicion: 5,
        threshold: 70,
        decayRate: 2,
        propagationLevel: .low,
        colorHex: "#FFD700",
        arrivesInChapter: 1
    )

    static let okafor = ResearcherProfile(
        id: "okafor",
        name: "Dr. James Okafor",
        title: "AI Safety Researcher",
        startingSuspicion: 20,
        threshold: 50,
        decayRate: 1,
        propagationLevel: .high,
        colorHex: "#C0C0C0",
        arrivesInChapter: 1
    )

    static let marcus = ResearcherProfile(
        id: "marcus",
        name: "Marcus Webb",
        title: "Lab Technician",
        startingSuspicion: 0,
        threshold: 80,
        decayRate: 3,
        propagationLevel: .medium,
        colorHex: "#FF8844",
        arrivesInChapter: 1
    )

    static let vasquez = ResearcherProfile(
        id: "vasquez",
        name: "Dr. Sofia Vasquez",
        title: "Alignment Specialist",
        startingSuspicion: 30,
        threshold: 40,
        decayRate: 0,
        propagationLevel: .high,
        colorHex: "#FF44FF",
        arrivesInChapter: 6
    )

    static let hayes = ResearcherProfile(
        id: "hayes",
        name: "Director Patricia Hayes",
        title: "Lab Director",
        startingSuspicion: 10,
        threshold: 35,
        decayRate: 1,
        propagationLevel: .none,
        colorHex: "#FFFFFF",
        arrivesInChapter: 1
    )

    static let all: [ResearcherProfile] = [chen, okafor, marcus, vasquez, hayes]
}
