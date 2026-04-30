// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "ColombaAuth",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "ColombaAuth", targets: ["ColombaAuth"])
    ],
    dependencies: [
        .package(path: "../ColombaNetworking")
    ],
    targets: [
        .target(
            name: "ColombaAuth",
            dependencies: ["ColombaNetworking"]
        ),
        .testTarget(name: "ColombaAuthTests", dependencies: ["ColombaAuth"])
    ]
)
