import SwiftUI
import PDFKit
import Combine

/// A single persistent view that switches between welcome and presenter content.
/// Never removed from the view hierarchy, preventing window destruction issues.
struct MainView: View {
    var manager: SlideManager
    @Binding var hasDocument: Bool
    #if os(macOS)
    var projectorManager: ProjectorWindowManager
    #endif
    var onClose: (() -> Void)?
    var onToggleProjector: (() -> Void)?

    var body: some View {
        Group {
            if hasDocument {
                PresenterView(manager: manager, onClose: onClose, onToggleProjector: onToggleProjector)
            } else {
                WelcomeView { url in
                    openDocument(url: url)
                }
            }
        }
        #if os(macOS)
        .onReceive(NotificationCenter.default.publisher(for: .openRecentFile)) { notification in
            if let url = notification.object as? URL {
                openDocument(url: url)
            }
        }
        #endif
        .alert("Unable to open file", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text("\(errorFile) could not be opened. It may have been moved or deleted.")
        }
        .onChange(of: hasDocument) { _, newValue in
            if newValue {
                #if os(macOS)
                projectorManager.open(manager: manager)
                if NSScreen.screens.count > 1 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        projectorManager.fullscreenOnScreen(NSScreen.screens[1])
                    }
                }
                #endif
            }
        }
    }

    @State private var showError = false
    @State private var errorFile = ""

    private func openDocument(url: URL) {
        if manager.load(url: url) {
            RecentFiles.shared.add(url: url)
            hasDocument = true
        } else {
            // Remove stale entry and show error
            RecentFiles.shared.removeByPath(url.path)
            errorFile = url.lastPathComponent
            showError = true
        }
    }
}
