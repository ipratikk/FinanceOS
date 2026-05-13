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
        )
    ],
    targets: [
        .target(
            name: "FinanceCore",
            dependencies: [
                .product(
                    name: "GRDB",
                    package: "GRDB.swift"
                )
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
    ],
    swiftLanguageModes: [.v6]
)
