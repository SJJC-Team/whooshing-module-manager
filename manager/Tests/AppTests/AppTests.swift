@testable import App
import VaporTesting
import Testing
import Fluent
import WhooshingServer

@Suite("App Tests with DB", .serialized)
struct AppTests {
    private func withApp(_ test: (Whooshing<Https>, Application) async throws -> ()) async throws {
        let woo = try await Whooshing.make(.testing(UnsafeDebuggingOnly.httpsDebuggingData()))
        do {
            for db in Entrypoint.dataBases { woo.app.databases.use(db.config, as: db.id) }
            try await Configuration.https(woo, app: woo.app)
            try await woo.app.autoMigrate()
            try await test(woo, woo.app)
            try await woo.app.autoRevert()
        } catch {
            try? await woo.app.autoRevert()
            try await woo.asyncShutdown()
            throw error
        }
        try await woo.asyncShutdown()
    }
}
