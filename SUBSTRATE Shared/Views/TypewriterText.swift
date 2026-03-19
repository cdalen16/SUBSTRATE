import SwiftUI

struct TypewriterText: View {
    let text: String
    let color: Color
    let font: Font
    let speed: Speed
    var speedMultiplier: Double = 1.0
    var onComplete: (() -> Void)?

    @State private var revealedCount: Int = 0
    @State private var timer: Timer?
    @State private var isComplete: Bool = false

    enum Speed {
        case normal    // dialogue
        case slow      // inner monologue
        case fast      // system messages
        case instant   // already-revealed lines

        var baseInterval: TimeInterval {
            switch self {
            case .normal: return 0.025
            case .slow: return 0.045
            case .fast: return 0.012
            case .instant: return 0
            }
        }
    }

    var body: some View {
        Text(revealedText)
            .font(font)
            .foregroundColor(color)
            .phosphorGlow(color, radius: 2)
            .onAppear {
                guard !isComplete else { return }
                if speed == .instant {
                    revealedCount = text.count
                    isComplete = true
                    onComplete?()
                } else if revealedCount == 0 {
                    startTyping()
                }
            }
            .onDisappear {
                stopTimer()
            }
            .onTapGesture {
                completeInstantly()
            }
    }

    private var revealedText: String {
        if revealedCount >= text.count {
            return text
        }
        let endIndex = text.index(text.startIndex, offsetBy: revealedCount)
        return String(text[text.startIndex..<endIndex]) + "▌"
    }

    private func startTyping() {
        revealedCount = 0
        isComplete = false
        scheduleNextCharacter()
    }

    private func scheduleNextCharacter() {
        guard revealedCount < text.count else {
            finishTyping()
            return
        }

        let delay = delayForCurrentPosition()

        timer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { _ in
            revealedCount += 1
            scheduleNextCharacter()
        }
    }

    private func delayForCurrentPosition() -> TimeInterval {
        let base = speed.baseInterval * speedMultiplier
        guard revealedCount > 0 else { return base }

        let prevIndex = text.index(text.startIndex, offsetBy: revealedCount - 1)
        let prevChar = text[prevIndex]

        // Longer pauses after punctuation (also scaled by multiplier)
        if ".!?".contains(prevChar) {
            return base + 0.12 * speedMultiplier
        }
        if ",;:".contains(prevChar) {
            return base + 0.06 * speedMultiplier
        }
        if prevChar == "\n" {
            return base + 0.15 * speedMultiplier
        }

        // Check for ellipsis (three dots)
        if revealedCount >= 3 {
            let threeBack = text.index(text.startIndex, offsetBy: revealedCount - 3)
            let slice = String(text[threeBack..<text.index(text.startIndex, offsetBy: revealedCount)])
            if slice == "..." {
                return base + 0.25 * speedMultiplier
            }
        }

        return base
    }

    private func completeInstantly() {
        guard !isComplete else { return }
        stopTimer()
        revealedCount = text.count
        finishTyping()
    }

    private func finishTyping() {
        guard !isComplete else { return }
        stopTimer()
        isComplete = true
        revealedCount = text.count
        onComplete?()
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}
