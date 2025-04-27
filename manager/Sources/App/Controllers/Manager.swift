import Vapor
import Fluent
import Whooshing
import Cryptos

struct Manager: RouteCollection {

    // 服务根密钥
    static let root = Crypto.Symm.makeKey()

    func boot(routes: RoutesBuilder) throws {
        let cryptoRoute = routes.grouped("params")
        cryptoRoute.post("init", use: getInit)
    }

    @Sendable func getInit(req: Request) async throws -> InitParaRes {
        // 解析请求中对方发来的的公钥
        let pubKey = try req.content.decode(Crypto.Asym.CPublicKey.self)
        // 生成一对密钥对，作为自己的公私密钥对以与对方进行密钥协商
        let keyPair = Crypto.Asym.makeCryptoKeyPair()
        // 使用对方的公钥和自己的私钥生成共享密钥
        let sharedKey = try Crypto.Asym.keyEncapsulate(key: keyPair.private, partyPublic: pubKey, salt: Crypto.hash("manager.shared.key"), info: "")
        // 查询数据库中的模块信息
        let modules = try await Module.query(on: req.db).all()
        let ms = try modules.map { try $0.dto(req: req) }
        // 使用共享密钥对服务根密钥进行加密
        let cipherRoot = try Crypto.Symm.encrypt(Self.root, key: sharedKey)
        // 使用共享密钥对服务模块密钥进行加密
        let cipherModules = try ms.map { try Crypto.Symm.encrypt($0, key: sharedKey) }
        // 返回明文的自己的公钥，以及加密后的服务根密钥和服务模块密钥
        return InitParaRes(pub: keyPair.public, root: cipherRoot, modules: cipherModules)
    }
}