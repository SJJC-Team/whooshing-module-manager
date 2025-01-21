import Vapor
import Fluent
import Whooshing
import Cryptos

struct Manager: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let cryptoRoute = routes.grouped("params")
        cryptoRoute.post("init", use: getInit)
    }

    @Sendable func getInit(req: Request) async throws -> InitParaRes {
        let pub = try req.content.decode(InitParaReq.self).pub
        let pubKey = try Crypto.Asym.CPublicKey(rawRepresentation: pub)
        let keyPair = Crypto.Asym.makeCryptoKeyPair()
        let sharedKey = try Crypto.Asym.keyEncapsulate(key: keyPair.private, partyPublic: pubKey, salt: Crypto.hash("manager.shared.key"), info: "")
        let modules = try await Module.query(on: req.db).all()
        let ms = try modules.map { try $0.dto(req: req) }
        let cipherRoot = try Crypto.Symm.encrypt(Whooshing.root, key: sharedKey)
        return InitParaRes(pub: keyPair.public, root: cipherRoot, modules: ms)
    }
}