import SwiftUI

struct ChoiceView: View {
    let choices: [Choice]
    var stageManager: VisualStageManager?
    let onSelect: (Choice) -> Void

    @State private var isVisible = false
    @State private var selectedId: String?
    @State private var expandedId: String?

    /// Max lines shown per choice before "more..." appears
    private let previewLineLimit = 3

    var body: some View {
        VStack(spacing: 0) {
            // Divider line
            Rectangle()
                .fill(TerminalTheme.dimGreen)
                .frame(height: 1)
                .padding(.horizontal, TerminalTheme.screenPadding)

            ScrollView {
                VStack(spacing: 8) {
                    ForEach(Array(choices.enumerated()), id: \.element.id) { index, choice in
                        if selectedId == nil || selectedId == choice.id {
                            choiceButton(choice, index: index)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .bottom).combined(with: .opacity),
                                    removal: .opacity.combined(with: .scale(scale: 0.9))
                                ))
                        }
                    }
                }
                .padding(.top, 8)
                .padding(.horizontal, TerminalTheme.screenPadding)
                .padding(.bottom, TerminalTheme.screenPadding)
            }
            .frame(maxHeight: 280)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) {
                isVisible = true
            }
        }
    }

    private func choiceButton(_ choice: Choice, index: Int) -> some View {
        let hintColor = stageManager?.choiceHintColor(for: choice.toneTag)
        let isExpanded = expandedId == choice.id

        let accentColor = isExpanded ? TerminalTheme.terminalGreen : TerminalTheme.dimGreen

        return Button {
            if !isExpanded && choice.text.count > 100 {
                withAnimation(.easeOut(duration: 0.15)) {
                    expandedId = choice.id
                }
            } else {
                selectChoice(choice)
            }
        } label: {
            HStack(alignment: .top, spacing: 0) {
                // Left accent bar — marks this as interactive/selectable
                RoundedRectangle(cornerRadius: 1)
                    .fill(accentColor)
                    .frame(width: 3)
                    .padding(.vertical, 2)

                VStack(alignment: .leading, spacing: 4) {
                    // Tone tag at top like a terminal command prefix
                    Text("> \(choice.toneTag.rawValue)")
                        .font(TerminalTheme.caption2Font)
                        .foregroundColor(accentColor)

                    Text(choice.text)
                        .font(TerminalTheme.calloutFont)
                        .foregroundColor(TerminalTheme.terminalGreen)
                        .multilineTextAlignment(.leading)
                        .lineLimit(isExpanded ? nil : previewLineLimit)
                }
                .padding(.leading, 8)
                .padding(.vertical, 8)
                .padding(.trailing, TerminalTheme.innerPadding)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(hintColor ?? Color.clear)
        }
        .offset(y: isVisible ? 0 : 20)
        .opacity(isVisible ? 1 : 0)
        .animation(
            .easeOut(duration: 0.3).delay(Double(index) * 0.08),
            value: isVisible
        )
    }

    private func selectChoice(_ choice: Choice) {
        guard selectedId == nil else { return }
        HapticManager.mediumTap()
        withAnimation(.easeOut(duration: 0.25)) {
            selectedId = choice.id
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onSelect(choice)
        }
    }
}
