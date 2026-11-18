// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "EngHelper",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "EngHelperKit", targets: ["EngHelperKit"])
    ],
    targets: [
        .target(name: "EngHelperKit"),
        .testTarget(
            name: "EngHelperKitTests",
            dependencies: ["EngHelperKit"],
            resources: [.copy("Fixtures")]
        ),
    ]
)
