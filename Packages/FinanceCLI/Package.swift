// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "FinanceCLI",
    platforms: [
        .macOS("26.0")
    ],
    products: [
        .executable(name: "FinanceCLI", targets: ["FinanceCLI"])
    ],
    dependencies: [
        .package(path: "../FinanceCore"),
        .package(path: "../FinanceParsers"),
        .package(path: "../FinanceIntelligence"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.0")
    ],
    targets: [
        .executableTarget(
            name: "FinanceCLI",
            dependencies: [
                "FinanceCore",
                "FinanceParsers",
                "FinanceIntelligence",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        )
    ]
)
