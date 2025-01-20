import ArgumentParser
import Foundation
import FluentPostgresDriver
import Fluent

struct Module: LCDS {
    static let name = "module"
    static let shortName: String? = nil
    static let paraLabel = "模块"
    static let help = "模块"
    static let subCmds: [any ParsableCommand.Type] = [L.self, C.self, D.self]
    
    struct L: List {
        typealias Super = Module
        func cmd(env: Env, depends: Depends) throws -> [String] { try Module.Action.list(env: env) }
    }
    
    struct C: Create {
        typealias Super = Module
        @Argument(help: "模块名称") var names: [String]
        var paras: [String] { names }
        func one(para name: String, env: Env, depends: Depends, i: Int) throws { try Module.Action.create(name: name, env: env, depends: depends) }
    }
    
    struct D: Delete {
        typealias Super = Module
        @Argument(help: "模块名称") var names: [String]
        var paras: [String] { names }
        func one(para name: String, env: Env, depends: Depends, i: Int) throws { try Module.Action.delete(name: name, env: env, depends: depends) }
    }
    
    struct S: Stop { typealias Super = Module; var paras: [()] { [] }; }
}

extension Module {
    enum Action {
        enum Err: String, ErrList {
            case moduleNotFound = "模块不存在"
            case pgServiceExist = "PostgreSQL 服务未删除"
            case createModuleFailed = "创建模块失败"
            case deleteModuleFailed = "删除模块失败"
            case missingModuleConfig = "模块配置异常缺失"
        }   

        static func paraAvailable(module: String, env: Env, depends: Depends) throws -> DBModel.Module {
            try NoCheck.paraAvailable(module: module, env: env)
            guard let res = try DBModel.Module.query(on: depends.db).filter(\.$name == module).first().wait() else { throw Err.missingModuleConfig }
            return res
        }

        static func list(env: Env) throws -> [String] {
            let modules = try FS.ls(path: env.dataDir, dir: true, hiddenFile: false)
            let isEmpty = modules.isEmpty
            if isEmpty { print("无服务模块".info) }
            else { for module in modules { print(module.info) } }
            return modules
        }

        static func create(name: String, env: Env, depends: Depends) throws {
            guard let res = try DBModel.Module.query(on: depends.db).filter(\.$name == name).first().wait() else { throw Err.missingModuleConfig }
            try NoCheck.create(name: name, env: env, basePort: res.startPort)
            do {
                print("正在更新数据库".info)
                let res = try DBModel.Module.query(on: depends.db).sort(\.$startPort, .descending).first().wait()
                let currentPort: Int
                if let res = res { currentPort = res.startPort + res.portSpace }
                else { currentPort = 20000 }
                try DBModel.Module(name: name, serviceId: UUID(), connection: nil, startPort: currentPort, portSpace: 20).create(on: depends.db).wait()
            } catch let err {
                print("任务失败，正在回退".err)
                try? delete(name: name, env: env, depends: depends)
                throw Err.createModuleFailed.d(err.localizedDescription)
            }
        }

        static func delete(name: String, env: Env, depends: Depends) throws {
            let res = try paraAvailable(module: name, env: env, depends: depends)
            try NoCheck.delete(name: name, env: env, basePort: res.startPort)
            print("正在更新数据库".info)
            do { try res.delete(force: false, on: depends.db).wait() } catch let err { throw Err.deleteModuleFailed.d(err.localizedDescription) }
        }
        
        enum NoCheck {
            static func paraAvailable(module: String, env: Env) throws {
                let dir = env.dataDir + "/" + module
                guard FS.isExist(path: dir, dir: true) == true else { throw Err.moduleNotFound.d(dir) }
            }

            static func create(name: String, env: Env, basePort: Int) throws {
                try Sh.Vault.login(env: env)
                let dir = env.dataDir + "/" + name
                do {
                    try Sh.Vault.newEngine(module: name, env: env)
                    try FS.mkdir(path: dir, slience: true, withIntermediates: true)
                    try FS.setPermissions(path: dir, owner: "root", group: "whooshing", permissions: 0o770, recursive: true)
                } catch let err {
                    print("任务失败，正在回退".err)
                    try delete(name: name, env: env, basePort: basePort)
                    throw err
                }
            }

            static func delete(name: String, env: Env, basePort: Int) throws {
                try paraAvailable(module: name, env: env)
                try Sh.Vault.login(env: env)
                let dir = env.dataDir + "/" + name
                let dbs = try PgService.Action.NoCheck.list(module: name,  env: env, basePort: basePort)
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
    }
}