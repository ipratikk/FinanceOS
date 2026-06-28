// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "FinanceCore",
    platforms: [
        .macOS("26.0"),
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "FinanceCore",
            targets: ["FinanceCore"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/groue/GRDB.swift",
            from: "7.0.0"
        ),
        .package(path: "../FinanceParsers"),
        .package(
            url: "https://github.com/apollographql/apollo-ios",
            from: "1.25.0"
        )
    ],
    targets: [
        .target(
            name: "FinanceCore",
            dependencies: [
                .product(
                    name: "GRDB",
                    package: "GRDB.swift"
                ),
                "FinanceParsers",
                .product(name: "Apollo", package: "apollo-ios"),
                .product(name: "ApolloAPI", package: "apollo-ios")
            ],
            resources: [
                .process("Resources/")
            ]
        ),
        .testTarget(
            name: "FinanceCoreTests",
            dependencies: [
                "FinanceCore",
                .product(
                    name: "GRDB",
                    package: "GRDB.swift"
                )
            ]
        )
    ]
)
