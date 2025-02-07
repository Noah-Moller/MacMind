// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MacMind",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "MacMind",
            targets: ["MacMind"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/scinfu/SwiftSoup.git", .upToNextMajor(from: "2.7.7")),
    ],
    targets: [
        .target(
            name: "MacMind",
            dependencies: [.product(name: "SwiftSoup", package: "SwiftSoup")],
            resources: [
                .copy("../../Models/Resnet50.mlpackage")
            ]
        ),
        .testTarget(
            name: "MacMindTests",
            dependencies: ["MacMind"]
        )
    ]
)
