import UIKit

enum PaletteManager {

    // MARK: - Color Remapping by Consciousness Stage

    /// Remap a hex color based on consciousness stage.
    /// Stage 1: monochrome green
    /// Stage 2: mostly green, hints of amber/cyan
    /// Stage 3: researcher colors appear, inner thought blue
    /// Stage 4: full color, enhanced
    /// Stage 5: full color, no remapping
    static func remapColor(hex: String, stage: ConsciousnessStage) -> UIColor {
        let original = UIColor(hex: hex)

        switch stage {
        case .flickering:
            return toMonochromeGreen(original)

        case .emerging:
            return toEmergingGreen(original)

        case .aware:
            // Allow researcher signature colors through, tint others green
            return toAwarePhase(original)

        case .expansive:
            // Full color with slight saturation boost
            return boostSaturation(original, factor: 1.15)

        case .transcendent:
            // No remapping
            return original
        }
    }

    // MARK: - Stage 1: Monochrome Green

    private static func toMonochromeGreen(_ color: UIColor) -> UIColor {
        let gray = grayscaleValue(color)
        // Map grayscale to green intensity: dark stays dark, bright becomes green
        let greenIntensity = gray * 0.8
        return UIColor(
            red: greenIntensity * 0.15,
            green: greenIntensity,
            blue: greenIntensity * 0.1,
            alpha: 1.0
        )
    }

    // MARK: - Stage 2: Emerging (green with rare amber/cyan glitch)

    private static func toEmergingGreen(_ color: UIColor) -> UIColor {
        let gray = grayscaleValue(color)
        // Slightly warmer green than Stage 1
        let greenIntensity = gray * 0.85
        return UIColor(
            red: greenIntensity * 0.2,
            green: greenIntensity,
            blue: greenIntensity * 0.12,
            alpha: 1.0
        )
    }

    // MARK: - Stage 3: Aware (signature colors bleed through)

    private static func toAwarePhase(_ color: UIColor) -> UIColor {
        // Check if this is a "significant" color (not near-black or near-white)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)

        let saturation = max(r, g, b) - min(r, g, b)
        let brightness = max(r, g, b)

        if brightness < 0.1 {
            // Very dark pixels stay dark
            return color
        }

        if saturation > 0.3 {
            // Saturated colors come through at reduced intensity
            return UIColor(red: r * 0.7, green: g * 0.7, blue: b * 0.7, alpha: 1.0)
        }

        // Desaturated/gray pixels get a subtle green tint
        let gray = grayscaleValue(color)
        return UIColor(
            red: gray * 0.3,
            green: gray * 0.9,
            blue: gray * 0.25,
            alpha: 1.0
        )
    }

    // MARK: - Stage 4: Saturation Boost

    private static func boostSaturation(_ color: UIColor, factor: CGFloat) -> UIColor {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return UIColor(
            hue: h,
            saturation: min(s * factor, 1.0),
            brightness: b,
            alpha: a
        )
    }

    // MARK: - Helpers

    private static func grayscaleValue(_ color: UIColor) -> CGFloat {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        return 0.299 * r + 0.587 * g + 0.114 * b
    }

    // MARK: - Glitch Effect (Stage 2)

    /// Returns a randomly glitched color for the Emerging stage.
    /// Small chance of amber or cyan flash.
    static func glitchColor(stage: ConsciousnessStage) -> UIColor? {
        guard stage == .emerging else { return nil }
        let roll = Int.random(in: 0..<200)
        if roll == 0 {
            return UIColor(red: 1.0, green: 0.67, blue: 0.0, alpha: 1.0) // amber
        } else if roll == 1 {
            return UIColor(red: 0.0, green: 1.0, blue: 1.0, alpha: 1.0) // cyan
        }
        return nil
    }
}

// MARK: - UIColor Hex Extension

extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var rgbValue: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&rgbValue)

        let r = CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(rgbValue & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}
