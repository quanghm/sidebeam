import SwiftUI
import PDFKit

struct ProjectorView: View {
    var manager: SlideManager

    var body: some View {
        Group {
            if manager.isBlank {
                Color.black
            } else {
                SlideView(
                    pdfPage: manager.page(at: manager.currentIndex),
                    cropRect: manager.isSplit ? manager.slideRect(for: manager.currentIndex) : nil
                )
            }
        }
        .background(.black)
        .ignoresSafeArea()
    }
}
