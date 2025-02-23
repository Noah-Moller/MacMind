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
        .executable(
            name: "macmind-server",
            targets: ["MacMindServer"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/scinfu/SwiftSoup.git", .upToNextMajor(from: "2.7.7")),
        .package(url: "https://github.com/vapor/vapor.git", from: "4.89.0"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.0"),
    ],
    targets: [
        .target(
            name: "MacMind",
            dependencies: [
                .product(name: "SwiftSoup", package: "SwiftSoup")
            ],
            resources: [
                .copy("../../Models/Resnet50.mlpackage")
            ]
        ),
        .executableTarget(
            name: "MacMindServer",
            dependencies: [
                "MacMind",
                .product(name: "Vapor", package: "vapor"),
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        ),
        .testTarget(
            name: "MacMindTests",
            dependencies: ["MacMind"]
        )
    ]
)
