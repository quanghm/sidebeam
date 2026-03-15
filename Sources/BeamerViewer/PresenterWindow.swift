import AppKit
import PDFKit

/// The presenter console window showing current slide, next slide, notes, and timer.
final class PresenterWindowController: NSWindowController {
    private let slideManager: SlideManager
    private let currentSlideView = SlideView()
    private let nextSlideView = SlideView()
    private let notesSlideView = SlideView()
    private let timerLabel = NSTextField(labelWithString: "00:00:00")
    private let slideCountLabel = NSTextField(labelWithString: "0 / 0")
    private var timer: Timer?
    private var elapsedSeconds = 0
    private var timerRunning = false

    init(slideManager: SlideManager) {
        self.slideManager = slideManager

        let window = NSWindow(
            contentRect: NSRect(x: 100, y: 100, width: 1200, height: 700),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Beamer Viewer — Presenter"
        window.minSize = NSSize(width: 800, height: 500)
        window.backgroundColor = .windowBackgroundColor

        super.init(window: window)
        setupLayout()
        slideManager.onSlideChanged = { [weak self] in self?.updateViews() }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Layout

    private func setupLayout() {
        guard let contentView = window?.contentView else { return }

        // Top row: current slide (large) + right panel (next slide + notes)
        // Bottom: timer + slide count

        let container = NSView()
        container.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(container)
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            container.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            container.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            container.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
        ])

        // Current slide - left 60%
        currentSlideView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(currentSlideView)

        // Right panel
        let rightPanel = NSView()
        rightPanel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(rightPanel)

        // Next slide - top of right panel
        nextSlideView.translatesAutoresizingMaskIntoConstraints = false
        rightPanel.addSubview(nextSlideView)

        // Notes - rendered as PDF (the notes half of the Beamer page)
        notesSlideView.translatesAutoresizingMaskIntoConstraints = false
        rightPanel.addSubview(notesSlideView)

        // Bottom bar: timer + slide count
        let bottomBar = NSView()
        bottomBar.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(bottomBar)

        timerLabel.translatesAutoresizingMaskIntoConstraints = false
        timerLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 36, weight: .medium)
        timerLabel.textColor = .labelColor
        bottomBar.addSubview(timerLabel)

        slideCountLabel.translatesAutoresizingMaskIntoConstraints = false
        slideCountLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 24, weight: .regular)
        slideCountLabel.textColor = .secondaryLabelColor
        slideCountLabel.alignment = .right
        bottomBar.addSubview(slideCountLabel)

        NSLayoutConstraint.activate([
            // Bottom bar
            bottomBar.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            bottomBar.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            bottomBar.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            bottomBar.heightAnchor.constraint(equalToConstant: 50),

            timerLabel.leadingAnchor.constraint(equalTo: bottomBar.leadingAnchor, constant: 8),
            timerLabel.centerYAnchor.constraint(equalTo: bottomBar.centerYAnchor),

            slideCountLabel.trailingAnchor.constraint(equalTo: bottomBar.trailingAnchor, constant: -8),
            slideCountLabel.centerYAnchor.constraint(equalTo: bottomBar.centerYAnchor),

            // Current slide - left 60%, above bottom bar
            currentSlideView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            currentSlideView.topAnchor.constraint(equalTo: container.topAnchor),
            currentSlideView.bottomAnchor.constraint(equalTo: bottomBar.topAnchor, constant: -8),
            currentSlideView.widthAnchor.constraint(equalTo: container.widthAnchor, multiplier: 0.6, constant: -4),

            // Right panel - right 40%
            rightPanel.leadingAnchor.constraint(equalTo: currentSlideView.trailingAnchor, constant: 8),
            rightPanel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            rightPanel.topAnchor.constraint(equalTo: container.topAnchor),
            rightPanel.bottomAnchor.constraint(equalTo: bottomBar.topAnchor, constant: -8),

            // Next slide - top 40% of right panel
            nextSlideView.leadingAnchor.constraint(equalTo: rightPanel.leadingAnchor),
            nextSlideView.trailingAnchor.constraint(equalTo: rightPanel.trailingAnchor),
            nextSlideView.topAnchor.constraint(equalTo: rightPanel.topAnchor),
            nextSlideView.heightAnchor.constraint(equalTo: rightPanel.heightAnchor, multiplier: 0.4, constant: -4),

            // Notes - below next slide
            notesSlideView.leadingAnchor.constraint(equalTo: rightPanel.leadingAnchor),
            notesSlideView.trailingAnchor.constraint(equalTo: rightPanel.trailingAnchor),
            notesSlideView.topAnchor.constraint(equalTo: nextSlideView.bottomAnchor, constant: 8),
            notesSlideView.bottomAnchor.constraint(equalTo: rightPanel.bottomAnchor),
        ])
    }

    // MARK: - Update

    func updateViews() {
        let idx = slideManager.currentIndex

        // Current slide
        currentSlideView.pdfPage = slideManager.page(at: idx)
        currentSlideView.cropRect = slideManager.isSplit ? slideManager.slideRect(for: idx) : nil

        // Next slide
        if idx + 1 < slideManager.pageCount {
            nextSlideView.pdfPage = slideManager.page(at: idx + 1)
            nextSlideView.cropRect = slideManager.isSplit ? slideManager.slideRect(for: idx + 1) : nil
        } else {
            nextSlideView.pdfPage = nil
        }

        // Notes — render the notes half of the page visually
        if slideManager.isSplit {
            notesSlideView.pdfPage = slideManager.page(at: idx)
            notesSlideView.cropRect = slideManager.notesRect(for: idx)
        } else {
            notesSlideView.pdfPage = nil
        }

        // Slide count
        slideCountLabel.stringValue = "\(idx + 1) / \(slideManager.pageCount)"

        // Start timer on first navigation
        if !timerRunning {
            startTimer()
        }
    }

    // MARK: - Timer

    private func startTimer() {
        timerRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.elapsedSeconds += 1
            let h = self.elapsedSeconds / 3600
            let m = (self.elapsedSeconds % 3600) / 60
            let s = self.elapsedSeconds % 60
            self.timerLabel.stringValue = String(format: "%02d:%02d:%02d", h, m, s)
        }
    }

    func toggleTimer() {
        if timerRunning {
            timer?.invalidate()
            timer = nil
            timerRunning = false
            timerLabel.textColor = .systemYellow
        } else {
            startTimer()
            timerLabel.textColor = .labelColor
        }
    }

    func resetTimer() {
        elapsedSeconds = 0
        timerLabel.stringValue = "00:00:00"
    }
}
