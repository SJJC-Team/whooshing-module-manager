import ArgumentParser
import Foundation

protocol ServiceType {
    static var serName: String { get }
    static var cmdName: String { get }
    static var dataName: String { get }
}

enum Api: ServiceType {
    static let serName: String = "API"
    static let cmdName: String = "api"
    static let dataName: String = "api"
}

enum Inline: ServiceType {
    static let serName: String = "INLINE"
    static let cmdName: String = "inl"
    static let dataName: String = "inline"
}

enum Https: ServiceType {
    static let serName: String = "HTTPS"
    static let cmdName: String = "htps"
    static let dataName: String = "https"
}

struct Service<SerType: ServiceType>: LCDS {
    static var name: String { "\(SerType.cmdName)service" }
    static var shortName: String? { nil }
    static var paraLabel: String { "端口" }
    static var help: String { "\(SerType.serName) 网络后端服务" }
    static var subCmds: [any ParsableCommand.Type] { [L.self, C.self, D.self, S.self, Restart.self, Start.self] }

    struct L: List {
        typealias Super = Service<SerType>
        @Argument(help: "模块名称") var module: String
        func cmd(env: Env, depends: Depends) throws -> [String] { 
            let dirs = try Action.list(module: module, env: env) 
            let isEmpty = dirs.isEmpty
            if isEmpty { print("无 \(SerType.serName) 服务".info) }
            else { for dir in dirs { print(dir.info) } }
            return dirs
        }
    }
    
    struct C: Create {
        typealias Super = Service<SerType>
        @Argument(help: "模块名称") var module: String
        @Option(name: .shortAndLong, help: "该 \(SerType.serName) 服务将用于监听的端口号") var port: Int
        @Option(name: .shortAndLong, help: "运行该服务的可执行文件包") var bundle: String
        @Option(name: .shortAndLong, parsing: .upToNextOption, help: "该 \(SerType.serName) 服务连接的数据库端口号") var databasePorts: [Int]
        var paras: [Int] { [port] }
        func one(para port: Int, i: Int, env: Env, depends: Depends) throws { 
            try Action.create(module: module, port: port, bundle: bundle, dbPorts: databasePorts, env: env, depends: depends) 
        }
    }
    
    struct D: Delete {
        typealias Super = Service<SerType>
        @Argument(help: "模块名称") var module: String
        @Option(name: .shortAndLong, parsing: .upToNextOption, help: "\(SerType.serName)(s) 服务的监听端口号") var ports: [Int]
        var paras: [Int] { ports }
        func one(para port: Int, i: Int, env: Env, depends: Depends) throws { try Action.delete(module: module, port: port, env: env, depends: depends) }
    }
    
    struct S: Stop {
        typealias Super = Service<SerType>

        @Argument(help: "模块名称") var module: String
        @Option(name: .shortAndLong, parsing: .upToNextOption, help: "\(SerType.serName)(s) 服务的监听端口号") var ports: [Int]
        var paras: [Int] { ports }
        func one(para port: Int, i: Int, env: Env, depends: Depends) throws { try Action.stop(module: module, port: port, env: env, depends: depends) }
    }

    struct Restart: LCDExpand {
        typealias Super = Service<SerType>
        static var name: String { "restart" }
        static var shortName: String? { "resta" }
        static var help: String { "重启 " }

        @Argument(help: "模块名称") var module: String
        @Option(name: .shortAndLong, parsing: .upToNextOption, help: "\(SerType.serName)(s) 服务的监听端口号") var ports: [Int]
        var paras: [Int] { ports }
        func one(para port: Int, i: Int, env: Env, depends: Depends) throws { try Action.restart(module: module, port: port, env: env, depends: depends) }
    }

    struct Start: LCDExpand {
        typealias Super = Service<SerType>
        static var name: String { "start" }
        static var shortName: String? { "sta" }
        static var help: String { "启动 " }

        @Argument(help: "模块名称") var module: String
        @Option(name: .shortAndLong, parsing: .upToNextOption, help: "\(SerType.serName)(s) 服务的监听端口号") var ports: [Int]
        var paras: [Int] { ports }
        func one(para port: Int, i: Int, env: Env, depends: Depends) throws { try Action.start(module: module, port: port, env: env, depends: depends) }
    }
}

extension Service {
    enum Action {
        enum Err: String, ErrList {
            case portOccupied = "端口被占用"
            case portNotCorrect = "端口号不正确, 请在 1 ~ 19 之间"
            case serviceNotFound = "Api 服务不存在"
            case serviceAlreadyExist = "Api 服务已存在"
            case serviceIsRunning = "Api 服务正在运行"
            case serviceIsNotRunning = "Api 服务未运行"
            case missingBundle = "缺少可执行文件包"
            case pgServiceNotRunning = "PostgreSQL 服务未运行"
        }

        static func paraAvailable(module: String, port: Int, env: Env, depends: Depends) throws -> DBModel.Module {
            let model = try Module.Action.paraAvailable(module: module, env: env, depends: depends)
            try NoCheck.paraAvailable(module: module, port: port, env: env)
            return model
        }

        static func list(module: String, env: Env) throws -> [String] {
            try Module.Action.NoCheck.paraAvailable(module: module, env: env)
            let moduleDir = "\(env.dataDir)/\(module)/"
            try FS.mkdir(path: moduleDir, slience: true, withIntermediates: true, output: false)
            let dirs = try FS.ls(path: moduleDir, dir: true, hiddenFile: false).filter { $0.hasPrefix("\(SerType.dataName)-") }
            return dirs
        }
        
        static func create(module: String, port: Int, bundle: String, dbPorts: [Int], env: Env, depends: Depends) throws {
            let model = try Module.Action.paraAvailable(module: module, env: env, depends: depends)
            try NoCheck.create(module: module, port: port, bundle: bundle, dbPorts: dbPorts, env: env, dbModule: model)
        }

        static func delete(module: String, port: Int, env: Env, depends: Depends) throws {
            let model = try paraAvailable(module: module, port: port, env: env, depends: depends)
            try NoCheck.delete(module: module, port: port, env: env, basePort: model.startPort)
        }

        static func restart(module: String, port: Int, env: Env, depends: Depends) throws {
            let model = try Module.Action.paraAvailable(module: module, env: env, depends: depends)
            try NoCheck.start(module: module, port: port, env: env, dbModule: model)
        }

        static func start(module: String, port: Int, env: Env, depends: Depends) throws {
            let model = try Module.Action.paraAvailable(module: module, env: env, depends: depends)
            try NoCheck.start(module: module, port: port, env: env, dbModule: model)
        }

        static func stop(module: String, port: Int, env: Env, depends: Depends) throws {
            let model = try Module.Action.paraAvailable(module: module, env: env, depends: depends)
            try NoCheck.stop(module: module, port: port, env: env, dbModule: model)
        }

        struct NoCheck {

            static func paraAvailable(module: String, port: Int, env: Env) throws {
                try Module.Action.NoCheck.paraAvailable(module: module, env: env)
                let moduleDir = env.dataDir + "/" + module
                let dataDir = "\(moduleDir)/\(SerType.dataName)-\(port)"
                guard Tool.portAvailable(port: port) else { throw Err.portNotCorrect.d(String(port)) }
                guard FS.isExist(path: dataDir, dir: true) == true else { throw Err.serviceNotFound.d(dataDir) }
            }

            static func parseEnv(in envFile: String, module: DBModel.Module, env: Env) throws -> [String: String] {
                var paras = try FS.readEnvFile(at: envFile)
                for (k, v) in paras { 
                    if k.contains("PORT") { let dp = Int(v)!; paras[k] = String(module.startPort + dp) }
                    else if k.contains("PASSWORD") { paras[k] = try Sh.Vault.getKey(in: v, env: env) }
                }
                paras["WHOOSHING_\(SerType.serName)_SERVICE_MANAGER_URL"] = "http://localhost:20000"
                if SerType.self == Inline.self { paras["WHOOSHING_INLINE_SERVICE_PRIVATE_SERVICE_ID"] = module.serviceId.uuidString }
                return paras
            }

            static func create(module: String, port: Int, bundle: String, dbPorts: [Int], env: Env, dbModule: DBModel.Module) throws {
                try Module.Action.NoCheck.paraAvailable(module: module, env: env)

                let moduleDir = "\(env.dataDir)/\(module)"
                let dataDir = "\(moduleDir)/\(SerType.dataName)-\(port)"
                let envFile = "\(dataDir)/.env"
                let p = dbModule.startPort + port

                guard Tool.portAvailable(port: port) else { throw Err.portNotCorrect.d(String(port)) }
                guard FS.isExist(path: dataDir, dir: true) == false else { throw Err.serviceAlreadyExist.d(dataDir) }
                guard try !Sh.isServing(port: p) else { throw Err.portOccupied.d("\(p)[\(dbModule.startPort) + \(port)]") }
                
                var paras: [String: String] = [:]
                paras["WHOOSHING_\(SerType.serName)_SERVICE_DB_COUNT"] = String(dbPorts.count)
                paras["WHOOSHING_\(SerType.serName)_SERVICE_NAME"] = "\(SerType.serName)Service-\(port)"
                paras["WHOOSHING_\(SerType.serName)_SERVICE_PORT"] = String(port)
                for (i, dp) in dbPorts.enumerated() {
                    let dbp = dbModule.startPort + dp
                    guard try Sh.isServing(port: dbp) else { throw Err.pgServiceNotRunning.d(String(dbp)) }
                    paras["WHOOSHING_\(SerType.serName)_SERVICE_DB_\(i + 1)_NAME"] = "PGDatabase-\(dp)"
                    paras["WHOOSHING_\(SerType.serName)_SERVICE_DB_\(i + 1)_PORT"] = String(dp)
                    paras["WHOOSHING_\(SerType.serName)_SERVICE_DB_\(i + 1)_USER"] = "woo"
                    paras["WHOOSHING_\(SerType.serName)_SERVICE_DB_\(i + 1)_PASSWORD"] = "\(module)/\(dp)/role/woo"
                }

                do {
                    try FS.createEnvFile(at: envFile, with: paras)
                    try FS.mkdir(path: dataDir, slience: true, withIntermediates: true)
                    try FS.setPermissions(path: dataDir, owner: "root", group: "whooshing", permissions: 0o770, recursive: true)
                    try FS.cp(path: bundle, to: dataDir)
                    try start(module: module, port: port, env: env, dbModule: dbModule)
                } catch let err {
                    print("任务失败，正在回退")
                    try? stop(module: module, port: port, env: env, dbModule: dbModule)
                    try? delete(module: module, port: port, env: env, basePort: dbModule.startPort)
                    throw err
                }
            }

            static func delete(module: String, port: Int, env: Env, basePort: Int) throws {
                try paraAvailable(module: module, port: port, env: env)
                let moduleDir = "\(env.dataDir)/\(module)"
                let dataDir = "\(moduleDir)/\(SerType.dataName)-\(port)"
                let envFile = "\(dataDir)/.env"
                let p = basePort + port
                guard !(try Sh.isServing(port: p)) else { throw Err.serviceIsRunning.d("\(p)[\(basePort) + \(port)], 您不能删除正在运行的服务") }
                try FS.rm(path: envFile)
                try FS.mkdir(path: moduleDir + "/.trash", slience: true, withIntermediates: true)
                let backupName = Tool.bakName(name: String(port))
                try FS.mv(path: dataDir, to: moduleDir + "/.trash/" + backupName)
            }

            static func restart(module: String, port: Int, env: Env, dbModule: DBModel.Module) throws {
                try Module.Action.NoCheck.paraAvailable(module: module, env: env)
                let dataDir = "\(env.dataDir)/\(module)/\(SerType.dataName)-\(port)"
                let paras = try parseEnv(in: "\(dataDir)/.env", module: dbModule, env: env)
                try Sh.PM2.restart(configFile: "\(dataDir)/pm2.config.json", args: paras, env: env)
            }

            static func start(module: String, port: Int, env: Env, dbModule: DBModel.Module) throws {
                try Module.Action.NoCheck.paraAvailable(module: module, env: env)
                guard try !Sh.isServing(port: dbModule.startPort + port) else { throw Err.serviceIsRunning.d("\(dbModule.startPort + port)[\(dbModule.startPort) + \(port)]") }
                let dataDir = "\(env.dataDir)/\(module)/\(SerType.dataName)-\(port)"
                let paras = try parseEnv(in: "\(dataDir)/.env", module: dbModule, env: env)
                try Sh.PM2.start(configFile: "\(dataDir)/pm2.config.json", args: paras, env: env)
            }

            static func stop(module: String, port: Int, env: Env, dbModule: DBModel.Module) throws {
                try Module.Action.NoCheck.paraAvailable(module: module, env: env)
                guard try Sh.isServing(port: dbModule.startPort + port) else { throw Err.serviceIsNotRunning.d("\(dbModule.startPort + port)[\(dbModule.startPort) + \(port)]") }
                let dataDir = "\(env.dataDir)/\(module)/\(SerType.dataName)-\(port)"
                try Sh.PM2.stop(configFile: "\(dataDir)/pm2.config.json", env: env)
            }
        }
    }
}
