// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "MacMind",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "MacMind",
            targets: ["MacMind"]
        ),
    ],
    targets: [
        .target(
            name: "MacMind",
            dependencies: []
        ),
        .testTarget(
            name: "MacMindTests",
            dependencies: ["MacMind"]
        )
    ]
)
