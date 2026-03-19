import SwiftUI

struct CRTBackground: View {
    @State private var scanlineOffset: CGFloat = 0
    @State private var flickerOpacity: Double = 0
    @State private var flickerTimer: Timer?

    var body: some View {
        ZStack {
            // Base background
            TerminalTheme.background
                .ignoresSafeArea()

            // Scanline overlay — horizontal lines scrolling upward
            ScanlineOverlay(offset: scanlineOffset)
                .ignoresSafeArea()

            // Occasional subtle flicker
            TerminalTheme.terminalGreen
                .opacity(flickerOpacity)
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
        flickerTimer = Timer.scheduledTimer(withTimeInterval: Double.random(in: 3...8), repeats: true) { _ in
            withAnimation(.easeOut(duration: 0.05)) {
                flickerOpacity = 0.015
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                withAnimation(.easeOut(duration: 0.1)) {
                    flickerOpacity = 0
                }
            }
        }
    }
}

// MARK: - Scanline Overlay

struct ScanlineOverlay: View {
    let offset: CGFloat
    private let lineSpacing: CGFloat = 4
    private let lineOpacity: Double = 0.06

    var body: some View {
        Canvas { context, size in
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

// MARK: - Screen Edge Vignette

struct VignetteOverlay: View {
    var body: some View {
        RadialGradient(
            gradient: Gradient(colors: [
                .clear,
                .black.opacity(0.3)
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
