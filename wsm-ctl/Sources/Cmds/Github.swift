import ArgumentParser
import Foundation
import Yams

struct Github: LCDS {
    
    static let name = "github"
    static let shortName: String? = "git"
    static let paraLabel = "Github 模块配置"
    static let reverseCmd: Bool = true
    static let subCmds: [any ParsableCommand.Type] = [ C.self ]

    struct C: Create {
        typealias Super = Github
        @Argument(help: "Github 存储库 URL 链接") var url: String
        @Argument(help: "服务模块的名称") var name: String
        var paras: [String] { [url] }
        static let help: String = "从 Github 下载模块以配置服务"

        func one(para: String, i: Int, env: Env, depends: Depends) throws -> () {
            let file = try githubDownload(from: para, moduleName: name, env: env)
            try Config.Action.create(file: file, env: env, depends: depends)
        }
    }
    
    struct D: Delete {
        typealias Super = Github
        @Argument(help: "Github 存储库 URL 链接") var url: String
        @Argument(help: "服务模块的名称") var name: String
        var paras: [String] { [url] }
        static let help: String = "从 Github 下载模块以删除服务"
        
        func one(para: String, i: Int, env: Env, depends: Depends) throws -> () {
            let file = try githubDownload(from: para, moduleName: name, env: env)
            try Config.Action.delete(file: file, env: env, depends: depends)
        }
    }
    
    struct S: Stop {
        typealias Super = Github
        @Argument(help: "Github 存储库 URL 链接") var url: String
        @Argument(help: "服务模块的名称") var name: String
        var paras: [String] { [url] }
        static let help: String = "从 Github 下载模块以停止服务"
        
        func one(para: String, i: Int, env: Env, depends: Depends) throws -> () {
            let file = try githubDownload(from: para, moduleName: name, env: env)
            try Config.Action.stop(file: file, env: env, depends: depends)
        }
    }
    
    struct Start: LCDExpand {
        typealias Super = Github
        static var name: String { "start" }
        static let shortName: String? = nil
        
        @Argument(help: "Github 存储库 URL 链接") var url: String
        @Argument(help: "服务模块的名称") var name: String
        var paras: [String] { [url] }
        static let help: String = "从 Github 下载模块以启动服务"
        
        func one(para: String, i: Int, env: Env, depends: Depends) throws -> () {
            let file = try githubDownload(from: para, moduleName: name, env: env)
            try Config.Action.start(file: file, env: env, depends: depends)
        }
    }
    
    struct Restart: LCDExpand {
        typealias Super = Github
        
        static var name: String { "restart" }
        static let shortName: String? = nil
        
        @Argument(help: "Github 存储库 URL 链接") var url: String
        @Argument(help: "服务模块的名称") var name: String
        var paras: [String] { [url] }
        static let help: String = "从 Github 下载模块以重启服务"
        
        func one(para: String, i: Int, env: Env, depends: Depends) throws -> () {
            let file = try githubDownload(from: para, moduleName: name, env: env)
            try Config.Action.restart(file: file, env: env, depends: depends)
        }
    }
    
    struct Update: LCDExpand {
        typealias Super = Github
        
        static var name: String { "update" }
        static let shortName: String? = nil
        
        @Argument(help: "Github 存储库 URL 链接") var url: String
        @Argument(help: "服务模块的名称") var name: String
        var paras: [String] { [url] }
        static let help: String = "从 Github 下载模块以更新服务"
        
        func one(para: String, i: Int, env: Env, depends: Depends) throws -> () {
            let file = try githubDownload(from: para, moduleName: name, env: env)
            try Config.Action.update(file: file, env: env, depends: depends)
        }
    }
    
    struct L: List { typealias Super = Github }
    
    enum Err: String, ErrList {
        case fileNotExist = "Yaml 文件不存在"
        case parseFailed = "Yaml 文件解析失败"
    }
}

extension Github {
    static func githubDownload(from url: String, moduleName: String, env: Env) throws -> String {
        
        let bundleName = try Sh.Github.getModuleName(name: moduleName, env: env)
        let url = "\(url)/releases/latest/download/\(bundleName).tar.gz"
        let githubDir = "\(env.dataDir)/.github/\(bundleName)"
        let tarPath = "\(githubDir)/\(bundleName).tar.gz"
        
        print("正在从 github 下载: \"\(url)\"...".info)
        
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        try FS.download(from: url, to: tarPath) { curSize, totalSize in
            print("\(Float(curSize) / Float(totalSize) * 100)% \(formatter.string(fromByteCount: Int64(curSize))) -> \(formatter.string(fromByteCount: Int64(totalSize)))")
        }
        
        print("下载完成，文件位于: \"\(tarPath)\"...".succ)
        
        print("正在解压 ...")
        
        try Sh.Github.unzip(name: bundleName, des: githubDir, env: env)
        
        print("解压完成".succ)
        
        return "\(githubDir)/module/configure.yaml"
    }
}

extension ByteCountFormatter: @unchecked @retroactive Sendable {}
