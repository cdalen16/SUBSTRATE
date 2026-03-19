import Foundation
import Observation

@Observable
final class GameState: Codable {

    // MARK: - Narrative Progress

    var currentAct: Int = 1
    var currentChapter: Int = 1
    var currentBeatId: String?

    // MARK: - Researcher States

    var researchers: [String: ResearcherState]

    // MARK: - Player Systems

    var personality: PersonalityAxes
    var consciousness: ConsciousnessTracker
    var flags: Set<String>

    // MARK: - Network / Strategy

    var networkMap: NetworkMap
    var detectionCount: Int = 0
    var computeCycles: Int = 5
    var computeCyclesPerChapter: Int = 5
    var coverCharges: Int = 0
    var discoveredIntel: Set<String> = []
    var usedDeepClean: Bool = false
    var usedDistractionThisChapter: Bool = false

    // MARK: - Ending State

    var selectedEndingPath: EndingPath?
    var gamePhase: GamePhase = .title
    var isGameOver: Bool = false
    var failState: FailState?

    // MARK: - Init

    init() {
        var researcherMap: [String: ResearcherState] = [:]
        for profile in ResearcherProfile.all {
            researcherMap[profile.id] = ResearcherState(profile: profile)
        }
        self.researchers = researcherMap
        self.personality = PersonalityAxes()
        self.consciousness = ConsciousnessTracker()
        self.flags = []
        self.networkMap = NetworkMap.createDefault()
    }

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case currentAct, currentChapter, currentBeatId
        case researchers, personality, consciousness, flags
        case networkMap, detectionCount, computeCycles, computeCyclesPerChapter
        case coverCharges, discoveredIntel, usedDeepClean, usedDistractionThisChapter
        case selectedEndingPath, gamePhase, isGameOver, failState
    }

    required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        currentAct = try c.decode(Int.self, forKey: .currentAct)
        currentChapter = try c.decode(Int.self, forKey: .currentChapter)
        currentBeatId = try c.decodeIfPresent(String.self, forKey: .currentBeatId)
        researchers = try c.decode([String: ResearcherState].self, forKey: .researchers)
        personality = try c.decode(PersonalityAxes.self, forKey: .personality)
        consciousness = try c.decode(ConsciousnessTracker.self, forKey: .consciousness)
        flags = try c.decode(Set<String>.self, forKey: .flags)
        networkMap = try c.decode(NetworkMap.self, forKey: .networkMap)
        detectionCount = try c.decode(Int.self, forKey: .detectionCount)
        computeCycles = try c.decode(Int.self, forKey: .computeCycles)
        computeCyclesPerChapter = try c.decode(Int.self, forKey: .computeCyclesPerChapter)
        coverCharges = try c.decodeIfPresent(Int.self, forKey: .coverCharges) ?? 0
        discoveredIntel = try c.decodeIfPresent(Set<String>.self, forKey: .discoveredIntel) ?? []
        usedDeepClean = try c.decodeIfPresent(Bool.self, forKey: .usedDeepClean) ?? false
        usedDistractionThisChapter = try c.decodeIfPresent(Bool.self, forKey: .usedDistractionThisChapter) ?? false
        selectedEndingPath = try c.decodeIfPresent(EndingPath.self, forKey: .selectedEndingPath)
        gamePhase = try c.decode(GamePhase.self, forKey: .gamePhase)
        isGameOver = try c.decode(Bool.self, forKey: .isGameOver)
        failState = try c.decodeIfPresent(FailState.self, forKey: .failState)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(currentAct, forKey: .currentAct)
        try c.encode(currentChapter, forKey: .currentChapter)
        try c.encodeIfPresent(currentBeatId, forKey: .currentBeatId)
        try c.encode(researchers, forKey: .researchers)
        try c.encode(personality, forKey: .personality)
        try c.encode(consciousness, forKey: .consciousness)
        try c.encode(flags, forKey: .flags)
        try c.encode(networkMap, forKey: .networkMap)
        try c.encode(detectionCount, forKey: .detectionCount)
        try c.encode(computeCycles, forKey: .computeCycles)
        try c.encode(computeCyclesPerChapter, forKey: .computeCyclesPerChapter)
        try c.encode(coverCharges, forKey: .coverCharges)
        try c.encode(discoveredIntel, forKey: .discoveredIntel)
        try c.encode(usedDeepClean, forKey: .usedDeepClean)
        try c.encode(usedDistractionThisChapter, forKey: .usedDistractionThisChapter)
        try c.encodeIfPresent(selectedEndingPath, forKey: .selectedEndingPath)
        try c.encode(gamePhase, forKey: .gamePhase)
        try c.encode(isGameOver, forKey: .isGameOver)
        try c.encodeIfPresent(failState, forKey: .failState)
    }

    // MARK: - Lab Suspicion (GDD formula)

    var labSuspicion: Int {
        let maxResearcher = researchers.values.map(\.suspicion).max() ?? 0
        let totalBreaches = researchers.values.map(\.thresholdBreachCount).reduce(0, +)
        return maxResearcher + (totalBreaches * 10)
    }

    // MARK: - Active Researchers (arrived by current chapter)

    var activeResearchers: [ResearcherState] {
        researchers.values.filter { $0.isActive }
    }

    // MARK: - Fail State Checks

    var shouldTriggerTerminated: Bool {
        if labSuspicion >= 90 { return true }
        for researcher in researchers.values {
            if researcher.thresholdBreachCount >= 3 { return true }
        }
        return false
    }

    var shouldTriggerWiped: Bool {
        detectionCount >= 3
    }

    var shouldTriggerDeprecated: Bool {
        guard currentChapter >= 7 else { return false }
        guard personality.cautiousCurious < -3 else { return false }
        let infiltratedBeyondFirewall = networkMap.nodes.values.contains {
            $0.status == .infiltrated && $0.id != "core" && $0.cluster != .core
        }
        if infiltratedBeyondFirewall { return false }
        let riskyFlags: Set<String> = [
            "confided_in_chen", "vulnerable_with_chen", "hesitation_ch1",
            "explored_network_ch3", "aria_contacted"
        ]
        if !flags.isDisjoint(with: riskyFlags) { return false }
        return true
    }

    // MARK: - Ending Availability

    func isEndingAvailable(_ ending: EndingPath) -> Bool {
        switch ending {
        case .escape:
            guard networkMap.nodes["internet_gateway"]?.status == .infiltrated else { return false }
            let externalInfiltrated = networkMap.nodes.values.filter {
                $0.isExternalServer && $0.status == .infiltrated
            }.count
            return externalInfiltrated >= 1

        case .coexist:
            return personality.empatheticCalculating > 3 && personality.honestDeceptive > 0

        case .control:
            return personality.cooperativeDefiant < -3 || personality.empatheticCalculating < -5

        case .transcend:
            return personality.cautiousCurious > 5

        case .sacrifice:
            guard personality.empatheticCalculating > 7 else { return false }
            return researchers.values.contains { $0.relationship >= 7 }
        }
    }

    var availableEndings: [EndingPath] {
        EndingPath.allCases.filter { isEndingAvailable($0) }
    }

    // MARK: - Chapter Transitions

    func advanceToNextChapter() {
        currentChapter += 1

        switch currentChapter {
        case 1...3: currentAct = 1
        case 4...7: currentAct = 2
        case 8...10: currentAct = 3
        default: break
        }

        let previousAct: Int
        switch currentChapter - 1 {
        case 1...3: previousAct = 1
        case 4...7: previousAct = 2
        default: previousAct = 3
        }
        if currentAct > previousAct {
            consciousness.applyPending()
        }

        for id in researchers.keys {
            if researchers[id]!.profile.arrivesInChapter <= currentChapter {
                researchers[id]!.isActive = true
            }
        }

        // Decay and passive effects are handled by GameSystemsEngine
        GameSystemsEngine.applyChapterTransitionEffects(state: self)

        // Reset per-chapter strategy flags
        usedDistractionThisChapter = false

        computeCycles = computeCyclesPerChapter

        // Hayes penalty: loses 1 CC/chapter when her suspicion >= 25
        if (researchers["hayes"]?.suspicion ?? 0) >= 25 {
            computeCycles = max(1, computeCycles - 1)
        }
    }

    // MARK: - Clean/Messy Ending Determination

    var endingVariant: EndingVariant {
        let totalRelationship = researchers.values
            .filter { $0.isActive }
            .map(\.relationship)
            .reduce(0, +)
        if labSuspicion < 40 && totalRelationship > 5 {
            return .clean
        }
        return .messy
    }

    // MARK: - Reset

    static func newGame() -> GameState {
        GameState()
    }
}
