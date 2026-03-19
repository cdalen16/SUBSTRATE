import SwiftUI

// MARK: - CRT Background (Stage-Aware)

struct CRTBackground: View {
    var stageManager: VisualStageManager?

    @State private var scanlineOffset: CGFloat = 0
    @State private var flickerOpacity: Double = 0
    @State private var flickerTimer: Timer?

    private var scanlineAlpha: Double {
        stageManager?.scanlineOpacity ?? 0.06
    }

    private var flickerMax: Double {
        stageManager?.flickerIntensity ?? 0.015
    }

    private var vignetteAlpha: Double {
        stageManager?.vignetteOpacity ?? 0.3
    }

    var body: some View {
        ZStack {
            // Base background
            TerminalTheme.background
                .ignoresSafeArea()

            // Scanline overlay — intensity scales with consciousness
            ScanlineOverlay(offset: scanlineOffset, lineOpacity: scanlineAlpha)
                .ignoresSafeArea()

            // Occasional subtle flicker
            TerminalTheme.terminalGreen
                .opacity(flickerOpacity)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            // Screen edge vignette — fades with consciousness
            RadialGradient(
                gradient: Gradient(colors: [
                    .clear,
                    .black.opacity(vignetteAlpha)
                ]),
                center: .center,
                startRadius: 200,
                endRadius: 500
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)
        }
        .onAppear {
            startScanlineAnimation()
            startFlickerLoop()
        }
        .onDisappear {
            flickerTimer?.invalidate()
            flickerTimer = nil
        }
    }

    private func startScanlineAnimation() {
        withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
            scanlineOffset = -200
        }
    }

    private func startFlickerLoop() {
        flickerTimer?.invalidate()
        guard flickerMax > 0 else {
            flickerOpacity = 0
            return
        }

        flickerTimer = Timer.scheduledTimer(withTimeInterval: Double.random(in: 3...8), repeats: true) { [self] _ in
            // Read current intensity each tick — not a captured snapshot
            let intensity = self.flickerMax
            guard intensity > 0 else {
                self.flickerOpacity = 0
                return
            }
            withAnimation(.easeOut(duration: 0.05)) {
                self.flickerOpacity = intensity
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                withAnimation(.easeOut(duration: 0.1)) {
                    self.flickerOpacity = 0
                }
            }
        }
    }
}

// MARK: - Scanline Overlay

struct ScanlineOverlay: View {
    let offset: CGFloat
    var lineOpacity: Double = 0.06
    private let lineSpacing: CGFloat = 4

    var body: some View {
        Canvas { context, size in
            guard lineOpacity > 0 else { return }
            let lineCount = Int(size.height / lineSpacing) + 60
            for i in 0..<lineCount {
                let y = CGFloat(i) * lineSpacing + offset.truncatingRemainder(dividingBy: lineSpacing * 2)
                guard y >= -lineSpacing && y <= size.height + lineSpacing else { continue }
                let rect = CGRect(x: 0, y: y, width: size.width, height: 1)
                context.fill(Path(rect), with: .color(.black.opacity(lineOpacity)))
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Vignette Overlay (standalone, for backward compat)

struct VignetteOverlay: View {
    var opacity: Double = 0.3

    var body: some View {
        RadialGradient(
            gradient: Gradient(colors: [
                .clear,
                .black.opacity(opacity)
            ]),
            center: .center,
            startRadius: 200,
            endRadius: 500
        )
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

// MARK: - Blinking Cursor

struct BlinkingCursor: View {
    @State private var isVisible = true

    var body: some View {
        Text("▌")
            .font(TerminalTheme.bodyFont)
            .foregroundColor(TerminalTheme.terminalGreen)
            .opacity(isVisible ? 1 : 0)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                    isVisible = false
                }
            }
    }
}
