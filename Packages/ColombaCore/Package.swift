// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "ColombaCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "ColombaCore", targets: ["ColombaCore"])
    ],
    targets: [
        .target(name: "ColombaCore"),
        .testTarget(name: "ColombaCoreTests", dependencies: ["ColombaCore"])
    ]
)
