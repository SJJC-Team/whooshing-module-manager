import Vapor
import Whooshing

struct Configuration {
    /// 对 Https 模块进行配置，如果设置了 INLINE 环境变量
    static func https(_ app: Application) async throws {
        app.migrations.add(Module.MIG())
        app.migrations.add(Domain.MIG())
        try await app.autoMigrate()
        try routes(app)
    }
}
