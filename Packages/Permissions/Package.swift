// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Permissions",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "Permissions", targets: ["Permissions"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "Permissions",
            dependencies: []
        ),
    ]
)
