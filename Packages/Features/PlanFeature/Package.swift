// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "PlanFeature",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "PlanFeature", targets: ["PlanFeature"])
    ],
    targets: [
        .target(name: "PlanFeature"),
        .testTarget(name: "PlanFeatureTests", dependencies: ["PlanFeature"])
    ]
)
