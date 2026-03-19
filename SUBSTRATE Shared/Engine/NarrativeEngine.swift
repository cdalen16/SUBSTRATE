import Foundation

final class NarrativeEngine {

    private(set) var chapters: [String: Chapter] = [:]
    private(set) var currentChapter: Chapter?
    private var beatIndex: Int = 0

    // MARK: - Loading

    func loadChapter(named filename: String) -> Chapter? {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "json") else {
            print("[NarrativeEngine] Chapter file not found: \(filename).json")
            return nil
        }
        do {
            let data = try Data(contentsOf: url)
            let chapter = try JSONDecoder().decode(Chapter.self, from: data)
            chapters[chapter.id] = chapter
            return chapter
        } catch {
            print("[NarrativeEngine] Failed to decode \(filename).json: \(error)")
            return nil
        }
    }

    func loadAllChapters(fileNames: [String]) {
        for name in fileNames {
            _ = loadChapter(named: name)
        }
    }

    // MARK: - Starting a Chapter

    func startChapter(_ chapter: Chapter, state: GameState) -> Beat? {
        currentChapter = chapter
        beatIndex = 0
        state.currentChapter = chapter.number
        state.currentAct = chapter.act
        return resolveCurrentBeat(state: state)
    }

    func startChapter(id: String, state: GameState) -> Beat? {
        guard let chapter = chapters[id] else { return nil }
        return startChapter(chapter, state: state)
    }

    func startChapter(number: Int, state: GameState) -> Beat? {
        guard let chapter = chapters.values.first(where: { $0.number == number }) else { return nil }
        return startChapter(chapter, state: state)
    }

    // MARK: - Beat Resolution

    /// Resolves which beat to display at the current position.
    /// Skips beats whose conditions aren't met (for variant groups).
    private func resolveCurrentBeat(state: GameState) -> Beat? {
        guard let chapter = currentChapter else { return nil }

        while beatIndex < chapter.beats.count {
            let beat = chapter.beats[beatIndex]

            if let conditions = beat.conditions {
                if conditions.isMet(by: state) {
                    return beat
                } else {
                    // Conditions not met — skip this beat (variant not selected)
                    beatIndex += 1
                    continue
                }
            }

            // No conditions — this beat always plays (standalone or fallback)
            return beat
        }

        // Reached end of chapter
        return nil
    }

    // MARK: - Advancing

    /// Advance to the next beat after the current one was displayed.
    /// Call this when the player taps to continue on a non-choice beat.
    func advanceBeat(state: GameState) -> Beat? {
        guard let chapter = currentChapter else { return nil }
        guard beatIndex < chapter.beats.count else { return nil }

        let currentBeat = chapter.beats[beatIndex]

        // Apply beat effects if any
        currentBeat.effects?.apply(to: state)

        // Determine next beat
        if let nextId = currentBeat.nextBeatId {
            return jumpToBeat(id: nextId, state: state)
        }

        // No explicit next — advance sequentially
        beatIndex += 1
        return resolveCurrentBeat(state: state)
    }

    /// Process a player's choice selection. Applies effects and moves to the next beat.
    func selectChoice(_ choice: Choice, state: GameState) -> Beat? {
        // Apply choice effects to game state
        choice.effects.apply(to: state)

        // Update game state beat tracking
        state.currentBeatId = choice.nextBeatId

        // Navigate to the choice's target beat
        if let nextId = choice.nextBeatId {
            return jumpToBeat(id: nextId, state: state)
        }

        // No explicit target — advance sequentially past the choice beat
        beatIndex += 1
        return resolveCurrentBeat(state: state)
    }

    // MARK: - Navigation Helpers

    private func jumpToBeat(id: String, state: GameState) -> Beat? {
        guard let chapter = currentChapter else { return nil }

        if let index = chapter.beats.firstIndex(where: { $0.id == id }) {
            beatIndex = index
            return resolveCurrentBeat(state: state)
        }

        print("[NarrativeEngine] Beat not found: \(id)")
        return nil
    }

    // MARK: - Choice Filtering

    func availableChoices(for beat: Beat, state: GameState) -> [Choice] {
        guard let choices = beat.choices else { return [] }
        return choices.filter { $0.isAvailable(given: state) }
    }

    // MARK: - Chapter Completion

    var isChapterComplete: Bool {
        guard let chapter = currentChapter else { return true }
        return beatIndex >= chapter.beats.count
    }

    // MARK: - State

    var currentBeat: Beat? {
        guard let chapter = currentChapter, beatIndex < chapter.beats.count else { return nil }
        return chapter.beats[beatIndex]
    }
}
