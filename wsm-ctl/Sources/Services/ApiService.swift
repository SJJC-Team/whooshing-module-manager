import ArgumentParser
import Foundation

struct ApiService: LCDS {
    static let name = "apiservice"
    static let shortName: String? = nil
    static let paraLabel = "端口"
    static let help = "API 网络后端服务"
    static let subCmds: [any ParsableCommand.Type] = [L.self, C.self, D.self, S.self, Restart.self, Start.self]

    struct L: List {
        typealias Super = ApiService
        @Argument(help: "模块名称") var module: String
        func cmd(env: Env, depends: Depends) throws -> [String] { 
            let dirs = try Action.list(module: module, env: env) 
            let isEmpty = dirs.isEmpty
            if isEmpty { print("无 API 服务".info) }
            else { for dir in dirs { print(dir.info) } }
            return dirs
        }
    }
    
    struct C: Create {
        typealias Super = ApiService
        @Argument(help: "模块名称") var module: String
        @Option(name: .shortAndLong, help: "该 API 服务将用于监听的端口号") var port: Int
        @Option(name: .shortAndLong, help: "运行该服务的可执行文件包") var bundle: String
        @Option(name: .shortAndLong, parsing: .upToNextOption, help: "该 API 服务连接的数据库端口号") var databasePorts: [Int]
        var paras: [Int] { [port] }
        func one(para port: Int, env: Env, i: Int, depends: Depends) throws { 
            try Action.create(module: module, port: port, bundle: bundle, dbPorts: databasePorts, env: env, depends: depends) 
        }
    }
    
    struct D: Delete {
        typealias Super = ApiService
        @Argument(help: "模块名称") var module: String
        @Option(name: .shortAndLong, parsing: .upToNextOption, help: "API(s) 服务的监听端口号") var ports: [Int]
        var paras: [Int] { ports }
        func one(para port: Int, env: Env, i: Int, depends: Depends) throws { try Action.delete(module: module, port: port, env: env, depends: depends) }
    }
    
    struct S: Stop {
        typealias Super = ApiService

        @Argument(help: "模块名称") var module: String
        @Option(name: .shortAndLong, parsing: .upToNextOption, help: "API(s) 服务的监听端口号") var ports: [Int]
        var paras: [Int] { ports }
        func one(para port: Int, env: Env, i: Int, depends: Depends) throws { try Action.stop(module: module, port: port, env: env, depends: depends) }
    }

    struct Restart: LCDExpand {
        typealias Super = ApiService
        static let name: String = "restart"
        static let shortName: String? = "resta"
        static let help: String = "重启 "

        @Argument(help: "模块名称") var module: String
        @Option(name: .shortAndLong, parsing: .upToNextOption, help: "API(s) 服务的监听端口号") var ports: [Int]
        var paras: [Int] { ports }
        func one(para port: Int, env: Env, i: Int, depends: Depends) throws { try Action.restart(module: module, port: port, env: env, depends: depends) }
    }

    struct Start: LCDExpand {
        typealias Super = ApiService
        static let name: String = "start"
        static let shortName: String? = "sta"
        static let help: String = "启动 "

        @Argument(help: "模块名称") var module: String
        @Option(name: .shortAndLong, parsing: .upToNextOption, help: "API(s) 服务的监听端口号") var ports: [Int]
        var paras: [Int] { ports }
        func one(para port: Int, env: Env, i: Int, depends: Depends) throws { try Action.start(module: module, port: port, env: env, depends: depends) }
    }
}

extension ApiService {
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
            let dirs = try FS.ls(path: moduleDir, dir: true, hiddenFile: false).filter { $0.hasPrefix("api-") }
            return dirs
        }
        
        static func create(module: String, port: Int, bundle: String, dbPorts: [Int], env: Env, depends: Depends) throws {
            let model = try Module.Action.paraAvailable(module: module, env: env, depends: depends)
            try NoCheck.create(module: module, port: port, bundle: bundle, dbPorts: dbPorts, env: env, basePort: model.startPort)
        }

        static func delete(module: String, port: Int, env: Env, depends: Depends) throws {
            let model = try paraAvailable(module: module, port: port, env: env, depends: depends)
            try NoCheck.delete(module: module, port: port, env: env, basePort: model.startPort)
        }

        static func restart(module: String, port: Int, env: Env, depends: Depends) throws {
            let model = try Module.Action.paraAvailable(module: module, env: env, depends: depends)
            try NoCheck.start(module: module, port: port, env: env, basePort: model.startPort)
        }

        static func start(module: String, port: Int, env: Env, depends: Depends) throws {
            let model = try Module.Action.paraAvailable(module: module, env: env, depends: depends)
            try NoCheck.start(module: module, port: port, env: env, basePort: model.startPort)
        }

        static func stop(module: String, port: Int, env: Env, depends: Depends) throws {
            let model = try Module.Action.paraAvailable(module: module, env: env, depends: depends)
            try NoCheck.stop(module: module, port: port, env: env, basePort: model.startPort)
        }

        struct NoCheck {

            static func paraAvailable(module: String, port: Int, env: Env) throws {
                try Module.Action.NoCheck.paraAvailable(module: module, env: env)
                let moduleDir = env.dataDir + "/" + module
                let dataDir = "\(moduleDir)/api-\(port)"
                guard Tool.portAvailable(port: port) else { throw Err.portNotCorrect.d(String(port)) }
                guard FS.isExist(path: dataDir, dir: true) == true else { throw Err.serviceNotFound.d(dataDir) }
            }

            static func parseEnv(in envFile: String, basePort: Int, env: Env) throws -> [String: String] {
                var paras = try FS.readEnvFile(at: envFile)
                for (k, v) in paras { 
                    if k.contains("PORT") { let dp = Int(v)!; paras[k] = String(basePort + dp) } 
                    else if k.contains("PASSWORD") { paras[k] = try Sh.Vault.getKey(in: v, env: env) }
                }
                return paras
            }

            static func create(module: String, port: Int, bundle: String, dbPorts: [Int], env: Env, basePort: Int) throws {
                try Module.Action.NoCheck.paraAvailable(module: module, env: env)

                let moduleDir = "\(env.dataDir)/\(module)"
                let dataDir = "\(moduleDir)/api-\(port)"
                let envFile = "\(dataDir)/.env"
                let p = basePort + port

                guard Tool.portAvailable(port: port) else { throw Err.portNotCorrect.d(String(port)) }
                guard FS.isExist(path: dataDir, dir: true) == false else { throw Err.serviceAlreadyExist.d(dataDir) }
                guard try !Sh.isServing(port: p) else { throw Err.portOccupied.d("\(p)[\(basePort) + \(port)]") }
                
                var paras: [String: String] = [:]
                paras["WHOOSHING_API_SERVICE_DB_COUNT"] = String(dbPorts.count)
                paras["WHOOSHING_API_SERVICE_NAME"] = "APIService-\(port)"
                paras["WHOOSHING_API_SERVICE_PORT"] = String(port)
                for (i, dp) in dbPorts.enumerated() {
                    let dbp = basePort + dp
                    guard try Sh.isServing(port: dbp) else { throw Err.pgServiceNotRunning.d(String(dbp)) }
                    paras["WHOOSHING_API_SERVICE_DB_\(i + 1)_NAME"] = "PGDatabase-\(dp)"
                    paras["WHOOSHING_API_SERVICE_DB_\(i + 1)_PORT"] = String(dp)
                    paras["WHOOSHING_API_SERVICE_DB_\(i + 1)_USER"] = "woo"
                    paras["WHOOSHING_API_SERVICE_DB_\(i + 1)_PASSWORD"] = "\(module)/\(dp)/role/woo"
                }

                do {
                    try FS.createEnvFile(at: envFile, with: paras)
                    try FS.mkdir(path: dataDir, slience: true, withIntermediates: true)
                    try FS.setPermissions(path: dataDir, owner: "root", group: "whooshing", permissions: 0o770, recursive: true)
                    try FS.cp(path: bundle, to: dataDir)
                    try start(module: module, port: port, env: env, basePort: basePort)
                } catch let err {
                    print("任务失败，正在回退")
                    try? stop(module: module, port: port, env: env, basePort: basePort)
                    try? delete(module: module, port: port, env: env, basePort: basePort)
                    throw err
                }
            }

            static func delete(module: String, port: Int, env: Env, basePort: Int) throws {
                try paraAvailable(module: module, port: port, env: env)
                let moduleDir = "\(env.dataDir)/\(module)"
                let dataDir = "\(moduleDir)/api-\(port)"
                let envFile = "\(dataDir)/.env"
                let p = basePort + port
                guard !(try Sh.isServing(port: p)) else { throw Err.serviceIsRunning.d("\(p)[\(basePort) + \(port)], 您不能删除正在运行的服务") }
                try FS.rm(path: envFile)
                try FS.mkdir(path: moduleDir + "/.trash", slience: true, withIntermediates: true)
                let backupName = Tool.bakName(name: String(port))
                try FS.mv(path: dataDir, to: moduleDir + "/.trash/" + backupName)
            }

            static func restart(module: String, port: Int, env: Env, basePort: Int) throws {
                try Module.Action.NoCheck.paraAvailable(module: module, env: env)
                let dataDir = "\(env.dataDir)/\(module)/api-\(port)"
                let paras = try parseEnv(in: "\(dataDir)/.env", basePort: basePort, env: env)
                try Sh.PM2.restart(configFile: "\(dataDir)/pm2.config.json", args: paras, env: env)
            }

            static func start(module: String, port: Int, env: Env, basePort: Int) throws {
                try Module.Action.NoCheck.paraAvailable(module: module, env: env)
                guard try !Sh.isServing(port: basePort + port) else { throw Err.serviceIsRunning.d("\(basePort + port)[\(basePort) + \(port)]") }
                let dataDir = "\(env.dataDir)/\(module)/api-\(port)"
                let paras = try parseEnv(in: "\(dataDir)/.env", basePort: basePort, env: env)
                try Sh.PM2.start(configFile: "\(dataDir)/pm2.config.json", args: paras, env: env)
            }

            static func stop(module: String, port: Int, env: Env, basePort: Int) throws {
                try Module.Action.NoCheck.paraAvailable(module: module, env: env)
                guard try Sh.isServing(port: basePort + port) else { throw Err.serviceIsNotRunning.d("\(basePort + port)[\(basePort) + \(port)]") }
                let dataDir = "\(env.dataDir)/\(module)/api-\(port)"
                try Sh.PM2.stop(configFile: "\(dataDir)/pm2.config.json", env: env)
            }
        }
    }
}