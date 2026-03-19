import SwiftUI

struct MenuView: View {
    @Bindable var viewModel: GameViewModel
    let endingTracker: EndingTracker
    var onDismiss: () -> Void

    @State private var showSettings = false
    @State private var showEndingLog = false

    var body: some View {
        ZStack {
            // Dim background
            Color.black.opacity(0.85)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            if showSettings {
                settingsPanel
            } else if showEndingLog {
                endingLogPanel
            } else {
                mainMenu
            }
        }
    }

    // MARK: - Main Menu

    private var mainMenu: some View {
        VStack(alignment: .leading, spacing: 0) {
            terminalHeader("> SYSTEM MENU")

            menuButton("SAVE SESSION") {
                viewModel.autoSave()
                onDismiss()
            }
            menuButton("LOAD SESSION") {
                viewModel.continueGame()
                onDismiss()
            }

            Divider().background(TerminalTheme.darkGreen)
                .padding(.vertical, 4)

            menuButton("SETTINGS") {
                withAnimation(.easeOut(duration: 0.2)) { showSettings = true }
            }
            menuButton("ENDING LOG") {
                withAnimation(.easeOut(duration: 0.2)) { showEndingLog = true }
            }

            Divider().background(TerminalTheme.darkGreen)
                .padding(.vertical, 4)

            menuButton("EXIT TO TITLE") {
                viewModel.returnToTitle()
                onDismiss()
            }
        }
        .padding(TerminalTheme.screenPadding)
        .frame(maxWidth: 280)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(TerminalTheme.background)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(TerminalTheme.dimGreen, lineWidth: 1)
                )
        )
    }

    // MARK: - Settings

    private var settingsPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            terminalHeader("> SETTINGS")

            settingsToggle("HAPTICS", isOn: Binding(
                get: { HapticManager.isEnabled },
                set: { HapticManager.setEnabled($0) }
            ))

            settingsToggle("SOUND", isOn: Binding(
                get: { AudioManager.shared.soundEnabled },
                set: { AudioManager.shared.soundEnabled = $0 }
            ))

            Divider().background(TerminalTheme.darkGreen)
                .padding(.vertical, 4)

            menuButton("< BACK") {
                withAnimation(.easeOut(duration: 0.2)) { showSettings = false }
            }
        }
        .padding(TerminalTheme.screenPadding)
        .frame(maxWidth: 280)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(TerminalTheme.background)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(TerminalTheme.dimGreen, lineWidth: 1)
                )
        )
    }

    // MARK: - Ending Log

    private var endingLogPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            terminalHeader("> ENDING LOG")

            ForEach(EndingPath.allCases, id: \.rawValue) { path in
                HStack(spacing: 8) {
                    Circle()
                        .fill(endingTracker.hasAchieved(path: path)
                              ? endingColor(path) : TerminalTheme.darkGreen)
                        .frame(width: 10, height: 10)
                    Text(path.rawValue.uppercased())
                        .font(TerminalTheme.captionFont)
                        .foregroundColor(endingTracker.hasAchieved(path: path)
                                         ? TerminalTheme.terminalGreen : TerminalTheme.dimGreen)
                    Spacer()
                    if endingTracker.hasAchieved(path: path, variant: .clean) {
                        Text("CLEAN")
                            .font(TerminalTheme.caption2Font)
                            .foregroundColor(TerminalTheme.terminalGreen)
                    }
                    if endingTracker.hasAchieved(path: path, variant: .messy) {
                        Text("MESSY")
                            .font(TerminalTheme.caption2Font)
                            .foregroundColor(TerminalTheme.amber)
                    }
                }
            }

            Text("RUNS: \(endingTracker.totalRuns)")
                .font(TerminalTheme.caption2Font)
                .foregroundColor(TerminalTheme.dimGreen)
                .padding(.top, 4)

            Divider().background(TerminalTheme.darkGreen)
                .padding(.vertical, 4)

            menuButton("< BACK") {
                withAnimation(.easeOut(duration: 0.2)) { showEndingLog = false }
            }
        }
        .padding(TerminalTheme.screenPadding)
        .frame(maxWidth: 280)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(TerminalTheme.background)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(TerminalTheme.dimGreen, lineWidth: 1)
                )
        )
    }

    // MARK: - Components

    private func terminalHeader(_ text: String) -> some View {
        Text(text)
            .font(TerminalTheme.headlineFont)
            .foregroundColor(TerminalTheme.terminalGreen)
            .phosphorGlow(radius: 2)
            .padding(.bottom, 8)
    }

    private func menuButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text("  [\(title)]")
                .font(TerminalTheme.calloutFont)
                .foregroundColor(TerminalTheme.terminalGreen)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 6)
        }
    }

    private func settingsToggle(_ label: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Text(label)
                .font(TerminalTheme.calloutFont)
                .foregroundColor(TerminalTheme.terminalGreen)
            Spacer()
            Text(isOn.wrappedValue ? "[ON]" : "[OFF]")
                .font(TerminalTheme.calloutFont)
                .foregroundColor(isOn.wrappedValue ? TerminalTheme.terminalGreen : TerminalTheme.dimGreen)
                .onTapGesture { isOn.wrappedValue.toggle() }
        }
        .padding(.vertical, 4)
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
}
