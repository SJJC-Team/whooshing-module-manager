import Vapor
import Logging
import NIOCore
import NIOPosix
import Cryptos
import ErrorHandle
import WhooshingServer

/// 该函数为入口函数，是整个 Vapor 服务的执行起始点
/// 该函数根据环境变量(API, HTTPS)分别设置服务类型，并进行初始化
/// 环境变量可在 Package.swift 中设置
/// 不同服务的 Application 实例可以分别通过 Woo.api, Woo.inline, Woo.https 来取得
/// 要对不同的实例进行额外配置，在 configure.swift 进行额外配置
///
/// 服务运行时，会根据启动参数决定所运行的模式
/// 根据不同的启动参数有：
///
/// swift run App serve --env production
/// swift run App serve --env development
/// swift run App serve --env testing
///
/// 分别对应 生产，开发，测试 环境
/// 若是 xcode 构建，则默认为 development 环境

@main
enum Entrypoint {
    enum Err: String, ErrList {
        var domain: String { "woo.sys.template.configurate.error" }
        case illegalService = "不合法的服务模块"
    }
    
    /// 配置该服务模块是否接受运行在测试环境中，可将其改为 false
    /// 这样，若检测到环境为 testing 将会直接 fatalError
    /// 另请详见 ``Whooshing.Mode``
    static let testingAllowed = true
    
    // 初始化你的 PostgreSQL 配置，此处设置，将连接到所有的服务模块，你也可以提供为不同的子模块提供不同的数据库
    // 这些参数仅在独立测试环境中可用
    // 生产环境中将由 Whooshing 系统提供加密数据库
    //
    // PostgreSQL 连接的主机名在生产和开发环境中仅仅允许在本地(localhost)
    // 而在测试环境中，可指定要用于测试的 Pg 服务器主机名
    // 该字段将会在生产环境中失效，因此标记为 "unsafeTestOnly"
    // unsafeTestOnlyHost 将会根据环境变量检测是否连接到特定的主机名，主要用于 Github Workflow 的自动测试检查
    static let dataBases: [Environment.DB] = [
        .init(
            name: "postgres",
            port: 5432,
            user: "postgres",
            password: "password",
            unsafeTestOnlyHost: ProcessInfo.processInfo.environment["GITHUB_PG_TESTING_HOST"] ?? "localhost"
        )
    ]
    
    static func main() async throws {
        var httpsMode = Whooshing<Https>.Mode.detect(testingAllowed ? UnsafeDebuggingOnly.httpsDebuggingData(databaseConfigs: dataBases) : nil)
        try LoggingSystem.bootstrap(from: &httpsMode.envrionment)
        Woo.isIndependentDebug = httpsMode.envrionment != .production && testingAllowed
        let https = try await Whooshing.make(httpsMode)
        do {
            try await Configuration.https(https, app: https.app)
        } catch {
            https.logger.report(error: error)
            try? await https.asyncShutdown()
            throw error
        }
        Woo.https = https

        let domainForward = DomainForward()

        // 并行启动服务
        async let _ = https.executeWithAsyncShutdown()
        async let _ = domainForward.domainForwardExecute(app: Woo.https.app)
    }
}

struct Woo {
    fileprivate(set) nonisolated(unsafe) static var isIndependentDebug = true
    fileprivate(set) nonisolated(unsafe) static var https: Whooshing<Https>!
}

struct UnsafeDebuggingOnly {
    static let rootKey = Crypto.Symm.Key(data: Data(base64Encoded: rootKeyStr)!)
    static let rootKeyStr = "0apYyvRtLuo7l07zuqbEjFIxDFZ1sIWabKM9mMOOIzQ="
    
    static let apiClientCredential = "bRRPIiYbt0t4RzfqeeHSkg=="

    static let apiClientToken = Crypto.Symm.Key(data: Data(base64Encoded: apiClientTokenStr)!)
    static let apiClientTokenStr = "jXTz4vTQk0O/XFIjWQIHLC7z9/E0/4VtEb+LkF8IcA4="

    static let inlineListenPort = 6500
    static let httpsListenPort = 6501
    static let apiListenPort = 6502
    
    static let serviceIds = [
        UUID(uuidString: "F1ECC1D7-6E19-4F50-9B89-68FAA332B415")!,
        UUID(uuidString: "2AC424F7-F26A-4EA4-BE44-202ABC7CC514")!,
        UUID(uuidString: "74854475-1C1A-48E2-BAC9-E9C752942F88")!,
        UUID(uuidString: "C59C74DC-AF7F-4497-854B-75561D9FE995")!,
        UUID(uuidString: "F02F2803-BF88-4B51-A743-B3AA0F3FF804")!
    ]
    
    static func inlineDebuggingData(databaseConfigs: [Environment.DB] = []) -> Inline.Debuging {
        .init(
            rootKey: rootKey,
            config: Environment.Config(
                name: "Testing-Inline-\(inlineListenPort)",
                port: inlineListenPort,
                databases: databaseConfigs
            ),
            serviceId: serviceIds[0],
            moduleDatas: serviceIds.enumerated().map {
                .init(name: "Testing-Inline-\(inlineListenPort + $0)", serviceId: $1, connection: nil)
            }
        )
    }
    
    static func apiDebuggingData(databaseConfigs: [Environment.DB] = []) -> Api.Debuging {
        .init(
            config: Environment.Config(
                name: "Tesing-Api-\(apiListenPort)",
                port: apiListenPort,
                databases: databaseConfigs
            )
        ) { authData in
            guard authData.credential.base64EncodedString() == apiClientCredential else {
                throw Abort(.badRequest, reason: "用户凭据无效")
            }
            return try Api.Debuging.testingTokenAuth(with: apiClientTokenStr, encrypted: authData.tokenEncrypted)
        }
    }
    
    static func httpsDebuggingData(databaseConfigs: [Environment.DB] = []) -> Https.Debuging{
        .init(
            config: Environment.Config(
                name: "Testing-Https-\(httpsListenPort)",
                port: httpsListenPort,
                databases: databaseConfigs
            )
        )
    }
}
