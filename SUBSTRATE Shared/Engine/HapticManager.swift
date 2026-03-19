import UIKit

enum HapticManager {

    private static var enabled: Bool {
        UserDefaults.standard.object(forKey: "haptics_enabled") as? Bool ?? true
    }

    // MARK: - Standard Haptics

    /// Light tap — text advance, tap to continue
    static func lightTap() {
        guard enabled else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    /// Medium tap — choice selection
    static func mediumTap() {
        guard enabled else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    /// Heavy tap — suspicion alert
    static func heavyTap() {
        guard enabled else { return }
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    }

    /// Success pattern — two quick taps (strategy action complete)
    static func success() {
        guard enabled else { return }
        let gen = UIImpactFeedbackGenerator(style: .light)
        gen.impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            gen.impactOccurred()
        }
    }

    /// Error pattern — one long buzz (detection event)
    static func error() {
        guard enabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }

    // MARK: - Settings

    static func setEnabled(_ value: Bool) {
        UserDefaults.standard.set(value, forKey: "haptics_enabled")
    }

    static var isEnabled: Bool { enabled }
}
