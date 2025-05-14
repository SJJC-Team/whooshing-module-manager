// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "manager",
    platforms: [
       .macOS(.v13)
    ],
    dependencies: [
        // 💧 Vapor -- Swift 服务器端第三方框架
        .package(url: "https://github.com/SJJC-Team/whooshing-vapor.git", from: "1.0.0"),
        // 🔵 Swift 高性能网络通讯模块
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.65.0"),
        // 🗄 关系型和非关系型数据库的 ORM(对象关系映射)
        .package(url: "https://github.com/SJJC-Team/whooshing-fluent.git", from: "1.0.0"),
        // 🐘 对 PostgreSQL 的 Fluent 驱动器
        .package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.8.0"),
        .package(url: "https://github.com/apple/swift-nio-extras.git", from: "1.0.0"),
        .package(url: "https://github.com/SJJC-Team/whooshing.toolbox-basic.git", .upToNextMajor(from: "1.2.3")),
        .package(url: "https://github.com/SJJC-Team/whooshing.toolbox-pgsql.git", .upToNextMajor(from: "1.0.0")),
        .package(url: "https://github.com/SJJC-Team/whooshing.toolbox-server.git", .upToNextMajor(from: "1.0.0"))
    ],
    targets: [
        .executableTarget(
            name: "App",
            dependencies: [
                .product(name: "Fluent", package: "whooshing-fluent"),
                .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
                .product(name: "Vapor", package: "whooshing-vapor"),
                .product(name: "NIOCore", package: "swift-nio"),
                .product(name: "NIOPosix", package: "swift-nio"),
                .product(name: "PgSQL", package: "whooshing.toolbox-pgsql"),
                .product(name: "WhooshingServer", package: "whooshing.toolbox-server"),
                .product(name: "NIOExtras", package: "swift-nio-extras"),
                .product(name: "Cryptos", package: "whooshing.toolbox-basic"),
                .product(name: "DataConvertable", package: "whooshing.toolbox-basic"),
                .product(name: "ErrorHandle", package: "whooshing.toolbox-basic"),
            ],
            swiftSettings: swiftSettings + ["HTTPS"].map { .define($0) }
        ),
        .testTarget(
            name: "AppTests",
            dependencies: [
                .target(name: "App"),
                .product(name: "VaporTesting", package: "whooshing-vapor"),
            ],
            swiftSettings: swiftSettings
        )
    ],
    swiftLanguageModes: [.v5]
)

var swiftSettings: [SwiftSetting] { [
    .enableUpcomingFeature("DisableOutwardActorInference"),
    .enableExperimentalFeature("StrictConcurrency"),
] }
