import Fluent
import FluentPostgresDriver

struct Database {

    static let port = 20001
    static let moduleName = ".manager"
    static let database = "manager"
    
    static func initializeIfNeed(env: Env) throws -> PostgresDatabase {
        
        let moduleDir = "\(env.dataDir)/\(moduleName)"
        let dataDir = "\(moduleDir)/percona/\(port)"

        if FS.isExist(path: moduleDir, dir: true) == false { try Module.Action.NoCheck.create(name: moduleName, env: env) }
        if FS.isExist(path: dataDir, dir: true) == false { try PgService.Action.NoCheck.create(module: moduleName, port: port, env: env) }
        if try Sh.isServing(port: port) == false { try PgService.Action.NoCheck.restart(module: moduleName, port: port, env: env) }
        if try PgDatabase.Action.list(module: moduleName, port: port, env: env).first(where: { $0.db == Self.database }) == nil { try PgDatabase.Action.NoCheck.create(module: moduleName, port: port, database: database, env: env) }
        
        let password = try Sh.Vault.getKey(in: "\(moduleName)/\(port)/role/woo", env: env)

        let configuration = SQLPostgresConfiguration(
            hostname: "localhost",
            port: port,
            username: "woo",
            password: password,
            database: database,
            tls: .disable
        )

        let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
        let db = Databases(threadPool: NIOThreadPool(numberOfThreads: 1), on: eventLoopGroup)
        db.use(.postgres(configuration: configuration), as: .psql)

        defer {
            db.shutdown()
            try? eventLoopGroup.syncShutdownGracefully()
        }

        guard let db = db.database(.psql, logger: .init(label: "woo.manager.log"), on: eventLoopGroup.next()) as? PostgresDatabase else { throw Err.dbInitFailed.d("未能成功获取 PostgreSQL 数据库实例") }
        return db
    }

    enum Err: String, ErrList {
        case dbInitFailed = "数据库初始化失败"
    }
}