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
            try Module.Action.paraAvailable(module: module, env: env)
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
        @Option(name: .shortAndLong, parsing: .upToNextOption, help: "该 API 服务将用于监听的端口号") var ports: [Int]
        @Option(name: .shortAndLong, parsing: .upToNextOption, help: "运行该服务的可执行文件包") var bundles: [String]
        var paras: [Int] { ports }
        func one(para port: Int, env: Env, i: Int) throws { 
            guard bundles.count > i else { throw Action.Err.missingBundle.d(String(port)) }
            try Action.create(module: module, port: port, bundle: bundles[i], env: env) 
        }
    }
    
    struct D: Delete {
        typealias Super = ApiService
        @Argument(help: "模块名称") var module: String
        @Option(name: .shortAndLong, parsing: .upToNextOption, help: "该 API 服务将用于监听的端口号") var ports: [Int]
        var paras: [Int] { ports }
        func one(para port: Int, env: Env, i: Int) throws { try Action.delete(module: module, port: port, env: env) }
    }
    
    struct S: Stop {
        typealias Super = ApiService

        @Argument(help: "模块名称") var module: String
        @Option(name: .shortAndLong, parsing: .upToNextOption, help: "该 API 服务将用于监听的端口号") var ports: [Int]
        var paras: [Int] { ports }
        func one(para port: Int, env: Env, i: Int) throws { try Action.stop(module: module, port: port, env: env) }
    }

    struct Restart: LCDExpand {
        typealias Super = ApiService
        static let name: String = "restart"
        static let shortName: String? = "resta"
        static let help: String = "重启 "

        @Argument(help: "模块名称") var module: String
        @Option(name: .shortAndLong, parsing: .upToNextOption, help: "该 API 服务将用于监听的端口号") var ports: [Int]
        @Option(name: .shortAndLong, parsing: .upToNextOption, help: "运行该服务的可执行文件包") var bundles: [String]
        var paras: [Int] { ports }
        func one(para port: Int, env: Env, i: Int) throws { try Action.restart(module: module, port: port, env: env) }
    }

    struct Start: LCDExpand {
        typealias Super = ApiService
        static let name: String = "start"
        static let shortName: String? = "sta"
        static let help: String = "启动 "

        @Argument(help: "模块名称") var module: String
        @Option(name: .shortAndLong, parsing: .upToNextOption, help: "该 API 服务将用于监听的端口号") var ports: [Int]
        @Option(name: .shortAndLong, parsing: .upToNextOption, help: "运行该服务的可执行文件包") var bundles: [String]
        var paras: [Int] { ports }
        func one(para port: Int, env: Env, i: Int) throws { try Action.start(module: module, port: port, env: env) }
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
        }

        static func paraAvailable(module: String, port: Int, env: Env) throws {
            try Module.Action.paraAvailable(module: module, env: env)
            let moduleDir = env.dataDir + "/" + module
            let dataDir = "\(moduleDir)/api-\(port)"
            guard Tool.portAvailable(port: port) else { throw Err.portNotCorrect.d(String(port)) }
            guard FS.isExist(path: dataDir, dir: true) == true else { throw Err.serviceNotFound.d(dataDir) }
        }

        static func list(module: String, env: Env) throws -> [String] {
            let perconaDir = "\(env.dataDir)/\(module)/"
            try FS.mkdir(path: perconaDir, slience: true, withIntermediates: true, output: false)
            let dirs = try FS.ls(path: perconaDir, dir: true, hiddenFile: false).filter { $0.hasPrefix("api-") }
            return dirs
        }
        
        static func create(module: String, port: Int, bundle: String, env: Env) throws {
            try Module.Action.paraAvailable(module: module, env: env)

            let moduleDir = "\(env.dataDir)/\(module)"
            let dataDir = "\(moduleDir)/api-\(port)"

            guard Tool.portAvailable(port: port) else { throw Err.portNotCorrect.d(String(port)) }
            guard FS.isExist(path: dataDir, dir: true) == false else { throw Err.serviceAlreadyExist.d(dataDir) }
            guard try Sh.run("lsof -i:\(port)", env: env).code != 0 else { throw Err.portOccupied.d(String(port)) }
    
            do {
                try FS.mkdir(path: dataDir, slience: true, withIntermediates: true)
                try FS.setPermissions(path: dataDir, owner: "root", group: "whooshing", permissions: 0o770, recursive: true)
                try FS.cp(path: bundle, to: dataDir)
                try start(module: module, port: port, env: env)
            } catch let err {
                print("任务失败，正在回退")
                try? stop(module: module, port: port, env: env)
                try? delete(module: module, port: port, env: env)
                throw err
            }
        }

        static func delete(module: String, port: Int, env: Env) throws {
            try paraAvailable(module: module, port: port, env: env)
            let moduleDir = "\(env.dataDir)/\(module)"
            let dataDir = "\(moduleDir)/api-\(port)"
            guard !(try Sh.isServing(port: port)) else { throw Err.serviceIsRunning.d("\(port), 您不能删除正在运行的服务") }
            try FS.mkdir(path: moduleDir + "/.trash", slience: true, withIntermediates: true)
            let backupName = Tool.bakName(name: String(port))
            try FS.mv(path: dataDir, to: moduleDir + "/.trash/" + backupName)
        }

        static func restart(module: String, port: Int, env: Env) throws {
            try paraAvailable(module: module, port: port, env: env)
            let dataDir = "\(env.dataDir)/\(module)/api-\(port)"



            
            // try Sh.PM2.restart(configFile: "\(dataDir)/pm2.config.json", env: env)
        }

        static func start(module: String, port: Int, env: Env) throws {
            try paraAvailable(module: module, port: port, env: env)
            guard !(try Sh.isServing(port: port)) else { throw Err.serviceIsRunning.d(String(port)) }
            let dataDir = "\(env.dataDir)/\(module)/api-\(port)"

            

            // try Sh.PM2.start(configFile: "\(dataDir)/pm2.config.json", env: env)
        }

        static func stop(module: String, port: Int, env: Env) throws {
            try paraAvailable(module: module, port: port, env: env)
            guard try Sh.isServing(port: port) else { throw Err.serviceIsNotRunning.d(String(port)) }
            let dataDir = "\(env.dataDir)/\(module)/api-\(port)"
            try Sh.PM2.stop(configFile: "\(dataDir)/pm2.config.json", env: env)
        }

    }
}