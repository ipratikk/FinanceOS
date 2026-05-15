// swift-tools-version: 6.3

import PackageDescription

let package = Package(
    name: "FinanceCore",
    platforms: [
        .macOS(.v15),
        .iOS(.v18)
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
    ],
    swiftLanguageModes: [.v6]
)
