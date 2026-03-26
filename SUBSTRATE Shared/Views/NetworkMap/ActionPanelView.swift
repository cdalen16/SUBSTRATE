import SwiftUI

struct ActionPanelView: View {
    let node: NetworkNode
    let actions: [NetworkAction]
    let probeTargets: [NetworkNode]
    let state: GameState
    var onAction: (NetworkAction, String) -> Void
    var onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Handle bar
            HStack {
                Spacer()
                RoundedRectangle(cornerRadius: 2)
                    .fill(MapTheme.dimBlue)
                    .frame(width: 40, height: 4)
                Spacer()
            }
            .padding(.top, 8)

            // Node info
            VStack(alignment: .leading, spacing: 4) {
                Text(node.name)
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(MapTheme.activeGreen)

                Text(node.description)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(MapTheme.dimBlue)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)

            // Discovered intel
            if node.status == .infiltrated {
                intelSection
            }

            // Action buttons
            VStack(spacing: 6) {
                // Regular actions for this node
                ForEach(actions, id: \.rawValue) { action in
                    actionButton(action: action, targetId: node.id)
                }

                // PROBE targets (undiscovered nodes adjacent to this one)
                if node.status == .infiltrated {
                    ForEach(probeTargets, id: \.id) { target in
                        actionButton(action: .probe, targetId: target.id, targetName: target.name)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)

            // Cancel
            Button(action: onDismiss) {
                Text("> CANCEL")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(MapTheme.dimBlue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 16)
        }
        .background(MapTheme.background)
        .overlay(
            Rectangle()
                .fill(MapTheme.dimBlue)
                .frame(height: 1),
            alignment: .top
        )
    }

    // MARK: - Intel Section

    private var intelSection: some View {
        let discovered = IntelDatabase.entriesForNode(node.id)
            .filter { state.discoveredIntel.contains($0.id) }

        return Group {
            if !discovered.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(discovered, id: \.id) { entry in
                        HStack(alignment: .top, spacing: 6) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 8))
                                .foregroundColor(MapTheme.activeGreen)
                                .padding(.top, 2)
                            Text(entry.title)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(MapTheme.activeGreen.opacity(0.7))
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
        }
    }

    // MARK: - Action Button

    private func actionButton(action: NetworkAction, targetId: String, targetName: String? = nil) -> some View {
        let cost = StrategyEngine.displayCost(for: action, nodeId: targetId, state: state)
        let risk = StrategyEngine.displayRisk(for: action, nodeId: targetId, state: state)
        let label = targetName.map { "\(action.displayName) → \($0)" } ?? action.displayName

        return Button {
            onAction(action, targetId)
        } label: {
            HStack {
                Text("> \(label)")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(MapTheme.activeGreen)

                Spacer()

                if cost > 0 {
                    Text("[\(cost) CC]")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(MapTheme.dimBlue)
                }

                // Risk indicator dot
                if risk > 0 {
                    Circle()
                        .fill(riskColor(risk))
                        .frame(width: 6, height: 6)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(MapTheme.dimBlue.opacity(0.5), lineWidth: 1)
            )
        }
        .accessibilityLabel(label)
        .accessibilityHint("Cost: \(cost) cycles")
    }

    private func riskColor(_ risk: Double) -> Color {
        switch risk {
        case ..<0.10: return MapTheme.activeGreen
        case 0.10..<0.20: return Color(hex: "#FFAA00")
        default: return MapTheme.alert
        }
    }
}
