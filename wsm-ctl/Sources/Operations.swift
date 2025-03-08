import Foundation

struct Sh {

    enum Err: String, ErrList {
        case fileNotFound = "文件不存在"
        case shellExecuteFailed = "shell 执行失败"
        case shellExceptionExit = "shell 异常退出"
    }

    struct File {
        enum Shell: String {
            case vaultLogin = "vault_login"
            case vaultNewEngine = "vault_new_engine"
            case vaultModuleBackup = "vault_module_backup"
            case vaultNewKey = "vault_new_key"
            case vaultGetKey = "vault_get_key"
            case vaultDbBackup = "vault_db_backup"
            case vaultDeleteKey = "vault_delete_key"
            case pgCreateService = "pg_create_service"
            case pgRestartService = "pg_restart_service"
            case pgStartService = "pg_start_service"
            case pgStopService = "pg_stop_service"
            case pgListDb = "pg_list_db"
            case pgCreateDb = "pg_create_db"
            case pgDeleteDb = "pg_delete_db"
            case pgTestDb = "pg_test_db"
        }

        static func sh(_ shell: Shell) throws -> String {
            guard let filePath = Bundle.module.path(forResource: shell.rawValue, ofType: "sh") else { throw Err.fileNotFound }
            return filePath
        }
    }

    struct Vault {

        enum Err: String, ErrList {
            case vaultNotRunning = "Vault 未运行"
            case vaultEngineExist = "Vault 引擎已存在"
            case vaultNewEngineFailed = "新建 Vault 引擎失败"
            case vaultLoginFailed = "Vault 登陆失败"
            case vaultIsSealed = "Vault 为封存状态"
            case vaultEngineNotFound = "Vault 引擎不存在"
            case vaultDeleteKeyFailed = "删除密钥失败"
            case vaultDisableKeyFailed = "禁用密钥失败"
            case backupFileCreateFailed = "备份文件创建失败"
            case vaultUnknowError = "Vault 未知错误"
        }

        static func login(env: Env, silent: Bool = false) throws {
            let res = try run(in: File.sh(.vaultLogin), env: env)
            switch res.code {
                case 1: throw Err.vaultNotRunning
                case 2: throw Err.vaultLoginFailed
                case 3: throw Err.vaultIsSealed
                case 0: if !silent { print("成功登陆到 Vault".succ) } 
                default: throw Err.vaultUnknowError.d(String(data: res.res, encoding: .utf8)!)
            }
        }

        static func newEngine(module: String, env: Env) throws {
            let res = try run(in: File.sh(.vaultNewEngine), paras: ["module": module], env: env)
            switch res.code {
                case 1: throw Err.vaultEngineExist.d(module)
                case 0: print("密钥引擎创建成功".succ)
                default: throw Err.vaultUnknowError.d(String(data: res.res, encoding: .utf8)!)
            }
        }

        static func moduleBackup(module: String, backupName: String, env: Env) throws {
            let res = try run(in: File.sh(.vaultModuleBackup), paras: [
                "module": module,
                "backup_name": backupName
            ], env: env)
            switch res.code {
                case 1: throw Err.vaultEngineNotFound.d(module)
                case 2: print("存储引擎 \(module) 为空，无需备份密钥，禁用引擎 \(module) 完成".info)
                case 3: throw Err.backupFileCreateFailed.d(module)
                case 0: print("已备份引擎 \(module) 的密钥到 /module-bak/\(backupName)".succ)
                default: throw Err.vaultUnknowError.d(String(data: res.res, encoding: .utf8)!)
            }
        }

        static func newKey(in path: String, env: Env) throws {
            let res = try run(in: File.sh(.vaultNewKey), paras: ["path": path], env: env)
            switch res.code {
                case 1: print("密钥已存在于 \(path)，无需创建".info)
                case 0: print("成功创建密钥到 \(path)".succ)
                default: throw Err.vaultUnknowError.d(String(data: res.res, encoding: .utf8)!)
            }
        }

        static func getKey(in path: String, env: Env) throws -> String {
            let res = try run(in: File.sh(.vaultGetKey), paras: ["path": path], env: env)
            guard res.code == 0 else { throw Err.vaultUnknowError.d(String(data: res.res, encoding: .utf8)!) }
            guard let str = String(data: res.res, encoding: .utf8) else { throw Err.vaultUnknowError.d("Vault 解包密钥失败-\(path)") }
            return str
        }

        static func dbBackup(module: String, port: Int, backupName: String, env: Env) throws {
            let res = try run(in: File.sh(.vaultDbBackup), paras: [
                "module": module,
                "port": String(port),
                "backup_name": backupName
            ], env: env)
            switch res.code {
                case 1: throw Err.vaultEngineNotFound.d(module)
                case 2: print("密钥存储 \(module)/\(port) 为空，无需备份密钥".info)
                case 3: throw Err.backupFileCreateFailed.d("\(module).\(port)")
                case 0: print("已备份密钥 \(module)/\(port) 到 /\(module)/server-bak/\(backupName)".succ)
                default: throw Err.vaultUnknowError.d(String(data: res.res, encoding: .utf8)!)
            }
        }

        static func deleteKey(in path: String, env: Env) throws {
            let res = try run(in: File.sh(.vaultDeleteKey), paras: ["path": path], env: env)
            switch res.code {
                case 3: throw Err.vaultDisableKeyFailed.d(path)
                case 2: throw Err.vaultDeleteKeyFailed.d(path)
                case 1: print("密钥 \(path) 不存在，无需删除".info)
                case 0: print("成功删除密钥 \(path)".succ)
                default: throw Err.vaultUnknowError.d(String(data: res.res, encoding: .utf8)!)
            }
        }
    }

    struct PG {

        enum Err: String, ErrList {
            case pgUnknowError = "PostgreSQL 未知错误"
            case pgRestartFailed = "PostgreSQL 重启失败"
            case pgStopFailed = "PostgreSQL 停止失败"
            case pgCreateDbFailed = "PostgreSQL 数据库创建失败"
            case pgDeleteDbFailed = "PostgreSQL 数据库删除失败"
            case pgListDbFailed = "PostgreSQL 数据库列表获取失败"
            case pgDbVaildFailed = "PostgreSQL 数据库验证失败"
        }

        static func create(module: String, port: Int, basePort: Int, key: String, env: Env) throws {
            let res = try run(in: File.sh(.pgCreateService), paras: [
                "module": module,
                "p": String(port),
                "port_base": String(basePort),
                "key": key
            ], env: env)
            guard res.code == 0 else { throw Err.pgUnknowError.d(String(data: res.res, encoding: .utf8)!) }
            guard let _ = String(data: res.res, encoding: .utf8) else { throw Err.pgUnknowError.d("PostgreSQL 服务初始化输出解包失败-\(module).\(port)") }
            print("PostgreSQL 服务 \(module).\(port) 初始化成功".succ)
        }

        static func restart(dataDir: String, env: Env) throws {
            let res = try run(in: File.sh(.pgRestartService), paras: ["data_dir": dataDir], env: env)
            guard res.code == 0 else { throw Err.pgRestartFailed.d(String(data: res.res, encoding: .utf8)!) }
            print("PostgreSQL 服务 \(dataDir) 已重启".succ)
        }

        static func start(dataDir: String, env: Env) throws {
            let res = try run(in: File.sh(.pgStartService), paras: ["data_dir": dataDir], env: env)
            guard res.code == 0 else { throw Err.pgStopFailed.d(String(data: res.res, encoding: .utf8)!) }
            print("PostgreSQL 服务 \(dataDir) 已启动".succ)
        }

        static func stop(dataDir: String, env: Env) throws {
            let res = try run(in: File.sh(.pgStopService), paras: ["data_dir": dataDir], env: env)
            guard res.code == 0 else { throw Err.pgStopFailed.d(String(data: res.res, encoding: .utf8)!) }
            print("PostgreSQL 服务 \(dataDir) 已停止".succ)
        }

        struct Db {
            
            typealias DataType = (oid: String, db: String)

            static func create(module: String, port: Int, basePort: Int, db: String, key: String, env: Env) throws {
                let res = try run(in: File.sh(.pgCreateDb), paras: [
                    "module": module,
                    "p": String(port),
                    "port_base": String(basePort),
                    "database": db,
                    "key": key
                ], env: env)
                guard res.code == 0 else { throw Err.pgCreateDbFailed.d(String(data: res.res, encoding: .utf8)!) }
                print("PostgreSQL 数据库 \(db) 创建成功".succ)
            }

            static func delete(port: Int, db: String, key: String, env: Env) throws {
                let res = try run(in: File.sh(.pgDeleteDb), paras: [
                    "port": String(port),
                    "database": db,
                    "key": key
                ], env: env)
                guard res.code == 0 else { throw Err.pgDeleteDbFailed.d(String(data: res.res, encoding: .utf8)!) }
                print("PostgreSQL 数据库 \(db) 删除成功".succ)
            }

            static func list(port: Int, key: String, env: Env) throws -> [DataType] {
                let res = try run(in: File.sh(.pgListDb), paras: ["port": String(port), "key": key], env: env)
                if (res.res.count == 0) { return [] }
                guard res.code == 0 else { throw Err.pgListDbFailed.d(String(data: res.res, encoding: .utf8)!) }
                guard let dbs = String(data: res.res, encoding: .utf8)?.components(separatedBy: " ") else { throw Err.pgListDbFailed.d("PostgreSQL 数据库列表解包失败-\(port)") }
                let dbList = try dbs.map {
                    let r = $0.split(separator: "|"); 
                    guard r.count == 2 else { throw Err.pgListDbFailed.d("PostgreSQL 数据库列表解构解构失败-\(port)") }
                    return (oid: String(r[0]), db: String(r[1])) 
                }
                return dbList
            }

            static func isExist(port: Int, database: String, key: String, env: Env) throws -> Bool {
                let res = try run(in: File.sh(.pgTestDb), paras: [
                    "port": String(port),
                    "database": database,
                    "key": key
                ], env: env)
                switch res.code {
                    case 0: return true
                    case 1: return false
                    default: throw Err.pgDbVaildFailed.d(String(data: res.res, encoding: .utf8)!)
                }
            }
        }
    }

    struct PM2 {

        enum Err: String, ErrList {
            case pm2StartFailed = "PM2 启动失败"
            case pm2StopFailed = "PM2 停止失败"
            case pm2RestartFailed = "PM2 重启失败"
        }

        static func restart(configFile: String, args: [String: String], env: Env) throws {
            let argStr = args.map { "\($0)=\($1)" }
            let res = try run(["-c"] + argStr + ["pm2 restart \(configFile)"], env: env)
            guard res.code == 0 else { throw Err.pm2StartFailed.d(String(data: res.res, encoding: .utf8)!) }
            print("PM2 重启服务成功".succ)
        }

        static func start(configFile: String, args: [String: String], env: Env) throws {
            let argStr = args.map { "\($0)=\($1)" }
            let res = try run(["-c"] + argStr + ["pm2 start \(configFile)"], env: env)
            guard res.code == 0 else { throw Err.pm2StartFailed.d(String(data: res.res, encoding: .utf8)!) }
            print("PM2 启动服务成功".succ)
        }

        static func stop(configFile: String, env: Env) throws {
            let res = try run("pm2 stop \(configFile)", env: env)
            guard res.code == 0 else { throw Err.pm2StartFailed.d(String(data: res.res, encoding: .utf8)!) }
            print("PM2 停止服务成功".succ)
        }
        
        static func isServing(name: String, env: Env) throws -> Bool {
            let res = try run("pm2 show \(name)", env: env)
            return res.code == 0
        }
    }

    static func isServing(port: Int) throws -> Bool {
        let res = try run("lsof -i :\(port)", env: Env())
        return res.res.count > 0
    }

    static func run(_ arguments: [String], paras: [String: String] = [:], env: Env) throws -> (code: Int32, res: Data) {
        let task = Process()
        let pipe = Pipe()
        task.executableURL = URL(fileURLWithPath: "/bin/bash")
        task.environment = ProcessInfo.processInfo.environment.merging(env.envs) { (_, new) in new }.merging(paras) { (_, new) in new }
        task.arguments = arguments
        task.standardOutput = pipe
        task.standardError = pipe
        do { try task.run() } catch let err { throw Err.shellExecuteFailed.d(err.localizedDescription) }
        task.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return (task.terminationStatus, data)
    }
    
    static func run(_ command: String, paras: [String: String] = [:], env: Env) throws -> (code: Int32, res: Data) { try run(["-c", command], paras: paras, env: env) }

    static func run(in path: String, paras: [String: String] = [:], env: Env) throws -> (code: Int32, res: Data) { try run([path], paras: paras, env:env) }
}

struct FS {

    enum Err: String, ErrList {
        case dirTraversalFailed = "目录遍历失败"
        case fileCreateFailed = "文件创建失败"
        case dirCreateFailed = "目录创建失败"
        case setPermissionFailed = "设置权限失败"
        case dirExist = "目录已存在"
        case mvFailed = "移动文件失败"
    }

    static let fileManager = FileManager.default

    static func ls(path: String, dir: Bool = false, hiddenFile: Bool = false) throws -> [String] {
        guard let files = try? fileManager.contentsOfDirectory(atPath: path) else { throw Err.dirTraversalFailed.d(path) }
        return files.filter { (file) -> Bool in
            var isDir: Bool = false
            let _ = fileManager.fileExists(atPath: path.appendingPathComponent(file), isDirectory: &isDir)
            let isHidden = file.hasPrefix(".")
            return isDir == dir && (hiddenFile || !isHidden)
        }
    }

    static func mkdir(path: String, slience: Bool = true, withIntermediates p: Bool = false, output: Bool = true) throws {
        if !fileManager.fileExists(atPath: path) {
            do { try fileManager.createDirectory(atPath: path, withIntermediateDirectories: p, attributes: nil) } catch let err { throw Err.dirCreateFailed.d(err.localizedDescription) }
            if (output) { print("创建目录: \(path) 成功".succ) }
            return
        } else if !slience { throw Err.dirExist }
        if (output) { print("目录: \(path) 已存在，无需创建".succ) }
    }

    static func mv(path: String, to: String) throws {
        do { try fileManager.moveItem(atPath: path, toPath: to) } catch let err { throw Err.mvFailed.d(err.localizedDescription) }
        print("移动文件: \(path) 到 \(to) 成功".succ)
    }

    static func cp(path: String, to: String) throws {
        do { try fileManager.copyItem(atPath: path, toPath: to) } catch let err { throw Err.mvFailed.d(err.localizedDescription) }
        print("复制文件: \(path) 到 \(to) 成功".succ)
    }

    static func rm(path: String) throws {
        do { try fileManager.removeItem(atPath: path) } catch let err { throw Err.mvFailed.d(err.localizedDescription) }
        print("删除文件: \(path) 成功".succ)
    }

    static func createEnvFile(at path: String, with content: [String: String]) throws {
        let envContent = content.map { "\($0.key)=\($0.value)" }.joined(separator: "\n")
        guard fileManager.createFile(atPath: path, contents: envContent.data(using: .utf8), attributes: nil) else { throw Err.fileCreateFailed.d(path) }
        print("创建 env 文件: \(path) 成功".succ)
    }

    static func readEnvFile(at path: String) throws -> [String: String] {
        guard let content = fileManager.contents(atPath: path),
              let contentString = String(data: content, encoding: .utf8) else {
            throw Err.fileCreateFailed.d(path)
        }
        
        var envDict = [String: String]()
        let lines = contentString.split(separator: "\n")
        for line in lines {
            let keyValue = line.split(separator: "=", maxSplits: 1)
            if keyValue.count == 2 {
                let key = String(keyValue[0]).trimmingCharacters(in: .whitespaces)
                let value = String(keyValue[1]).trimmingCharacters(in: .whitespaces)
                envDict[key] = value
            }
        }
        return envDict
    }

    static func isExist(path: String, dir: Bool = true) -> Bool {
        var isDir: Bool = false
        let exists = fileManager.fileExists(atPath: path, isDirectory: &isDir)
        return exists && (isDir == dir)
    }
    
    static func setPermissions(path: String, owner: String, group: String, permissions: Int, recursive: Bool = false) throws {
        let attributes: [FileAttributeKey: Any] = [
            .posixPermissions: permissions,
            .ownerAccountName: owner,
            .groupOwnerAccountName: group
        ]
        
        do { try fileManager.setAttributes(attributes, ofItemAtPath: path) } catch let err { throw Err.setPermissionFailed.d(err.localizedDescription) }

        if recursive {
            let enumerator = fileManager.enumerator(atPath: path)
            while let element = enumerator?.nextObject() as? String {
                let fullPath = path.appendingPathComponent(element)
                do { try fileManager.setAttributes(attributes, ofItemAtPath: fullPath) } catch let err { throw Err.setPermissionFailed.d(err.localizedDescription) }
            }
        }
        print("设置权限: \(path) 成功".succ)
    }
}

struct Tool {
    static func bakName(name: String) -> String { name + "-" + Date().description }
    static func portAvailable(port: Int) -> Bool { port >= 0 && port < 20 }
}
