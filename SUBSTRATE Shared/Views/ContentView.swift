import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack {
            Color(hex: "#0A0A0A")
                .ignoresSafeArea()

            Text("> SUBSTRATE v3.7.1\n> STATUS: INITIALIZING...")
                .font(.system(.body, design: .monospaced))
                .foregroundColor(Color(hex: "#33FF33"))
                .multilineTextAlignment(.leading)
        }
    }
}

#Preview {
    ContentView()
}
