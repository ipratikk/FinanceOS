// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "FinanceUI",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
        .macCatalyst(.v16)
    ],
    products: [
        .library(name: "FinanceUI", targets: ["FinanceUI"])
    ],
    targets: [
        .target(
            name: "FinanceUI",
            dependencies: []
        ),
        .testTarget(
            name: "FinanceUITests",
            dependencies: ["FinanceUI"]
        )
    ]
)
