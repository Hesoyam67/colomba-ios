// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "ColombaAuth",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "ColombaAuth", targets: ["ColombaAuth"])
    ],
    targets: [
        .target(name: "ColombaAuth"),
        .testTarget(name: "ColombaAuthTests", dependencies: ["ColombaAuth"])
    ]
)
