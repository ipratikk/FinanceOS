// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "FinanceUI",
    platforms: [
        .macOS("26.0"),
        .iOS(.v17),
        .macCatalyst(.v16)
    ],
    products: [
        .library(name: "FinanceUI", targets: ["FinanceUI"])
    ],
    dependencies: [
        .package(path: "../FinanceCore")
    ],
    targets: [
        .target(
            name: "FinanceUI",
            dependencies: ["FinanceCore"]
        ),
        .testTarget(
            name: "FinanceUITests",
            dependencies: ["FinanceUI", "FinanceCore"]
        )
    ]
)
