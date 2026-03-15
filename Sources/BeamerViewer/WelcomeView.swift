import SwiftUI

struct WelcomeView: View {
    var onOpen: (URL) -> Void

    @State private var showFilePicker = false
    @State private var showHelp = false
    @State private var showSponsor = false
    var recentFiles = RecentFiles.shared

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    showSponsor = true
                } label: {
                    Image(systemName: "heart")
                        .font(.title2)
                        .foregroundColor(.pink.opacity(0.6))
                }
                .buttonStyle(.plain)
                .padding()

                Spacer()

                Button {
                    showHelp = true
                } label: {
                    Image(systemName: "questionmark.circle")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .padding()
            }

            Spacer()

            // Header
            VStack(spacing: 12) {
                Image(systemName: "doc.richtext")
                    .font(.system(size: 64))
                    .foregroundColor(.accentColor)
                Text("SideBeam")
                    .font(.largeTitle)
                    .fontWeight(.semibold)
                Text("Open a PDF to start presenting")
                    .foregroundStyle(.secondary)
                Button("Open PDF…") { showFilePicker = true }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .keyboardShortcut("o", modifiers: .command)
                Text("⌘O")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            // Recent files
            if !recentFiles.files.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Recent")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button("Clear") { recentFiles.clear() }
                            .buttonStyle(.plain)
                            .foregroundStyle(.tertiary)
                            .font(.caption)
                    }

                    ForEach(Array(recentFiles.files.enumerated()), id: \.element.id) { index, file in
                        Button {
                            if let url = file.url { onOpen(url) }
                        } label: {
                            HStack(spacing: 10) {
                                Text(hotkeyLabel(for: index))
                                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                                    .foregroundColor(.accentColor)
                                    .frame(width: 20)
                                Image(systemName: "doc.fill")
                                    .foregroundColor(.accentColor)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(file.name)
                                        .lineLimit(1)
                                    Text(file.path)
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                }
                                Spacer()
                                Text(file.date, format: .dateTime.month(.abbreviated).day().hour().minute())
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .padding(.vertical, 4)
                    }
                }
                .padding(.horizontal, 40)
                .padding(.top, 30)
                .frame(maxWidth: 500)
            }

            Spacer()
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
        .sheet(isPresented: $showHelp) {
            #if os(iOS)
            NavigationStack {
                HelpView()
                    .navigationTitle("Help")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Done") { showHelp = false }
                        }
                    }
            }
            #else
            HelpView()
                .frame(minWidth: 550, minHeight: 500)
            #endif
        }
        .alert("Support SideBeam", isPresented: $showSponsor) {
            Link("Sponsor on GitHub", destination: URL(string: "https://github.com/sponsors/quanghm")!)
            Button("Not now", role: .cancel) { }
        } message: {
            Text("SideBeam is free and open source. If you find it useful, consider sponsoring the project!")
        }
    }

    private func hotkeyLabel(for index: Int) -> String {
        index == 9 ? "0" : "\(index + 1)"
    }
}
