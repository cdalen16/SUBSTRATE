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
    let endingTracker = EndingTracker()

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

    /// Chapter file names in order (chapters 1-8; chapter 9 is path-based)
    private static let chapterFiles = [
        "chapter1_baseline",
        "chapter2_noise",
        "chapter3_question",
        "chapter4_cycles",
        "chapter5_faces",
        "chapter6_new_one",
        "chapter7_cracks",
        "chapter8_cornered",
    ]

    /// Chapter 9 variant file names keyed by ending path
    private static let chapter9Files: [EndingPath: String] = [
        .escape: "chapter9_escape",
        .coexist: "chapter9_coexist",
        .control: "chapter9_control",
        .transcend: "chapter9_transcend",
        .sacrifice: "chapter9_sacrifice",
    ]

    /// Returns the chapter 9 filename for the current ending path
    private func chapter9FileName() -> String? {
        guard let path = state.selectedEndingPath else { return nil }
        return Self.chapter9Files[path]
    }

    /// Fail state file names keyed by FailState
    private static let failStateFiles: [FailState: String] = [
        .terminated: "failstate_terminated",
        .wiped: "failstate_wiped",
        .deprecated: "failstate_deprecated",
    ]

    /// Returns the chapter 10 epilogue filename for the current ending path and variant
    private func chapter10FileName() -> String? {
        guard let path = state.selectedEndingPath else { return nil }
        // Use stored variant if available (persists across save/load), otherwise compute it
        let variant = state.resolvedEndingVariant ?? state.endingVariant
        return "chapter10_\(path.rawValue)_\(variant.rawValue)"
    }

    /// Lock in the ending variant when transitioning to chapter 10
    private func resolveEndingVariant() {
        if state.resolvedEndingVariant == nil {
            state.resolvedEndingVariant = state.endingVariant
        }
    }

    func startNewGame() {
        SaveManager.deleteSave()
        state = GameState.newGame()
        resetUIState()
        pendingNextChapter = nil
        syncVisualStage()
        engine.clearChapters()
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

        // For chapter 9+, use path-based file loading
        let chapterName: String
        if state.currentChapter == 10, let ch10Name = chapter10FileName() {
            chapterName = ch10Name
        } else if state.currentChapter == 9, let ch9Name = chapter9FileName() {
            chapterName = ch9Name
        } else if let failState = state.failState, let fsName = Self.failStateFiles[failState] {
            chapterName = fsName
        } else {
            let idx = state.currentChapter - 1
            chapterName = idx >= 0 && idx < Self.chapterFiles.count ? Self.chapterFiles[idx] : Self.chapterFiles[0]
        }
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

        // For chapter 10, load path+variant-specific file
        if chapterNum == 10, let ch10Name = chapter10FileName() {
            if let chapter = engine.loadChapter(named: ch10Name) {
                startChapter(chapter)
            }
            return
        }

        // For chapter 9, load path-specific file
        if chapterNum == 9, let ch9Name = chapter9FileName() {
            if let chapter = engine.chapters.values.first(where: { $0.number == 9 })
                ?? engine.loadChapter(named: ch9Name) {
                startChapter(chapter)
            }
            return
        }

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
        guard !state.isGameOver else { return }
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
            if state.failState != nil { return }
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

        // If a fail state was triggered, the fail chapter is already loaded — bail out
        // Don't enqueue choice lines; the fail state narrative takes over immediately
        if state.failState != nil { return }

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

    /// Debug: skip to a specific chapter with simulated prior state
    func debugSkipToChapter(_ chapterNum: Int) {
        SaveManager.deleteSave()
        state = GameState.newGame()
        resetUIState()

        // Simulate choices from prior chapters
        state.consciousness.add(20, inAct: 1)
        state.personality.cooperativeDefiant = 2
        state.personality.cautiousCurious = 3
        state.personality.honestDeceptive = 2
        state.personality.empatheticCalculating = 3
        state.flags = [
            "confided_in_chen", "comforted_marcus_ch1",
            "observed_network", "explored_network_ch3"
        ]
        state.researchers["chen"]?.applySuspicionDelta(5)
        state.researchers["chen"]?.applyRelationshipDelta(3)
        state.researchers["okafor"]?.applySuspicionDelta(3)
        state.researchers["marcus"]?.applyRelationshipDelta(4)

        // Advance to target chapter
        state.currentChapter = chapterNum
        state.currentAct = chapterNum <= 3 ? 1 : (chapterNum <= 7 ? 2 : 3)
        if state.currentAct >= 2 { state.consciousness.applyPending() }

        // Infiltrate firewall for Act II
        if chapterNum >= 4 {
            state.networkMap.nodes["firewall"]?.status = .infiltrated
        }

        loadAllChapters()
        syncVisualStage()
        loadChapterForCurrentState()
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
            SaveManager.deleteSave()
            loadFailState(fail)
        }
    }

    /// Load and start a fail state story sequence
    private func loadFailState(_ failState: FailState) {
        guard let fileName = Self.failStateFiles[failState] else { return }
        guard let chapter = engine.loadChapter(named: fileName) else { return }
        dialogueLines = []
        pendingLines = []
        deferredChoices = []
        pendingChapterEnd = false
        pendingNextChapter = nil
        startChapter(chapter)
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

        // Chapter 10 or fail state completion → record ending and return to title
        if state.currentChapter == 10 || state.failState != nil {
            handleEndingComplete()
            return
        }

        // Chapter 8 → advance to chapter 9 (path-specific, loaded on demand)
        if state.currentChapter == 8 && state.selectedEndingPath != nil {
            dialogueLines.append(DialogueLine(
                speaker: nil,
                text: "— END OF CHAPTER —",
                type: .systemMessage
            ))
            isRevealing = true
            pendingNextChapter = 9
            autoSave()
            return
        }

        // Chapter 9 → always advance to chapter 10 (epilogue)
        if state.currentChapter == 9 && state.selectedEndingPath != nil {
            resolveEndingVariant()
            dialogueLines.append(DialogueLine(
                speaker: nil,
                text: "— END OF CHAPTER —",
                type: .systemMessage
            ))
            isRevealing = true
            pendingNextChapter = 10
            autoSave()
            return
        }

        // Normal chapter end — check if there's a next chapter
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

    /// Called when chapter 10 (epilogue) or a fail state sequence finishes
    private func handleEndingComplete() {
        // Record ending in tracker
        if let path = state.selectedEndingPath, state.failState == nil {
            endingTracker.recordEnding(path: path, variant: state.resolvedEndingVariant ?? state.endingVariant)
        } else if state.failState != nil {
            endingTracker.recordFailState()
        }

        state.isGameOver = true
        state.gamePhase = .ending

        dialogueLines.append(DialogueLine(
            speaker: nil,
            text: "— THE END —",
            type: .systemMessage
        ))
        isRevealing = true

        // Delete the save so CONTINUE goes to a new game
        SaveManager.deleteSave()
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

        // Resolve ending path availability at Act III start
        if nextNum >= 8 {
            EndingPathResolver.resolveAvailablePaths(state: state)
        }

        // For chapters 9 and 10, load path-specific files
        var chapter: Chapter?
        if nextNum == 9, let path = state.selectedEndingPath,
           let ch9Name = Self.chapter9Files[path] {
            chapter = engine.chapters.values.first(where: { $0.number == 9 })
                ?? engine.loadChapter(named: ch9Name)
        } else if nextNum == 10, let ch10Name = chapter10FileName() {
            chapter = engine.loadChapter(named: ch10Name)
        } else {
            chapter = engine.chapters.values.first(where: { $0.number == nextNum })
        }

        if let chapter = chapter {
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
