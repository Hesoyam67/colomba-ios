// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "ColombaNetworking",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "ColombaNetworking", targets: ["ColombaNetworking"])
    ],
    targets: [
        .target(name: "ColombaNetworking"),
        .testTarget(name: "ColombaNetworkingTests", dependencies: ["ColombaNetworking"])
    ]
)
