// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "ColombaDesign",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "ColombaDesign", targets: ["ColombaDesign"])
    ],
    targets: [
        .target(name: "ColombaDesign"),
        .testTarget(name: "ColombaDesignTests", dependencies: ["ColombaDesign"])
    ]
)
