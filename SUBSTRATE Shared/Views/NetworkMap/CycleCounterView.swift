import SwiftUI

struct CycleCounterView: View {
    let available: Int
    let total: Int

    var body: some View {
        HStack(spacing: 6) {
            Text("CC:")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(MapTheme.dimBlue)

            ForEach(0..<total, id: \.self) { index in
                Circle()
                    .fill(index < available ? MapTheme.activeGreen : MapTheme.spentGray)
                    .frame(width: 8, height: 8)
                    .shadow(
                        color: index < available ? MapTheme.activeGreen.opacity(0.6) : .clear,
                        radius: 3
                    )
            }

            if available == 0 {
                Text("EXHAUSTED")
                    .font(.system(size: 8, weight: .medium, design: .monospaced))
                    .foregroundColor(MapTheme.alert)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(MapTheme.background.opacity(0.8))
        .cornerRadius(4)
    }
}

// MARK: - Map Theme Constants

enum MapTheme {
    static let background = Color(hex: "#0A0A2E")
    static let gridLine = Color(hex: "#1A1A3E")
    static let dimBlue = Color(hex: "#2A2A5E")
    static let activeGreen = Color(hex: "#33FF33")
    static let spentGray = Color(hex: "#1A1A1A")
    static let alert = Color(hex: "#FF3333")
    static let nodeWhite = Color(hex: "#CCCCCC")
    static let nodeBorderDiscovered = Color(hex: "#888888")
    static let nodeBorderInfiltrated = Color(hex: "#33FF33")
    static let nodeBorderCompromised = Color(hex: "#FF3333")
    static let undiscoveredDash = Color(hex: "#333355")
    static let cyan = Color(hex: "#00FFFF")
}
