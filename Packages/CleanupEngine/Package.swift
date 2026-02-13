// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CleanupEngine",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "CleanupEngine", targets: ["CleanupEngine"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "CleanupEngine",
            dependencies: []
        ),
        .testTarget(
            name: "CleanupEngineTests",
            dependencies: ["CleanupEngine"]
        ),
    ]
)
