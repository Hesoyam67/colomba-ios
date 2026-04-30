// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "ColombaBilling",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "ColombaBilling", targets: ["ColombaBilling"])
    ],
    targets: [
        .target(name: "ColombaBilling"),
        .testTarget(name: "ColombaBillingTests", dependencies: ["ColombaBilling"])
    ]
)
