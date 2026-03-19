import SwiftUI

// MARK: - Glitch Overlay

/// Random visual glitches that fire at Stage 2+ (Emerging onwards).
/// Includes amber/cyan word flashes, static noise bands, and screen distortion.
struct GlitchOverlay: View {
    let stageManager: VisualStageManager

    @State private var activeGlitch: GlitchType?
    @State private var glitchPosition: CGPoint = .zero
    @State private var glitchSize: CGSize = CGSize(width: 80, height: 16)
    @State private var noiseY: CGFloat = 100
    @State private var glitchTimer: Timer?
    @State private var containerSize: CGSize = CGSize(width: 400, height: 800)

    enum GlitchType {
        case amberFlash
        case cyanFlash
        case staticNoise
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                switch activeGlitch {
                case .amberFlash:
                    RoundedRectangle(cornerRadius: 2)
                        .fill(TerminalTheme.amber.opacity(0.35))
                        .frame(width: glitchSize.width, height: glitchSize.height)
                        .position(glitchPosition)

                case .cyanFlash:
                    RoundedRectangle(cornerRadius: 2)
                        .fill(TerminalTheme.cyan.opacity(0.25))
                        .frame(width: glitchSize.width, height: glitchSize.height)
                        .position(glitchPosition)

                case .staticNoise:
                    staticNoiseBand(in: geo.size)

                case nil:
                    EmptyView()
                }
            }
            .onAppear {
                containerSize = geo.size
            }
            .onChange(of: geo.size) {
                containerSize = geo.size
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
        .onAppear {
            startGlitchLoop()
        }
        .onDisappear {
            glitchTimer?.invalidate()
            glitchTimer = nil
        }
        .onChange(of: stageManager.effectiveStage) {
            glitchTimer?.invalidate()
            glitchTimer = nil
            activeGlitch = nil
            startGlitchLoop()
        }
    }

    // MARK: - Static Noise

    private func staticNoiseBand(in size: CGSize) -> some View {
        Canvas { context, canvasSize in
            let bandHeight: CGFloat = CGFloat.random(in: 3...10)
            for x in stride(from: 0, to: canvasSize.width, by: 2) {
                let brightness = Double.random(in: 0...0.12)
                let rect = CGRect(x: x, y: noiseY, width: 2, height: bandHeight)
                context.fill(Path(rect), with: .color(.white.opacity(brightness)))
            }
        }
    }

    // MARK: - Glitch Loop

    private func startGlitchLoop() {
        guard stageManager.glitchEnabled else { return }
        let range = stageManager.glitchInterval
        scheduleNext(in: Double.random(in: range))
    }

    private func scheduleNext(in interval: TimeInterval) {
        glitchTimer?.invalidate()
        glitchTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { _ in
            fireGlitch()
        }
    }

    private func fireGlitch() {
        guard stageManager.glitchEnabled else { return }

        let w = max(containerSize.width, 100)
        let h = max(containerSize.height, 200)

        // Random position
        glitchPosition = CGPoint(
            x: CGFloat.random(in: 30...(w - 30)),
            y: CGFloat.random(in: 80...(h - 80))
        )
        glitchSize = CGSize(
            width: CGFloat.random(in: 40...140),
            height: CGFloat.random(in: 14...20)
        )
        noiseY = CGFloat.random(in: 60...(h - 60))

        // Pick type weighted by stage
        let type: GlitchType
        switch stageManager.effectiveStage {
        case .emerging:
            type = [.amberFlash, .amberFlash, .staticNoise].randomElement()!
        case .aware:
            type = [.amberFlash, .cyanFlash, .staticNoise].randomElement()!
        default:
            type = [.staticNoise, .amberFlash].randomElement()!
        }

        // Flash on
        withAnimation(.easeIn(duration: 0.04)) {
            activeGlitch = type
        }

        // Flash off
        let duration = Double.random(in: 0.06...0.18)
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            withAnimation(.easeOut(duration: 0.06)) {
                activeGlitch = nil
            }
        }

        // Schedule next
        let range = stageManager.glitchInterval
        scheduleNext(in: Double.random(in: range))
    }
}

// MARK: - Screen Shift Effect

/// A brief horizontal screen-tear effect used during high-drama moments.
/// Can be triggered programmatically for narrative emphasis.
struct ScreenShiftModifier: ViewModifier {
    @State private var shiftOffset: CGFloat = 0
    var trigger: Bool = false

    func body(content: Content) -> some View {
        content
            .offset(x: shiftOffset)
            .onChange(of: trigger) {
                guard trigger else { return }
                // Quick shake
                withAnimation(.linear(duration: 0.03)) {
                    shiftOffset = CGFloat.random(in: 2...6)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) {
                    withAnimation(.linear(duration: 0.03)) {
                        shiftOffset = -CGFloat.random(in: 2...6)
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
                    withAnimation(.easeOut(duration: 0.05)) {
                        shiftOffset = 0
                    }
                }
            }
    }
}

extension View {
    func screenShift(trigger: Bool) -> some View {
        self.modifier(ScreenShiftModifier(trigger: trigger))
    }
}
