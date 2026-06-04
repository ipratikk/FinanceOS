// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "FinanceIntelligence",
    platforms: [
        .macOS("26.0"),
        .iOS("26.0")
    ],
    products: [
        .library(name: "FinanceIntelligence", targets: ["FinanceIntelligence"]),
        .executable(name: "FinanceIntelligenceCLI", targets: ["FinanceIntelligenceCLI"])
    ],
    dependencies: [
        .package(path: "../FinanceCore"),
        .package(path: "../FinanceTesting"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.0"),
        .package(url: "https://github.com/groue/GRDB.swift", from: "7.0.0"),
        .package(url: "https://github.com/huggingface/swift-transformers", from: "1.3.0"),
        .package(url: "https://github.com/weichsel/ZIPFoundation.git", from: "0.9.0"),
        .package(url: "https://github.com/ml-explore/mlx-swift", from: "0.21.0")
    ],
    targets: [
        .target(
            name: "FinanceIntelligence",
            dependencies: [
                "FinanceCore",
                .product(name: "GRDB", package: "GRDB.swift"),
                .product(name: "Transformers", package: "swift-transformers"),
                .product(name: "ZIPFoundation", package: "ZIPFoundation")
            ],
            resources: [.process("Resources/")]
        ),
        .executableTarget(
            name: "FinanceIntelligenceCLI",
            dependencies: [
                "FinanceIntelligence",
                "FinanceCore",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "GRDB", package: "GRDB.swift")
            ]
        ),
        .testTarget(
            name: "FinanceIntelligenceTests",
            dependencies: [
                "FinanceIntelligence",
                "FinanceCore",
                "FinanceTesting",
                .product(name: "GRDB", package: "GRDB.swift")
            ],
            resources: [.process("Resources")]
        )
    ]
)
