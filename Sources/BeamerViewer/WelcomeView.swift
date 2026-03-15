import SwiftUI

struct WelcomeView: View {
    var onOpen: (URL) -> Void

    @State private var showFilePicker = false

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.richtext")
                .font(.system(size: 64))
                .foregroundStyle(.teal)
            Text("Beamer Viewer")
                .font(.largeTitle)
                .fontWeight(.semibold)
            Text("Open a PDF to start presenting")
                .foregroundStyle(.secondary)
            Button("Open PDF…") { showFilePicker = true }
                .buttonStyle(.borderedProminent)
                .tint(.teal)
                .controlSize(.large)
                .keyboardShortcut("o", modifiers: .command)
            Text("⌘O")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [.pdf],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                onOpen(url)
            }
        }
    }
}
