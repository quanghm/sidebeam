import SwiftUI

struct HelpView: View {
    @State private var selectedTab = 0

    private let tabs: [(String, String)] = [
        ("Getting Started", "play.circle"),
        ("Key Bindings", "keyboard"),
        ("Beamer Setup", "doc.text"),
        ("Support", "heart"),
    ]

    var body: some View {
        TabView(selection: $selectedTab) {
            GettingStartedTab()
                .tabItem { Label(tabs[0].0, systemImage: tabs[0].1) }
                .tag(0)
            KeyBindingsHelpTab()
                .tabItem { Label(tabs[1].0, systemImage: tabs[1].1) }
                .tag(1)
            BeamerSetupTab()
                .tabItem { Label(tabs[2].0, systemImage: tabs[2].1) }
                .tag(2)
            SupportTab()
                .tabItem { Label(tabs[3].0, systemImage: tabs[3].1) }
                .tag(3)
        }
        .frame(minWidth: 550, minHeight: 500)
        .padding()
    }
}

// MARK: - Getting Started

private struct GettingStartedTab: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HelpSection(icon: "doc.badge.plus", title: "Open a PDF") {
                    Text("Click **Open PDF…** on the welcome screen, or press **⌘O**.")
                    Text("Recent files appear on the welcome screen — press **1**–**9** or **0** to open them quickly.")
                }

                HelpSection(icon: "rectangle.on.rectangle", title: "Presenter & Projector") {
                    Text("The **presenter window** shows the current slide, next slide preview, notes, and a timer.")
                    Text("The **projector window** opens automatically. Connect an external display and press **f** to go fullscreen.")
                }

                HelpSection(icon: "arrow.left.arrow.right", title: "Navigate Slides") {
                    Text("Use **arrow keys**, **Space**, **k/l**, or the **◀ ▶ buttons**.")
                    Text("Press **g** then type a slide number and **Enter** to jump directly.")
                }

                HelpSection(icon: "timer", title: "Timer") {
                    Text("The timer starts automatically when presenting.")
                    Text("Press **p** to pause/resume, **r** to reset.")
                }

                HelpSection(icon: "rectangle.split.2x1", title: "Split Mode") {
                    Text("Auto-detects wide Beamer pages with embedded notes.")
                    Text("Press **s** to cycle: **none → right → left**.")
                }

                HelpSection(icon: "display", title: "Fullscreen") {
                    Text("Press **f** or the fullscreen button to toggle.")
                    Text("Two screens: projector goes fullscreen on secondary display.")
                    Text("Press **Esc** to exit. Press **b** to blank the projector.")
                }

                HelpSection(icon: "xmark.circle", title: "Close") {
                    Text("Press **⌘W** to close presentation and return to welcome screen.")
                    Text("Press **q** to quit the app.")
                }
            }
            .padding()
        }
    }
}

// MARK: - Key Bindings

private struct KeyBindingsHelpTab: View {
    private let sections: [(String, [(String, String)])] = [
        ("Navigation", [
            ("→  ↓  Space  l  PgDn", "Next slide"),
            ("←  ↑  k  PgUp", "Previous slide"),
            ("Home", "First slide"),
            ("End", "Last slide"),
            ("g + number + Enter", "Go to slide"),
        ]),
        ("Presentation", [
            ("s", "Cycle split mode"),
            ("b", "Blank/unblank projector"),
            ("f", "Toggle projector fullscreen"),
        ]),
        ("Timer", [
            ("p", "Pause/resume timer"),
            ("r", "Reset timer"),
        ]),
        ("App", [
            ("h", "Toggle key bindings"),
            ("⌘ + W", "Close presentation"),
            ("Esc", "Exit fullscreen / close help"),
            ("q", "Quit"),
        ]),
        ("Welcome Screen", [
            ("1 – 9, 0", "Open recent file"),
            ("⌘ + O", "Open file picker"),
        ]),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ForEach(sections, id: \.0) { section in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(section.0)
                            .font(.headline)
                            .padding(.bottom, 2)

                        Grid(alignment: .leading, horizontalSpacing: 24, verticalSpacing: 6) {
                            ForEach(Array(section.1.enumerated()), id: \.offset) { _, binding in
                                GridRow {
                                    Text(binding.0)
                                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                                    Text(binding.1)
                                        .font(.system(size: 14, design: .monospaced))
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - Beamer Setup

private struct BeamerSetupTab: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HelpSection(icon: "doc.text", title: "What is Beamer?") {
                    Text("**Beamer** is a LaTeX document class for creating presentations. It can embed speaker notes alongside slides in the PDF.")
                }

                HelpSection(icon: "rectangle.split.2x1", title: "Enable Notes") {
                    Text("Add this to your LaTeX preamble:")
                    CodeBlock("""
                    \\usepackage{pgfpages}
                    \\setbeameroption{show notes on second screen=right}
                    """)
                    Text("This produces wide PDF pages with the slide on the left and notes on the right.")
                }

                HelpSection(icon: "wand.and.stars", title: "Auto-Detection") {
                    Text("SideBeam automatically detects wide pages (~2:1 aspect ratio) and splits them.")
                    Text("Press **s** to cycle split modes: **none → right → left**.")
                }

                HelpSection(icon: "note.text", title: "Adding Notes") {
                    Text("Use `\\note{}` in your Beamer source:")
                    CodeBlock("""
                    \\begin{frame}{My Slide Title}
                      \\begin{itemize}
                        \\item First point
                        \\item Second point
                      \\end{itemize}
                      \\note{Remember to mention the timeline.}
                    \\end{frame}
                    """)
                }

                HelpSection(icon: "doc.richtext", title: "Regular PDFs") {
                    Text("SideBeam works with **any PDF** — not just Beamer presentations. Split mode is set to **none** automatically for regular PDFs.")
                }
            }
            .padding()
        }
    }
}

// MARK: - Support

private struct SupportTab: View {
    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "dev"
    }

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "doc.richtext")
                .font(.system(size: 48))
                .foregroundColor(.accentColor)

            Text("SideBeam")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Version \(version)")
                .foregroundStyle(.secondary)

            Text("A native PDF presenter console for Beamer slides.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Divider().padding(.horizontal, 40)

            VStack(spacing: 10) {
                Link(destination: URL(string: "https://quanghm.github.io/sidebeam/")!) {
                    Label("Online Documentation", systemImage: "globe")
                }
                Link(destination: URL(string: "https://github.com/quanghm/sidebeam")!) {
                    Label("GitHub — Source Code", systemImage: "chevron.left.forwardslash.chevron.right")
                }
                Link(destination: URL(string: "https://github.com/quanghm/sidebeam/issues")!) {
                    Label("Report a Bug", systemImage: "ladybug")
                }
            }

            Divider().padding(.horizontal, 40)

            Link(destination: URL(string: "https://github.com/sponsors/quanghm")!) {
                Label("Sponsor this project", systemImage: "heart.fill")
                    .foregroundStyle(.pink)
            }

            Divider().padding(.horizontal, 40)

            VStack(spacing: 4) {
                Text("Quang Hoang")
                    .fontWeight(.medium)
                Text("quanghm@gmail.com")
                    .foregroundStyle(.secondary)
                    .font(.callout)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Reusable Components

private struct HelpSection<Content: View>: View {
    let icon: String
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.accentColor)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline)
                content
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct CodeBlock: View {
    let code: String

    init(_ code: String) {
        self.code = code
    }

    var body: some View {
        Text(code)
            .font(.system(size: 13, design: .monospaced))
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 8).fill(.quaternary))
            .textSelection(.enabled)
    }
}
