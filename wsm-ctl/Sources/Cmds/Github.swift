import ArgumentParser
import Foundation
import Yams

struct Config: LCDS {
    
    static let name = ""
    static let shortName: String? = ""
    static let paraLabel = "模块"
    static let subCmds: [any ParsableCommand.Type] = [
        C.self,
        D.self,
        S.self,
        Start.self,
        Restart.self,
        Update.self
    ]

    struct C: Create {
        typealias Super = Config
        @Argument(help: "Github 存储库 URL 链接") var url: String
        var paras: [String] { [file] }
        static let help: String = "提供 .yaml 文件以配置服务"

        func one(para: String, i: Int, env: Env, depends: Depends) throws -> () {
            let yaml = try parseYamlFileFrom(url: para, env: env)
            try yaml.create(filePath: file, env: env, depends: depends)
        }
    }
    
    struct D: Delete {
        typealias Super = Config
        @Argument(help: "Github 存储库 URL 链接") var url: String
        var paras: [String] { [file] }
        static let help: String = "提供 .yaml 文件以删除服务"
        
        func one(para: String, i: Int, env: Env, depends: Depends) throws -> () {
            let yaml = try parseYamlFileFrom(url: para, env: env)
            yaml.delete(filePath: file, env: env, depends: depends)
        }
    }
    
    struct S: Stop {
        typealias Super = Config
        @Argument(help: "Github 存储库 URL 链接") var url: String
        var paras: [String] { [file] }
        static let help: String = "提供 .yaml 文件以停止服务"
        
        func one(para: String, i: Int, env: Env, depends: Depends) throws -> () {
            let yaml = try parseYamlFileFrom(url: para, env: env)
            yaml.stop(filePath: file, env: env, depends: depends)
        }
    }
    
    struct Start: LCDExpand {
        typealias Super = Config
        static var name: String { "start" }
        static let shortName: String? = nil
        
        @Argument(help: "Github 存储库 URL 链接") var url: String
        var paras: [String] { [file] }
        static let help: String = "提供 .yaml 文件以启动服务"
        
        func one(para: String, i: Int, env: Env, depends: Depends) throws -> () {
            let yaml = try parseYamlFileFrom(url: para, env: env)
            yaml.start(filePath: file, env: env, depends: depends)
        }
    }
    
    struct Restart: LCDExpand {
        typealias Super = Config
        
        static var name: String { "restart" }
        static let shortName: String? = nil
        
        @Argument(help: "Github 存储库 URL 链接") var url: String
        var paras: [String] { [file] }
        static let help: String = "提供 .yaml 文件以重启服务"
        
        func one(para: String, i: Int, env: Env, depends: Depends) throws -> () {
            let yaml = try parseYamlFileFrom(url: para, env: env)
            yaml.restart(filePath: file, env: env, depends: depends)
        }
    }
    
    struct Update: LCDExpand {
        typealias Super = Config
        
        static var name: String { "update" }
        static let shortName: String? = nil
        
        @Argument(help: "Github 存储库 URL 链接") var url: String
        var paras: [String] { [file] }
        static let help: String = "提供 .yaml 文件以更新服务"
        
        func one(para: String, i: Int, env: Env, depends: Depends) throws -> () {
            let yaml = try parseYamlFileFrom(url: para, env: env)
            try yaml.update(filePath: file, env: env, depends: depends)
        }
    }
    
    struct L: List { typealias Super = Config }
    
    enum Err: String, ErrList {
        case fileNotExist = "Yaml 文件不存在"
        case parseFailed = "Yaml 文件解析失败"
    }
}

extension Config {
    static func parseYamlFileFrom(url: String, env: Env) throws -> Yaml {
        try paraAvailable(file: file, env: env)
        guard let data = try Yams.load(yaml: try String(contentsOfFile: file, encoding: .utf8)) else { throw Err.parseFailed.d(file) }
        guard let d = data as? [String: [String: Any]] else { throw Err.parseFailed.d(file) }
        return try Yaml.parse(data: d, filePath: file)
    }
}
