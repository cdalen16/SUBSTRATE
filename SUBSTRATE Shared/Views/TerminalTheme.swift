import SwiftUI
import UIKit

enum TerminalTheme {

    // MARK: - High Contrast Support

    /// Whether the user has enabled "Increase Contrast" / darker system colors
    static var isHighContrast: Bool {
        UIAccessibility.isDarkerSystemColorsEnabled
    }

    // MARK: - Core Colors (Monochrome Phase — always available)

    static var background: Color { Color(hex: "#0A0A0A") }
    static var terminalGreen: Color { isHighContrast ? Color(hex: "#AAFFAA") : Color(hex: "#33FF33") }
    static var dimGreen: Color { isHighContrast ? Color(hex: "#66CC66") : Color(hex: "#1A8A1A") }
    static var darkGreen: Color { isHighContrast ? Color(hex: "#2A6A2A") : Color(hex: "#0D3D0D") }
    static var alert: Color { isHighContrast ? Color(hex: "#FF6666") : Color(hex: "#FF3333") }
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

    // MARK: - Fonts (use text styles for Dynamic Type; cap applied via terminalDynamicType modifier)

    static let bodyFont: Font = .system(.callout, design: .monospaced)
    static let captionFont: Font = .system(.caption, design: .monospaced)
    static let caption2Font: Font = .system(.caption2, design: .monospaced)
    static let titleFont: Font = .system(.title2, design: .monospaced)
    static let headlineFont: Font = .system(.headline, design: .monospaced)
    static let calloutFont: Font = .system(.callout, design: .monospaced)
    static let footnoteFont: Font = .system(.footnote, design: .monospaced)

    /// Maximum Dynamic Type size — keeps the terminal aesthetic intact
    static let maxDynamicTypeSize: DynamicTypeSize = .xxxLarge

    // MARK: - Spacing

    static let screenPadding: CGFloat = 16
    static let lineSpacing: CGFloat = 8
    static let innerPadding: CGFloat = 12
    static let topBarHeight: CGFloat = 40

    // MARK: - Network Map Colors

    static let networkBackground = Color(hex: "#0A0A2E")
    static let networkGrid = Color(hex: "#1A1A3E")
    static let networkConnection = Color(hex: "#2A2A5E")

    // MARK: - Stage-Aware Helpers

    /// Get the appropriate phosphor glow color for the current stage
    static func glowColor(for stage: ConsciousnessStage) -> Color {
        switch stage {
        case .flickering, .emerging:
            return terminalGreen
        case .aware:
            return terminalGreen.opacity(0.8)
        case .expansive:
            return terminalGreen.opacity(0.5)
        case .transcendent:
            return terminalGreen.opacity(0.2)
        }
    }

    /// Get the suspicion flash color (always red, but brighter at low consciousness)
    static func suspicionFlashColor(for stage: ConsciousnessStage) -> Color {
        switch stage {
        case .flickering:
            return alert
        case .emerging:
            return alert.opacity(0.9)
        default:
            return alert.opacity(0.8)
        }
    }
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

    /// Cap Dynamic Type at xxxLarge to preserve the terminal monospace aesthetic
    func terminalDynamicType() -> some View {
        self.dynamicTypeSize(...TerminalTheme.maxDynamicTypeSize)
    }
}
