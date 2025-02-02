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
            path: "Sources/MacMind",
            resources: [
                // Adjust the relative path to point from Sources/MacMind to the package's Resources folder.
                .copy("../../Resources")
            ]
        ),
        .testTarget(
            name: "MacMindTests",
            dependencies: ["MacMind"]
        )
    ]
)
