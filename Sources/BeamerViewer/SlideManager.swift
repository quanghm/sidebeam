import Foundation
import PDFKit

/// Manages PDF loading, Beamer page splitting, and navigation state.
@Observable
final class SlideManager {
    enum SplitMode: String { case none, right, left }

    private(set) var pdfDocument: PDFDocument?
    private(set) var pageCount = 0
    private(set) var currentIndex = 0
    var splitMode: SplitMode = .none
    var isBlank = false

    // MARK: - Loading

    func reset() {
        pdfDocument = nil
        pageCount = 0
        currentIndex = 0
        splitMode = .none
        isBlank = false
    }

    func load(url: URL) -> Bool {
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

    func goTo(index: Int) {
        let clamped = max(0, min(index, pageCount - 1))
        guard clamped != currentIndex else { return }
        currentIndex = clamped
    }

    func next() { goTo(index: currentIndex + 1) }
    func previous() { goTo(index: currentIndex - 1) }
    func goToFirst() { goTo(index: 0) }
    func goToLast() { goTo(index: pageCount - 1) }

    // MARK: - Page Rects

    var isSplit: Bool { splitMode != .none }

    func cycleSplitMode() {
        switch splitMode {
        case .none:  splitMode = .right
        case .right: splitMode = .left
        case .left:  splitMode = .none
        }
    }

    func slideRect(for pageIndex: Int) -> CGRect? {
        guard isSplit, let page = pdfDocument?.page(at: pageIndex) else { return nil }
        let bounds = page.bounds(for: .mediaBox)
        let half = bounds.width / 2
        switch splitMode {
        case .none:  return nil
        case .right: return CGRect(x: 0, y: 0, width: half, height: bounds.height)
        case .left:  return CGRect(x: half, y: 0, width: half, height: bounds.height)
        }
    }

    func notesRect(for pageIndex: Int) -> CGRect? {
        guard isSplit, let page = pdfDocument?.page(at: pageIndex) else { return nil }
        let bounds = page.bounds(for: .mediaBox)
        let half = bounds.width / 2
        switch splitMode {
        case .none:  return nil
        case .right: return CGRect(x: half, y: 0, width: half, height: bounds.height)
        case .left:  return CGRect(x: 0, y: 0, width: half, height: bounds.height)
        }
    }

    func page(at index: Int) -> PDFPage? {
        pdfDocument?.page(at: index)
    }
}
