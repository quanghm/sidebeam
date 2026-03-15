import AppKit
import PDFKit

final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private let slideManager = SlideManager()
    private var presenterWindow: PresenterWindowController?
    private var projectorWindow: ProjectorWindowController?
    private var keyBindingsWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()

        // Check for CLI argument
        let args = CommandLine.arguments
        if args.count > 1 {
            let path = args[1]
            let url: URL
            if path.hasPrefix("/") {
                url = URL(fileURLWithPath: path)
            } else {
                url = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
                    .appendingPathComponent(path)
            }
            openDocument(url: url)
        } else {
            openFileDialog()
        }

        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    func windowWillClose(_ notification: Notification) {
        // Closing presenter window closes everything
        if let closing = notification.object as? NSWindow, closing === presenterWindow?.window {
            projectorWindow?.window?.close()
        }
    }

    // MARK: - Menu Bar

    private func setupMenuBar() {
        let mainMenu = NSMenu()

        // App menu
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "About Beamer Viewer", action: #selector(showAbout), keyEquivalent: "")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        let appMenuItem = NSMenuItem()
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)

        // File menu
        let fileMenu = NSMenu(title: "File")
        fileMenu.addItem(withTitle: "Open…", action: #selector(openAction), keyEquivalent: "o")
        let fileMenuItem = NSMenuItem()
        fileMenuItem.submenu = fileMenu
        mainMenu.addItem(fileMenuItem)

        // Help menu (key bindings)
        let helpMenu = NSMenu(title: "Help")
        let helpItem = NSMenuItem(title: "Key Bindings", action: #selector(showKeyBindings), keyEquivalent: "")
        helpMenu.addItem(helpItem)
        let helpMenuItem = NSMenuItem()
        helpMenuItem.submenu = helpMenu
        mainMenu.addItem(helpMenuItem)

        NSApp.mainMenu = mainMenu
    }

    @objc private func showAbout() {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "dev"
        let alert = NSAlert()
        alert.messageText = "Beamer Viewer"
        alert.informativeText = """
        Version \(version)

        A native macOS PDF presenter console for Beamer slides.

        Author: Quang Hoang <quanghm@gmail.com>
        """
        alert.alertStyle = .informational
        alert.runModal()
    }

    @objc private func openAction() {
        openFileDialog()
    }

    @objc private func showKeyBindings() {
        // Toggle — close if already visible
        if let win = keyBindingsWindow, win.isVisible {
            win.close()
            keyBindingsWindow = nil
            return
        }

        let bindings: [(String, String)] = [
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
            ("Esc  q", "Quit"),
        ]

        // Build two-column grid using NSGridView
        let mono = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        let bold = NSFont.monospacedSystemFont(ofSize: 13, weight: .bold)
        let keyColor = NSColor.labelColor
        let labelColor = NSColor.secondaryLabelColor

        var rows: [[NSView]] = []
        for (key, action) in bindings {
            let keyLabel = NSTextField(labelWithString: key)
            keyLabel.font = bold
            keyLabel.textColor = keyColor
            keyLabel.backgroundColor = .clear
            keyLabel.isBezeled = false

            let actionLabel = NSTextField(labelWithString: action)
            actionLabel.font = mono
            actionLabel.textColor = labelColor
            actionLabel.backgroundColor = .clear
            actionLabel.isBezeled = false

            rows.append([keyLabel, actionLabel])
        }

        let grid = NSGridView(views: rows)
        grid.column(at: 0).xPlacement = .leading
        grid.column(at: 1).xPlacement = .leading
        grid.columnSpacing = 24
        grid.rowSpacing = 6
        grid.setContentHuggingPriority(.required, for: .horizontal)
        grid.setContentHuggingPriority(.required, for: .vertical)
        let gridSize = grid.fittingSize

        let padding: CGFloat = 20
        let winWidth = gridSize.width + padding * 2
        let winHeight = gridSize.height + padding * 2 + 30
        grid.frame = NSRect(x: padding, y: padding, width: gridSize.width, height: gridSize.height)

        let win = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: winWidth, height: winHeight),
            styleMask: [.titled, .closable, .utilityWindow],
            backing: .buffered,
            defer: false
        )
        win.title = "Key Bindings"
        win.isFloatingPanel = true
        win.becomesKeyOnlyIfNeeded = true
        win.isOpaque = true
        win.backgroundColor = .windowBackgroundColor
        win.contentView?.addSubview(grid)
        win.center()
        win.orderFront(nil)

        keyBindingsWindow = win
    }

    // MARK: - File Opening

    private func openFileDialog() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.pdf]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        if panel.runModal() == .OK, let url = panel.url {
            openDocument(url: url)
        } else if slideManager.pdfDocument == nil {
            // No document loaded and user cancelled — quit
            NSApp.terminate(nil)
        }
    }

    private func openDocument(url: URL) {
        guard slideManager.load(url: url) else {
            let alert = NSAlert()
            alert.messageText = "Failed to open PDF"
            alert.informativeText = "Could not load: \(url.lastPathComponent)"
            alert.alertStyle = .critical
            alert.runModal()
            NSApp.terminate(nil)
            return
        }

        setupWindows()
        presenterWindow?.updateViews()
        projectorWindow?.updateSlide()
    }

    // MARK: - Windows

    private func setupWindows() {
        let screens = NSScreen.screens

        // Presenter on primary screen
        presenterWindow = PresenterWindowController(slideManager: slideManager)
        presenterWindow?.showWindow(nil)

        // Projector on secondary screen if available
        if screens.count > 1 {
            projectorWindow = ProjectorWindowController(slideManager: slideManager, screen: screens[1])
            projectorWindow?.showOnScreen(screens[1])
        } else {
            // Single screen mode — create a floating window for the projector
            let frame = NSRect(x: 200, y: 200, width: 800, height: 600)
            let screen = screens[0]
            projectorWindow = ProjectorWindowController(slideManager: slideManager, screen: screen)
            projectorWindow?.window?.styleMask = [.titled, .closable, .resizable]
            projectorWindow?.window?.setFrame(frame, display: true)
            projectorWindow?.window?.level = .normal
            projectorWindow?.window?.title = "Beamer Viewer — Projector"
            projectorWindow?.showWindow(nil)
        }

        // Closing presenter window quits the app
        presenterWindow?.window?.delegate = self
        presenterWindow?.window?.makeKeyAndOrderFront(nil)
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            return self?.handleKeyDown(event) ?? event
        }
    }

    // MARK: - Keyboard Navigation

    private var pendingGoTo = ""

    private func handleKeyDown(_ event: NSEvent) -> NSEvent? {
        // If we're accumulating a slide number for "go to"
        if !pendingGoTo.isEmpty {
            if event.keyCode == 36 { // Enter
                if let num = Int(pendingGoTo.trimmingCharacters(in: .whitespaces)) {
                    slideManager.goTo(index: num - 1) // 1-indexed for user
                    projectorWindow?.updateSlide()
                }
                pendingGoTo = ""
                return nil
            } else if event.keyCode == 53 { // Escape
                pendingGoTo = ""
                return nil
            } else if let chars = event.characters, chars.rangeOfCharacter(from: .decimalDigits) != nil {
                pendingGoTo += chars
                return nil
            }
        }

        switch event.keyCode {
        case 124, 125, 49: // Right, Down, Space
            slideManager.next()
            projectorWindow?.updateSlide()
            return nil
        case 123, 126: // Left, Up
            slideManager.previous()
            projectorWindow?.updateSlide()
            return nil
        case 116: // Page Up
            slideManager.previous()
            projectorWindow?.updateSlide()
            return nil
        case 121: // Page Down
            slideManager.next()
            projectorWindow?.updateSlide()
            return nil
        case 115: // Home
            slideManager.goToFirst()
            projectorWindow?.updateSlide()
            return nil
        case 119: // End
            slideManager.goToLast()
            projectorWindow?.updateSlide()
            return nil
        default:
            break
        }

        // Character-based shortcuts
        guard let chars = event.characters else { return event }
        switch chars {
        case "l":
            slideManager.next()
            projectorWindow?.updateSlide()
            return nil
        case "k":
            slideManager.previous()
            projectorWindow?.updateSlide()
            return nil
        case "h":
            showKeyBindings()
            return nil
        case "g":
            pendingGoTo = " " // sentinel to start collecting digits
            return nil
        case "b":
            projectorWindow?.toggleBlank()
            return nil
        case "p":
            presenterWindow?.toggleTimer()
            return nil
        case "r":
            presenterWindow?.resetTimer()
            return nil
        case "s":
            slideManager.cycleSplitMode()
            projectorWindow?.updateSlide()
            return nil
        case "f":
            toggleProjectorFullscreen()
            return nil
        case "q":
            NSApp.terminate(nil)
            return nil
        default:
            // Check if it's a digit for go-to after 'g'
            return event
        }
    }

    private func toggleProjectorFullscreen() {
        guard let window = projectorWindow?.window else { return }
        if window.styleMask.contains(.borderless) && window.level == .screenSaver {
            // Exit fullscreen
            window.styleMask = [.titled, .closable, .resizable]
            window.level = .normal
            window.setFrame(NSRect(x: 200, y: 200, width: 800, height: 600), display: true)
            window.title = "Beamer Viewer — Projector"
        } else {
            // Enter fullscreen on secondary screen or current
            let screen = NSScreen.screens.count > 1 ? NSScreen.screens[1] : NSScreen.screens[0]
            window.styleMask = [.borderless]
            window.level = .screenSaver
            window.setFrame(screen.frame, display: true)
        }
    }
}
