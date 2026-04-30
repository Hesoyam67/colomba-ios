// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "TopUpFeature",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "TopUpFeature", targets: ["TopUpFeature"])
    ],
    targets: [
        .target(name: "TopUpFeature"),
        .testTarget(name: "TopUpFeatureTests", dependencies: ["TopUpFeature"])
    ]
)
