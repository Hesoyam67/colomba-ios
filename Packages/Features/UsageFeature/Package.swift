// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "UsageFeature",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "UsageFeature", targets: ["UsageFeature"])
    ],
    targets: [
        .target(name: "UsageFeature"),
        .testTarget(name: "UsageFeatureTests", dependencies: ["UsageFeature"])
    ]
)
