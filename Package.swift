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
    ],
    targets: [
        .target(
            name: "AsyncShell",
            dependencies: []),
        .testTarget(
            name: "AsyncShellTests",
            dependencies: ["AsyncShell"]),
    ]
)
