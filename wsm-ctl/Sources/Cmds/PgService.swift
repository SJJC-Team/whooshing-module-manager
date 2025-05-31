import ArgumentParser
import Foundation

struct PgService: LCDS {
    static let name = "pgservice"
    static let shortName: String? = "pg"
    static let paraLabel = "端口"
    static let help = "PostgreSQL 服务"
    static let subCmds: [any ParsableCommand.Type] = [L.self, C.self, D.self, S.self, Restart.self, Start.self]

    struct L: List {
        typealias Super = PgService
        @Argument(help: "模块名称") var module: String
        func cmd(env: Env, depends: Depends) throws -> [String] { 
            let dirs = try Action.list(module: module, env: env, depends: depends) 
            let isEmpty = dirs.isEmpty
            if isEmpty { print("无 PostgreSQL 服务".info) }
            else { for dir in dirs { print(dir.info) } }
            return dirs
        }
    }
    
    struct C: Create {
        typealias Super = PgService
        @Argument(help: "模块名称") var module: String
        @Option(name: .shortAndLong, parsing: .upToNextOption, help: "PostgreSQL 将用于监听的端口号") var ports: [Int]
        var paras: [Int] { ports }
        func one(para port: Int, i: Int, env: Env, depends: Depends) throws { try Action.create(module: module, port: port, env: env, depends: depends) }
    }
    
    struct D: Delete {
        typealias Super = PgService

        @Argument(help: "模块名称") var module: String
        @Option(name: .shortAndLong, parsing: .upToNextOption, help: "PostgreSQL 服务的监听端口号") var ports: [Int]
        var paras: [Int] { ports }
        func one(para port: Int, i: Int, env: Env, depends: Depends) throws { try Action.delete(module: module, port: port, env: env, depends: depends) }
    }
    
    struct S: Stop {
        typealias Super = PgService

        @Argument(help: "模块名称") var module: String
        @Option(name: .shortAndLong, parsing: .upToNextOption, help: "PostgreSQL 服务的监听端口号") var ports: [Int]
        var paras: [Int] { ports }
        func one(para port: Int, i: Int, env: Env, depends: Depends) throws { try Action.stop(module: module, port: port, env: env, depends: depends) }
    }

    struct Restart: LCDExpand {
        typealias Super = PgService
        static let name: String = "restart"
        static let shortName: String? = nil
        static let help: String = "重启 "

        @Argument(help: "模块名称") var module: String
        @Option(name: .shortAndLong, parsing: .upToNextOption, help: "PostgreSQL 服务的监听端口号") var ports: [Int]
        var paras: [Int] { ports }
        func one(para port: Int, i: Int, env: Env, depends: Depends) throws { try Action.restart(module: module, port: port, env: env, depends: depends) }
    }

    struct Start: LCDExpand {
        typealias Super = PgService
        static let name: String = "start"
        static let shortName: String? = nil
        static let help: String = "启动 "

        @Argument(help: "模块名称") var module: String
        @Option(name: .shortAndLong, parsing: .upToNextOption, help: "PostgreSQL 服务的监听端口号") var ports: [Int]
        var paras: [Int] { ports }
        func one(para port: Int, i: Int, env: Env, depends: Depends) throws { try Action.start(module: module, port: port, env: env, depends: depends) }
    }
}

extension PgService {
    enum Action {
        enum Err: String, ErrList {
            case portOccupied = "端口被占用"
            case portNotCorrect = "端口号不正确, 请在 1 ~ 19 之间"
            case pgDatabaseExist = "PostgreSQL 数据库未删除"
            case serviceAlreadyExist = "PostgreSQL 服务已存在"
            case serviceNotFound = "PostgreSQL 服务不存在"
            case serviceIsRunning = "PostgreSQL 服务正在运行"
            case serviceIsNotRunning = "PostgreSQL 服务未运行"
            case serviceNameInCorrect = "服务名称异常不正确"
        }

        static func paraAvailable(module: String, port: Int, env: Env, depends: Depends) throws -> DBModel.Module {
            try NoCheck.paraAvailable(module: module, port: port, env: env)
            return try Module.Action.paraAvailable(module: module, env: env, depends: depends)
        }

        static func list(module: String, env: Env, depends: Depends) throws -> [String] {
            let res = try Module.Action.paraAvailable(module: module, env: env, depends: depends)
            return try NoCheck.list(module: module, basePort: res.startPort, env: env)
        }

        static func create(module: String, port: Int, env: Env, depends: Depends) throws {
            let res = try Module.Action.paraAvailable(module: module, env: env, depends: depends)
            try NoCheck.create(module: module, port: port, basePort: res.startPort, env: env)
        }

        static func delete(module: String, port: Int, env: Env, depends: Depends) throws {
            let res = try paraAvailable(module: module, port: port, env: env, depends: depends)
            try NoCheck.delete(module: module, port: port, basePort: res.startPort, env: env)
        }

        static func restart(module: String, port: Int, env: Env, depends: Depends) throws {
            let res = try paraAvailable(module: module, port: port, env: env, depends: depends)
            let p = res.startPort + port
            guard try Sh.isServing(port: p) else { throw Err.serviceIsNotRunning.d("\(p)[\(res.startPort) + \(port)]") }
            try NoCheck.restart(module: module, port: port, env: env)
        }

        static func stop(module: String, port: Int, env: Env, depends: Depends) throws {
            let res = try paraAvailable(module: module, port: port, env: env, depends: depends)
            let p = res.startPort + port
            guard try Sh.isServing(port: p) else { throw Err.serviceIsNotRunning.d("\(p)[\(res.startPort) + \(port)]") }
            try NoCheck.stop(module: module, port: port, basePort: res.startPort, env: env)
        }

        static func start(module: String, port: Int, env: Env, depends: Depends) throws {
            let res = try paraAvailable(module: module, port: port, env: env, depends: depends)
            let p = res.startPort + port
            guard !(try Sh.isServing(port: p)) else { throw Err.serviceIsRunning.d("\(p)[\(res.startPort) + \(port)]") }
            try NoCheck.start(module: module, port: port, env: env)
        }

        struct NoCheck {

            static func paraAvailable(module: String, port: Int, env: Env) throws {
                try Module.Action.NoCheck.paraAvailable(module: module, env: env)
                let moduleDir = env.dataDir + "/" + module
                let dataDir = "\(moduleDir)/percona/\(port)"
                guard Tool.portAvailable(port: port) else { throw Err.portNotCorrect.d(String(port)) }
                guard FS.isExist(path: dataDir, dir: true) == true else { throw Err.serviceNotFound.d(dataDir) }
            }

            static func list(module: String, basePort: Int, env: Env) throws -> [String] {
                let perconaDir = "\(env.dataDir)/\(module)/percona/"
                try FS.mkdir(path: perconaDir, slience: true, withIntermediates: true, output: false)
                let dirs = try FS.ls(path: perconaDir, dir: true, hiddenFile: false).map { guard let port = Int($0) else { throw Err.serviceNameInCorrect.d($0) }; return "\(port + basePort)[\(basePort) + \(port)]" }
                return dirs
            }

            static func create(module: String, port: Int, basePort: Int, env: Env) throws {
                try Module.Action.NoCheck.paraAvailable(module: module, env: env)

                let moduleDir = "\(env.dataDir)/\(module)"
                let dataDir = "\(moduleDir)/percona/\(port)"

                guard Tool.portAvailable(port: port) else { throw Err.portNotCorrect.d(String(port)) }
                guard FS.isExist(path: dataDir, dir: true) == false else { throw Err.serviceAlreadyExist.d(dataDir) }
                let p = basePort + port
                guard !(try Sh.isServing(port: p)) else { throw Err.portOccupied.d("\(p)[\(basePort) + \(port)]") }
                
                try Sh.Vault.login(env: env)
                let keyPath = "\(module)/\(port)/role/woo"

                do {
                    try Sh.Vault.newKey(in: keyPath, env: env)
                    let key = try Sh.Vault.getKey(in: keyPath, env: env)
                    try FS.mkdir(path: dataDir, slience: true, withIntermediates: true)
                    try FS.setPermissions(path: dataDir, owner: "woo", group: "whooshing", permissions: 0o700, recursive: true)
                    try Sh.PG.create(module: module, port: port, basePort: basePort, key: key, env: env)
                    try Sh.PG.restart(dataDir: dataDir, env: env)
                } catch let err {
                    print("任务失败，正在回退".err)
                    try? stop(module: module, port: port, basePort: basePort, env: env)
                    try? delete(module: module, port: port, basePort: basePort, env: env)
                    throw err
                }
            }
            
            static func delete(module: String, port: Int, basePort: Int, env: Env) throws {
                try paraAvailable(module: module, port: port, env: env)
                let perconaDir =  env.dataDir + "/" + module + "/percona"
                let dataDir = "\(perconaDir)/\(port)"
                let p = basePort + port
                guard !(try Sh.isServing(port: p)) else { throw Err.serviceIsRunning.d("\(p)[\(basePort) + \(port)], 您不能删除正在运行的服务") }
                let backupName = Tool.bakName(name: String(port))
                try Sh.Vault.dbBackup(module: module, port: port, backupName: backupName, env: env)
                try Sh.Vault.deleteKey(in: "\(module)/\(port)", env: env)
                try? Sh.PG.stop(dataDir: dataDir, env: env)
                try FS.mkdir(path: perconaDir + "/.trash", slience: true, withIntermediates: true)
                try FS.mv(path: dataDir, to: perconaDir + "/.trash/" + backupName)
            }

            static func stop(module: String, port: Int, basePort: Int, env: Env) throws {
                try paraAvailable(module: module, port: port, env: env)
                let p = basePort + port
                guard try Sh.isServing(port: p) else { throw Err.serviceIsNotRunning.d("\(p)[\(basePort) + \(port)]") }
                let dataDir = "\(env.dataDir)/\(module)/percona/\(port)"
                try Sh.PG.stop(dataDir: dataDir, env: env)
            }

            static func restart(module: String, port: Int, env: Env) throws {
                try NoCheck.paraAvailable(module: module, port: port, env: env)
                let dataDir = "\(env.dataDir)/\(module)/percona/\(port)"
                try Sh.PG.restart(dataDir: dataDir, env: env)
            }

            static func start(module: String, port: Int, env: Env) throws {
                try paraAvailable(module: module, port: port, env: env)
                let dataDir = "\(env.dataDir)/\(module)/percona/\(port)"
                try Sh.PG.start(dataDir: dataDir, env: env)
            }

            static func initIfNeeded(module: String, port: Int, basePort: Int, env: Env) throws {
                var log = false
                do {
                    try paraAvailable(module: module, port: port, env: env)
                } catch {
                    print("PG 服务不存在，正在初始化...".info)
                    log = true
                    try create(module: module, port: port, basePort: basePort, env: env)
                }

                if (try? Sh.Vault.getKey(in: "\(module)/\(port)/role/woo", env: env)) == nil { 
                    print("PG 密钥不存在，正在初始化...".info)
                    log = true
                    try Sh.Vault.newKey(in: "\(module)/\(port)/role/woo", env: env)
                }
                let p = basePort + port
                if try Sh.isServing(port: p) == false {
                    print("PG 未运行，正在运行...".info)
                    log = true
                    try start(module: module, port: port, env: env)
                }

                if log {
                    print("PG 服务初始化完成".succ)
                }
            }
        }
    }
}
