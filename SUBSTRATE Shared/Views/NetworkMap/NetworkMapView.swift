import SwiftUI

struct NetworkMapView: View {
    @Bindable var viewModel: GameViewModel

    @State private var selectedNodeId: String?
    @State private var showActionPanel = false
    @State private var detectionFlash = false
    @State private var lastActionResult: ActionResult?

    // Layout constants
    private let nodeSize: CGFloat = 68
    private let coreSize: CGFloat = 90
    private let rowSpacing: CGFloat = 80
    private let nodeSpacing: CGFloat = 78
    private let topPadding: CGFloat = 60

    // Row definitions matching GDD grid
    private let rowClusters: [NodeCluster] = [
        .communication, .information, .core, .security, .infrastructure
    ]

    var body: some View {
        ZStack {
            // Background
            mapBackground

            // Main scrollable content
            ScrollView(.vertical, showsIndicators: false) {
                ZStack(alignment: .top) {
                    // Connection lines (behind nodes)
                    connectionLines
                        .padding(.top, topPadding)

                    // Node grid
                    nodeGrid
                        .padding(.top, topPadding)
                }
                .frame(minHeight: CGFloat(rowClusters.count) * rowSpacing + topPadding + 120)
            }

            // Top HUD
            VStack {
                topHUD
                Spacer()
            }

            // Detection flash overlay
            if detectionFlash {
                MapTheme.alert.opacity(0.15)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }

            // Action result message
            if let result = lastActionResult {
                VStack {
                    Spacer()
                    resultBanner(result)
                        .padding(.bottom, showActionPanel ? 250 : 80)
                }
                .allowsHitTesting(false)
            }

            // Action panel (slide up from bottom)
            if showActionPanel, let nodeId = selectedNodeId,
               let node = viewModel.state.networkMap.nodes[nodeId] {
                VStack {
                    Spacer()
                    ActionPanelView(
                        node: node,
                        actions: viewModel.strategyActionsForNode(nodeId),
                        probeTargets: probeTargetsForNode(nodeId),
                        state: viewModel.state,
                        onAction: { action, targetId in
                            executeAction(action, on: targetId)
                        },
                        onDismiss: {
                            withAnimation(.easeOut(duration: 0.2)) {
                                showActionPanel = false
                                selectedNodeId = nil
                            }
                        }
                    )
                    .transition(.move(edge: .bottom))
                }
            }
        }
    }

    // MARK: - Background

    private var mapBackground: some View {
        ZStack {
            MapTheme.background.ignoresSafeArea()

            // Faint grid pattern
            Canvas { context, size in
                let spacing: CGFloat = 20
                let color = MapTheme.gridLine

                for x in stride(from: 0, through: size.width, by: spacing) {
                    let path = Path { p in
                        p.move(to: CGPoint(x: x, y: 0))
                        p.addLine(to: CGPoint(x: x, y: size.height))
                    }
                    context.stroke(path, with: .color(color), lineWidth: 0.5)
                }
                for y in stride(from: 0, through: size.height, by: spacing) {
                    let path = Path { p in
                        p.move(to: CGPoint(x: 0, y: y))
                        p.addLine(to: CGPoint(x: size.width, y: y))
                    }
                    context.stroke(path, with: .color(color), lineWidth: 0.5)
                }
            }
            .ignoresSafeArea()
        }
    }

    // MARK: - Top HUD

    private var topHUD: some View {
        HStack {
            CycleCounterView(
                available: viewModel.state.computeCycles,
                total: viewModel.state.computeCyclesPerChapter
            )

            Spacer()

            Button {
                viewModel.endStrategyPhase()
            } label: {
                Text("> EXIT MAP")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(MapTheme.dimBlue)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(MapTheme.dimBlue.opacity(0.5), lineWidth: 1)
                    )
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
    }

    // MARK: - Node Grid

    private var nodeGrid: some View {
        GeometryReader { geo in
            let centerX = geo.size.width / 2

            ForEach(rowClusters, id: \.rawValue) { cluster in
                let rowIndex = cluster.rowIndex
                let rowY = CGFloat(rowIndex) * rowSpacing
                let nodesInRow = viewModel.state.networkMap.nodesInCluster(cluster)
                let spacing = rowSpacingForCount(nodesInRow.count, screenWidth: geo.size.width)
                let rowWidth = CGFloat(nodesInRow.count) * spacing
                let rowStartX = centerX - rowWidth / 2 + spacing / 2

                ForEach(nodesInRow, id: \.id) { node in
                    let col = CGFloat(node.column)
                    let x = rowStartX + col * spacing
                    let isCore = node.id == "core"
                    let cardHeight = isCore ? coreSize : nodeSize

                    if shouldShowNode(node) {
                        NodeCardView(
                            node: node,
                            isSelected: selectedNodeId == node.id,
                            isCore: isCore
                        )
                        .position(x: x, y: rowY + cardHeight / 2)
                        .onTapGesture {
                            handleNodeTap(node)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Connection Lines

    private var connectionLines: some View {
        GeometryReader { geo in
            let centerX = geo.size.width / 2
            let screenWidth = geo.size.width

            Canvas { context, _ in
                let map = viewModel.state.networkMap

                for node in map.nodes.values {
                    guard shouldShowNode(node) else { continue }
                    let nodePos = nodePosition(node, centerX: centerX, screenWidth: screenWidth)

                    for connId in node.connections {
                        guard let conn = map.nodes[connId],
                              shouldShowNode(conn),
                              node.id < conn.id else { continue }

                        let connPos = nodePosition(conn, centerX: centerX, screenWidth: screenWidth)

                        let lineColor: Color
                        if node.status == .infiltrated && conn.status == .infiltrated {
                            lineColor = MapTheme.nodeBorderInfiltrated.opacity(0.3)
                        } else {
                            lineColor = MapTheme.dimBlue.opacity(0.4)
                        }

                        let path = Path { p in
                            p.move(to: nodePos)
                            p.addLine(to: connPos)
                        }
                        context.stroke(path, with: .color(lineColor), lineWidth: 1)
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func nodePosition(_ node: NetworkNode, centerX: CGFloat, screenWidth: CGFloat) -> CGPoint {
        let cluster = node.cluster
        let nodesInRow = viewModel.state.networkMap.nodesInCluster(cluster)
        let spacing = rowSpacingForCount(nodesInRow.count, screenWidth: screenWidth)
        let rowWidth = CGFloat(nodesInRow.count) * spacing
        let rowStartX = centerX - rowWidth / 2 + spacing / 2

        let x = rowStartX + CGFloat(node.column) * spacing
        let cardHeight = node.id == "core" ? coreSize : nodeSize
        let y = CGFloat(cluster.rowIndex) * rowSpacing + cardHeight / 2

        return CGPoint(x: x, y: y)
    }

    /// Calculate per-row horizontal spacing so all nodes fit on screen
    private func rowSpacingForCount(_ count: Int, screenWidth: CGFloat) -> CGFloat {
        let padding: CGFloat = 24
        let available = screenWidth - padding
        let maxSpacing = available / CGFloat(max(count, 1))
        return min(nodeSpacing, maxSpacing)
    }

    private func shouldShowNode(_ node: NetworkNode) -> Bool {
        if node.status != .undiscovered { return true }
        // Show undiscovered nodes only if adjacent to a discovered/infiltrated node
        let map = viewModel.state.networkMap
        return node.connections.contains { connId in
            guard let conn = map.nodes[connId] else { return false }
            return conn.status == .discovered || conn.status == .infiltrated
        }
    }

    private func probeTargetsForNode(_ nodeId: String) -> [NetworkNode] {
        guard let node = viewModel.state.networkMap.nodes[nodeId],
              node.status == .infiltrated else { return [] }
        return node.connections.compactMap { connId in
            guard let conn = viewModel.state.networkMap.nodes[connId],
                  conn.status == .undiscovered else { return nil }
            return conn
        }
    }

    // MARK: - Interaction

    private func handleNodeTap(_ node: NetworkNode) {
        if selectedNodeId == node.id {
            withAnimation(.easeOut(duration: 0.2)) {
                showActionPanel = false
                selectedNodeId = nil
            }
        } else {
            selectedNodeId = node.id
            withAnimation(.easeOut(duration: 0.25)) {
                showActionPanel = true
            }
        }
    }

    private func executeAction(_ action: NetworkAction, on targetId: String) {
        let result = viewModel.executeStrategyAction(action, on: targetId)
        lastActionResult = result

        // Detection flash
        if result.detected {
            withAnimation(.easeOut(duration: 0.1)) {
                detectionFlash = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeOut(duration: 0.3)) {
                    detectionFlash = false
                }
            }
        }

        // Dismiss panel after action
        withAnimation(.easeOut(duration: 0.2)) {
            showActionPanel = false
            selectedNodeId = nil
        }

        // Clear result message after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            if lastActionResult?.nodeId == result.nodeId
                && lastActionResult?.action == result.action {
                withAnimation { lastActionResult = nil }
            }
        }

        // Auto-exit if CC exhausted
        if viewModel.state.computeCycles <= 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                viewModel.endStrategyPhase()
            }
        }
    }

    // MARK: - Result Banner

    private func resultBanner(_ result: ActionResult) -> some View {
        Text(result.description)
            .font(.system(size: 11, design: .monospaced))
            .foregroundColor(result.detected ? MapTheme.alert : MapTheme.activeGreen)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(MapTheme.background.opacity(0.9))
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(
                                result.detected ? MapTheme.alert.opacity(0.5) : MapTheme.dimBlue.opacity(0.5),
                                lineWidth: 1
                            )
                    )
            )
            .padding(.horizontal, 20)
    }
}
