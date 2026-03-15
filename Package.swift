// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "BeamerViewer",
    platforms: [.macOS(.v14), .iOS(.v17)],
    targets: [
        .executableTarget(
            name: "BeamerViewer",
            path: "Sources/BeamerViewer",
            exclude: ["Info.plist"]
        ),
    ]
)
