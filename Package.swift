// swift-tools-version: 5.6
import PackageDescription

let package = Package(
    name: "swift-async-shell",
    platforms: [
        .macOS(.v10_15),
    ],
    products: [
        .library(
            name: "AsyncShell",
            targets: ["AsyncShell"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-async-algorithms", .upToNextMinor(from: "0.0.1")),
    ],
    targets: [
        .target(
            name: "AsyncShell",
            dependencies: [
                .product(name: "AsyncAlgorithms", package: "swift-async-algorithms"),
            ]),
        .testTarget(
            name: "AsyncShellTests",
            dependencies: ["AsyncShell"]),
    ]
)
