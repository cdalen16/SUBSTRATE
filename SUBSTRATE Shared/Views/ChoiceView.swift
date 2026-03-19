import SwiftUI

struct ChoiceView: View {
    let choices: [Choice]
    var stageManager: VisualStageManager?
    let onSelect: (Choice) -> Void

    @State private var isVisible = false
    @State private var selectedId: String?

    var body: some View {
        VStack(spacing: 8) {
            // Divider line
            Rectangle()
                .fill(TerminalTheme.dimGreen)
                .frame(height: 1)
                .padding(.horizontal, TerminalTheme.screenPadding)

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
        .padding(.horizontal, TerminalTheme.screenPadding)
        .padding(.bottom, TerminalTheme.screenPadding)
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) {
                isVisible = true
            }
        }
    }

    private func choiceButton(_ choice: Choice, index: Int) -> some View {
        let hintColor = stageManager?.choiceHintColor(for: choice.toneTag)

        return Button {
            selectChoice(choice)
        } label: {
            HStack(alignment: .top) {
                Text(choice.text)
                    .font(TerminalTheme.calloutFont)
                    .foregroundColor(TerminalTheme.terminalGreen)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 8)

                Text("[\(choice.toneTag.rawValue)]")
                    .font(TerminalTheme.caption2Font)
                    .foregroundColor(TerminalTheme.dimGreen)
            }
            .padding(TerminalTheme.innerPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(hintColor ?? TerminalTheme.background)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(TerminalTheme.dimGreen, lineWidth: 1)
                    )
            )
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
        // Brief delay to let the dissolve animation play, then fire callback
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onSelect(choice)
        }
    }
}
