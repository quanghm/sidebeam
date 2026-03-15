import SwiftUI
import PDFKit

/// Renders a cropped portion of a PDFPage with a border around the page content.
struct SlideView: View {
    let pdfPage: PDFPage?
    let cropRect: CGRect?

    var body: some View {
        Canvas { context, size in
            // Background
            // Transparent background — inherits from parent

            guard let page = pdfPage else { return }

            let pageRect = page.bounds(for: .mediaBox)
            let sourceRect = cropRect ?? pageRect

            let scaleX = size.width / sourceRect.width
            let scaleY = size.height / sourceRect.height
            let scale = min(scaleX, scaleY)

            let scaledWidth = sourceRect.width * scale
            let scaledHeight = sourceRect.height * scale
            let offsetX = (size.width - scaledWidth) / 2
            let offsetY = (size.height - scaledHeight) / 2

            // White "paper" background for the PDF content area
            let pageFrame = CGRect(x: offsetX, y: offsetY, width: scaledWidth, height: scaledHeight)
            context.fill(Path(pageFrame), with: .color(.white))

            // Render PDF page
            context.drawLayer { ctx in
                ctx.withCGContext { cgContext in
                    cgContext.saveGState()
                    // Flip + position for PDF coordinate system
                    cgContext.translateBy(x: offsetX, y: offsetY + scaledHeight)
                    cgContext.scaleBy(x: scale, y: -scale)
                    cgContext.translateBy(x: -sourceRect.origin.x, y: -sourceRect.origin.y)
                    cgContext.clip(to: sourceRect)
                    page.draw(with: .mediaBox, to: cgContext)
                    cgContext.restoreGState()
                }
            }

            // Border around the rendered page area
            context.stroke(Path(roundedRect: pageFrame, cornerRadius: 2),
                          with: .color(.gray.opacity(0.3)),
                          lineWidth: 1)
        }
    }
}
