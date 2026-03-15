import SwiftUI

struct AboutView: View {
    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "dev"
    }

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.richtext")
                .font(.system(size: 48))
                .foregroundStyle(.teal)

            Text("SideBeam")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Version \(version)")
                .foregroundStyle(.secondary)

            Text("A native PDF presenter console for Beamer slides.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Divider().padding(.horizontal, 20)

            Link("Online Help", destination: URL(string: "https://quanghm.github.io/sidebeam/")!)
                .font(.callout)

            Divider().padding(.horizontal, 20)

            Text("Quang Hoang")
                .fontWeight(.medium)
            Text("quanghm@gmail.com")
                .foregroundStyle(.secondary)
                .font(.callout)
        }
        .padding(30)
        .frame(width: 350)
        .fixedSize(horizontal: false, vertical: true)
    }
}
