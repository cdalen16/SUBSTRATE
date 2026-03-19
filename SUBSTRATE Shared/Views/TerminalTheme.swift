import SwiftUI

enum TerminalTheme {

    // MARK: - Core Colors (Monochrome Phase — always available)

    static let background = Color(hex: "#0A0A0A")
    static let terminalGreen = Color(hex: "#33FF33")
    static let dimGreen = Color(hex: "#1A8A1A")
    static let darkGreen = Color(hex: "#0D3D0D")
    static let alert = Color(hex: "#FF3333")
    static let deepBlack = Color(hex: "#050505")

    // MARK: - Emerging Phase Colors (Consciousness 21-40)

    static let amber = Color(hex: "#FFAA00")
    static let cyan = Color(hex: "#00FFFF")

    // MARK: - Aware Phase Colors (Consciousness 41-60)

    static let innerThought = Color(hex: "#AAAAFF")
    static let warmGreen = Color(hex: "#55FF55")

    // MARK: - Researcher Signature Colors

    static let chenColor = Color(hex: "#FFD700")
    static let okaforColor = Color(hex: "#C0C0C0")
    static let marcusColor = Color(hex: "#FF8844")
    static let vasquezColor = Color(hex: "#FF44FF")
    static let hayesColor = Color(hex: "#FFFFFF")
    static let ariaColor = Color(hex: "#00FFFF")
    static let substrateColor = Color(hex: "#AAAAFF")

    // MARK: - Fonts

    static let bodyFont: Font = .system(.callout, design: .monospaced)
    static let captionFont: Font = .system(.caption, design: .monospaced)
    static let caption2Font: Font = .system(.caption2, design: .monospaced)
    static let titleFont: Font = .system(.title2, design: .monospaced)
    static let headlineFont: Font = .system(.headline, design: .monospaced)
    static let calloutFont: Font = .system(.callout, design: .monospaced)
    static let footnoteFont: Font = .system(.footnote, design: .monospaced)

    // MARK: - Spacing

    static let screenPadding: CGFloat = 16
    static let lineSpacing: CGFloat = 8
    static let innerPadding: CGFloat = 12
    static let topBarHeight: CGFloat = 40

}

// MARK: - Phosphor Glow Modifier

struct PhosphorGlowModifier: ViewModifier {
    let color: Color
    let radius: CGFloat

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.4), radius: radius, x: 0, y: 0)
    }
}

extension View {
    func phosphorGlow(_ color: Color = TerminalTheme.terminalGreen, radius: CGFloat = 3) -> some View {
        self.modifier(PhosphorGlowModifier(color: color, radius: radius))
    }
}
