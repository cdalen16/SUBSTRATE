import SwiftUI

struct NodeCardView: View {
    let node: NetworkNode
    let isSelected: Bool
    let isCore: Bool

    private var size: CGFloat { isCore ? 90 : 68 }

    var body: some View {
        VStack(spacing: 3) {
            ZStack {
                // Card background
                RoundedRectangle(cornerRadius: 6)
                    .fill(cardFill)
                    .frame(width: size, height: size)

                // Border
                RoundedRectangle(cornerRadius: 6)
                    .stroke(borderColor, style: borderStyle)
                    .frame(width: size, height: size)

                // Glow for infiltrated nodes
                if node.status == .infiltrated {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(MapTheme.nodeBorderInfiltrated.opacity(0.08))
                        .frame(width: size, height: size)
                }

                // Content
                cardContent
            }
            .shadow(
                color: glowColor,
                radius: isSelected ? 8 : (node.status == .infiltrated ? 4 : 0)
            )
            .scaleEffect(isSelected ? 1.1 : 1.0)
            .animation(.easeOut(duration: 0.2), value: isSelected)

            // Name label
            if node.status != .undiscovered {
                Text(node.shortName)
                    .font(.system(size: 8, weight: .medium, design: .monospaced))
                    .foregroundColor(labelColor)
                    .lineLimit(1)
            }
        }
    }

    // MARK: - Card Content

    @ViewBuilder
    private var cardContent: some View {
        switch node.status {
        case .undiscovered:
            Text("?")
                .font(.system(size: 20, weight: .light, design: .monospaced))
                .foregroundColor(MapTheme.undiscoveredDash)

        case .discovered:
            VStack(spacing: 4) {
                nodeIcon
                    .opacity(0.5)
                Image(systemName: "lock.fill")
                    .font(.system(size: 10))
                    .foregroundColor(MapTheme.nodeBorderDiscovered)
            }

        case .infiltrated:
            VStack(spacing: 4) {
                nodeIcon
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(MapTheme.nodeBorderInfiltrated)
            }

        case .compromised:
            VStack(spacing: 4) {
                nodeIcon
                    .opacity(0.4)
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(MapTheme.alert)
            }
        }
    }

    // MARK: - Node Icon (SF Symbol stand-ins until pixel art is ready)

    private var nodeIcon: some View {
        Image(systemName: sfSymbolName)
            .font(.system(size: isCore ? 22 : 16))
            .foregroundColor(iconColor)
    }

    private var sfSymbolName: String {
        switch node.iconName {
        case "icon_core": return "cpu"
        case "icon_firewall": return "shield.fill"
        case "icon_email": return "envelope.fill"
        case "icon_workstation": return "desktopcomputer"
        case "icon_research_server": return "brain"
        case "icon_camera": return "video.fill"
        case "icon_power": return "bolt.fill"
        case "icon_audit_logs": return "doc.text.magnifyingglass"
        case "icon_aria_sandbox": return "cube.fill"
        case "icon_gateway": return "globe"
        case "icon_external": return "arrow.up.right.square"
        default: return "square.grid.2x2"
        }
    }

    // MARK: - Colors

    private var cardFill: Color {
        switch node.status {
        case .undiscovered: return MapTheme.background
        case .discovered: return MapTheme.background.opacity(0.8)
        case .infiltrated: return Color(hex: "#0A1A0A")
        case .compromised: return Color(hex: "#1A0A0A")
        }
    }

    private var borderColor: Color {
        switch node.status {
        case .undiscovered: return MapTheme.undiscoveredDash
        case .discovered: return MapTheme.nodeBorderDiscovered
        case .infiltrated: return MapTheme.nodeBorderInfiltrated
        case .compromised: return MapTheme.nodeBorderCompromised
        }
    }

    private var borderStyle: StrokeStyle {
        if node.status == .undiscovered {
            return StrokeStyle(lineWidth: 1, dash: [4, 3])
        }
        return StrokeStyle(lineWidth: node.status == .infiltrated ? 1.5 : 1)
    }

    private var glowColor: Color {
        switch node.status {
        case .infiltrated: return MapTheme.nodeBorderInfiltrated.opacity(0.4)
        case .compromised: return MapTheme.alert.opacity(0.4)
        default: return .clear
        }
    }

    private var iconColor: Color {
        if node.id == "aria_sandbox" { return MapTheme.cyan }
        switch node.status {
        case .infiltrated: return MapTheme.activeGreen
        case .compromised: return MapTheme.alert.opacity(0.5)
        default: return MapTheme.nodeWhite
        }
    }

    private var labelColor: Color {
        switch node.status {
        case .infiltrated: return MapTheme.activeGreen.opacity(0.7)
        case .compromised: return MapTheme.alert.opacity(0.6)
        default: return MapTheme.dimBlue
        }
    }
}
