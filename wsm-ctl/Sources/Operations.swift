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
        }

        static func login(env: Env) throws {
            switch (try run(in: File.sh(.vaultLogin), env: env).code) {
                case 1: throw Err.vaultIsSealed
                case 0: print("成功登陆到 Vault".succ)
                default: throw Err.vaultLoginFailed
            }
        }

        static func newEngine(module: String, env: Env) throws {
            switch (try run(in: File.sh(.vaultNewEngine), paras: ["module": module], env: env).code) {
                case 1: throw Err.vaultEngineExist
                case 0: print("密钥引擎创建成功".succ)
                default: throw Err.vaultNewEngineFailed
            }
        }

        static func moduleBackup(module: String, backupName: String, env: Env) throws {
            switch (try run(in: File.sh(.vaultModuleBackup), paras: [
                "module": module,
                "backup_name": backupName
            ], env: env).code) {
                case 1: throw Err.vaultEngineNotFound
                case 2: print("存储引擎\(module)为空，无需备份密钥，禁用引擎\(module)完成".succ)
                case 3: throw Err.backupFileCreateFailed
                case 0: print("已备份引擎 \(module) 的密钥到 \(backupName)".succ)
                default: throw Err.vaultNewEngineFailed
            }
        }
    }

    static func run(in path: String, paras: [String: String] = [:], env: Env) throws -> (code: Int32, res: Data) {
        let task = Process()
        let pipe = Pipe()
        task.executableURL = URL(fileURLWithPath: "/bin/bash")
        task.environment = ProcessInfo.processInfo.environment.merging(env.envs) { (current, _) in current }.merging(paras) { (current, _) in current }
        task.arguments = [path]
        task.standardOutput = pipe
        task.standardError = pipe
        do { try task.run() } catch let err { throw Err.shellExecuteFailed.d(err.localizedDescription) }
        task.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return (task.terminationStatus, data)
    }
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
        if recursive {
            let enumerator = fileManager.enumerator(atPath: path)
            while let element = enumerator?.nextObject() as? String {
                let fullPath = path.appendingPathComponent(element)
                do { try fileManager.setAttributes(attributes, ofItemAtPath: fullPath) } catch let err { throw Err.setPermissionFailed.d(err.localizedDescription) }
            }
        } else {
            do { try fileManager.setAttributes(attributes, ofItemAtPath: path) } catch let err { throw Err.setPermissionFailed.d(err.localizedDescription) }
        }
        print("设置权限: \(path) 成功".succ)
    }
}