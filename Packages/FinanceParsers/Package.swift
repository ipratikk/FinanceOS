// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "FinanceParsers",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "FinanceParsers",
            targets: ["FinanceParsers"]
        ),
        .executable(
            name: "FinanceParserCLI",
            targets: ["FinanceParserCLI"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.0"),
        .package(url: "https://github.com/swiftcsv/SwiftCSV", from: "0.10.0")
    ],
    targets: [
        .target(
            name: "FinanceParsers",
            dependencies: [
                .product(name: "SwiftCSV", package: "SwiftCSV")
            ],
            path: "Sources/FinanceParsers"
        ),
        .executableTarget(
            name: "FinanceParserCLI",
            dependencies: [
                "FinanceParsers",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ],
            path: "Sources/CLI"
        ),
        .testTarget(
            name: "FinanceParsersTests",
            dependencies: ["FinanceParsers"],
            path: "Tests",
            resources: [.process("Fixtures")]
        )
    ]
)
