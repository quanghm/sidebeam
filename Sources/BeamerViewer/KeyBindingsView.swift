import SwiftUI

struct KeyBindingsView: View {
    private let bindings: [(String, String)] = [
        ("→  ↓  Space  l  PgDn", "Next slide"),
        ("←  ↑  k  PgUp", "Previous slide"),
        ("Home", "First slide"),
        ("End", "Last slide"),
        ("g + number + Enter", "Go to slide"),
        ("s", "Cycle split mode"),
        ("b", "Blank/unblank projector"),
        ("p", "Pause/resume timer"),
        ("r", "Reset timer"),
        ("f", "Toggle projector fullscreen"),
        ("h", "Toggle this help"),
        ("Esc", "Close help / cancel go-to"),
        ("q", "Quit"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Key Bindings")
                .font(.headline)
                .padding(.bottom, 12)

            Grid(alignment: .leading, horizontalSpacing: 24, verticalSpacing: 6) {
                ForEach(Array(bindings.enumerated()), id: \.offset) { _, binding in
                    GridRow {
                        Text(binding.0)
                            .font(.system(size: 15, weight: .bold, design: .monospaced))
                            .foregroundStyle(.primary)
                        Text(binding.1)
                            .font(.system(size: 15, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(30)
        .frame(minWidth: 450)
    }
}
