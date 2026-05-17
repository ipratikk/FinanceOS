// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "FinanceCore",
    platforms: [
        .macOS(.v14),
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
        .package(
            url: "https://github.com/swiftcsv/SwiftCSV",
            from: "0.10.0"
        ),
        .package(path: "../FinanceParsers")
    ],
    targets: [
        .target(
            name: "FinanceCore",
            dependencies: [
                .product(
                    name: "GRDB",
                    package: "GRDB.swift"
                ),
                .product(
                    name: "SwiftCSV",
                    package: "SwiftCSV"
                ),
                "FinanceParsers"
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
                ),
                .product(
                    name: "SwiftCSV",
                    package: "SwiftCSV"
                )
            ]
        )
    ]
)
