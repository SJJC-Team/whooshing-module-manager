import ArgumentParser
import Foundation
import Yams

struct Config: LCDS {
    
    static let name = "config"
    static let shortName: String? = nil
    static let paraLabel = "模块"
    static let reverseCmd = true
    static let subCmds: [any ParsableCommand.Type] = [C.self]

    struct C: Create {
        typealias Super = Config
        @Argument(help: "Yaml 配置文件") var file: String
        var paras: [String] { [file] }
        static let help: String = "提供 .yaml 文件配置服务"

        func one(para: String, env: Env, i: Int) throws -> () {
            try paraAvailable(file: file, env: env)
            guard let data = try Yams.load(yaml: try String(contentsOfFile: file, encoding: .utf8)) else { throw Err.parseFailed.d(file) }
            let res = try Yaml.parse(data: data, filePath: file)
            try res.create()
        }
    }

    static func paraAvailable(file: String, env: Env) throws {
        guard FS.isExist(path: file, dir: false) else { throw Err.fileNotExist.d(file) }
    }
    
    struct L: List { typealias Super = Config }
    struct D: Delete { typealias Super = Config; var paras: [()] { [] } }
    struct S: Stop { typealias Super = Config; var paras: [()] { [] } }
    
    enum Err: String, ErrList {
        case fileNotExist = "Yaml 文件不存在"
        case parseFailed = "Yaml 文件解析失败"
    }   
}
