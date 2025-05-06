import Vapor
import Logging
import NIOCore
import NIOPosix
import Whooshing
import ErrorHandle

/// 该函数为入口函数，是整个 Vapor 服务的执行起始点
/// 该函数根据环境变量(API, HTTPS)分别设置服务类型，并进行初始化
/// 环境变量可在 Package.swift 中设置
/// 不同服务的 Application 实例可以分别通过 Woo.api, Woo.inline, Woo.https 来取得
/// 要对不同的实例进行额外配置，在 configure.swift 进行额外配置

@main
enum Entrypoint {
    enum Err: String, ErrList {
        var domain: String { "woo.sys.template.configurate.error" }
        case illegalService = "不合法的服务模块"
    }
    
    static func main() async throws {

        #if API && !INLINE
        fatalError("若要设置 API 模块，必须要设置 INLINE 模块！")
        #endif

        var e = try Environment.detect()
        try LoggingSystem.bootstrap(from: &e)
        let env = e
        let domainForward = DomainForward()
        #if INLINE
        try await runService(.inline, env: env)
        #endif
        #if API
        try await runService(.api, env: env)
        #endif
        #if HTTPS
        try await runService(.https, env: env)
        #endif
        async let _ = domainForward.domainForwardExecute(app: Woo.https)
        #if INLINE
        async let _ = run(app: Woo.inline)
        #endif
        #if API
        async let _ = run(app: Woo.api)
        #endif
        #if HTTPS
        async let _ = run(app: Woo.https)
        #endif
    }

    static func runService(_ service: Application.ServiceType, env: Environment) async throws {
        let app = try await Application.make(env)
        switch service {
            #if API
            case .api: await MainActor.run { Woo.api = app }
            #endif
            #if HTTPS
            case .https: await MainActor.run { Woo.https = app }
            #endif
            #if INLINE
            case .inline: await MainActor.run { Woo.inline = app }
            #endif
            #if !(HTTPS && API && INLINE)
            default: fatalError(Err.illegalService.d(service.rawValue, 20100, (#file, #line)).description)
            #endif
        }
        do {
            switch service {
                #if API
                case .api: try await app.configure(for: .api, data: Woo.inline.inlineClient); try await Configuration.api(app)
                #endif
                #if HTTPS
                case .https: try await app.configure(for: .https); try await Configuration.https(app)
                #endif
                #if INLINE
                case .inline: try await app.configure(for: .inline); try await Configuration.inline(app)
                #endif
                #if !(HTTPS && API && INLINE)
                default: fatalError(Err.illegalService.d(service.rawValue, 20101, (#file, #line)).description)
                #endif
            }
        } catch {
            app.logger.report(error: error)
            try? await app.asyncShutdown()
            throw error
        }
    }

    static func run(app: Application) async {
        do {
            try await app.execute()
            try await app.asyncShutdown()
        } catch let err {
            app.logger.report(error: err)
        }
    }
}

@MainActor
struct Woo {
    #if API
    fileprivate(set) static var api: Application!
    #endif
    #if HTTPS
    fileprivate(set) static var https: Application!
    #endif
    #if INLINE
    fileprivate(set) static var inline: Application!
    #endif
}
