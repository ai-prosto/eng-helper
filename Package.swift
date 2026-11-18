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
            // Lowercase `tests/` so the same directory also hosts the
            // pytest bridge that CI invokes as `pytest tests`.
            path: "tests/EngHelperKitTests",
            resources: [.copy("Fixtures")]
        ),
    ]
)
