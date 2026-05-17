// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "FinanceTesting",
    platforms: [
        .macOS(.v14),
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "FinanceTesting",
            targets: ["FinanceTesting"]
        )
    ],
    dependencies: [
        .package(path: "../FinanceCore"),
        .package(path: "../FinanceUI"),
        .package(
            url: "https://github.com/pointfreeco/swift-snapshot-testing",
            from: "1.17.0"
        )
    ],
    targets: [
        .target(
            name: "FinanceTesting",
            dependencies: [
                "FinanceCore",
                "FinanceUI",
                .product(
                    name: "SnapshotTesting",
                    package: "swift-snapshot-testing"
                )
            ],
            swiftSettings: [
                .unsafeFlags([
                    "-suppress-warnings"
                ])
            ]
        )
    ]
)
