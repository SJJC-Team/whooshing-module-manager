import Fluent
import FluentPostgresDriver

struct DatabaseDepends {

    static let port = 1
    static let moduleName = ".manager"
    static let database = "manager"
    static let basePort = 20000
    static let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
    static let db = Databases(threadPool: NIOThreadPool(numberOfThreads: 1), on: eventLoopGroup)

    static func initializeIfNeed(env: Env) throws -> Database {
        
        let moduleDir = "\(env.dataDir)/\(moduleName)"
        let dataDir = "\(moduleDir)/percona/\(port)"
        let p = basePort + port

        let needInit = try
            FS.isExist(path: dataDir, dir: true) == false ||
            Sh.isServing(port: p) == false || 
            PgDatabase.Action.NoCheck.list(module: moduleName, port: port, env: env, basePort: basePort).first(where: { $0.db == Self.database }) == nil ||
            Sh.PM2.isServing(name: "Whooshing.Manager", env: env) == false

        if needInit { print("需要进行系统初始化 --------------------------------".info) }

        try Module.Action.NoCheck.initIfNeeded(name: moduleName, basePort: basePort, env: env)
        try PgService.Action.NoCheck.initIfNeeded(module: moduleName, port: port, basePort: basePort, env: env)
        try PgDatabase.Action.NoCheck.initIfNeeded(module: moduleName, port: port, database: database, env: env, basePort: basePort)

        let webPath = "\(moduleDir)/web/bundle"
        let configPath = "\(webPath)/pm2.config.json"
        if try Sh.PM2.isServing(name: "Whooshing.Manager", env: env) == false {
            print("管理模块未运行，正在初始化...".info)
            let envPrefix = "WHOOSHING_HTTPS_SERVICE"
            let key = try Sh.Vault.getKey(in: "\(moduleName)/\(port)/role/woo", env: env)
            let envParas: [String: String] = [
                envPrefix + "_DB_COUNT": "1",
                envPrefix + "_NAME": "Manager",
                envPrefix + "_PORT": String(basePort),
                envPrefix + "_DB_1_NAME": database,
                envPrefix + "_DB_1_PORT": String(basePort + port),
                envPrefix + "_DB_1_USER": "woo",
                envPrefix + "_DB_1_PASSWORD": key,
                envPrefix + "_MANAGER_URL": "http://localhost:20000"
            ]
            // print(envParas.map { "\($0.key)=\($0.value)" }.joined(separator: " "))
            try Sh.PM2.start(configFile: configPath, args: envParas, cwd: webPath, env: env)
            print("管理模块初始化完成".succ)
        }

        if needInit { print("系统初始化完成 ------------------------------------\n\n".info) }

        let password = try Sh.Vault.getKey(in: "\(moduleName)/\(port)/role/woo", env: env)

        let configuration = SQLPostgresConfiguration(
            hostname: "localhost",
            port: p,
            username: "woo",
            password: password,
            database: database,
            tls: .disable
        )

        let eventLoop = eventLoopGroup.next()

        do {
            db.use(.postgres(configuration: configuration), as: .psql)
            guard let db = db.database(.psql, logger: .init(label: "woo.manager.log"), on: eventLoop) else { throw Err.dbInitFailed.d("未能成功获取数据库实例") }
            return db
        } catch let err {
            db.shutdown()
            try? eventLoopGroup.syncShutdownGracefully()
            throw Err.dbInitFailed.d(err.localizedDescription)
        }
    }

    enum Err: String, ErrList {
        case dbInitFailed = "数据库初始化失败"
        case dbMigrationFailed = "数据库迁移失败"
    }
}