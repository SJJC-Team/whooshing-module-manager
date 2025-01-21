import Vapor
import Cryptos

struct InitParaReq: Content {
    var pub: Data
}

struct InitParaRes: Content {
    let pub: Crypto.Asym.CPublicKey
    let root: Data
    let modules: [Module.DTO]
}