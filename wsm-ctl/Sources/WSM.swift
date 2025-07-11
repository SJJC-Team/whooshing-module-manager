import ArgumentParser
import Foundation
import SwiftDotenv
import FluentPostgresDriver

@main
struct WSM: ParsableCommand {
    static let configuration = CommandConfiguration(
        subcommands: Config.subCmds,
        groupedSubcommands: [
            .init(name: Github.help + "管理", subcommands: Github.subCmds),
            .init(name: Module.help + "管理", subcommands: Module.subCmds),
            .init(name: PgService.help + "管理", subcommands: PgService.subCmds),
            .init(name: PgDatabase.help + "管理", subcommands: PgDatabase.subCmds),
            .init(name: WebService.help + "管理", subcommands: WebService.subCmds),
        ]
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
    let cfToken: String
    let cfAccountId: String
    let cfZoneId: String
    let nginxDir: String
    let rootDomain: String
    let fileStorageRootDir: String
    let fileStorageOwnerId: UInt
    let fileStorageGroupId: UInt
    let fileStorageRWX: UInt16

    var envs: [String: String] {
        [
            "WHOOSHING_DATA_DIR": dataDir,
            "WHOOSHING_VAULT_ROOT_TOKEN": vaultToken,
            "VAULT_ADDR": vaultAddr,
            "VAULT_TOKEN": vaultToken,
            "CF_Token": cfToken,
            "CF_Account_ID": cfAccountId,
            "CF_Zone_ID": cfZoneId,
            "WHOOSHING_NGINX_DIR": nginxDir,
            "WHOOSHING_ROOT_DOMAIN": rootDomain,
            "WHOOSHING_FILESTORAGE_ROOT_DIR": fileStorageRootDir,
            "WHOOSHING_FILESTORAGE_OWNER_ID": String(fileStorageOwnerId),
            "WHOOSHING_FILESTORAGE_GROUP_ID": String(fileStorageGroupId),
            "WHOOSHING_FILESTORAGE_RWX": String(fileStorageRWX)
        ]
    }

    init() throws {
        try Dotenv.configure(atPath: "/home/woo/.env")
        guard
            let dataDir = ProcessInfo.processInfo.environment["WHOOSHING_DATA_DIR"],
            let vaultToken = ProcessInfo.processInfo.environment["WHOOSHING_VAULT_ROOT_TOKEN"],
            let vaultAddr = ProcessInfo.processInfo.environment["VAULT_ADDR"],
            let cfToken = ProcessInfo.processInfo.environment["CF_Token"],
            let cfAccountId = ProcessInfo.processInfo.environment["CF_Account_ID"],
            let cfZoneId = ProcessInfo.processInfo.environment["CF_Zone_ID"],
            let nginxDir = ProcessInfo.processInfo.environment["WHOOSHING_NGINX_DIR"],
            let rootDomain = ProcessInfo.processInfo.environment["WHOOSHING_ROOT_DOMAIN"],
            let fileStorageRootDir = ProcessInfo.processInfo.environment["WHOOSHING_FILESTORAGE_ROOT_DIR"],
            let fsod = ProcessInfo.processInfo.environment["WHOOSHING_FILESTORAGE_OWNER_ID"], let fileStorageOwnerId = UInt(fsod),
            let fsgd = ProcessInfo.processInfo.environment["WHOOSHING_FILESTORAGE_GROUP_ID"], let fileStorageGroupId = UInt(fsgd),
            let fsRWX = ProcessInfo.processInfo.environment["WHOOSHING_FILESTORAGE_RWX"], let fileStorageRWX = UInt16(fsRWX)
        else { throw Err.envErr }
        
        self.dataDir = dataDir
        self.vaultToken = vaultToken
        self.vaultAddr = vaultAddr
        self.cfToken = cfToken
        self.cfAccountId = cfAccountId
        self.cfZoneId = cfZoneId
        self.nginxDir = nginxDir
        self.rootDomain = rootDomain
        self.fileStorageRootDir = fileStorageRootDir
        self.fileStorageOwnerId = fileStorageOwnerId
        self.fileStorageGroupId = fileStorageGroupId
        self.fileStorageRWX = fileStorageRWX
    }
}
