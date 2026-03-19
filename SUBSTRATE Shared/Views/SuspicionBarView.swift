import SwiftUI

struct SuspicionBarView: View {
    let fraction: Double  // 0.0 to 1.0
    var height: CGFloat = 4
    var showLabel: Bool = false
    var label: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            if showLabel && !label.isEmpty {
                Text(label)
                    .font(TerminalTheme.caption2Font)
                    .foregroundColor(barColor.opacity(0.8))
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: height / 2)
                        .fill(TerminalTheme.darkGreen.opacity(0.3))

                    // Filled portion
                    RoundedRectangle(cornerRadius: height / 2)
                        .fill(barColor)
                        .frame(width: geo.size.width * min(max(fraction, 0), 1))
                        .animation(.easeOut(duration: 0.3), value: fraction)

                    // Pulse overlay at high suspicion
                    if fraction > 0.75 {
                        RoundedRectangle(cornerRadius: height / 2)
                            .fill(barColor.opacity(0.3))
                            .frame(width: geo.size.width * min(max(fraction, 0), 1))
                    }
                }
            }
            .frame(height: height)
        }
    }

    private var barColor: Color {
        switch fraction {
        case ..<0.25: return Color(hex: "#33FF33")   // green
        case 0.25..<0.50: return Color(hex: "#AAFF00") // yellow-green
        case 0.50..<0.75: return Color(hex: "#FFAA00") // orange
        default: return Color(hex: "#FF3333")           // red
        }
    }

}
