@testable import App
import VaporTesting
import Testing
import Fluent
import WhooshingServer

@Suite("App Tests with DB", .serialized)
struct AppTests {
    private func withApp(_ test: (Whooshing<Https>, Application) async throws -> ()) async throws {
        let woo = try await Whooshing.make(.testing(DebuggingParameters.httpsDebuggingData(dbServiceConfigs: Woo.dbServices))).get()
        do {
            try await Configuration.https(woo, app: woo.app)
            try await woo.app.autoMigrate()
            try await test(woo, woo.app)
            try await woo.app.autoRevert()
        } catch {
            try? await woo.app.autoRevert()
            try await woo.asyncShutdown().get()
            throw error
        }
        try await woo.asyncShutdown().get()
    }
}
