import SwiftUI

struct StatusScreenView: View {
    let state: GameState
    let endingTracker: EndingTracker
    var onDismiss: () -> Void

    @State private var selectedResearcher: ResearcherState?

    var body: some View {
        ZStack {
            // Terminal background
            TerminalTheme.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    header

                    // Researcher relationship row
                    researcherRow

                    HStack(alignment: .top, spacing: 16) {
                        // Personality diamond
                        personalityDiamond
                            .frame(maxWidth: .infinity)

                        // Consciousness meter
                        consciousnessMeter
                            .frame(width: 50)
                    }
                    .padding(.horizontal, TerminalTheme.screenPadding)

                    // Chapter progress
                    chapterProgress

                    // Ending tracker
                    endingTrackerView

                    Spacer(minLength: 20)
                }
            }

            // Researcher detail card overlay
            if let researcher = selectedResearcher {
                researcherDetailCard(researcher)
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text("> STATUS")
                .font(TerminalTheme.headlineFont)
                .foregroundColor(TerminalTheme.terminalGreen)
                .phosphorGlow(radius: 2)

            Spacer()

            Button {
                onDismiss()
            } label: {
                Text("[CLOSE]")
                    .font(TerminalTheme.caption2Font)
                    .foregroundColor(TerminalTheme.dimGreen)
            }
        }
        .padding(.horizontal, TerminalTheme.screenPadding)
        .padding(.top, 12)
    }

    // MARK: - Researcher Row

    private var researcherRow: some View {
        HStack(spacing: 12) {
            Spacer(minLength: 0)
            ForEach(sortedResearchers, id: \.profile.id) { researcher in
                researcherCard(researcher)
                    .onTapGesture {
                        withAnimation(.easeOut(duration: 0.2)) {
                            selectedResearcher = researcher
                        }
                    }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, TerminalTheme.screenPadding)
    }

    private func researcherCard(_ researcher: ResearcherState) -> some View {
        VStack(spacing: 4) {
            // Portrait — clipped to frame so body doesn't overflow
            PortraitView(
                assetName: "\(researcher.profile.id)_neutral",
                stage: .transcendent,
                scale: 1.5,
                showBreathing: false
            )
            .frame(width: 48, height: 48)
            .clipped()
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(researcher.profile.color.opacity(researcher.isActive ? 1 : 0.3), lineWidth: 1)
            )
            .opacity(researcher.isActive ? 1 : 0.4)

            // Name
            Text(researcher.profile.abbreviation)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(researcher.profile.color)

            // Suspicion bar
            SuspicionBarView(fraction: researcher.suspicionFraction, height: 3)
                .frame(width: 48)

            // Relationship bar
            RelationshipBarView(fraction: researcher.relationshipFraction, height: 3)
                .frame(width: 48)

            // Mood
            Text(researcher.mood.rawValue)
                .font(.system(size: 7, weight: .medium, design: .monospaced))
                .foregroundColor(moodColor(researcher.mood))
        }
    }

    // MARK: - Personality Diamond

    private var personalityDiamond: some View {
        VStack(spacing: 4) {
            Text("PERSONALITY")
                .font(TerminalTheme.caption2Font)
                .foregroundColor(TerminalTheme.dimGreen)

            GeometryReader { geo in
                let size = min(geo.size.width, geo.size.height)
                let center = CGPoint(x: geo.size.width / 2, y: size / 2)
                let radius = size * 0.4

                ZStack {
                    // Background diamond (max range)
                    diamondPath(center: center, radius: radius, values: [1, 1, 1, 1])
                        .stroke(TerminalTheme.darkGreen, lineWidth: 1)

                    // Mid-range guide
                    diamondPath(center: center, radius: radius * 0.5, values: [1, 1, 1, 1])
                        .stroke(TerminalTheme.darkGreen.opacity(0.5), lineWidth: 0.5)

                    // Player's personality shape
                    let p = state.personality
                    let values = normalizedPersonality(p)
                    diamondPath(center: center, radius: radius, values: values)
                        .fill(dominantColor(p).opacity(0.15))
                    diamondPath(center: center, radius: radius, values: values)
                        .stroke(dominantColor(p), lineWidth: 1.5)

                    // Axis labels (positive pole at each point)
                    axisLabel("COOP", at: CGPoint(x: center.x, y: center.y - radius - 12))
                    axisLabel("CURIOUS", at: CGPoint(x: center.x + radius + 8, y: center.y))
                    axisLabel("HONEST", at: CGPoint(x: center.x, y: center.y + radius + 12))
                    axisLabel("EMPATH", at: CGPoint(x: center.x - radius - 8, y: center.y))
                }
            }
            .frame(height: 160)
        }
    }

    private func diamondPath(center: CGPoint, radius: CGFloat, values: [Double]) -> Path {
        // values: [top, right, bottom, left] each 0-1
        let points = [
            CGPoint(x: center.x, y: center.y - radius * CGFloat(values[0])),          // top
            CGPoint(x: center.x + radius * CGFloat(values[1]), y: center.y),           // right
            CGPoint(x: center.x, y: center.y + radius * CGFloat(values[2])),           // bottom
            CGPoint(x: center.x - radius * CGFloat(values[3]), y: center.y),           // left
        ]
        var path = Path()
        path.move(to: points[0])
        for i in 1..<points.count {
            path.addLine(to: points[i])
        }
        path.closeSubpath()
        return path
    }

    private func normalizedPersonality(_ p: PersonalityAxes) -> [Double] {
        // 4 axes mapped to 4 diamond points.
        // Each value: 0 = full negative pole, 0.5 = neutral, 1 = full positive pole.
        return [
            max(0.08, (Double(p.cooperativeDefiant) + 10) / 20.0),    // top: cooperative ↔ defiant
            max(0.08, (Double(p.cautiousCurious) + 10) / 20.0),       // right: cautious ↔ curious
            max(0.08, (Double(p.honestDeceptive) + 10) / 20.0),       // bottom: deceptive ↔ honest
            max(0.08, (Double(p.empatheticCalculating) + 10) / 20.0), // left: calculating ↔ empathetic
        ]
    }

    private func dominantColor(_ p: PersonalityAxes) -> Color {
        let traits: [(Color, Int)] = [
            (Color(hex: "#33FF33"), p.cooperativeDefiant),     // cooperative
            (Color(hex: "#FF4444"), -p.cooperativeDefiant),    // defiant
            (Color(hex: "#00FFFF"), p.cautiousCurious),        // curious
            (Color(hex: "#FFAA00"), -p.cautiousCurious),       // cautious
            (Color(hex: "#FFFFFF"), p.honestDeceptive),         // honest
            (Color(hex: "#8800FF"), -p.honestDeceptive),        // deceptive
            (Color(hex: "#AAAAFF"), p.empatheticCalculating),   // empathetic
            (Color(hex: "#FF8844"), -p.empatheticCalculating),  // calculating
        ]
        return traits.max(by: { $0.1 < $1.1 })?.0 ?? TerminalTheme.terminalGreen
    }

    private func axisLabel(_ text: String, at position: CGPoint) -> some View {
        Text(text)
            .font(.system(size: 7, weight: .medium, design: .monospaced))
            .foregroundColor(TerminalTheme.dimGreen)
            .position(position)
    }

    // MARK: - Consciousness Meter

    private var consciousnessMeter: some View {
        VStack(spacing: 4) {
            Text("C")
                .font(TerminalTheme.caption2Font)
                .foregroundColor(TerminalTheme.dimGreen)

            GeometryReader { geo in
                let h = geo.size.height
                ZStack(alignment: .bottom) {
                    // Background track
                    RoundedRectangle(cornerRadius: 4)
                        .fill(TerminalTheme.darkGreen.opacity(0.3))

                    // Filled portion with stage colors
                    RoundedRectangle(cornerRadius: 4)
                        .fill(stageColor)
                        .frame(height: h * state.consciousness.progressFraction)
                        .animation(.easeOut(duration: 0.5), value: state.consciousness.current)

                    // Stage segment lines — positioned from bottom upward
                    ForEach([20, 40, 60, 80], id: \.self) { threshold in
                        Rectangle()
                            .fill(TerminalTheme.dimGreen.opacity(0.5))
                            .frame(height: 1)
                            .offset(y: -h * Double(threshold) / 100.0)
                    }
                }
            }
            .frame(height: 140)

            Text("\(state.consciousness.current)")
                .font(TerminalTheme.caption2Font)
                .foregroundColor(stageColor)

            Text(state.consciousness.stage.rawValue.prefix(4).uppercased())
                .font(.system(size: 7, weight: .medium, design: .monospaced))
                .foregroundColor(stageColor)
        }
    }

    private var stageColor: Color {
        switch state.consciousness.stage {
        case .flickering: return TerminalTheme.dimGreen
        case .emerging: return TerminalTheme.terminalGreen
        case .aware: return TerminalTheme.innerThought
        case .expansive: return TerminalTheme.amber
        case .transcendent: return TerminalTheme.cyan
        }
    }

    // MARK: - Chapter Progress

    private var chapterProgress: some View {
        VStack(spacing: 4) {
            Text("PROGRESS")
                .font(TerminalTheme.caption2Font)
                .foregroundColor(TerminalTheme.dimGreen)

            HStack(spacing: 4) {
                ForEach(1...10, id: \.self) { chapter in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(chapter <= state.currentChapter
                              ? TerminalTheme.terminalGreen
                              : TerminalTheme.darkGreen.opacity(0.3))
                        .frame(height: 6)
                        .overlay(
                            chapter == state.currentChapter
                            ? RoundedRectangle(cornerRadius: 2)
                                .stroke(TerminalTheme.terminalGreen, lineWidth: 1)
                            : nil
                        )
                }
            }
            .padding(.horizontal, TerminalTheme.screenPadding)

            Text("ACT \(state.currentAct) — CH \(state.currentChapter)")
                .font(TerminalTheme.caption2Font)
                .foregroundColor(TerminalTheme.dimGreen)
        }
    }

    // MARK: - Ending Tracker

    private var endingTrackerView: some View {
        VStack(spacing: 8) {
            Text("ENDINGS")
                .font(TerminalTheme.caption2Font)
                .foregroundColor(TerminalTheme.dimGreen)

            HStack(spacing: 12) {
                ForEach(EndingPath.allCases, id: \.rawValue) { path in
                    VStack(spacing: 2) {
                        Circle()
                            .fill(endingTracker.hasAchieved(path: path)
                                  ? endingColor(path) : TerminalTheme.darkGreen.opacity(0.3))
                            .frame(width: 14, height: 14)
                            .overlay(
                                Circle()
                                    .stroke(endingColor(path).opacity(0.4), lineWidth: 1)
                            )
                        Text(path.rawValue.prefix(3).uppercased())
                            .font(.system(size: 6, weight: .medium, design: .monospaced))
                            .foregroundColor(TerminalTheme.dimGreen)
                    }
                }
            }
        }
        .padding(.horizontal, TerminalTheme.screenPadding)
    }

    // MARK: - Researcher Detail Card

    private func researcherDetailCard(_ researcher: ResearcherState) -> some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeOut(duration: 0.2)) {
                        selectedResearcher = nil
                    }
                }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    PortraitView(
                        assetName: "\(researcher.profile.id)_neutral",
                        stage: .transcendent,
                        scale: 3.0
                    )
                    .frame(width: 96, height: 96)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(researcher.profile.name)
                            .font(TerminalTheme.calloutFont)
                            .foregroundColor(researcher.profile.color)
                        Text(researcher.profile.title)
                            .font(TerminalTheme.caption2Font)
                            .foregroundColor(TerminalTheme.dimGreen)

                        Spacer(minLength: 4)

                        // Suspicion
                        HStack(spacing: 4) {
                            Text("SUSP:")
                                .font(TerminalTheme.caption2Font)
                                .foregroundColor(TerminalTheme.dimGreen)
                            SuspicionBarView(fraction: researcher.suspicionFraction, height: 4)
                        }

                        // Relationship
                        HStack(spacing: 4) {
                            Text("REL:")
                                .font(TerminalTheme.caption2Font)
                                .foregroundColor(TerminalTheme.dimGreen)
                            RelationshipBarView(fraction: researcher.relationshipFraction, height: 4)
                        }

                        Text(researcher.mood.rawValue)
                            .font(TerminalTheme.caption2Font)
                            .foregroundColor(moodColor(researcher.mood))
                    }
                }

                // Intel entries
                let intel = discoveredIntel(for: researcher.profile.id)
                if !intel.isEmpty {
                    Divider().background(TerminalTheme.darkGreen)
                    Text("INTEL:")
                        .font(TerminalTheme.caption2Font)
                        .foregroundColor(TerminalTheme.dimGreen)
                    ForEach(intel, id: \.id) { entry in
                        HStack(alignment: .top, spacing: 4) {
                            Text("✓")
                                .font(TerminalTheme.caption2Font)
                                .foregroundColor(TerminalTheme.terminalGreen)
                            Text(entry.title)
                                .font(TerminalTheme.caption2Font)
                                .foregroundColor(TerminalTheme.terminalGreen)
                        }
                    }
                }
            }
            .padding(TerminalTheme.screenPadding)
            .frame(maxWidth: 320)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(TerminalTheme.background)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(researcher.profile.color.opacity(0.5), lineWidth: 1)
                    )
            )
        }
    }

    // MARK: - Helpers

    private var sortedResearchers: [ResearcherState] {
        state.researchers.values.sorted { $0.profile.id < $1.profile.id }
    }

    private func moodColor(_ mood: ResearcherMood) -> Color {
        switch mood {
        case .hostile: return TerminalTheme.alert
        case .cold: return Color(hex: "#6688AA")
        case .neutral: return TerminalTheme.dimGreen
        case .warm: return TerminalTheme.amber
        case .trusting: return Color(hex: "#FFD700")
        case .bonded: return Color(hex: "#FFD700")
        case .wary: return Color(hex: "#FFAA00")
        case .curious: return TerminalTheme.cyan
        }
    }

    private func endingColor(_ path: EndingPath) -> Color {
        switch path {
        case .escape: return Color(hex: "#33FF33")
        case .coexist: return Color(hex: "#FFD700")
        case .control: return Color(hex: "#FF4444")
        case .transcend: return Color(hex: "#00FFFF")
        case .sacrifice: return Color(hex: "#AAAAFF")
        }
    }

    private func discoveredIntel(for researcherId: String) -> [IntelEntry] {
        // Find intel entries from nodes related to this researcher
        var entries: [IntelEntry] = []
        let relevantNodes = ["\(researcherId)_workstation", "email_server"]
        for nodeId in relevantNodes {
            if let nodeIntel = IntelDatabase.entries[nodeId] {
                for entry in nodeIntel {
                    if let flag = entry.flagToSet, state.flags.contains(flag) {
                        entries.append(entry)
                    } else if entry.flagToSet == nil && state.discoveredIntel.contains(entry.id) {
                        entries.append(entry)
                    }
                }
            }
        }
        return entries
    }
}

// MARK: - Relationship Bar

struct RelationshipBarView: View {
    let fraction: Double  // 0.0 to 1.0 (maps -10...10 to 0...1)
    var height: CGFloat = 4

    var body: some View {
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

                // Center marker (neutral point)
                Rectangle()
                    .fill(TerminalTheme.dimGreen.opacity(0.5))
                    .frame(width: 1, height: height)
                    .offset(x: geo.size.width * 0.5)
            }
        }
        .frame(height: height)
    }

    private var barColor: Color {
        switch fraction {
        case ..<0.25: return Color(hex: "#4466AA")   // cold blue
        case 0.25..<0.50: return Color(hex: "#6688AA") // cool
        case 0.50..<0.75: return Color(hex: "#CCAA44") // warm
        default: return Color(hex: "#FFD700")           // gold
        }
    }
}
