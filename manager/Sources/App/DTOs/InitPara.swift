import Vapor
import Cryptos

struct InitParaRes: Content {
    let pub: Crypto.Asym.CPublicKey
    let root: Data
    let modules: [Data]
}