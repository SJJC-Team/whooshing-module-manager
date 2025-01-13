import ArgumentParser
import Foundation

struct PgService: LCDS {
    static let name = "pgservice"

    static var subCmds: [any ParsableCommand.Type] { [L.self, C.self, D.self, S.self, Restart.self, Start.self] }

    struct L: List {
        typealias Super = PgService

        @Argument(help: "模块名称") var module: String

        func cmd(env: Env) throws {
            let perconaDir = env.dataDir + "/" + module + "/percona"
            let dirs = try FS.ls(path: perconaDir, dir: true, hiddenFile: false)
            if dirs.isEmpty { print("无 PostgreSQL 服务".info) }
            for dir in dirs { print(dir.info) }
        }
    }
    
    struct C: Create {
        typealias Super = PgService

        @Argument(help: "模块名称") var module: String
        @Option(name: .short, help: "PostgreSQL 将用于监听的端口号") var port: Int

        func cmd(env: Env) throws {
            let moduleDir = env.dataDir + "/" + module
            let dataDir = "\(moduleDir)/percona/\(port)"
            
            guard Tool.portAvailable(port: port) else { throw Err.portNotCorrect.d(String(port)) }
            guard FS.isExist(path: moduleDir, dir: true) == true else { throw Err.moduleNotFound.d(moduleDir) }
            guard FS.isExist(path: dataDir, dir: true) == false else { throw Err.serviceAlreadyExist.d(dataDir) }
            guard try Sh.run("lsof -i:\(port)", env: env).code != 0 else { throw Err.portOccupied.d(String(port)) }
            
            try Sh.Vault.login(env: env)
            try FS.mkdir(path: dataDir, slience: true, withIntermediates: true)
            try FS.setPermissions(path: dataDir, owner: "woo", group: "whooshing", permissions: 0o700, recursive: true)

            let keyPath = "\(module)/\(port)/role/woo"
            try Sh.Vault.newKey(in: keyPath, env: env)
            let key = try Sh.Vault.getKey(in: keyPath, env: env)
            try Sh.PG.initS(module: module, port: port, key: key, env: env)
            try Sh.PG.restart(dataDir: dataDir, env: env)
        }
    }
    
    struct D: Delete {
        typealias Super = PgService

        @Argument(help: "模块名称") var module: String
        @Option(name: .short, help: "PostgreSQL 服务的监听端口号") var port: Int

        func cmd(env: Env) throws {
            let moduleDir = env.dataDir + "/" + module
            let perconaDir =  moduleDir + "/percona"
            let dataDir = "\(perconaDir)/\(port)"

            guard Tool.portAvailable(port: port) else { throw Err.portNotCorrect.d(String(port)) }
            guard FS.isExist(path: moduleDir, dir: true) == true else { throw Err.moduleNotFound.d(moduleDir) }

            let backupName = Tool.bakName(name: String(port))

            // todo: 数据库处理？

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
        @Option(name: .short, help: "PostgreSQL 服务的监听端口号") var port: Int

        func cmd(env: Env) throws {
            let dataDir = "\(env.dataDir)/\(module)/percona/\(port)"
            try Sh.PG.stop(dataDir: dataDir, env: env)
        }
    }

    struct Restart: LCDCmd {
        typealias Super = PgService
        static var name: String { "restart" }

        @Argument(help: "模块名称") var module: String
        @Option(name: .short, help: "PostgreSQL 服务的监听端口号") var port: Int

        func cmd(env: Env) throws {
            let dataDir = "\(env.dataDir)/\(module)/percona/\(port)"
            try Sh.PG.restart(dataDir: dataDir, env: env)
        }
    }

    struct Start: LCDCmd {
        typealias Super = PgService
        static var name: String { "start" }

        @Argument(help: "模块名称") var module: String
        @Option(name: .short, help: "PostgreSQL 服务的监听端口号") var port: Int

        func cmd(env: Env) throws {
            let dataDir = "\(env.dataDir)/\(module)/percona/\(port)"
            try Sh.PG.start(dataDir: dataDir, env: env)
        }
    }

    enum Err: String, ErrList {
        case moduleNotFound = "模块不存在"
        case portOccupied = "端口被占用"
        case portNotCorrect = "端口号不正确, 请在 1024 ~ 65535 之间"
        case serviceAlreadyExist = "PostgreSQL 服务已存在"
    }

}