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
            case pgInitService = "pg_init_service"
            case pgRestartService = "pg_restart_service"
        }

        static func sh(_ shell: Shell) throws -> String {
            guard let filePath = Bundle.module.path(forResource: shell.rawValue, ofType: "sh") else { throw Err.fileNotFound }
            return filePath
        }
    }

    struct Vault {

        enum Err: String, ErrList {
            case vaultEngineExist = "Vault 引擎已存在"
            case vaultNewEngineFailed = "新建 Vault 引擎失败"
            case vaultLoginFailed = "Vault 登陆失败"
            case vaultIsSealed = "Vault 为封存状态"
            case vaultEngineNotFound = "Vault 引擎不存在"
            case backupFileCreateFailed = "备份文件创建失败"
            case vaultUnknowError = "Vault 未知错误"
        }

        static func login(env: Env) throws {
            let res = try run(in: File.sh(.vaultLogin), env: env)
            switch (res.code) {
                case 1: throw Err.vaultIsSealed
                case 2: throw Err.vaultLoginFailed
                case 0: print("成功登陆到 Vault".succ)
                default: throw Err.vaultUnknowError.d(String(data: res.res, encoding: .utf8)!)
            }
        }

        static func newEngine(module: String, env: Env) throws {
            let res = try run(in: File.sh(.vaultNewEngine), paras: ["module": module], env: env)
            switch (res.code) {
                case 1: throw Err.vaultEngineExist
                case 0: print("密钥引擎创建成功".succ)
                default: throw Err.vaultUnknowError.d(String(data: res.res, encoding: .utf8)!)
            }
        }

        static func moduleBackup(module: String, backupName: String, env: Env) throws {
            let res = try run(in: File.sh(.vaultModuleBackup), paras: [
                "module": module,
                "backup_name": backupName
            ], env: env)
            switch (res.code) {
                case 1: throw Err.vaultEngineNotFound
                case 2: print("存储引擎\(module)为空，无需备份密钥，禁用引擎\(module)完成".succ)
                case 3: throw Err.backupFileCreateFailed
                case 0: print("已备份引擎 \(module) 的密钥到 \(backupName)".succ)
                default: throw Err.vaultUnknowError.d(String(data: res.res, encoding: .utf8)!)
            }
        }

        static func newKey(in path: String, env: Env) throws {
            let res = try run(in: File.sh(.vaultNewKey), paras: ["path": path], env: env)
            switch (res.code) {
                case 1: print("密钥已存在于 \(path)，无需创建".succ)
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
    }

    struct PG {

        enum Err: String, ErrList {
            case pgUnknowError = "PostgreSQL 未知错误"
        }

        static func initS(module: String, port: Int, key: String, env: Env) throws {
            let res = try run(in: File.sh(.pgInitService), paras: [
                "module": module,
                "port": String(port),
                "key": key
            ], env: env)
            guard res.code == 0 else { throw Err.pgUnknowError.d(String(data: res.res, encoding: .utf8)!) }
            guard let _ = String(data: res.res, encoding: .utf8) else { throw Err.pgUnknowError.d("PostgreSQL 服务初始化输出解包失败-\(module).\(port)") }
            print("PostgreSQL 服务 \(module).\(port) 初始化成功".succ)
        }

        static func restart(dataDir: String, env: Env) throws {
            let res = try run(in: File.sh(.pgRestartService), paras: ["data_dir": dataDir], env: env)
            guard res.code == 0 else { throw Err.pgUnknowError.d(String(data: res.res, encoding: .utf8)!) }
            print("PostgreSQL 服务 \(dataDir) 重启成功".succ)
        }
    }

    static func run(_ command: String, paras: [String: String] = [:], env: Env) throws -> (code: Int32, res: Data) {
        let task = Process()
        let pipe = Pipe()
        task.executableURL = URL(fileURLWithPath: "/bin/bash")
        task.environment = ProcessInfo.processInfo.environment.merging(env.envs) { (_, new) in new }.merging(paras) { (_, new) in new }
        task.arguments = [command]
        task.standardOutput = pipe
        task.standardError = pipe
        do { try task.run() } catch let err { throw Err.shellExecuteFailed.d(err.localizedDescription) }
        task.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return (task.terminationStatus, data)
    }
    
    static func run(in path: String, paras: [String: String] = [:], env: Env) throws -> (code: Int32, res: Data) { try run(path, paras: paras, env:env) }
}

struct FS {

    enum Err: String, ErrList {
        case fileCreateFailed = "文件创建失败"
        case dirCreateFailed = "目录创建失败"
        case setPermissionFailed = "设置权限失败"
        case dirExist = "目录已存在"
        case mvFailed = "移动文件失败"
    }

    static let fileManager = FileManager.default

    static func ls(path: String, dir: Bool = false, hiddenFile: Bool = false) throws -> [String] {
        guard let files = try? fileManager.contentsOfDirectory(atPath: path) else { throw Err.fileCreateFailed }
        return files.filter { (file) -> Bool in
            var isDir: Bool = false
            let _ = fileManager.fileExists(atPath: path.appendingPathComponent(file), isDirectory: &isDir)
            let isHidden = file.hasPrefix(".")
            return isDir == dir && (hiddenFile || !isHidden)
        }
    }

    static func mkdir(path: String, slience: Bool = true, withIntermediates p: Bool = false) throws {
        if !fileManager.fileExists(atPath: path) {
            do { try fileManager.createDirectory(atPath: path, withIntermediateDirectories: p, attributes: nil) } catch let err { throw Err.dirCreateFailed.d(err.localizedDescription) }
            print("创建目录: \(path) 成功".succ)
            return
        } else if !slience { throw Err.dirExist }
        print("目录: \(path) 已存在，无需创建".succ)
    }

    static func mv(path: String, to: String) throws {
        do { try fileManager.moveItem(atPath: path, toPath: to) } catch let err { throw Err.mvFailed.d(err.localizedDescription) }
        print("移动文件: \(path) 到 \(to) 成功".succ)
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
    static func portAvailable(port: Int) -> Bool { port > 1024 && port < 65535 }
}