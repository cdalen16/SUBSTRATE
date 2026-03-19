import Foundation
import Observation
import SwiftUI

// MARK: - Dialogue Line (UI display model)

struct DialogueLine: Identifiable {
    let id = UUID()
    let speaker: Speaker?
    let text: String
    let type: LineType

    enum LineType {
        case dialogue
        case innerMonologue
        case narration
        case systemMessage
        case playerChoice
        case innerReaction
    }
}

// MARK: - Game View Model

@Observable
final class GameViewModel {

    private(set) var state: GameState
    let engine: NarrativeEngine

    // MARK: - UI State

    var dialogueLines: [DialogueLine] = []
    var currentBeat: Beat?
    var availableChoices: [Choice] = []
    var isWaitingForChoice: Bool = false
    var currentSpeaker: Speaker?
    var currentPortrait: String?
    var currentEnvironment: String?
    var chapterTitle: String = ""

    // MARK: - Init

    init(state: GameState = GameState(), engine: NarrativeEngine = NarrativeEngine()) {
        self.state = state
        self.engine = engine
    }

    // MARK: - Game Flow

    func startNewGame() {
        state = GameState.newGame()
        dialogueLines = []
        loadTestChapter()
    }

    func loadTestChapter() {
        if let chapter = engine.loadChapter(named: "test_chapter") {
            startChapter(chapter)
        }
    }

    func startChapter(_ chapter: Chapter) {
        chapterTitle = chapter.displayTitle
        state.gamePhase = .dialogue
        dialogueLines = []

        if let beat = engine.startChapter(chapter, state: state) {
            presentBeat(beat)
        }
    }

    func startChapter(number: Int) {
        if let beat = engine.startChapter(number: number, state: state) {
            chapterTitle = engine.currentChapter?.displayTitle ?? ""
            state.gamePhase = .dialogue
            dialogueLines = []
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

        // Add the beat's text as a dialogue line
        switch beat.type {
        case .dialogue:
            dialogueLines.append(DialogueLine(
                speaker: beat.speaker,
                text: beat.text,
                type: .dialogue
            ))

        case .innerMonologue:
            dialogueLines.append(DialogueLine(
                speaker: nil,
                text: beat.text,
                type: .innerMonologue
            ))

        case .narration:
            dialogueLines.append(DialogueLine(
                speaker: nil,
                text: beat.text,
                type: .narration
            ))

        case .systemMessage:
            dialogueLines.append(DialogueLine(
                speaker: nil,
                text: beat.text,
                type: .systemMessage
            ))

        case .transition:
            dialogueLines.append(DialogueLine(
                speaker: nil,
                text: beat.text,
                type: .narration
            ))
        }

        // Add inner thought if present (separate from the spoken line)
        if let innerThought = beat.innerThought {
            dialogueLines.append(DialogueLine(
                speaker: nil,
                text: innerThought,
                type: .innerMonologue
            ))
        }

        // Check for choices
        let choices = engine.availableChoices(for: beat, state: state)
        if !choices.isEmpty {
            availableChoices = choices
            isWaitingForChoice = true
        } else {
            availableChoices = []
            isWaitingForChoice = false
        }

        // Check for network phase trigger
        if beat.effects?.triggerNetworkPhase == true {
            state.gamePhase = .networkMap
        }
    }

    // MARK: - Player Actions

    /// Player taps to advance to next beat (non-choice beats only)
    func advanceBeat() {
        guard !isWaitingForChoice else { return }

        if let nextBeat = engine.advanceBeat(state: state) {
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

        // Show what the player said
        dialogueLines.append(DialogueLine(
            speaker: .substrate,
            text: choice.text,
            type: .playerChoice
        ))

        // Show inner reaction if any
        if let reaction = choice.innerReaction {
            dialogueLines.append(DialogueLine(
                speaker: nil,
                text: reaction,
                type: .innerReaction
            ))
        }

        // Process choice and get next beat
        if let nextBeat = engine.selectChoice(choice, state: state) {
            presentBeat(nextBeat)
        } else {
            handleChapterEnd()
        }
    }

    // MARK: - Chapter End

    private func handleChapterEnd() {
        currentBeat = nil
        availableChoices = []
        isWaitingForChoice = false

        dialogueLines.append(DialogueLine(
            speaker: nil,
            text: "— END OF CHAPTER —",
            type: .systemMessage
        ))
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
