import PgSQL
import Foundation
import Vapor

enum DBModel {
    
    final class Module: PGModel, @unchecked Sendable  {
        static let name: String = "modules"

        struct Fields: PGFields {
            let id = PGField("id", .uuid)
            let name = PGField("name", .string).cons([.required])
            let serviceId = PGField("service_id", .uuid).cons([.required])
            let connection = PGField("connection", .string).cons([.required])
            let startPort = PGField("start_port", .int).cons([.required])
            let portSpace = PGField("port_space", .int).def(20).cons([.required])
            let createdAt = PGField("create_at", .string, true)
            let updateAt = PGField("update_at", .string)
        }

        static let fields = Fields()

        @ID(key: .id)                                                   var id: UUID?
        @Field(fields.name)                                             var name: String
        @Field(fields.serviceId)                                        var serviceId: UUID
        @Field(fields.connection)                                       var connection: String
        @Field(fields.startPort)                                        var startPort: Int
        @Field(fields.portSpace)                                        var portSpace: Int
        @Timestamp(fields.createdAt, on: .create)                       var createdAt: Date?
        @Timestamp(fields.updateAt, on: .update)                        var updateAt: Date?

        struct DTO: Content, Sendable {}

        @Sendable func dto(req: Request) throws -> DTO { DTO() }

        struct MIG: PGMigration, Sendable { typealias DataModel = Module }
    }

}