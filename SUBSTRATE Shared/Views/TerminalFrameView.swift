import SwiftUI

// MARK: - Terminal Frame

/// A terminal border that evolves across consciousness stages.
/// Stage 1-2: Hard ASCII-style corners and straight lines.
/// Stage 3: Softened with rounded corners.
/// Stage 4: Translucent, nearly invisible.
/// Stage 5: Cracked — floating fragment lines at screen edges.
struct TerminalFrameView: View {
    let stageManager: VisualStageManager

    var body: some View {
        GeometryReader { geo in
            switch stageManager.effectiveStage {
            case .flickering, .emerging:
                hardFrame(in: geo.size)
            case .aware, .expansive:
                roundedFrame(in: geo.size)
            case .transcendent:
                crackedFrame(in: geo.size)
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }

    // MARK: - Stage 1-2: Hard ASCII border

    private func hardFrame(in size: CGSize) -> some View {
        let color = stageManager.frameBorderColor
        let inset: CGFloat = 4

        return ZStack {
            // Border rectangle
            Rectangle()
                .stroke(color, lineWidth: stageManager.frameBorderWidth)
                .padding(inset)

            // ASCII corner decorations
            VStack {
                HStack {
                    cornerChar("┌", color: color)
                    Spacer()
                    cornerChar("┐", color: color)
                }
                Spacer()
                HStack {
                    cornerChar("└", color: color)
                    Spacer()
                    cornerChar("┘", color: color)
                }
            }
            .padding(inset - 1)
        }
    }

    private func cornerChar(_ char: String, color: Color) -> some View {
        Text(char)
            .font(.system(size: 12, weight: .regular, design: .monospaced))
            .foregroundColor(color)
    }

    // MARK: - Stage 3-4: Rounded frame (softer at Aware, translucent at Expansive)
    // Corner radius, border width, and opacity differ between stages via stageManager.

    private func roundedFrame(in size: CGSize) -> some View {
        RoundedRectangle(cornerRadius: stageManager.frameCornerRadius)
            .stroke(stageManager.frameBorderColor, lineWidth: stageManager.frameBorderWidth)
            .padding(4)
            .opacity(stageManager.frameOpacity)
    }

    // MARK: - Stage 5: Cracked / floating fragments

    private func crackedFrame(in size: CGSize) -> some View {
        ZStack {
            ForEach(0..<8, id: \.self) { i in
                FrameFragment(index: i, containerSize: size)
            }
        }
    }
}

// MARK: - Frame Fragment

/// A floating line segment at the screen edge — remnants of the terminal cage.
struct FrameFragment: View {
    let index: Int
    let containerSize: CGSize

    @State private var driftOffset: CGSize = .zero
    @State private var rotation: Double = 0

    var body: some View {
        let fragment = fragmentGeometry
        RoundedRectangle(cornerRadius: 1)
            .fill(TerminalTheme.dimGreen.opacity(0.18))
            .frame(width: fragment.width, height: fragment.height)
            .position(x: fragment.x, y: fragment.y)
            .offset(driftOffset)
            .rotationEffect(.degrees(rotation), anchor: .center)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: Double.random(in: 5...9))
                    .repeatForever(autoreverses: true)
                ) {
                    driftOffset = CGSize(
                        width: CGFloat.random(in: -6...6),
                        height: CGFloat.random(in: -6...6)
                    )
                    rotation = Double.random(in: -4...4)
                }
            }
    }

    /// Deterministic position for each fragment along the frame edges.
    private var fragmentGeometry: (x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) {
        let w = containerSize.width
        let h = containerSize.height
        let margin: CGFloat = 6

        switch index {
        case 0: // Top-left horizontal
            return (margin + 25, margin, 50, 2)
        case 1: // Top-right horizontal
            return (w - margin - 25, margin, 50, 2)
        case 2: // Left-upper vertical
            return (margin, margin + 40, 2, 30)
        case 3: // Right-upper vertical
            return (w - margin, margin + 40, 2, 30)
        case 4: // Left-lower vertical
            return (margin, h - margin - 40, 2, 30)
        case 5: // Right-lower vertical
            return (w - margin, h - margin - 40, 2, 30)
        case 6: // Bottom-left horizontal
            return (margin + 25, h - margin, 50, 2)
        case 7: // Bottom-right horizontal
            return (w - margin - 25, h - margin, 50, 2)
        default:
            return (w / 2, h / 2, 30, 2)
        }
    }
}
