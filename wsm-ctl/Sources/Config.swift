import ArgumentParser
import Foundation
import Yams

struct Config: LCDS {
    
    static let name = "config"
    static let shortName: String? = nil
    static let paraLabel = "模块"
    static let reverseCmd = true
    static let subCmds: [any ParsableCommand.Type] = [C.self]

    static var structure: Any {[
        [
            "#domain": "String",
            "pgsql": [ 
                [
                    "database": "String", 
                    "port": "Int"
                ] 
            ],
            "api": [
                [
                    "port": "Int",
                    "pgdatabases": "[String]",
                    "#domain": "String"
                ]
            ],
            "inline": [
                [
                    "port": "Int",
                    "pgdatabases": "[String]"
                ]
            ],
            "https": [
                [
                    "port": "Int",
                    "pgdatabases": "[String]",
                    "#domain": "String"
                ]
            ]
        ]
    ]}
    
    static func validate(_ data: Any, t: Any, keyPath: String = "") throws {
        if let t3 = t as? String {
            let err = Err.typeIncorrect.d("\(keyPath)(预期为 \(t3), 得到 \(type(of: data)))")
            switch t3 {
                case "String": guard let _ = data as? String else { throw err }
                case "Int": guard let _ = data as? Int else { throw err }
                case "[String]": guard let _ = data as? [String] else { throw err }
                case "[Int]": guard let _ = data as? [Int] else { throw err }
                default: throw err
            }
        } else if let t1 = t as? [Any] {
            guard let d1 = data as? [String: Any] else { throw Err.typeIncorrect.d("\(keyPath)(预期为 Dictionary, 得到 \(type(of: data)))") }
            for (k, v) in d1 {
                let keyP = keyPath + "/" + k
                try validate(v, t: t1[0], keyPath: keyP)
            }
        } else if let t2 = t as? [String: Any] {
            guard let d2 = data as? [String: Any] else { throw Err.typeIncorrect.d("\(keyPath)(预期为 Dictionary, 得到 \(type(of: data)))") }
            for (k, v) in t2 {
                if k.hasPrefix("#") { continue }
                let keyP = keyPath + "/" + k
                guard let value = d2[k] else { throw Err.missingKey.d(keyP) }
                try validate(value, t: v, keyPath: keyP)
            }
        }
    }

    struct C: Create {
        typealias Super = Config
        @Argument(help: "Yaml 配置文件") var file: String
        var paras: [String] { [file] }
        static let help: String = "提供 .yaml 文件配置服务"

        func one(para: String, env: Env) throws -> () {
            try paraAvailable(file: file, env: env)
            // var keyPath = ""
            guard let res = try Yams.load(yaml: try String(contentsOfFile: file, encoding: .utf8)) else { throw Err.parseFailed.d(file) }

            try Super.validate(res, t: Super.structure)

            // for (moduleName, moduleConfig) in res {

            //     keyPath += moduleName
            //     // todo: create module
            //     print("Create " + moduleName)

            //     guard let moduleConfig = moduleConfig as? [String: Any] else { throw Err.typeIncorrect.d(keyPath) }
            //     try parse(content: moduleConfig, keys: [
            //         "domain": String.self,
            //         "pgsql": [String: Any].self,
            //         "api": [String: Any].self,
            //         "inline": [String: Any].self,
            //         "https": [String: Any].self
            //     ], keyPath: String)
            // }
        }
    }

    static func parse(content: [String: Any], keys: [String: Any.Type], keyPath: String) throws -> [String: Any] {
        var res: [String: Any] = [:]
        for (k, t) in keys {
            if type(of: content[k]) == t { res[k] = content[k] }
            else { throw Err.typeIncorrect.d("\(keyPath)/\(k)") }
        }
        return res
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
        case typeIncorrect = "Yaml 配置类型不匹配"
        case missingKey = "Yaml 配置字段缺失"
    }   
}
