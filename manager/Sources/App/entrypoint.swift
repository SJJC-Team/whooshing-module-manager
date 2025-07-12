import Vapor
import Logging
import NIOCore
import NIOPosix
import Cryptos
import ErrorHandle
import FileStorage
import WhooshingServer

/// 该函数为入口函数，是整个 Whooshing 服务的执行起始点
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
enum Woo {
    
    /// 配置该服务模块是否接受运行在测试环境中，可将其改为 false
    /// 这样，若检测到环境为 testing 将会直接 fatalError
    /// 另请详见 `Whooshing.Mode`
    static let testingAllowed = true
    
    /// 指示当前环境是否为独立调试模式
    static let isIndependentDebug: Bool = mode.envrionment != .production && testingAllowed
    
    /// 指定所有日志的记录等级
    static let logLevel: Logger.Level = .notice
    
    /// 初始化你的 PostgreSQL 配置，此处设置，将连接到所有的服务模块，你也可以提供为不同的子模块提供不同的数据库
    /// 这些参数仅在独立测试环境中可用
    /// 生产环境中将由 Whooshing 系统提供加密数据库
    ///
    /// 该配置设置 PostgreSQL 服务配置，而每个数据库服务中可有多个数据库，通过 dbParameters 进行设置
    ///
    /// PostgreSQL 连接的主机名在生产和开发环境中仅仅允许在本地(localhost)
    /// 而在测试环境中，可指定要用于测试的 Pg 服务器主机名
    /// 该字段将会在生产环境中失效，因此标记为 "testingHost"
    ///
    /// fileStorageKey 用于文件加密系统的加密主密钥，为方便测试，硬编码至此。在生产环境中，这些均为无效
    /// 只有需要作为 FileStorage 的数据库才需要配置 fileStorageKey，若不设置则表示不支持在其上创建文件加密系统
    /// 作为测试目的，这些密钥可以重复
    static let dbServices: [Environment.DBService] = [
        .init(
            name: "default",
            port: 5432,
            dbParameters: [
                .init(
                    name: "postgres",
                    user: "postgres",
                    password: "password"
                )
            ]
        )
    ]
}

/// 用于调试模式的参数，仅在独立调试和测试模式下生效，不会在生产或非独立开发模式下生效
/// 关于模式，见 `Whooshing.Mode`
struct DebuggingParameters {
    /// 服务跟密钥
    static let rootKey = Crypto.Symm.Key(data: Data(base64Encoded: rootKeyStr)!)
    static let rootKeyStr = "0apYyvRtLuo7l07zuqbEjFIxDFZ1sIWabKM9mMOOIzQ="
    
    /// 客户端访问 api 服务时所必须持有的凭据，若凭据不正确，则会拒绝该用户的连线
    static let apiClientCredential = "bRRPIiYbt0t4RzfqeeHSkg=="
    
    /// 客户端访问 api 服务时所必须持有的口令，若口令不正确，则会拒绝该用户的连线
    static let apiClientToken = Crypto.Symm.Key(data: Data(base64Encoded: apiClientTokenStr)!)
    static let apiClientTokenStr = "jXTz4vTQk0O/XFIjWQIHLC7z9/E0/4VtEb+LkF8IcA4="
    
    /// inline 子模块监听的段口号
    static let inlineListenPort = 6500
    /// https 子模块监听的段口号
    static let httpsListenPort = 6501
    /// api 子模块监听的段口号
    static let apiListenPort = 6502
    
    /// inline 模块接受的来源服务的 ID
    ///
    /// 若有其他服务模块访问该模块，其 ServiceId 必须在以下白名单中，否则将会被拒绝连线
    /// 作为例子仅提供 5 个，你可以按需添加或减少
    static let serviceIds = [
        UUID(uuidString: "F1ECC1D7-6E19-4F50-9B89-68FAA332B415")!,
        UUID(uuidString: "2AC424F7-F26A-4EA4-BE44-202ABC7CC514")!,
        UUID(uuidString: "74854475-1C1A-48E2-BAC9-E9C752942F88")!,
        UUID(uuidString: "C59C74DC-AF7F-4497-854B-75561D9FE995")!,
        UUID(uuidString: "F02F2803-BF88-4B51-A743-B3AA0F3FF804")!
    ]
}

// MARK: - 以下为内部初始化代码，不要随意修改，除非你知道在做什么

extension DebuggingParameters {
    static func inlineDebuggingData(dbServiceConfigs: [Environment.DBService] = []) -> Inline.Debuging {
        .init(
            rootKey: rootKey,
            config: Environment.Config(
                name: "Testing-Inline-\(inlineListenPort)",
                port: inlineListenPort,
                dbServices: dbServiceConfigs
            ),
            serviceId: serviceIds[0],
            moduleDatas: serviceIds.enumerated().map {
                .init(name: "Testing-Inline-\(inlineListenPort + $0)", serviceId: $1, connection: nil)
            }
        )
    }
    
    static func apiDebuggingData(dbServiceConfigs: [Environment.DBService] = []) -> Api.Debuging {
        .init(
            config: Environment.Config(
                name: "Tesing-Api-\(apiListenPort)",
                port: apiListenPort,
                dbServices: dbServiceConfigs
            )
        ) { authData in
            guard authData.credential.base64EncodedString() == apiClientCredential else {
                throw Abort(.badRequest, reason: "用户凭据无效")
            }
            return try Api.Debuging.testingTokenAuth(with: apiClientTokenStr, encrypted: authData.tokenEncrypted)
        }
    }
    
    static func httpsDebuggingData(dbServiceConfigs: [Environment.DBService] = []) -> Https.Debuging{
        .init(
            config: Environment.Config(
                name: "Testing-Https-\(httpsListenPort)",
                port: httpsListenPort,
                dbServices: dbServiceConfigs
            )
        )
    }
}

extension Woo {
    
    static let mode: Whooshing<Https>.Mode = {
        var mode = Whooshing<Https>.Mode.detect(testingAllowed ? DebuggingParameters.httpsDebuggingData(dbServiceConfigs: dbServices) : nil)
        fatalIfFail {
            try LoggingSystem.bootstrap(from: &mode.envrionment)
        }
        return mode
    }()
    
    static let https: Whooshing<Https> = {
        asyncToSync {
            let https = try await Whooshing.make(mode).get()
            https.app.logger.logLevel = logLevel
            do {
                try await Configuration.https(https, app: https.app)
            } catch {
                https.logger.report(error: error)
                try? await https.asyncShutdown().get()
                throw error
            }
            return https
        }
    }()
    
    static func main() async throws {
        try await https.executeWithAsyncShutdown().get()
    }
}
