import SwiftUI
import PDFKit

struct PresenterView: View {
    var manager: SlideManager
    @State private var elapsedSeconds = 0
    @State private var timerRunning = false
    @State private var timerPaused = false
    @State private var timer: Timer?

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                // Current slide — left 60%
                currentSlide
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Right panel — next slide + notes
                VStack(spacing: 8) {
                    nextSlide
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    notesView
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(maxWidth: .infinity)
            }

            // Bottom bar
            bottomBar
        }
        .padding(8)
        .onAppear { startTimer() }
    }

    // MARK: - Subviews

    private var currentSlide: some View {
        SlideView(
            pdfPage: manager.page(at: manager.currentIndex),
            cropRect: manager.isSplit ? manager.slideRect(for: manager.currentIndex) : nil
        )
    }

    private var nextSlide: some View {
        Group {
            if manager.currentIndex + 1 < manager.pageCount {
                SlideView(
                    pdfPage: manager.page(at: manager.currentIndex + 1),
                    cropRect: manager.isSplit ? manager.slideRect(for: manager.currentIndex + 1) : nil
                )
            } else {
                Color.clear
            }
        }
    }

    private var notesView: some View {
        Group {
            if manager.isSplit {
                SlideView(
                    pdfPage: manager.page(at: manager.currentIndex),
                    cropRect: manager.notesRect(for: manager.currentIndex)
                )
            } else {
                ZStack {
                    Color.clear
                    Text("No notes")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var bottomBar: some View {
        HStack {
            Text(timerString)
                .font(.system(size: 36, weight: .medium, design: .monospaced))
                .foregroundStyle(timerPaused ? .yellow : .primary)

            Spacer()

            #if os(iOS)
            Button(action: { manager.previous() }) {
                Image(systemName: "chevron.left").font(.title2)
            }
            .buttonStyle(.bordered)

            Button(action: { manager.next() }) {
                Image(systemName: "chevron.right").font(.title2)
            }
            .buttonStyle(.bordered)

            Spacer()
            #endif

            Text("\(manager.currentIndex + 1) / \(manager.pageCount)")
                .font(.system(size: 24, design: .monospaced))
                .foregroundStyle(.secondary)
        }
        .frame(height: 50)
    }

    // MARK: - Timer

    private var timerString: String {
        let h = elapsedSeconds / 3600
        let m = (elapsedSeconds % 3600) / 60
        let s = elapsedSeconds % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }

    private func startTimer() {
        timerRunning = true
        timerPaused = false
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            elapsedSeconds += 1
        }
    }

    func toggleTimer() {
        if timerRunning {
            timer?.invalidate()
            timer = nil
            timerRunning = false
            timerPaused = true
        } else {
            startTimer()
        }
    }

    func resetTimer() {
        elapsedSeconds = 0
    }
}
