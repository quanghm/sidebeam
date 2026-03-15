import AppKit
import PDFKit

/// Renders a cropped portion of a PDFPage.
final class SlideView: NSView {
    var pdfPage: PDFPage? { didSet { needsDisplay = true } }
    var cropRect: CGRect? { didSet { needsDisplay = true } } // nil = full page

    override var isFlipped: Bool { false }

    override func draw(_ dirtyRect: NSRect) {
        let ctx = NSGraphicsContext.current?.cgContext
        NSColor.controlBackgroundColor.setFill()
        ctx?.fill(bounds)

        guard let page = pdfPage,
              let context = ctx else {
            return
        }

        let pageRect = page.bounds(for: .mediaBox)
        let sourceRect = cropRect ?? pageRect

        // Calculate scaling to fit the view while maintaining aspect ratio
        let scaleX = bounds.width / sourceRect.width
        let scaleY = bounds.height / sourceRect.height
        let scale = min(scaleX, scaleY)

        let scaledWidth = sourceRect.width * scale
        let scaledHeight = sourceRect.height * scale
        let offsetX = (bounds.width - scaledWidth) / 2
        let offsetY = (bounds.height - scaledHeight) / 2

        context.saveGState()

        // Move to centered position, scale, then translate to crop origin
        context.translateBy(x: offsetX, y: offsetY)
        context.scaleBy(x: scale, y: scale)
        context.translateBy(x: -sourceRect.origin.x, y: -sourceRect.origin.y)

        // Clip to the source rect
        context.clip(to: sourceRect)

        // PDFPage.draw draws at the page's mediaBox origin
        page.draw(with: .mediaBox, to: context)

        context.restoreGState()

        // Draw border around the rendered page area
        let pageFrame = NSRect(x: offsetX, y: offsetY, width: scaledWidth, height: scaledHeight)
        NSColor.separatorColor.setStroke()
        let borderPath = NSBezierPath(roundedRect: pageFrame, xRadius: 2, yRadius: 2)
        borderPath.lineWidth = 1
        borderPath.stroke()
    }
}
