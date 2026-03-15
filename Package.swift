// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "BeamerViewer",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "BeamerViewer",
            path: "Sources/BeamerViewer",
            exclude: ["Info.plist"],
            linkerSettings: [
                .unsafeFlags(["-Xlinker", "-framework", "-Xlinker", "Quartz"]),
            ]
        ),
    ]
)
