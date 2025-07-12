// swift-tools-version:6.0
import PackageDescription

// 设置该 Whooshing 服务模块的子模块
// 指定某个环境变量，则需要在 configure.swift 中实现相关的配置函数
// 可设置 .https 和 .api 两个
let WhooshingModules: [WhooshingModuleType] = [
    .https
]

enum WhooshingModuleType: String {
    case https = "HTTPS"
    case api = "API"
}

let package = Package(
    name: "manager",
    platforms: [
        .macOS(.v11),
        .iOS(.v13),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    dependencies: [
        // 💧 Vapor -- Swift 服务器端第三方框架
        .package(url: "https://github.com/SJJC-Team/whooshing-vapor.git", from: "1.0.6"),
        // 🔵 Swift 高性能网络通讯模块
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.65.0"),
        // 🗄 关系型和非关系型数据库的 ORM(对象关系映射)
        .package(url: "https://github.com/SJJC-Team/whooshing-fluent.git", from: "1.0.0"),
        // 🐘 对 PostgreSQL 的 Fluent 驱动器
        .package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.8.0"),

        .package(url: "https://github.com/apple/swift-nio-extras.git", from: "1.0.0"),

        .package(url: "https://github.com/SJJC-Team/whooshing.toolbox-basic.git", .upToNextMajor(from: "1.4.4")),

        .package(url: "https://github.com/SJJC-Team/whooshing.toolbox-pgsql.git", .upToNextMajor(from: "1.0.5")),
        
        .package(url: "https://github.com/SJJC-Team/whooshing.toolbox-server.git", .upToNextMajor(from: "1.1.7"))
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
            swiftSettings: swiftSettings
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

var swiftSettings: [SwiftSetting] {
    [
        .enableUpcomingFeature("DisableOutwardActorInference"),
        .enableExperimentalFeature("StrictConcurrency")
    ] +
    WhooshingModules.map { SwiftSetting.define($0.rawValue) }
}
