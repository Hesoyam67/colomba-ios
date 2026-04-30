// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "ScheduledChangeFeature",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "ScheduledChangeFeature", targets: ["ScheduledChangeFeature"])
    ],
    targets: [
        .target(name: "ScheduledChangeFeature"),
        .testTarget(name: "ScheduledChangeFeatureTests", dependencies: ["ScheduledChangeFeature"])
    ]
)
