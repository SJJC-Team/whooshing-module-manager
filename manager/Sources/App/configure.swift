import NIOSSL
import Fluent
import FluentPostgresDriver
import Vapor
import Cryptos

public enum Whooshing {
    // 暂时如此设置，用以测试
    public static let root: Crypto.Symm.Key = Crypto.Symm.makeKey()
}

public func configure(_ app: Application) async throws {
    // 仅用做测试，不在生产环境中使用
    app.http.server.configuration.address = .hostname("0.0.0.0", port: 20000)

    app.databases.use(DatabaseConfigurationFactory.postgres(configuration: .init(
        hostname: "localhost",
        port: 5432,
        username: "woo",
        // 该密码仅为测试密码，无需担心泄露
        password: "testing",
        database: "postgres",
        tls: .prefer(try .init(configuration: .clientDefault)))
    ), as: .psql)
    
    app.migrations.add(Module.MIG())
    try await app.autoMigrate()
    try routes(app)
}
