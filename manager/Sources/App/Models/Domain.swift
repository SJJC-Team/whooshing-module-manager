import PgSQL
import Foundation
import Vapor

final class Domain: PGModel, @unchecked Sendable  {
    static let name: String = "domains"

    struct Fields: PGFields {
        static var tdeEncrypt: Bool { !Woo.isIndependentDebug }
        let id = PGField("id", .uuid)
        let domain = PGField("domain", .string, true).cons([.required])
        let port = PGField("port", .int, true).cons([.required])
        let createdAt = PGField("create_at", .string)
        let updateAt = PGField("update_at", .string)
    }

    static let fields = Fields()

    @ID(key: .id)                                                   var id: UUID?
    @Field(fields.domain)                                           var domain: String
    @Field(fields.port)                                             var port: Int
    @Timestamp(fields.createdAt, on: .create)                       var createdAt: Date!
    @Timestamp(fields.updateAt, on: .update)                        var updateAt: Date!

    init() {}

    struct MIG: PGMigration, Sendable { typealias DataModel = Domain }
}
