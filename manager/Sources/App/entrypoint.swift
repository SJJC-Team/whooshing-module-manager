import Vapor
import Logging
import NIOCore
import NIOPosix
import Whooshing
import ErrorHandle

/// 该函数为入口函数，是整个 Vapor 服务的执行起始点
/// 该函数根据环境变量(API, INLINE, HTTPS)分别设置服务类型，并进行初始化
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
        var e = try Environment.detect()
        try LoggingSystem.bootstrap(from: &e)
        let env = e
        #if API
        async let _ = runService(.api, env: env)
        #endif
        #if HTTPS
        async let _ = runService(.https, env: env)
        #endif
        #if INLINE
        async let _ = runService(.inline, env: env)
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
            #if !(INLINE && HTTPS && API)
            default: fatalError(Err.illegalService.d(service.rawValue, 20100, (#file, #line)).description)
            #endif
        }
        do {
            switch service {
                #if API
                case .api: try await app.configure(for: .api); try await Configuration.api(app)
                #endif
                #if HTTPS
                case .https: try await app.configure(for: .https); try await Configuration.https(app)
                #endif
                #if INLINE
                case .inline: try await app.configure(for: .inline); try await Configuration.inline(app)
                #endif
                #if !(INLINE && HTTPS && API)
                default: fatalError(Err.illegalService.d(service.rawValue, 20101, (#file, #line)).description)
                #endif
            }
        } catch {
            app.logger.report(error: error)
            try? await app.asyncShutdown()
            throw error
        }
        do {
            try await app.execute()
            try await app.asyncShutdown()
        } catch {
            print("Error: \(error)")
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
