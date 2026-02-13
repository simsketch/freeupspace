// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SharedUtilities",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "SharedUtilities", targets: ["SharedUtilities"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "SharedUtilities",
            dependencies: []
        ),
    ]
)
