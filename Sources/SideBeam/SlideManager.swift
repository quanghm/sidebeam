import Foundation
import PDFKit

/// Manages PDF loading, Beamer page splitting, and navigation state.
@Observable
public final class SlideManager {
    public enum SplitMode: String { case none, right, left }

    public private(set) var pdfDocument: PDFDocument?
    public private(set) var pageCount = 0
    public private(set) var currentIndex = 0
    public var splitMode: SplitMode = .none
    public var isBlank = false
    public var isSlideFullscreen = false
    public var isInteractionOverridden = false  // Pro features can suppress default gestures

    public init() {}

    // MARK: - Loading

    public func reset() {
        pdfDocument = nil
        pageCount = 0
        currentIndex = 0
        splitMode = .none
        isBlank = false
        isSlideFullscreen = false
        isInteractionOverridden = false
        onCloseCallbacks.forEach { $0() }
    }

    /// Pro features register cleanup callbacks here.
    public var onCloseCallbacks: [() -> Void] = []

    public func load(url: URL) -> Bool {
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }

        // Copy data so we don't hold the security scope
        guard let data = try? Data(contentsOf: url),
              let doc = PDFDocument(data: data) else { return false }
        pdfDocument = doc
        pageCount = doc.pageCount
        currentIndex = 0

        // Auto-detect split mode from aspect ratio
        if let firstPage = doc.page(at: 0) {
            let bounds = firstPage.bounds(for: .mediaBox)
            splitMode = bounds.width > bounds.height * 1.8 ? .right : .none
        }

        return true
    }

    // MARK: - Navigation

    public func goTo(index: Int) {
        let clamped = max(0, min(index, pageCount - 1))
        guard clamped != currentIndex else { return }
        currentIndex = clamped
    }

    public func next() { goTo(index: currentIndex + 1) }
    public func previous() { goTo(index: currentIndex - 1) }
    public func goToFirst() { goTo(index: 0) }
    public func goToLast() { goTo(index: pageCount - 1) }

    // MARK: - Page Rects

    public var isSplit: Bool { splitMode != .none }

    public func cycleSplitMode() {
        switch splitMode {
        case .none:  splitMode = .right
        case .right: splitMode = .left
        case .left:  splitMode = .none
        }
    }

    public func slideRect(for pageIndex: Int) -> CGRect? {
        guard isSplit, let page = pdfDocument?.page(at: pageIndex) else { return nil }
        let bounds = page.bounds(for: .mediaBox)
        let half = bounds.width / 2
        switch splitMode {
        case .none:  return nil
        case .right: return CGRect(x: 0, y: 0, width: half, height: bounds.height)
        case .left:  return CGRect(x: half, y: 0, width: half, height: bounds.height)
        }
    }

    public func notesRect(for pageIndex: Int) -> CGRect? {
        guard isSplit, let page = pdfDocument?.page(at: pageIndex) else { return nil }
        let bounds = page.bounds(for: .mediaBox)
        let half = bounds.width / 2
        switch splitMode {
        case .none:  return nil
        case .right: return CGRect(x: half, y: 0, width: half, height: bounds.height)
        case .left:  return CGRect(x: 0, y: 0, width: half, height: bounds.height)
        }
    }

    public func page(at index: Int) -> PDFPage? {
        pdfDocument?.page(at: index)
    }
}
