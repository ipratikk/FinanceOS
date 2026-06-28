// swift-tools-version:5.9

import PackageDescription

let package = Package(
    name: "FinanceOSAPI",
    platforms: [
        .iOS(.v12),
        .macOS(.v10_14),
        .tvOS(.v12),
        .watchOS(.v5)
    ],
    products: [
        .library(name: "FinanceOSAPI", targets: ["FinanceOSAPI"])
    ],
    dependencies: [
        .package(url: "https://github.com/apollographql/apollo-ios", exact: "1.25.6")
    ],
    targets: [
        .target(
            name: "FinanceOSAPI",
            dependencies: [
                .product(name: "ApolloAPI", package: "apollo-ios")
            ],
            path: "./Sources"
        )
    ]
)
