// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "wsm",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.5.0"),
        .package(url: "https://github.com/thebarndog/swift-dotenv.git", from: "2.1.0"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.1.3"),
        .package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.10.0"),
        .package(url: "https://github.com/SJJC-Team/cloudflare-dns.git", .upToNextMajor(from: "1.0.7")),
        .package(url: "https://github.com/SJJC-Team/whooshing-fluent.git", .upToNextMajor(from: "1.0.0")),
        .package(url: "https://github.com/SJJC-Team/whooshing.toolbox-basic.git", .upToNextMajor(from: "1.2.3")),
        .package(url: "https://github.com/SJJC-Team/whooshing.toolbox-pgsql.git", .upToNextMajor(from: "1.0.0")),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "wsm",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "SwiftDotenv", package: "swift-dotenv"),
                .product(name: "Yams", package: "Yams"),
                .product(name: "Fluent", package: "whooshing-fluent"),
                .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
                .product(name: "CloudflareDNS", package: "cloudflare-dns"),
                .product(name: "PgSQL", package: "whooshing.toolbox-pgsql"),
                .product(name: "Cryptos", package: "whooshing.toolbox-basic"),
                .product(name: "DataConvertable", package: "whooshing.toolbox-basic"),
                .product(name: "ErrorHandle", package: "whooshing.toolbox-basic"),
            ],
            resources: [
                .process("Shell")
            ]
        )
    ]
)
