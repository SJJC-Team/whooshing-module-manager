import ArgumentParser
import Foundation

struct PgDatabase: LCDS {

    static let name = "pgdatabase"

    static var subCmds: [any ParsableCommand.Type] { [L.self, C.self, D.self] }
    
    struct L: List {
        typealias Super = PgDatabase
        @Argument(help: "模块名称") var module: String
        @Option(name: .shortAndLong, help: "PostgreSQL 将用于监听的端口号") var port: Int
        
        func cmd(env: Env) throws -> () {
            let moduleDir = env.dataDir + "/" + module
            let dataDir = "\(moduleDir)/percona/\(port)"
            guard Tool.portAvailable(port: port) else { throw Err.portNotCorrect.d(String(port)) }
            guard FS.isExist(path: moduleDir, dir: true) == true else { throw Err.moduleNotFound.d(moduleDir) }
            guard FS.isExist(path: dataDir, dir: true) == true else { throw Err.serviceNotExist.d(dataDir) }
            guard try Sh.run("lsof -i:\(port)", env: env).code == 0 else { throw Err.serviceNotRunning.d(String(port)) }

            let key = try Sh.Vault.getKey(in: "\(module)/\(port)/role/woo", env: env)
            let res = try Sh.PG.Db.list(port: port, key: key, env: env)
            if res.isEmpty { print("无数据库".info) }
            else { for db in res { print("\(db.db)(\(db.oid))".info) } }
        }
    }
    
    struct C: Create {
        typealias Super = PgDatabase
        @Argument(help: "模块名称") var module: String
        @Option(name: .short, help: "PostgreSQL 将用于监听的端口号") var port: Int
        @Option(name: .shortAndLong, help: "要新建的 PostgreSQL 数据库名称") var database: String

        func cmd(env: Env) throws -> () {
            let moduleDir = env.dataDir + "/" + module
            let dataDir = "\(moduleDir)/percona/\(port)"
            guard Tool.portAvailable(port: port) else { throw Err.portNotCorrect.d(String(port)) }
            guard FS.isExist(path: moduleDir, dir: true) == true else { throw Err.moduleNotFound.d(moduleDir) }
            guard FS.isExist(path: dataDir, dir: true) == true else { throw Err.serviceNotExist.d(dataDir) }
            guard try Sh.run("lsof -i:\(port)", env: env).code == 0 else { throw Err.serviceNotRunning.d(String(port)) }

            try Sh.Vault.login(env: env)
            let key = try Sh.Vault.getKey(in: "\(module)/\(port)/role/woo", env: env)
            try Sh.PG.Db.create(module: module, port: port, db: database, key: key, env: env)
        }
    }
    
    struct D: Delete {
        typealias Super = PgDatabase
        @Argument(help: "模块名称") var module: String
        @Option(name: .short, help: "PostgreSQL 服务的监听端口号") var port: Int
        @Option(name: .shortAndLong, help: "PostgreSQL 数据库名称") var database: String

        func cmd(env: Env) throws -> () {
            let moduleDir = env.dataDir + "/" + module
            let dataDir = "\(moduleDir)/percona/\(port)"
            guard Tool.portAvailable(port: port) else { throw Err.portNotCorrect.d(String(port)) }
            guard FS.isExist(path: moduleDir, dir: true) == true else { throw Err.moduleNotFound.d(moduleDir) }
            guard FS.isExist(path: dataDir, dir: true) == true else { throw Err.serviceNotExist.d(dataDir) }
            guard try Sh.run("lsof -i:\(port)", env: env).code == 0 else { throw Err.serviceNotRunning.d(String(port)) }

            try Sh.Vault.login(env: env)
            let key = try Sh.Vault.getKey(in: "\(module)/\(port)/role/woo", env: env)
            try Sh.PG.Db.delete(port: port, db: database, key: key, env: env)
            try Sh.Vault.deleteKey(in: "\(module)/\(port)/tde/\(database)_1", env: env)
        }

    }
    
    struct S: Stop { typealias Super = PgDatabase }
    
    enum Err: String, ErrList {
        case moduleNotFound = "模块不存在"
        case serviceNotRunning = "该端口无服务正在运行"
        case serviceNotExist = "数据库服务不存在"
        case portNotCorrect = "端口号不正确, 请在 1024 ~ 65535 之间"
    }

}