import ArgumentParser
import Foundation

struct Module: LCDS {
    
    static let name = "module"
    static let shortName: String? = nil
    static let paraLabel = "模块"
    static let help = "模块"
    static let subCmds: [any ParsableCommand.Type] = [L.self, C.self, D.self]
    
    struct L: List {
        typealias Super = Module
        func cmd(env: Env) throws -> [String] {
            let modules = try FS.ls(path: env.dataDir, dir: true, hiddenFile: false)
            let isEmpty = modules.isEmpty
            if isEmpty { print("无服务模块".info) }
            else { for module in modules { print(module.info) } }
            return modules
        }
    }
    
    struct C: Create {
        typealias Super = Module
        @Argument(help: "模块名称") var names: [String]
        var paras: [String] { names }
        func one(para name: String, env: Env) throws {
            try Sh.Vault.login(env: env)
            let dir = env.dataDir + "/" + name
            try Sh.Vault.newEngine(module: name, env: env)
            try FS.mkdir(path: dir, slience: true, withIntermediates: true)
            try FS.setPermissions(path: dir, owner: "root", group: "whooshing", permissions: 0o770, recursive: true)
        }
    }
    
    struct D: Delete {
        typealias Super = Module
        @Argument(help: "模块名称") var names: [String]
        var paras: [String] { names }
        func one(para name: String, env: Env) throws {
            try paraAvailable(module: name, env: env)
            try Sh.Vault.login(env: env)
            let dir = env.dataDir + "/" + name
            let dbs = try PgService.L.list(module: name,  env: env)
            guard dbs.count == 0 else { 
                print("该模块还有以下 PostgreSQL 服务模块，请先删除:".warn)
                for db in dbs { print(db.info) }
                throw Err.pgServiceExist 
            }
            let backupName = Tool.bakName(name: name)
            try Sh.Vault.moduleBackup(module: name, backupName: backupName, env: env)
            try FS.mkdir(path: env.dataDir + "/.trash", slience: true, withIntermediates: true)
            try FS.mv(path: dir, to: env.dataDir + "/.trash/" + backupName)
        }
    }
    
    struct S: Stop { typealias Super = Module; var paras: [()] { [] }; }

    static func paraAvailable(module: String, env: Env) throws {
        let dir = env.dataDir + "/" + module
        guard FS.isExist(path: dir, dir: true) == true else { throw Err.moduleNotFound.d(dir) }
    }
    
    enum Err: String, ErrList {
        case moduleNotFound = "模块不存在"
        case pgServiceExist = "PostgreSQL 服务未删除"
    }   
}
