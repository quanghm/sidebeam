import SwiftUI
import PDFKit
import Combine

#if os(macOS)
import AppKit

extension Notification.Name {
    static let closePresentation = Notification.Name("closePresentation")
    static let openRecentFile = Notification.Name("openRecentFile")
}

@main
struct BeamerViewerApp: App {
    @State private var manager = SlideManager()
    @State private var hasDocument = false
    @State private var projectorManager = ProjectorWindowManager()

    var body: some Scene {
        WindowGroup {
            MainView(
                manager: manager,
                hasDocument: $hasDocument,
                projectorManager: projectorManager,
                onClose: { closePresentation() }
            )
            .onAppear {
                // Disable window state restoration
                UserDefaults.standard.set(false, forKey: "NSQuitAlwaysKeepsWindows")
                NSWindow.allowsAutomaticWindowTabbing = false
                KeyboardManager.shared.setup(
                    manager: manager,
                    projectorManager: projectorManager
                )
                checkCLIArgs()
            }
            .onReceive(NotificationCenter.default.publisher(for: .closePresentation)) { _ in
                closePresentation()
            }
        }
        .defaultSize(width: 1200, height: 700)
        .commands {
            CommandGroup(replacing: .newItem) { }
            CommandGroup(replacing: .appInfo) {
                Button("About Beamer Viewer") {
                    AboutWindowManager.show()
                }
            }
            CommandGroup(replacing: .help) {
                Button("Key Bindings") {
                    KeyboardManager.shared.toggleKeyBindings()
                }
            }
        }
    }

    private func checkCLIArgs() {
        let args = CommandLine.arguments
        guard args.count > 1 else { return }
        let path = args[1]
        let url: URL
        if path.hasPrefix("/") {
            url = URL(fileURLWithPath: path)
        } else {
            url = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
                .appendingPathComponent(path)
        }
        if manager.load(url: url) {
            RecentFiles.shared.add(url: url)
            hasDocument = true
        }
    }

    func closePresentation() {
        projectorManager.hide()
        manager.reset()
        hasDocument = false
    }
}

// MARK: - Projector Window (AppKit, reliable multi-screen)

@Observable
final class ProjectorWindowManager {
    private var window: NSWindow?

    func open(manager: SlideManager) {
        if let window {
            window.orderFront(nil)
            return
        }

        let projView = ProjectorView(manager: manager)
        let hosting = NSHostingController(rootView: projView)

        let win = NSWindow(
            contentRect: NSRect(x: 200, y: 200, width: 800, height: 600),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        win.title = "Beamer Viewer — Projector"
        win.backgroundColor = .black
        win.contentViewController = hosting
        win.orderFront(nil)
        window = win

        // Auto-fullscreen on external display, then move presenter to primary screen
        DispatchQueue.main.async { [weak self] in
            let screens = NSScreen.screens
            if screens.count > 1 {
                self?.toggleFullscreen()
                // Move presenter to primary screen if it's on the external display
                if let mainWindow = NSApp.mainWindow, let primary = screens.first {
                    let presenterFrame = mainWindow.frame
                    let primaryFrame = primary.visibleFrame
                    if !primaryFrame.intersects(presenterFrame) {
                        // Presenter is on the external screen — move it to primary
                        mainWindow.setFrame(
                            NSRect(x: primaryFrame.origin.x + 50,
                                   y: primaryFrame.origin.y + 50,
                                   width: min(presenterFrame.width, primaryFrame.width - 100),
                                   height: min(presenterFrame.height, primaryFrame.height - 100)),
                            display: true
                        )
                    }
                    mainWindow.makeKeyAndOrderFront(nil)
                }
            }
        }
    }

    func close() {
        window?.close()
        window = nil
    }

    func hide() {
        window?.orderOut(nil)
    }

    func toggleFullscreen() {
        guard let win = window else { return }
        if win.styleMask.contains(.borderless) && win.level == .screenSaver {
            win.styleMask = [.titled, .closable, .resizable]
            win.level = .normal
            win.setFrame(NSRect(x: 200, y: 200, width: 800, height: 600), display: true)
            win.title = "Beamer Viewer — Projector"
        } else {
            let screen = NSScreen.screens.count > 1 ? NSScreen.screens[1] : NSScreen.screens[0]
            win.styleMask = [.borderless]
            win.level = .screenSaver
            win.setFrame(screen.frame, display: true)
        }
    }
}

// MARK: - Keyboard (AppKit NSEvent monitor, reliable)

final class KeyboardManager {
    static let shared = KeyboardManager()
    private var monitor: Any?
    private var pendingGoTo = ""
    private weak var manager: SlideManager?
    private weak var projectorManager: ProjectorWindowManager?
    private var keyBindingsWindow: NSWindow?

    func teardown() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
        manager = nil
        projectorManager = nil
        keyBindingsWindow?.close()
        keyBindingsWindow = nil
    }

    func setup(manager: SlideManager, projectorManager: ProjectorWindowManager) {
        guard monitor == nil else { return }
        self.manager = manager
        self.projectorManager = projectorManager

        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyDown(event)
        }
    }

    private func handleKeyDown(_ event: NSEvent) -> NSEvent? {
        // ⌘W — close presentation (when presenting), or quit (when on welcome)
        if event.modifierFlags.contains(.command),
           event.charactersIgnoringModifiers?.lowercased() == "w" {
            if manager?.pdfDocument != nil {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .closePresentation, object: nil)
                }
                return nil
            }
            // On welcome screen, let ⌘W close the window normally (quits app)
            return event
        }

        // When no document is loaded, number keys open recent files
        if manager?.pdfDocument == nil, let chars = event.characters,
           "1234567890".contains(chars) {
            let index = chars == "0" ? 9 : (Int(chars) ?? 1) - 1
            let files = RecentFiles.shared.files
            if index < files.count {
                NotificationCenter.default.post(
                    name: .openRecentFile,
                    object: files[index].url
                )
            }
            return nil
        }

        guard let manager else { return event }

        if !pendingGoTo.isEmpty {
            if event.keyCode == 36 { // Enter
                if let num = Int(pendingGoTo.trimmingCharacters(in: .whitespaces)) {
                    manager.goTo(index: num - 1)
                }
                pendingGoTo = ""
                return nil
            } else if event.keyCode == 53 { // Escape — cancel go-to
                pendingGoTo = ""
                return nil
            } else if let chars = event.characters, chars.rangeOfCharacter(from: .decimalDigits) != nil {
                pendingGoTo += chars
                return nil
            }
        }

        switch event.keyCode {
        case 53: // Escape — close key bindings if open
            if let win = keyBindingsWindow, win.isVisible {
                win.close()
                keyBindingsWindow = nil
                return nil
            }
            return event
        case 124, 125, 49: manager.next(); return nil
        case 123, 126: manager.previous(); return nil
        case 116: manager.previous(); return nil
        case 121: manager.next(); return nil
        case 115: manager.goToFirst(); return nil
        case 119: manager.goToLast(); return nil
        default: break
        }

        guard let chars = event.characters else { return event }
        switch chars {
        case "l": manager.next(); return nil
        case "k": manager.previous(); return nil
        case "h": toggleKeyBindings(); return nil
        case "g": pendingGoTo = " "; return nil
        case "b": manager.isBlank.toggle(); return nil
        case "s": manager.cycleSplitMode(); return nil
        case "f": projectorManager?.toggleFullscreen(); return nil
        case "q": NSApp.terminate(nil); return nil
        default: return event
        }
    }

    func toggleKeyBindings() {
        if let win = keyBindingsWindow, win.isVisible {
            win.close()
            keyBindingsWindow = nil
            return
        }

        let hosting = NSHostingController(rootView: KeyBindingsView())
        let size = hosting.view.fittingSize
        let win = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: max(size.width, 500), height: max(size.height, 400)),
            styleMask: [.titled, .closable, .utilityWindow],
            backing: .buffered,
            defer: false
        )
        win.contentViewController = hosting
        win.title = "Key Bindings"
        win.isFloatingPanel = true
        win.becomesKeyOnlyIfNeeded = true
        win.center()
        win.orderFront(nil)
        keyBindingsWindow = win
    }
}

// MARK: - About Window

enum AboutWindowManager {
    private static var window: NSWindow?

    static func show() {
        if let win = window, win.isVisible {
            win.makeKeyAndOrderFront(nil)
            return
        }

        let hosting = NSHostingController(rootView: AboutView())
        let win = NSWindow(
            contentRect: .zero,
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        win.contentViewController = hosting
        win.title = "About Beamer Viewer"
        win.center()
        win.makeKeyAndOrderFront(nil)
        window = win
    }
}

#else
// iOS / iPadOS
import UIKit

@main
struct BeamerViewerApp: App {
    @State private var manager = SlideManager()
    @State private var hasDocument = false
    @State private var showKeyBindings = false
    @State private var showAbout = false
    @Environment(\.externalDisplayManager) private var externalDisplay

    var body: some Scene {
        WindowGroup {
            Group {
                if hasDocument {
                    PresenterView(manager: manager)
                        .onAppear {
                            ExternalDisplayObserver.shared.start(manager: manager)
                        }
                } else {
                    WelcomeView { url in
                        if manager.load(url: url) {
                            hasDocument = true
                        }
                    }
                }
            }
            .sheet(isPresented: $showKeyBindings) {
                NavigationStack {
                    KeyBindingsView()
                        .navigationTitle("Key Bindings")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Done") { showKeyBindings = false }
                            }
                        }
                }
            }
            .sheet(isPresented: $showAbout) {
                NavigationStack {
                    AboutView()
                        .navigationTitle("About")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Done") { showAbout = false }
                            }
                        }
                }
            }
            // Hardware keyboard shortcuts (iPad with keyboard)
            .onKeyPress(.rightArrow) { manager.next(); return .handled }
            .onKeyPress(.downArrow) { manager.next(); return .handled }
            .onKeyPress(.space) { manager.next(); return .handled }
            .onKeyPress(.leftArrow) { manager.previous(); return .handled }
            .onKeyPress(.upArrow) { manager.previous(); return .handled }
            .onKeyPress("l") { manager.next(); return .handled }
            .onKeyPress("k") { manager.previous(); return .handled }
            .onKeyPress("s") { manager.cycleSplitMode(); return .handled }
            .onKeyPress("b") { manager.isBlank.toggle(); return .handled }
            .onKeyPress("h") { showKeyBindings.toggle(); return .handled }
            .focusable()
            .focusEffectDisabled()
        }
    }
}

// MARK: - External Display (iPad → projector/TV via AirPlay or USB-C)

@Observable
final class ExternalDisplayObserver {
    static let shared = ExternalDisplayObserver()
    private var additionalWindow: UIWindow?
    private weak var manager: SlideManager?

    func start(manager: SlideManager) {
        self.manager = manager

        // Check for existing external scenes
        for scene in UIApplication.shared.connectedScenes {
            if let windowScene = scene as? UIWindowScene,
               windowScene.session.role == .windowExternalDisplayNonInteractive {
                setupExternalWindow(on: windowScene)
            }
        }

        // Observe new scenes connecting
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(sceneDidConnect),
            name: UIScene.didActivateNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(sceneDidDisconnect),
            name: UIScene.didDisconnectNotification,
            object: nil
        )
    }

    @objc private func sceneDidConnect(_ notification: Notification) {
        guard let windowScene = notification.object as? UIWindowScene,
              windowScene.session.role == .windowExternalDisplayNonInteractive else { return }
        setupExternalWindow(on: windowScene)
    }

    @objc private func sceneDidDisconnect(_ notification: Notification) {
        guard let windowScene = notification.object as? UIWindowScene,
              windowScene.session.role == .windowExternalDisplayNonInteractive else { return }
        additionalWindow?.isHidden = true
        additionalWindow = nil
    }

    private func setupExternalWindow(on scene: UIWindowScene) {
        guard let manager else { return }
        let projectorView = ProjectorView(manager: manager)
        let hosting = UIHostingController(rootView: projectorView)
        hosting.view.backgroundColor = .black

        let window = UIWindow(windowScene: scene)
        window.rootViewController = hosting
        window.isHidden = false
        additionalWindow = window
    }
}

// Environment key for external display (future use)
private struct ExternalDisplayManagerKey: EnvironmentKey {
    static let defaultValue = ExternalDisplayObserver.shared
}

extension EnvironmentValues {
    var externalDisplayManager: ExternalDisplayObserver {
        get { self[ExternalDisplayManagerKey.self] }
        set { self[ExternalDisplayManagerKey.self] = newValue }
    }
}

#endif
