import SwiftUI
import PDFKit

public struct PresenterView: View {
    public var manager: SlideManager
    public var onClose: (() -> Void)?
    public var onShowProjector: (() -> Void)?
    public var onHideProjector: (() -> Void)?
    public var slideOverlay: AnyView?
    public var extraToolbarButtons: AnyView?
    public var extraMenuItems: AnyView?
    @State private var showOverflowMenu = false
    @State private var elapsedSeconds = 0
    @State private var timerRunning = false
    @State private var timerPaused = false
    @State private var timer: Timer?

    public init(
        manager: SlideManager,
        onClose: (() -> Void)? = nil,
        onShowProjector: (() -> Void)? = nil,
        onHideProjector: (() -> Void)? = nil,
        slideOverlay: AnyView? = nil,
        extraToolbarButtons: AnyView? = nil,
        extraMenuItems: AnyView? = nil
    ) {
        self.manager = manager
        self.onClose = onClose
        self.onShowProjector = onShowProjector
        self.onHideProjector = onHideProjector
        self.slideOverlay = slideOverlay
        self.extraToolbarButtons = extraToolbarButtons
        self.extraMenuItems = extraMenuItems
    }

    public var body: some View {
        VStack(spacing: 8) {
            switch manager.viewMode {
            case .focus, .mirror:
                currentSlide
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .rehearse, .sideBeam:
                HStack(spacing: 8) {
                    currentSlide
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    VStack(spacing: 8) {
                        nextSlide
                            .frame(maxWidth: .infinity, maxHeight: .infinity)

                        notesView
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            bottomBar
        }
        .padding(8)
        .overlay(alignment: .topTrailing) {
            HStack(spacing: 4) {
                if manager.viewMode != .sideBeam {
                    Text(viewModeLabel)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color.accentColor))
                }
                if manager.isSplit {
                    Text("Split: \(manager.splitMode == .right ? "R" : "L")")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(.orange))
                }
            }
            .padding(12)
            .allowsHitTesting(false)
        }
        #if os(iOS)
        .gesture(
            DragGesture(minimumDistance: 50)
                .onEnded { value in
                    if value.translation.width < -50 { manager.next() }
                    else if value.translation.width > 50 { manager.previous() }
                },
            isEnabled: !manager.isInteractionOverridden
        )
        #endif
        .onAppear { startTimer() }
        .onDisappear { stopTimer() }
    }

    // MARK: - Subviews

    private var currentSlide: some View {
        ZStack {
            SlideView(
                pdfPage: manager.page(at: manager.currentIndex),
                cropRect: manager.isSplit ? manager.slideRect(for: manager.currentIndex) : nil
            )
            if let slideOverlay { slideOverlay }
        }
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
        HStack(spacing: 12) {
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
                    .frame(width: 44, height: 32)
                    .background(Capsule().strokeBorder(Color.accentColor.opacity(0.3), lineWidth: 1))
            }
            .buttonStyle(.plain)

            Button(action: { manager.next() }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.accentColor)
                    .frame(width: 44, height: 32)
                    .background(Capsule().strokeBorder(Color.accentColor.opacity(0.3), lineWidth: 1))
            }
            .buttonStyle(.plain)

            // Pro extension point — extra toolbar buttons (e.g. annotations)
            if let extraToolbarButtons { extraToolbarButtons }

            // Overflow menu
            Button { showOverflowMenu.toggle() } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.accentColor)
                    .frame(width: 44, height: 32)
                    .background(Capsule().strokeBorder(Color.accentColor.opacity(0.3), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showOverflowMenu) {
                VStack(alignment: .leading, spacing: 0) {
                    overflowMenuSection("View Mode") {
                        overflowMenuItem("SideBeam", icon: "rectangle.split.2x1", active: manager.viewMode == .sideBeam) {
                            setViewMode(.sideBeam); showOverflowMenu = false
                        }
                        overflowMenuItem("Rehearse", icon: "person.fill", active: manager.viewMode == .rehearse) {
                            setViewMode(.rehearse); showOverflowMenu = false
                        }
                        overflowMenuItem("Focus", icon: "rectangle.center.inset.filled", active: manager.viewMode == .focus) {
                            setViewMode(.focus); showOverflowMenu = false
                        }
                        overflowMenuItem("Mirror", icon: "rectangle.on.rectangle", active: manager.viewMode == .mirror) {
                            setViewMode(.mirror); showOverflowMenu = false
                        }
                    }

                    Divider().padding(.vertical, 4)

                    overflowMenuSection("Split Mode") {
                        overflowMenuItem("None", icon: "rectangle", active: manager.splitMode == .none) {
                            manager.splitMode = .none; showOverflowMenu = false
                        }
                        overflowMenuItem("Notes Right", icon: "rectangle.righthalf.inset.filled", active: manager.splitMode == .right) {
                            manager.splitMode = .right; showOverflowMenu = false
                        }
                        overflowMenuItem("Notes Left", icon: "rectangle.lefthalf.inset.filled", active: manager.splitMode == .left) {
                            manager.splitMode = .left; showOverflowMenu = false
                        }
                    }

                    if let extraMenuItems {
                        Divider().padding(.vertical, 4)
                        extraMenuItems
                    }
                }
                .padding(12)
                .frame(minWidth: 200)
            }

            if let onClose {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.red)
                        .frame(width: 44, height: 32)
                        .background(Capsule().strokeBorder(.red.opacity(0.5), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
        .frame(height: 50)
    }

    private var viewModeLabel: String {
        switch manager.viewMode {
        case .rehearse:  return "Rehearse"
        case .sideBeam:  return "SideBeam"
        case .focus:     return "Focus"
        case .mirror:    return "Mirror"
        }
    }

    private func setViewMode(_ mode: SlideManager.ViewMode) {
        manager.viewMode = mode
        let needsProjector = (mode == .sideBeam || mode == .mirror)
        if needsProjector {
            onShowProjector?()
        } else {
            onHideProjector?()
        }
    }

    // MARK: - Overflow Menu Helpers

    private func overflowMenuSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.bottom, 2)
            content()
        }
    }

    private func overflowMenuItem(_ label: String, icon: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .frame(width: 20)
                    .foregroundColor(active ? .accentColor : .primary)
                Text(label)
                    .foregroundColor(.primary)
                Spacer()
                if active {
                    Image(systemName: "checkmark")
                        .foregroundColor(.accentColor)
                        .font(.caption)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(active ? Color.accentColor.opacity(0.1) : .clear)
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
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

    public func toggleTimer() {
        if timerRunning {
            timer?.invalidate()
            timer = nil
            timerRunning = false
            timerPaused = true
        } else {
            startTimer()
        }
    }

    public func resetTimer() {
        elapsedSeconds = 0
    }
}
