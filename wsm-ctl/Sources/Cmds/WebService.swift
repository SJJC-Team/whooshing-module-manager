import ArgumentParser
import Foundation
import Fluent
import CloudflareDNS

struct WebService: LCDS {
    
    enum ServiceType: String, ExpressibleByArgument {
        case api = "API"
        case https = "HTTPS"
        case inline = "INLINE"
    }
    
    static let name = "webservice"
    static let shortName: String? = "web"
    static let paraLabel = "端口"
    static let help = "网络后端服务"
    static let subCmds: [any ParsableCommand.Type] = [L.self, C.self, D.self, S.self, Restart.self, Start.self]

    struct L: List {
        typealias Super = WebService
        @Argument(help: "模块名称") var module: String
        func cmd(env: Env, depends: Depends) throws -> [String] { 
            let dirs = try Action.list(module: module, env: env) 
            let isEmpty = dirs.isEmpty
            if isEmpty { print("无 Web 服务".info) }
            else { for dir in dirs { print(dir.info) } }
            return dirs
        }
    }
    
    struct C: Create {
        typealias Super = WebService
        @Argument(help: "模块名称") var module: String
        @Argument(help: "该 Web 服务的名称") var name: String
        @Option(name: .shortAndLong, help: "运行该服务的可执行文件包") var bundle: String
        
        @Argument(help: "INLINE 服务的端口号") var inlinePort: Int
        @Argument(help: "API 服务的端口号") var apiPort: Int?
        @Argument(help: "HTTPS 服务的端口号") var httpsPort: Int?

        @Option(name: .shortAndLong, help: "HTTP 服务模块的相对域名") var httpsDomain: String?
        @Option(name: .shortAndLong, help: "API 服务模块的相对域名") var apiDomain: String?

        @Option(name: .shortAndLong, help: "HTTP 服务模块的绑定主机名") var httpsHostname: String?
        @Option(name: .shortAndLong, help: "API 服务模块的绑定主机名") var apiHostname: String?
        
        @Option(name: .shortAndLong, parsing: .upToNextOption, help: "API 服务连接的数据库端口号列表") var apiDbPorts: [Int]
        @Option(name: .shortAndLong, parsing: .upToNextOption, help: "INLINE 服务连接的数据库端口号列表") var inlineDbPorts: [Int]
        @Option(name: .shortAndLong, parsing: .upToNextOption, help: "HTTPS 服务连接的数据库端口号列表") var httpsDbPorts: [Int]

        @Option(name: .shortAndLong, parsing: .upToNextOption, help: "API 服务连接的数据库名称") var apiDbNames: [String]
        @Option(name: .shortAndLong, parsing: .upToNextOption, help: "INLINE 服务连接的数据库名称") var inlineDbNames: [String]
        @Option(name: .shortAndLong, parsing: .upToNextOption, help: "HTTPS 服务连接的数据库名称") var httpsDbNames: [String]
        
        struct Paras {
            let domain: String?
            let serviceType: ServiceType
            let hostname: String
            let port: Int
            let dbServices: [DBService]

            struct DBService {
                let name: String
                let port: Int
                let dbs: [String]
            }
        }
        
        var paras: [String] { [bundle] }
        func one(para name: String, i: Int, env: Env, depends: Depends) throws {
            let paras: [Paras] = ([.api: apiPort, .inline: inlinePort, .https: httpsPort].compactMapValues { $0 } as [ServiceType: Int]).map { type, port in
                let domain: String?
                let hostname: String
                var dbServices: [Paras.DBService] = []
                switch type {
                case .api:
                    domain = apiDomain
                    hostname = apiHostname ?? "localhost"
                    
                    for (i, dbPort) in apiDbPorts.enumerated() {
                        dbServices.append(.init(name: "api_\(dbPort)", port: dbPort, dbs: [apiDbNames[i]]))
                    }
                case .inline:
                    domain = nil
                    hostname = "localhost"
                    
                    for (i, dbPort) in inlineDbPorts.enumerated() {
                        dbServices.append(.init(name: "inline_\(dbPort)", port: dbPort, dbs: [inlineDbNames[i]]))
                    }
                case .https:
                    domain = httpsDomain
                    hostname = httpsHostname ?? "localhost"
                    
                    for (i, dbPort) in httpsDbPorts.enumerated() {
                        dbServices.append(.init(name: "https_\(dbPort)", port: dbPort, dbs: [httpsDbNames[i]]))
                    }
                }
                return .init(
                    domain: domain,
                    serviceType: type,
                    hostname: hostname,
                    port: port,
                    dbServices: dbServices
                )
            }
            
            try Action.create(
                module: module,
                name: name,
                serviceParas: paras,
                bundle: bundle,
                env: env,
                depends: depends
            )
        }
    }
    
    struct D: Delete {
        typealias Super = WebService
        @Argument(help: "模块名称") var module: String
        @Option(name: .shortAndLong, parsing: .upToNextOption, help: "Web 服务的名称") var name: [String]
        var paras: [String] { name }
        func one(para name: String, i: Int, env: Env, depends: Depends) throws { try Action.delete(module: module, name: name, env: env, depends: depends) }
    }
    
    struct S: Stop {
        typealias Super = WebService
        @Argument(help: "模块名称") var module: String
        @Option(name: .shortAndLong, parsing: .upToNextOption, help: "Web 服务的名称") var name: [String]
        var paras: [String] { name }
        func one(para name: String, i: Int, env: Env, depends: Depends) throws { try Action.stop(module: module, name: name, env: env, depends: depends) }
    }

    struct Restart: LCDExpand {
        typealias Super = WebService
        static var name: String { "restart" }
        static let shortName: String? = nil
        static var help: String { "重启 " }

        @Argument(help: "模块名称") var module: String
        @Option(name: .shortAndLong, parsing: .upToNextOption, help: "Web 服务的名称") var name: [String]
        var paras: [String] { name }
        func one(para name: String, i: Int, env: Env, depends: Depends) throws { try Action.restart(module: module, name: name, env: env, depends: depends) }
    }

    struct Start: LCDExpand {
        typealias Super = WebService
        static var name: String { "start" }
        static let shortName: String? = nil
        static var help: String { "启动 " }

        @Argument(help: "模块名称") var module: String
        @Option(name: .shortAndLong, parsing: .upToNextOption, help: "Web 服务的名称") var name: [String]
        var paras: [String] { name }
        func one(para name: String, i: Int, env: Env, depends: Depends) throws { try Action.start(module: module, name: name, env: env, depends: depends) }
    }
}

extension WebService {
    enum Action {
        enum Err: String, ErrList {
            case portOccupied = "端口被占用"
            case portNotCorrect = "端口号不正确, 请在 1 ~ 19 之间"
            case serviceNotFound = "Web 服务不存在"
            case serviceAlreadyExist = "Web 服务已存在"
            case serviceIsRunning = "Web 服务正在运行"
            case serviceIsNotRunning = "Web 服务未运行"
            case missingBundle = "缺少可执行文件包"
            case pgServiceNotRunning = "PostgreSQL 服务未运行"
            case missingInlineService = "Inline 模块未找到"
            case createModuleFailed = "创建 Web 模块失败"
        }

        static func paraAvailable(module: String, name: String, env: Env, depends: Depends) throws -> DBModel.Module {
            let model = try Module.Action.paraAvailable(module: module, env: env, depends: depends)
            try NoCheck.paraAvailable(module: module, name: name, env: env)
            return model
        }

        static func list(module: String, env: Env) throws -> [String] {
            try Module.Action.NoCheck.paraAvailable(module: module, env: env)
            let moduleDir = "\(env.dataDir)/\(module)/web"
            try FS.mkdir(path: moduleDir, slience: true, withIntermediates: true, output: false)
            let dirs = try FS.ls(path: moduleDir, dir: true, hiddenFile: false)
            return dirs
        }
        
        static func create(module: String, name: String, serviceParas: [C.Paras], bundle: String, env: Env, depends: Depends) throws {
            let model = try Module.Action.paraAvailable(module: module, env: env, depends: depends)
            guard let inline = (serviceParas.first { $0.serviceType == .inline }) else { throw Err.missingInlineService }
            try NoCheck.create(module: module, name: name, serviceParas: serviceParas, bundle: bundle, env: env, dbModule: model)
            do {
                try createDomain(module: module, name: name, model: model, serviceParas: serviceParas, env: env, depends: depends)
                try DBModel.Module.query(on: depends.db).set(\.$connection, to: "http://localhost:\(model.startPort + inline.port)").filter(\.$serviceId == model.serviceId).update().wait()
                print("数据库更新完成".succ)
            } catch let err {
                print("任务失败-数据库更新失败，正在回退".err)
                try? delete(module: module, name: name, env: env, depends: depends)
                throw Err.createModuleFailed.d(err.localizedDescription)
            }
        }

        static func createDomain(module: String, name: String, model: DBModel.Module, serviceParas: [C.Paras], env: Env, depends: Depends) throws {
            let moduleDir = "\(env.dataDir)/\(module)"
            let dataDir = "\(moduleDir)/web/\(name)"
            let envFile = "\(dataDir)/.env"

            let cloudflare = Cloudflare(token: env.cfToken, accountId: env.cfAccountId, zoneId: env.cfZoneId)
            let semaphore = DispatchSemaphore(value: 0)
            var caughtError: Error?
            var envs: [String: String] = [:]
            Task.detached {
                defer { semaphore.signal() }
                do {
                    let records = try await cloudflare.listRecords()
                    print("正在拉取所有的 DNS 记录".info)
                    for serPara in serviceParas {
                        let serviceSuffix = serPara.serviceType.rawValue.uppercased()
                        if let domain = serPara.domain {
                            let ip = try Sh.ipAddr()
                            let dnsRec: DNSRecord
                            if let record = records.first(where: { $0.name == domain }) {
                                print("DNS 记录已存在，无需再创建".succ)
                                dnsRec = try await cloudflare.updateRecord(.init(.A, domain: domain, to: ip), id: record.id)
                            }
                            else {
                                print("DNS 记录不存在，正在创建".info)
                                dnsRec = try await cloudflare.createRecord(.init(.A, domain: domain, to: ip))
                            }

                            envs["CLOUDFLARE_DNS_RECORD_ID_\(serviceSuffix)"] = dnsRec.id

                            let p = model.startPort + serPara.port
                            if serPara.serviceType == .https {
                                print("正在申请证书，请稍侯...".info)
                                try Sh.Acme.create(domain: domain, port: p, wildcard: true, force: true, env: env)

                                envs["ACME_CERT_\(serviceSuffix)"] = domain

                                try Sh.Nginx.create(domain: domain, port: p, https: true, wildcard: true, env: env)
                            } else {
                                if let _ = try await DBModel.Domain.query(on: depends.db).filter(\.$domain == domain).first() {
                                    print("域名转发配置已存在，更新中...".info)
                                    try await DBModel.Domain.query(on: depends.db).set(\.$port, to: p).filter(\.$domain == domain).update()
                                } else {
                                    print("正在创建域名转发配置...".info)
                                    try await DBModel.Domain(domain: domain, port: p).save(on: depends.db)
                                }

                                envs["DOMAIN_FORWARD_\(serviceSuffix)"] = domain

                                print("域名转发配置完成".info)
                                try Sh.Nginx.create(domain: domain, port: p, https: false, wildcard: true, env: env)
                            }
                            envs["NGINX_CONF_\(serviceSuffix)"] = domain
                        }
                    }
                } catch {
                    caughtError = error
                }
            }
            semaphore.wait()
            if envs.count > 0 { try FS.appendEnvFile(to: envFile, with: envs) }
            if let error = caughtError { throw error }
            try Sh.Nginx.restart(env: env)
        }

        static func delete(module: String, name: String, env: Env, depends: Depends) throws {
            let model = try paraAvailable(module: module, name: name, env: env, depends: depends)
            let envFile = "\(env.dataDir)/\(module)/web/\(name)/.env"
            try cleanDomains(envFile: envFile, env: env, depends: depends)
            try NoCheck.delete(module: module, name: name, env: env, basePort: model.startPort)
        }

        static func cleanDomains(envFile: String, env: Env, depends: Depends) throws {
            print("正在清空域名配置".info)
            let cloudflare = Cloudflare(token: env.cfToken, accountId: env.cfAccountId, zoneId: env.cfZoneId)
            let envs = try FS.readEnvFile(at: envFile)

            let semaphore = DispatchSemaphore(value: 0)
            var error: Error?
            Task.detached {
                defer {
                    semaphore.signal()
                }
                do {
                    for (key, value) in envs {
                        if key.hasPrefix("CLOUDFLARE_DNS_RECORD_ID_") {
                            let _ = try await cloudflare.deleteRecord(value)
                        } else if key.hasPrefix("ACME_CERT_") {
                            try Sh.Acme.delete(domain: value, wildcard: true, env: env)
                        } else if key.hasPrefix("DOMAIN_FORWARD_") {
                            try await DBModel.Domain.query(on: depends.db).filter(\.$domain == value).delete()
                        } else if key.hasPrefix("NGINX_CONF_") {
                            try Sh.Nginx.delete(domain: value, env: env)
                        }
                    }
                } catch let err {
                    error = err
                }
            }
            
            semaphore.wait()
            if let err = error { throw err }
            try Sh.Nginx.restart(env: env)
        }

        static func restart(module: String, name: String, env: Env, depends: Depends) throws {
            let model = try Module.Action.paraAvailable(module: module, env: env, depends: depends)
            try NoCheck.start(module: module, name: name, env: env, dbModule: model)
        }

        static func start(module: String, name: String, env: Env, depends: Depends) throws {
            let model = try Module.Action.paraAvailable(module: module, env: env, depends: depends)
            try NoCheck.start(module: module, name: name, env: env, dbModule: model)
        }

        static func stop(module: String, name: String, env: Env, depends: Depends) throws {
            let model = try Module.Action.paraAvailable(module: module, env: env, depends: depends)
            try NoCheck.stop(module: module, name: name, env: env, dbModule: model)
        }

        struct NoCheck {

            static func paraAvailable(module: String, name: String, env: Env) throws {
                try Module.Action.NoCheck.paraAvailable(module: module, env: env)
                let moduleDir = env.dataDir + "/" + module
                let dataDir = moduleDir + "/web/" + name
                guard FS.isExist(path: dataDir, dir: true) == true else { throw Err.serviceNotFound.d(dataDir) }
            }

            static func parseEnv(in envFile: String, module: DBModel.Module, env: Env) throws -> [String: String] {
                var paras = try FS.readEnvFile(at: envFile)
                for (k, v) in paras { 
                    if k.contains("PORT") { let dp = Int(v)!; paras[k] = String(module.startPort + dp) }
                    else if k.contains("PASSWORD") { paras[k] = try Sh.Vault.getKey(in: v, env: env) }
                    else if k.contains("FILE_STORAGE_KEY") { paras[k] = try Sh.Vault.getKey(in: v, env: env) }
                }
                for envName in [
                    "WHOOSHING_API_SERVICE_MANAGER_URL",
                    "WHOOSHING_INLINE_SERVICE_MANAGER_URL",
                    "WHOOSHING_HTTPS_SERVICE_MANAGER_URL",
                ] {
                    paras[envName] = "http://localhost:20000"
                }
                paras["WHOOSHING_INLINE_SERVICE_PRIVATE_SERVICE_ID"] = module.serviceId.uuidString.lowercased()
                paras["WHOOSHING_API_SERVICE_PRIVATE_AUTHENTICATION_URL"] = "http://localhost:20020"
                
                for service in [ServiceType.https, .api, .inline] {
                    paras["WHOOSHING_\(service.rawValue.uppercased())_SERVICE_FILE_STORAGE_DIR"] = env.fileStorageRootDir
                    paras["WHOOSHING_\(service.rawValue.uppercased())_SERVICE_FILE_STORAGE_UNIX_PERMISSION_OWNER_ID"] = String(env.fileStorageOwnerId)
                    paras["WHOOSHING_\(service.rawValue.uppercased())_SERVICE_FILE_STORAGE_UNIX_PERMISSION_GROUP_ID"] = String(env.fileStorageGroupId)
                    paras["WHOOSHING_\(service.rawValue.uppercased())_SERVICE_FILE_STORAGE_UNIX_PERMISSION_RWX"] = String(env.fileStorageRWX)
                }
                
                return paras
            }

            static func create(module: String, name: String, serviceParas: [C.Paras], bundle: String, env: Env, dbModule: DBModel.Module) throws {
                try Module.Action.NoCheck.paraAvailable(module: module, env: env)
                let moduleDir = "\(env.dataDir)/\(module)"
                let dataDir = "\(moduleDir)/web/\(name)"
                let envFile = "\(dataDir)/.env"
                let bundleDir = "\(dataDir)/bundle"
                var envParas: [String: String] = [:]
                for serPara in serviceParas {
                    let p = dbModule.startPort + serPara.port
                    guard Tool.portAvailable(port: serPara.port) else { throw Err.portNotCorrect.d(String(serPara.port)) }
                    guard FS.isExist(path: dataDir, dir: true) == false else { throw Err.serviceAlreadyExist.d(dataDir) }
                    guard try !Sh.isServing(port: p) else { throw Err.portOccupied.d("\(p)[\(dbModule.startPort) + \(serPara.port)]") }
                    
                    let envPrefix = "WHOOSHING_\(serPara.serviceType.rawValue.uppercased())_SERVICE"
                    envParas[envPrefix + "_DB_COUNT"] = String(serPara.dbServices.count)
                    envParas[envPrefix + "_NAME"] = "\(serPara.serviceType)Service-\(serPara.port)"
                    envParas[envPrefix + "_PORT"] = String(serPara.port)
                    envParas[envPrefix + "_HOSTNAME"] = serPara.hostname
                    
                    for (i, dbService) in serPara.dbServices.enumerated() {
                        
                        let dbServicePort = dbModule.startPort + dbService.port
                        guard try Sh.isServing(port: dbServicePort) == true else { throw Err.pgServiceNotRunning.d(String(dbServicePort)) }
                        
                        envParas["\(envPrefix)_DB_\(i + 1)_NAME"] = dbService.name
                        envParas["\(envPrefix)_DB_\(i + 1)_PORT"] = String(dbService.port)
                        envParas["\(envPrefix)_DB_\(i + 1)_DBS_COUNT"] = String(dbService.dbs.count)
                        
                        for (j, db) in dbService.dbs.enumerated() {
                            
                            envParas["\(envPrefix)_DB_\(i + 1)_DB_\(j + 1)_NAME"] = db
                            envParas["\(envPrefix)_DB_\(i + 1)_DB_\(j + 1)_USER"] = "woo"
                            envParas["\(envPrefix)_DB_\(i + 1)_DB_\(j + 1)_PASSWORD"] = "\(module)/\(dbService.port)/role/woo"
                            envParas["\(envPrefix)_DB_\(i + 1)_DB_\(j + 1)_FILE_STORAGE_KEY"] = "\(module)/\(dbService.port)/file_storage/\(db)"

                        }
                    }
                }
                do {
                    try FS.mkdir(path: dataDir, slience: true, withIntermediates: true)
                    try FS.createEnvFile(at: envFile, with: envParas)
                    try FS.cp(path: bundle, to: bundleDir)
                    try FS.setPermissions(path: dataDir, owner: "root", group: "whooshing", permissions: 0o770, recursive: true)
                    try start(module: module, name: name, env: env, dbModule: dbModule)
                } catch let err {
                    print("任务失败，正在回退".err)
                    try? stop(module: module, name: name, env: env, dbModule: dbModule)
                    try? delete(module: module, name: name, env: env, basePort: dbModule.startPort)
                    throw err
                }
            }

            static func delete(module: String, name: String, env: Env, basePort: Int) throws {
                try paraAvailable(module: module, name: name, env: env)
                let moduleDir = "\(env.dataDir)/\(module)"
                let dataDir = "\(moduleDir)/web/\(name)"
                let envFile = "\(dataDir)/.env"
                let bundleDir = "\(dataDir)/bundle"
                try FS.rm(path: envFile)
                try FS.mkdir(path: moduleDir + "/.trash", slience: true, withIntermediates: true)
                let backupName = Tool.bakName(name: name)
                try Sh.PM2.delete(configFile: "\(bundleDir)/pm2.config.json", cwd: bundleDir, env: env)
                try FS.mv(path: dataDir, to: moduleDir + "/.trash/" + backupName)
            }

            static func restart(module: String, name: String, env: Env, dbModule: DBModel.Module) throws {
                try Module.Action.NoCheck.paraAvailable(module: module, env: env)
                let dataDir = "\(env.dataDir)/\(module)/web/\(name)"
                let bundleDir = "\(dataDir)/bundle"
                let paras = try parseEnv(in: "\(dataDir)/.env", module: dbModule, env: env)
                try Sh.PM2.restart(configFile: "\(bundleDir)/pm2.config.json", args: paras, cwd: bundleDir, env: env)
            }

            static func start(module: String, name: String, env: Env, dbModule: DBModel.Module) throws {
                try Module.Action.NoCheck.paraAvailable(module: module, env: env)
                let dataDir = "\(env.dataDir)/\(module)/web/\(name)"
                let bundleDir = "\(dataDir)/bundle"
                let paras = try parseEnv(in: "\(dataDir)/.env", module: dbModule, env: env)
                // print(paras.map { "\($0.key)=\($0.value)" }.joined(separator: " "))
                try Sh.PM2.start(configFile: "\(bundleDir)/pm2.config.json", args: paras, cwd: bundleDir, env: env)
            }

            static func stop(module: String, name: String, env: Env, dbModule: DBModel.Module) throws {
                try Module.Action.NoCheck.paraAvailable(module: module, env: env)
                let dataDir = "\(env.dataDir)/\(module)/web/\(name)"
                let bundleDir = "\(dataDir)/bundle"
                try Sh.PM2.stop(configFile: "\(bundleDir)/pm2.config.json", cwd: bundleDir, env: env)
            }
        }
    }
}
