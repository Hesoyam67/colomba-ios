// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "UpgradeFeature",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "UpgradeFeature", targets: ["UpgradeFeature"])
    ],
    targets: [
        .target(name: "UpgradeFeature"),
        .testTarget(name: "UpgradeFeatureTests", dependencies: ["UpgradeFeature"])
    ]
)
