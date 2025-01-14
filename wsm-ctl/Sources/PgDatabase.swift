import ArgumentParser
import Foundation

struct PgDatabase: LCDS {

    static let name = "pgdatabase"
    static let shortName: String? = nil
    static let paraLabel = "数据库"
    static let help = "PostgreSQL 数据库"
    static let subCmds: [any ParsableCommand.Type] = [L.self, C.self, D.self]
    
    struct L: List {
        typealias Super = PgDatabase
        @Argument(help: "模块名称") var module: String
        @Option(name: .shortAndLong, help: "PostgreSQL 将用于监听的端口号") var port: Int
        func cmd(env: Env) throws -> [Sh.PG.Db.DataType] {
            try PgService.paraAvailable(module: module, port: port, env: env)
            guard try Sh.run("lsof -i:\(port)", env: env).code == 0 else { throw Err.serviceNotRunning.d(String(port)) }
            let res = try Self.list(module: module, port: port, env: env)
            if res.isEmpty { print("无数据库".info) }
            else { for db in res { print("\(db.db)(\(db.oid))".info) } }
            return res
        }

        static func list(module: String, port: Int, env: Env) throws -> [Sh.PG.Db.DataType] {
            let key = try Sh.Vault.getKey(in: "\(module)/\(port)/role/woo", env: env)
            return try Sh.PG.Db.list(port: port, key: key, env: env)
        }
    }
    
    struct C: Create {
        typealias Super = PgDatabase
        @Argument(help: "模块名称") var module: String
        @Option(name: .short, help: "PostgreSQL 将用于监听的端口号") var port: Int
        @Option(name: .shortAndLong, parsing: .upToNextOption, help: "要新建的 PostgreSQL 数据库名称") var databases: [String]
        var paras: [String] { databases }
        func one(para database: String, env: Env) throws -> () {
            try PgService.paraAvailable(module: module, port: port, env: env)
            guard try Sh.run("lsof -i:\(port)", env: env).code == 0 else { throw Err.serviceNotRunning.d(String(port)) }
            try Sh.Vault.login(env: env)
            let key = try Sh.Vault.getKey(in: "\(module)/\(port)/role/woo", env: env)
            guard try Sh.PG.Db.test(port: port, database: database, key: key, env: env) == false else { throw Err.dbAlreadyExist.d("\(module)/\(port)/\(database)") }
            try Sh.PG.Db.create(module: module, port: port, db: database, key: key, env: env)
        }
    }
    
    struct D: Delete {
        typealias Super = PgDatabase
        @Argument(help: "模块名称") var module: String
        @Option(name: .short, help: "PostgreSQL 服务的监听端口号") var port: Int
        @Option(name: .shortAndLong, parsing: .upToNextOption, help: "PostgreSQL 数据库名称") var databases: [String]
        var paras: [String] { databases }
        func one(para database: String, env: Env) throws -> () {
            let key = try paraAvailable(module: module, port: port, database: database, env: env)
            try Sh.PG.Db.delete(port: port, db: database, key: key, env: env)
            try Sh.Vault.deleteKey(in: "\(module)/\(port)/tde/\(database)_1", env: env)
        }
    }

    static func paraAvailable(module: String, port: Int, database: String, env: Env) throws -> String {
        try PgService.paraAvailable(module: module, port: port, env: env)
        guard try Sh.run("lsof -i:\(port)", env: env).code == 0 else { throw Err.serviceNotRunning.d(String(port)) }
        try Sh.Vault.login(env: env)
        let key = try Sh.Vault.getKey(in: "\(module)/\(port)/role/woo", env: env)
        guard try Sh.PG.Db.test(port: port, database: database, key: key, env: env) == true else { throw Err.dbNotExist.d("\(module)/\(port)/\(database)") }
        return key
    }
    
    enum Err: String, ErrList {
        case serviceNotRunning = "数据库服务未运行"
        case dbNotExist = "数据库不存在"
        case dbAlreadyExist = "数据库已存在"
    }

    struct S: Stop { typealias Super = PgDatabase; var paras: [()] { [] } }
}