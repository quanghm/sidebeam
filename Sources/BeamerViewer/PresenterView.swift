import SwiftUI
import PDFKit

struct PresenterView: View {
    var manager: SlideManager
    var onClose: (() -> Void)?
    var onToggleFullscreen: (() -> Void)?
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
        #if os(iOS)
        .gesture(
            DragGesture(minimumDistance: 50)
                .onEnded { value in
                    if value.translation.width < -50 { manager.next() }
                    else if value.translation.width > 50 { manager.previous() }
                }
        )
        #endif
        .onAppear { startTimer() }
        .onDisappear { stopTimer() }
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
                .font(.system(size: 20, weight: .bold, design: .monospaced))
                .foregroundStyle(timerPaused ? .black : .black)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(
                    Capsule().fill(timerPaused ? Color.yellow : Color.accentColor)
                )

            GeometryReader { geo in
                let progress = manager.pageCount > 1
                    ? Double(manager.currentIndex) / Double(manager.pageCount - 1)
                    : 0
                ZStack {
                    // Thin progress bar behind
                    VStack {
                        Spacer()
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(.secondary.opacity(0.15))
                                .frame(height: 4)
                            Capsule()
                                .fill(Color.accentColor)
                                .frame(width: max(4, geo.size.width * progress), height: 4)
                        }
                        Spacer()
                    }

                    // Slide counter pill on top, centered on the bar
                    Text("\(manager.currentIndex + 1) / \(manager.pageCount)")
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(
                            Capsule().fill(.background)
                                .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
                        )
                        .overlay(
                            Capsule().strokeBorder(.secondary.opacity(0.2), lineWidth: 1)
                        )
                }
                .frame(maxHeight: .infinity, alignment: .center)
            }

            Button(action: { manager.previous() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.accentColor)
                    .frame(width: 32, height: 32)
                    .background(Circle().strokeBorder(Color.accentColor.opacity(0.3), lineWidth: 1))
            }
            .buttonStyle(.plain)

            Button(action: { manager.next() }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.accentColor)
                    .frame(width: 32, height: 32)
                    .background(Circle().strokeBorder(Color.accentColor.opacity(0.3), lineWidth: 1))
            }
            .buttonStyle(.plain)

            if let onToggleFullscreen {
                Button(action: onToggleFullscreen) {
                    Image(systemName: "rectangle.inset.filled.and.person.filled")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.accentColor)
                        .frame(width: 32, height: 32)
                        .background(Circle().strokeBorder(Color.accentColor.opacity(0.3), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }

            if let onClose {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.red)
                        .frame(width: 32, height: 32)
                        .background(Circle().strokeBorder(.red.opacity(0.5), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
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

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        timerRunning = false
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
