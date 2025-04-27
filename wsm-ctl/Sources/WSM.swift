import ArgumentParser
import Foundation
import SwiftDotenv
import FluentPostgresDriver

@main
struct WSM: ParsableCommand {
    static let configuration = CommandConfiguration(
        subcommands: Config.subCmds,
        groupedSubcommands: [
            .init(name: Module.help + "管理", subcommands: Module.subCmds),
            .init(name: PgService.help + "管理", subcommands: PgService.subCmds),
            .init(name: PgDatabase.help + "管理", subcommands: PgDatabase.subCmds),
            .init(name: WebService.help + "管理", subcommands: WebService.subCmds),
        ], defaultSubcommand: Config.C.self
    )
}

struct Depends {
    let db: Database

    init(env: Env) throws {
        self.db = try DatabaseDepends.initializeIfNeed(env: env)
    }
}

struct Env {

    enum Err: String, ErrList {
        case envErr = "环境变量导入失败"
    }

    let dataDir: String
    let vaultToken: String
    let vaultAddr: String

    var envs: [String: String] {
        [
            "WHOOSHING_DATA_DIR": dataDir,
            "WHOOSHING_VAULT_ROOT_TOKEN": vaultToken,
            "VAULT_ADDR": vaultAddr,
            "VAULT_TOKEN": vaultToken
        ]
    }

    init() throws {
        try Dotenv.configure(atPath: "/home/woo/.env")
        guard
            let dataDir = ProcessInfo.processInfo.environment["WHOOSHING_DATA_DIR"],
            let vaultToken = ProcessInfo.processInfo.environment["WHOOSHING_VAULT_ROOT_TOKEN"],
            let vaultAddr = ProcessInfo.processInfo.environment["VAULT_ADDR"]
        else { throw Err.envErr }
        self.dataDir = dataDir
        self.vaultToken = vaultToken
        self.vaultAddr = vaultAddr
    }
}
