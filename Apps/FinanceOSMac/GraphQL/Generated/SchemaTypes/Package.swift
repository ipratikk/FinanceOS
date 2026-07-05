// swift-tools-version:6.1

import PackageDescription

let package = Package(
    name: "FinanceOSAPI",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .tvOS(.v15),
        .watchOS(.v8),
        .visionOS(.v1)
    ],
    products: [
        .library(name: "FinanceOSAPI", targets: ["FinanceOSAPI"])
    ],
    dependencies: [
        .package(url: "https://github.com/apollographql/apollo-ios", exact: "2.2.0")
    ],
    targets: [
        .target(
            name: "FinanceOSAPI",
            dependencies: [
                .product(name: "ApolloAPI", package: "apollo-ios")
            ],
            path: "./Sources"
        )
    ],
    swiftLanguageModes: [.v6, .v5]
)
