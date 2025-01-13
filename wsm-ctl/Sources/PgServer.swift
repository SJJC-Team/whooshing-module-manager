import ArgumentParser
import Foundation

struct PgServer: LCDS {
    static let name = "pgserver"

    static func begin(env: Env) throws {
        
    }

    struct L: List {
        typealias Super = PgServer
    }
    
    struct C: Create {
        typealias Super = PgServer

        @Argument(help: "模块名称") var module: String
        @Argument(help: "PostgreSQL 将用于监听的端口号") var port: Int

        func cmd(env: Env) throws {
            let moduleDir = env.dataDir + "/" + module
            let perconaDir = moduleDir + "/percona"
            let dataDir = "\(perconaDir)/\(port)"
            
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
        typealias Super = PgServer
    }
    
    struct S: Stop {
        typealias Super = PgServer
    }

    enum Err: String, ErrList {
        case moduleNotFound = "模块不存在"
        case portOccupied = "端口被占用"
        case portNotCorrect = "端口号不正确, 请在 1024 ~ 65535 之间"
        case serviceAlreadyExist = "PostgreSQL 服务已存在"
    }

}