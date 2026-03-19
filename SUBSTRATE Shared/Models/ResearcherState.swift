import Foundation

struct ResearcherState: Codable, Sendable {
    let profile: ResearcherProfile
    var suspicion: Int
    var relationship: Int
    var mood: ResearcherMood
    var thresholdBreachCount: Int
    var isActive: Bool  // false until their arrivesInChapter is reached

    init(profile: ResearcherProfile) {
        self.profile = profile
        self.suspicion = profile.startingSuspicion
        self.relationship = 0
        self.mood = .neutral
        self.thresholdBreachCount = 0
        self.isActive = profile.arrivesInChapter <= 1
    }

    // MARK: - Suspicion

    mutating func applySuspicionDelta(_ delta: Int) {
        let wasBelowThreshold = suspicion < profile.threshold
        suspicion = max(0, min(100, suspicion + delta))
        // Count a new breach each time suspicion crosses from below to at/above threshold
        if wasBelowThreshold && suspicion >= profile.threshold {
            thresholdBreachCount += 1
        }
    }

    mutating func applyDecay() {
        guard profile.decayRate > 0 else { return }
        suspicion = max(0, suspicion - profile.decayRate)
    }

    var hasBreachedThreshold: Bool {
        suspicion >= profile.threshold
    }

    // MARK: - Relationship

    mutating func applyRelationshipDelta(_ delta: Int) {
        relationship = max(-10, min(10, relationship + delta))
        updateMood()
    }

    private mutating func updateMood() {
        mood = ResearcherMood.from(relationship: relationship)
    }

    var relationshipLabel: String {
        switch relationship {
        case ...(-5): return "HOSTILE"
        case -4...(-1): return "COLD"
        case 0...2: return "NEUTRAL"
        case 3...5: return "WARM"
        case 6...8: return "TRUSTING"
        default: return "BONDED"
        }
    }

    /// High relationship delays suspicion propagation by 1 chapter
    var delaysPropagation: Bool {
        relationship >= 6
    }

    // MARK: - Suspicion fraction for UI bars

    var suspicionFraction: Double {
        Double(suspicion) / 100.0
    }

    var relationshipFraction: Double {
        Double(relationship + 10) / 20.0  // maps -10...10 to 0...1
    }
}
