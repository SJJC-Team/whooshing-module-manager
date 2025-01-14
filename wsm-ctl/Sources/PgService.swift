import ArgumentParser
import Foundation

struct PgService: LCDS {
    static let name = "pgservice"
    static let shortName: String? = nil
    static let paraLabel = "端口"
    static let help = "PostgreSQL 服务"
    static let subCmds: [any ParsableCommand.Type] = [L.self, C.self, D.self, S.self, Restart.self, Start.self]

    struct L: List {
        typealias Super = PgService
        @Argument(help: "模块名称") var module: String
        func cmd(env: Env) throws -> [String] { 
            try Module.paraAvailable(module: module, env: env)
            let dirs = try Self.list(module: module, env: env) 
            let isEmpty = dirs.isEmpty
            if isEmpty { print("无 PostgreSQL 服务".info) }
            else { for dir in dirs { print(dir.info) } }
            return dirs
        }

        static func list(module: String, env: Env) throws -> [String] {
            let perconaDir = "\(env.dataDir)/\(module)/percona/"
            try FS.mkdir(path: perconaDir, slience: true, withIntermediates: true, output: false)
            let dirs = try FS.ls(path: perconaDir, dir: true, hiddenFile: false)
            return dirs
        }
    }
    
    struct C: Create {
        typealias Super = PgService

        @Argument(help: "模块名称") var module: String
        @Option(name: .shortAndLong, parsing: .upToNextOption, help: "PostgreSQL 将用于监听的端口号") var ports: [Int]
        var paras: [Int] { ports }
        func one(para port: Int, env: Env) throws {
            try Module.paraAvailable(module: module, env: env)

            let moduleDir = "\(env.dataDir)/\(module)"
            let dataDir = "\(moduleDir)/percona/\(port)"

            guard Tool.portAvailable(port: port) else { throw Err.portNotCorrect.d(String(port)) }
            guard FS.isExist(path: dataDir, dir: true) == false else { throw Err.serviceAlreadyExist.d(dataDir) }
            guard try Sh.run("lsof -i:\(port)", env: env).code != 0 else { throw Err.portOccupied.d(String(port)) }
            
            try Sh.Vault.login(env: env)
            let keyPath = "\(module)/\(port)/role/woo"
            try Sh.Vault.newKey(in: keyPath, env: env)
            let key = try Sh.Vault.getKey(in: keyPath, env: env)
            try FS.mkdir(path: dataDir, slience: true, withIntermediates: true)
            try FS.setPermissions(path: dataDir, owner: "woo", group: "whooshing", permissions: 0o700, recursive: true)
            try Sh.PG.create(module: module, port: port, key: key, env: env)
            try Sh.PG.restart(dataDir: dataDir, env: env)
        }
    }
    
    struct D: Delete {
        typealias Super = PgService

        @Argument(help: "模块名称") var module: String
        @Option(name: .shortAndLong, parsing: .upToNextOption, help: "PostgreSQL 服务的监听端口号") var ports: [Int]
        var paras: [Int] { ports }
        func one(para port: Int, env: Env) throws {
            try paraAvailable(module: module, port: port, env: env)
            let perconaDir =  env.dataDir + "/" + module + "/percona"
            let dataDir = "\(perconaDir)/\(port)"
            guard try Sh.run("lsof -i:\(port)", env: env).code != 0 else { throw Err.serviceIsRunning.d("\(port), 您不能删除正在运行的服务") }
            let backupName = Tool.bakName(name: String(port))
            try Sh.Vault.dbBackup(module: module, port: port, backupName: backupName, env: env)
            try Sh.Vault.deleteKey(in: "\(module)/\(port)", env: env)
            try? Sh.PG.stop(dataDir: dataDir, env: env)
            try FS.mkdir(path: perconaDir + "/.trash", slience: true, withIntermediates: true)
            try FS.mv(path: dataDir, to: perconaDir + "/.trash/" + backupName)
        }
    }
    
    struct S: Stop {
        typealias Super = PgService

        @Argument(help: "模块名称") var module: String
        @Option(name: .shortAndLong, parsing: .upToNextOption, help: "PostgreSQL 服务的监听端口号") var ports: [Int]
        var paras: [Int] { ports }
        func one(para port: Int, env: Env) throws {
            try paraAvailable(module: module, port: port, env: env)
            guard try Sh.run("lsof -i:\(port)", env: env).code == 0 else { throw Err.serviceIsNotRunning.d(String(port)) }
            let dataDir = "\(env.dataDir)/\(module)/percona/\(port)"
            try Sh.PG.stop(dataDir: dataDir, env: env)
        }
    }

    struct Restart: LCDExpand {
        typealias Super = PgService
        static let name: String = "restart"
        static let shortName: String? = "resta"
        static let help: String = "重启 "

        @Argument(help: "模块名称") var module: String
        @Option(name: .shortAndLong, parsing: .upToNextOption, help: "PostgreSQL 服务的监听端口号") var ports: [Int]
        var paras: [Int] { ports }
        func one(para port: Int, env: Env) throws {
            try paraAvailable(module: module, port: port, env: env)
            let dataDir = "\(env.dataDir)/\(module)/percona/\(port)"
            try Sh.PG.restart(dataDir: dataDir, env: env)
        }
    }

    struct Start: LCDExpand {
        typealias Super = PgService
        static let name: String = "start"
        static let shortName: String? = "sta"
        static let help: String = "启动 "

        @Argument(help: "模块名称") var module: String
        @Option(name: .shortAndLong, parsing: .upToNextOption, help: "PostgreSQL 服务的监听端口号") var ports: [Int]
        var paras: [Int] { ports }
        func one(para port: Int, env: Env) throws {
            try paraAvailable(module: module, port: port, env: env)
            guard try Sh.run("lsof -i:\(port)", env: env).code != 0 else { throw Err.serviceIsRunning.d(String(port)) }
            let dataDir = "\(env.dataDir)/\(module)/percona/\(port)"
            try Sh.PG.start(dataDir: dataDir, env: env)
        }
    }

    static func paraAvailable(module: String, port: Int, env: Env) throws {
        try Module.paraAvailable(module: module, env: env)
        let moduleDir = env.dataDir + "/" + module
        let dataDir = "\(moduleDir)/percona/\(port)"
        guard Tool.portAvailable(port: port) else { throw Err.portNotCorrect.d(String(port)) }
        guard FS.isExist(path: dataDir, dir: true) == true else { throw Err.serviceNotFound.d(dataDir) }
    }

    enum Err: String, ErrList {
        case portOccupied = "端口被占用"
        case portNotCorrect = "端口号不正确, 请在 1024 ~ 65535 之间"
        case pgDatabaseExist = "PostgreSQL 数据库未删除"
        case serviceAlreadyExist = "PostgreSQL 服务已存在"
        case serviceNotFound = "PostgreSQL 服务不存在"
        case serviceIsRunning = "PostgreSQL 服务正在运行"
        case serviceIsNotRunning = "PostgreSQL 服务未运行"
    }

}