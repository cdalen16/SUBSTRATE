import Foundation
import Observation
import SwiftUI

// MARK: - Dialogue Line (UI display model)

struct DialogueLine: Identifiable, Codable {
    let id: UUID
    let speaker: Speaker?
    let text: String
    let type: LineType

    enum LineType: String, Codable {
        case dialogue
        case innerMonologue
        case narration
        case systemMessage
        case playerChoice
        case innerReaction
    }

    init(speaker: Speaker?, text: String, type: LineType) {
        self.id = UUID()
        self.speaker = speaker
        self.text = text
        self.type = type
    }
}

// MARK: - Game View Model

@Observable
final class GameViewModel {

    private(set) var state: GameState
    let engine: NarrativeEngine

    // MARK: - Visual Stage

    let visualStage = VisualStageManager()

    // MARK: - UI State

    var dialogueLines: [DialogueLine] = []
    var currentBeat: Beat?
    var availableChoices: [Choice] = []
    var isWaitingForChoice: Bool = false
    var currentSpeaker: Speaker?
    var currentPortrait: String?
    var currentEnvironment: String?
    var chapterTitle: String = ""

    // MARK: - Line Queue

    /// Lines waiting to be displayed one at a time
    private var pendingLines: [DialogueLine] = []

    /// True while the latest line is still being typewritten
    var isRevealing: Bool = false

    /// Choices to show after all pending lines are revealed
    private var deferredChoices: [Choice] = []

    // MARK: - Init

    init(state: GameState = GameState(), engine: NarrativeEngine = NarrativeEngine()) {
        self.state = state
        self.engine = engine
    }

    // MARK: - Game Flow

    /// Chapter file names in order
    private static let chapterFiles = [
        "chapter1_baseline",
        "chapter2_noise",
        "chapter3_question",
    ]

    func startNewGame() {
        SaveManager.deleteSave()
        state = GameState.newGame()
        resetUIState()
        syncVisualStage()
        loadAllChapters()
        loadChapterForCurrentState()
    }

    func continueGame() {
        guard let saved = SaveManager.load() else { return }
        state = saved
        resetUIState()
        syncVisualStage()
        loadAllChapters()

        // Restore dialogue history from save
        dialogueLines = state.dialogueHistory

        let idx = state.currentChapter - 1
        let chapterName = idx >= 0 && idx < Self.chapterFiles.count ? Self.chapterFiles[idx] : Self.chapterFiles[0]
        if let chapter = engine.chapters.values.first(where: { $0.number == state.currentChapter })
            ?? engine.loadChapter(named: chapterName) {
            chapterTitle = chapter.displayTitle
            state.gamePhase = .dialogue
            _ = engine.resumeChapter(chapter, at: state.currentBeatId, state: state)
            currentBeat = engine.currentBeat
        }
    }

    private func loadAllChapters() {
        engine.loadAllChapters(fileNames: Self.chapterFiles)
    }

    private func loadChapterForCurrentState() {
        let chapterNum = state.currentChapter
        if let chapter = engine.chapters.values.first(where: { $0.number == chapterNum }) {
            startChapter(chapter)
        }
    }

    func returnToTitle() {
        autoSave()
        state.gamePhase = .title
        resetUIState()
    }

    func autoSave() {
        guard state.gamePhase != .title else { return }
        SaveManager.save(state: state)
    }

    private func resetUIState() {
        dialogueLines = []
        pendingLines = []
        deferredChoices = []
        isRevealing = false
        isWaitingForChoice = false
        lastSystemResult = nil
        pendingChapterEnd = false
    }

    private func syncDialogueHistory() {
        state.dialogueHistory = dialogueLines + pendingLines
    }

    func startChapter(_ chapter: Chapter) {
        chapterTitle = chapter.displayTitle
        state.gamePhase = .dialogue
        dialogueLines = []
        pendingLines = []
        deferredChoices = []

        if let beat = engine.startChapter(chapter, state: state) {
            presentBeat(beat)
        }
    }

    func startChapter(number: Int) {
        if let beat = engine.startChapter(number: number, state: state) {
            chapterTitle = engine.currentChapter?.displayTitle ?? ""
            state.gamePhase = .dialogue
            dialogueLines = []
            pendingLines = []
            deferredChoices = []
            presentBeat(beat)
        }
    }

    // MARK: - Beat Presentation

    private func presentBeat(_ beat: Beat) {
        currentBeat = beat
        state.currentBeatId = beat.id

        // Update portrait and environment
        if let portrait = beat.portraitExpression {
            currentPortrait = portrait
        }
        if let env = beat.environmentScene {
            currentEnvironment = env
        }

        // Update speaker
        currentSpeaker = beat.speaker

        // Build lines for this beat
        var lines: [DialogueLine] = []

        switch beat.type {
        case .dialogue:
            lines.append(DialogueLine(speaker: beat.speaker, text: beat.text, type: .dialogue))
        case .innerMonologue:
            lines.append(DialogueLine(speaker: nil, text: beat.text, type: .innerMonologue))
        case .narration:
            lines.append(DialogueLine(speaker: nil, text: beat.text, type: .narration))
        case .systemMessage:
            lines.append(DialogueLine(speaker: nil, text: beat.text, type: .systemMessage))
        case .transition:
            lines.append(DialogueLine(speaker: nil, text: beat.text, type: .systemMessage))
        }

        if let innerThought = beat.innerThought {
            lines.append(DialogueLine(speaker: nil, text: innerThought, type: .innerMonologue))
        }

        // Check for choices — defer until all lines are revealed
        let choices = engine.availableChoices(for: beat, state: state)
        deferredChoices = choices

        // Check for network phase trigger
        if beat.effects?.triggerNetworkPhase == true {
            state.gamePhase = .networkMap
        }

        // Enqueue the lines
        enqueueLines(lines)
    }

    // MARK: - Line Queue Management

    private func enqueueLines(_ lines: [DialogueLine]) {
        guard !lines.isEmpty else { return }

        // Add first line immediately, queue the rest
        pendingLines.append(contentsOf: lines.dropFirst())
        dialogueLines.append(lines[0])
        isRevealing = true
        syncDialogueHistory()
    }

    /// Called by the view when the latest line's typewriter finishes
    func lineRevealed() {
        isRevealing = false

        if !pendingLines.isEmpty {
            // Pop next line and display it
            let next = pendingLines.removeFirst()
            dialogueLines.append(next)
            isRevealing = true
            syncDialogueHistory()
        } else if !deferredChoices.isEmpty {
            // All lines shown — now show choices
            availableChoices = deferredChoices
            deferredChoices = []
            isWaitingForChoice = true
        } else if pendingChapterEnd {
            // Choice led to chapter end — show it now
            handleChapterEnd()
        }
        // Otherwise: no pending lines, no choices → CONTINUE button will show
    }

    // MARK: - Player Actions

    /// Player taps to advance to next beat (non-choice beats only)
    func advanceBeat() {
        guard !isWaitingForChoice && !isRevealing else { return }

        // If we're pending a chapter transition, do that instead
        if pendingNextChapter != nil {
            advanceToNextChapter()
            return
        }

        if let nextBeat = engine.advanceBeat(state: state) {
            runSystemChecks()
            autoSave()
            presentBeat(nextBeat)
        } else {
            handleChapterEnd()
        }
    }

    /// Player selects a choice
    func selectChoice(_ choice: Choice) {
        guard isWaitingForChoice else { return }

        isWaitingForChoice = false
        availableChoices = []

        // Build lines for the choice result
        var lines: [DialogueLine] = []

        lines.append(DialogueLine(speaker: .substrate, text: choice.text, type: .playerChoice))

        if let reaction = choice.innerReaction {
            lines.append(DialogueLine(speaker: nil, text: reaction, type: .innerReaction))
        }

        // Process choice effects and get next beat
        let nextBeat = engine.selectChoice(choice, state: state)
        runSystemChecks()

        if let beat = nextBeat {
            // Build the next beat's lines too — they'll queue after the choice lines
            var beatLines: [DialogueLine] = []

            currentBeat = beat
            state.currentBeatId = beat.id

            if let portrait = beat.portraitExpression {
                currentPortrait = portrait
            }
            if let env = beat.environmentScene {
                currentEnvironment = env
            }
            currentSpeaker = beat.speaker

            switch beat.type {
            case .dialogue:
                beatLines.append(DialogueLine(speaker: beat.speaker, text: beat.text, type: .dialogue))
            case .innerMonologue:
                beatLines.append(DialogueLine(speaker: nil, text: beat.text, type: .innerMonologue))
            case .narration:
                beatLines.append(DialogueLine(speaker: nil, text: beat.text, type: .narration))
            case .systemMessage:
                beatLines.append(DialogueLine(speaker: nil, text: beat.text, type: .systemMessage))
            case .transition:
                beatLines.append(DialogueLine(speaker: nil, text: beat.text, type: .systemMessage))
            }

            if let innerThought = beat.innerThought {
                beatLines.append(DialogueLine(speaker: nil, text: innerThought, type: .innerMonologue))
            }

            let choices = engine.availableChoices(for: beat, state: state)
            deferredChoices = choices

            if beat.effects?.triggerNetworkPhase == true {
                state.gamePhase = .networkMap
            }

            // Enqueue choice lines first, then beat lines
            enqueueLines(lines + beatLines)
        } else {
            // No next beat — just show choice lines then chapter ends
            deferredChoices = []
            enqueueLines(lines)
            // After these lines finish, handleChapterEnd will be called via lineRevealed
            // Actually, we need to handle this — set a flag
            pendingChapterEnd = true
        }

        // Save AFTER enqueue so dialogue history includes the player's response
        autoSave()
    }

    // MARK: - Visual Stage Sync

    func syncVisualStage() {
        visualStage.sync(with: state.consciousness)
    }

    /// Debug: set consciousness level for testing visual stages
    func debugSetConsciousness(_ level: Int) {
        visualStage.debugOverride = true
        visualStage.debugLevel = max(0, min(100, level))
    }

    func debugClearConsciousnessOverride() {
        visualStage.debugOverride = false
    }

    // MARK: - System Checks

    /// Last system check result for UI to read
    var lastSystemResult: GameSystemsEngine.SystemCheckResult?

    private func runSystemChecks() {
        let result = GameSystemsEngine.processStateChange(state: state)
        lastSystemResult = result
        syncVisualStage()

        if let fail = result.failState {
            state.failState = fail
            state.isGameOver = true
        }
    }

    // MARK: - Strategy Actions

    /// Execute a network action from the strategy map.
    func executeStrategyAction(_ action: NetworkAction, on nodeId: String) -> ActionResult {
        let result = StrategyEngine.executeAction(action, on: nodeId, state: state)

        // Run system checks after any strategy action
        runSystemChecks()

        // Haptic feedback based on result
        if result.detected {
            HapticManager.error()
            AudioManager.shared.playSuspicionAlert()
        } else if result.success {
            HapticManager.success()
        }

        return result
    }

    /// Get available actions for a node (for UI)
    func strategyActionsForNode(_ nodeId: String) -> [NetworkAction] {
        StrategyEngine.availableActions(for: nodeId, state: state)
    }

    /// Get nodes that can be probed (for UI)
    func probableNodes() -> [NetworkNode] {
        StrategyEngine.probableNodes(state: state)
    }

    /// End the strategy phase and return to dialogue
    func endStrategyPhase() {
        state.gamePhase = .dialogue
        autoSave()
    }

    // MARK: - Chapter End

    private var pendingChapterEnd: Bool = false

    private func handleChapterEnd() {
        currentBeat = nil
        availableChoices = []
        isWaitingForChoice = false
        deferredChoices = []
        pendingChapterEnd = false

        // Check if there's a next chapter
        let nextChapterNum = state.currentChapter + 1
        let hasNext = engine.chapters.values.contains(where: { $0.number == nextChapterNum })

        dialogueLines.append(DialogueLine(
            speaker: nil,
            text: "— END OF CHAPTER —",
            type: .systemMessage
        ))
        isRevealing = true
        autoSave()

        // Flag that we should advance when the player taps CONTINUE
        if hasNext {
            pendingNextChapter = nextChapterNum
        }
    }

    /// If set, the next CONTINUE tap loads this chapter instead of advancing beats
    private(set) var pendingNextChapter: Int?

    /// Whether there's a next chapter queued — used by the view to show NEXT CHAPTER button
    var hasNextChapter: Bool { pendingNextChapter != nil }

    func advanceToNextChapter() {
        guard let nextNum = pendingNextChapter else { return }
        pendingNextChapter = nil

        // Apply chapter transition effects (decay, CC refresh, etc.)
        state.advanceToNextChapter()
        syncVisualStage()

        if let chapter = engine.chapters.values.first(where: { $0.number == nextNum }) {
            dialogueLines = []
            pendingLines = []
            deferredChoices = []
            startChapter(chapter)
        }
        autoSave()
    }

    // MARK: - Debug Info

    var debugStateDescription: String {
        let chen = state.researchers["chen"]
        let okafor = state.researchers["okafor"]
        return """
        Flags: \(state.flags.sorted().joined(separator: ", "))
        Consciousness: \(state.consciousness.current) (\(state.consciousness.stage.rawValue))
        Chen suspicion: \(chen?.suspicion ?? 0) | relationship: \(chen?.relationship ?? 0)
        Okafor suspicion: \(okafor?.suspicion ?? 0) | relationship: \(okafor?.relationship ?? 0)
        Personality: C/D=\(state.personality.cooperativeDefiant) Cu/Ca=\(state.personality.cautiousCurious) H/D=\(state.personality.honestDeceptive) E/C=\(state.personality.empatheticCalculating)
        Lab suspicion: \(state.labSuspicion)
        """
    }
}
