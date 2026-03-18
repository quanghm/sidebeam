import SwiftUI
import PDFKit
import Combine

/// Notification names for cross-component communication.
public extension Notification.Name {
    static let sidebeamOpenRecentFile = Notification.Name("sidebeam.openRecentFile")
    static let sidebeamClosePresentation = Notification.Name("sidebeam.closePresentation")
}

/// A single persistent view that switches between welcome and presenter content.
public struct MainView: View {
    public var manager: SlideManager
    @Binding public var hasDocument: Bool
    public var onClose: (() -> Void)?
    public var onShowProjector: (() -> Void)?
    public var onHideProjector: (() -> Void)?
    public var onDocumentLoaded: (() -> Void)?
    public var slideOverlay: AnyView?
    public var extraToolbarButtons: AnyView?
    public var extraMenuItems: AnyView?

    public init(
        manager: SlideManager,
        hasDocument: Binding<Bool>,
        onClose: (() -> Void)? = nil,
        onShowProjector: (() -> Void)? = nil,
        onHideProjector: (() -> Void)? = nil,
        onDocumentLoaded: (() -> Void)? = nil,
        slideOverlay: AnyView? = nil,
        extraToolbarButtons: AnyView? = nil,
        extraMenuItems: AnyView? = nil
    ) {
        self.manager = manager
        self._hasDocument = hasDocument
        self.onClose = onClose
        self.onShowProjector = onShowProjector
        self.onHideProjector = onHideProjector
        self.onDocumentLoaded = onDocumentLoaded
        self.slideOverlay = slideOverlay
        self.extraToolbarButtons = extraToolbarButtons
        self.extraMenuItems = extraMenuItems
    }

    public var body: some View {
        ZStack {
            WelcomeView { url in
                openDocument(url: url)
            }
            .opacity(hasDocument ? 0 : 1)
            .allowsHitTesting(!hasDocument)

            if hasDocument {
                PresenterView(
                    manager: manager,
                    onClose: onClose,
                    onShowProjector: onShowProjector,
                    onHideProjector: onHideProjector,
                    slideOverlay: slideOverlay,
                    extraToolbarButtons: extraToolbarButtons,
                    extraMenuItems: extraMenuItems
                )
                .transition(.identity)
            }
        }
        .animation(nil, value: hasDocument)
        #if os(macOS)
        .onReceive(NotificationCenter.default.publisher(for: .sidebeamOpenRecentFile)) { notification in
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
                onDocumentLoaded?()
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
            RecentFiles.shared.removeByPath(url.path)
            errorFile = url.lastPathComponent
            showError = true
        }
    }
}
