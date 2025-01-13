import ArgumentParser
import Foundation

struct Module: LCDS {
    
    static let name = "module"
    
    static func begin(env: Env) throws {
        try Sh.Vault.login(env: env)
    }
    
    struct L: List {
        typealias Super = Module
    }
    
    struct C: Create {
        typealias Super = Module
        
        @Argument var name: String
        
        func cmd(env: Env) throws {
            let dir = env.dataDir + "/" + name
            try Sh.Vault.newEngine(module: name, env: env)
            try FS.mkdir(path: dir, slience: true, withIntermediates: true)
            try FS.setPermissions(path: dir, owner: "root", group: "whooshing", permissions: 0o770)
        }
    }
    
    struct D: Delete {
        typealias Super = Module
    }
    
    struct S: Stop {
        typealias Super = Module
    }
    
    
}
