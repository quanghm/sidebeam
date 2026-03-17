import SwiftUI
import PDFKit

public struct ProjectorView: View {
    public var manager: SlideManager
    public var slideOverlay: AnyView?

    public init(manager: SlideManager, slideOverlay: AnyView? = nil) {
        self.manager = manager
        self.slideOverlay = slideOverlay
    }

    public var body: some View {
        Group {
            if manager.isBlank {
                Color.black
            } else {
                ZStack {
                    SlideView(
                        pdfPage: manager.page(at: manager.currentIndex),
                        cropRect: manager.isSplit ? manager.slideRect(for: manager.currentIndex) : nil
                    )
                    if let slideOverlay { slideOverlay }
                }
            }
        }
        .background(.black)
        .ignoresSafeArea()
    }
}
