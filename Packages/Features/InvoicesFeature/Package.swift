// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "InvoicesFeature",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "InvoicesFeature", targets: ["InvoicesFeature"])
    ],
    targets: [
        .target(name: "InvoicesFeature"),
        .testTarget(name: "InvoicesFeatureTests", dependencies: ["InvoicesFeature"])
    ]
)
