import ArgumentParser
import Foundation

enum Err: String, Error, CustomStringConvertible {
    case envErr = "环境变量导入失败"
    
    var description: String { self.rawValue }
}

@main
struct WSM: ParsableCommand {
    static let configuration = CommandConfiguration(
        subcommands: Module.subCmds
    )
    
    static func getEnv() throws -> Env {
        guard
            let dataDir = ProcessInfo.processInfo.environment["WHOOSHING_DATA_DIR"],
            let vaultToken = ProcessInfo.processInfo.environment["WHOOSHING_VAULT_ROOT"],
            let vaultAddr = ProcessInfo.processInfo.environment["VAULT_ADDR"]
        else { throw Err.envErr }
        return .init( dataDir: dataDir, vaultToken: vaultToken, vaultAddr: vaultAddr )
    }
}

struct Env {
    let dataDir: String
    let vaultToken: String
    let vaultAddr: String
}
