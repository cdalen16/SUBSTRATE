import Foundation
import Observation

@Observable
final class EndingTracker {

    private static let storageKey = "substrate_ending_tracker"

    var achievedEndings: Set<String> = []
    var totalRuns: Int = 0

    init() {
        loadFromStorage()
    }

    // MARK: - Record an Ending

    func recordEnding(path: EndingPath, variant: EndingVariant) {
        let key = "\(path.rawValue)_\(variant.rawValue)"
        achievedEndings.insert(key)
        totalRuns += 1
        saveToStorage()
    }

    func recordFailState() {
        totalRuns += 1
        saveToStorage()
    }

    // MARK: - Queries

    func hasAchieved(path: EndingPath) -> Bool {
        achievedEndings.contains("\(path.rawValue)_clean")
            || achievedEndings.contains("\(path.rawValue)_messy")
    }

    func hasAchieved(path: EndingPath, variant: EndingVariant) -> Bool {
        achievedEndings.contains("\(path.rawValue)_\(variant.rawValue)")
    }

    var achievedCount: Int {
        EndingPath.allCases.filter { hasAchieved(path: $0) }.count
    }

    // MARK: - Persistence (UserDefaults — survives save deletion)

    private func saveToStorage() {
        let data: [String: Any] = [
            "endings": Array(achievedEndings),
            "runs": totalRuns
        ]
        UserDefaults.standard.set(data, forKey: Self.storageKey)
    }

    private func loadFromStorage() {
        guard let data = UserDefaults.standard.dictionary(forKey: Self.storageKey) else { return }
        if let endings = data["endings"] as? [String] {
            achievedEndings = Set(endings)
        }
        if let runs = data["runs"] as? Int {
            totalRuns = runs
        }
    }

    func resetAll() {
        achievedEndings = []
        totalRuns = 0
        UserDefaults.standard.removeObject(forKey: Self.storageKey)
    }
}
