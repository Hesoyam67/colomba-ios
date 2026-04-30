// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "ColombaCustomerWorkspace",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "ColombaCustomerWorkspace", targets: ["ColombaCustomerWorkspace"])
    ],
    dependencies: [
        .package(path: "Packages/ColombaCore"),
        .package(path: "Packages/ColombaDesign"),
        .package(path: "Packages/ColombaNetworking"),
        .package(path: "Packages/ColombaAuth"),
        .package(path: "Packages/ColombaBilling"),
        .package(path: "Packages/Features/PlanFeature"),
        .package(path: "Packages/Features/UsageFeature"),
        .package(path: "Packages/Features/UpgradeFeature"),
        .package(path: "Packages/Features/TopUpFeature"),
        .package(path: "Packages/Features/ScheduledChangeFeature"),
        .package(path: "Packages/Features/InvoicesFeature"),
        .package(path: "Packages/Features/AccountFeature")
    ],
    targets: [
        .target(
            name: "ColombaCustomerWorkspace",
            dependencies: [
                "ColombaCore",
                "ColombaDesign",
                "ColombaNetworking",
                "ColombaAuth",
                "ColombaBilling",
                "PlanFeature",
                "UsageFeature",
                "UpgradeFeature",
                "TopUpFeature",
                "ScheduledChangeFeature",
                "InvoicesFeature",
                "AccountFeature"
            ]
        ),
        .testTarget(
            name: "ColombaCustomerWorkspaceTests",
            dependencies: ["ColombaCustomerWorkspace"]
        )
    ]
)
