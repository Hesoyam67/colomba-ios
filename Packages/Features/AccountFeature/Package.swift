// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "AccountFeature",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "AccountFeature", targets: ["AccountFeature"])
    ],
    targets: [
        .target(name: "AccountFeature"),
        .testTarget(name: "AccountFeatureTests", dependencies: ["AccountFeature"])
    ]
)
