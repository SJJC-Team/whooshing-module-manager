import ArgumentParser
import Foundation
import Yams

struct Github: LCDS {
    
    static let name = "github"
    static let shortName: String? = "git"
    static let paraLabel = "Github 模块配置"
    static let reverseCmd: Bool = true
    static let subCmds: [any ParsableCommand.Type] = [ C.self, Update.self ]

    struct C: Create {
        typealias Super = Github
        @Argument(help: "Github 存储库 URL 链接") var url: String
        @Option(name: .shortAndLong, help: "服务模块的名称") var name: String
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
        @Option(name: .shortAndLong, help: "服务模块的名称") var name: String
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
        @Option(name: .shortAndLong, help: "服务模块的名称") var name: String
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
        @Option(name: .shortAndLong, help: "服务模块的名称") var name: String
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
        @Option(name: .shortAndLong, help: "服务模块的名称") var name: String
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
        static let shortName: String? = "up"
        
        @Argument(help: "Github 存储库 URL 链接") var url: String
        @Option(name: .shortAndLong, help: "服务模块的名称") var name: String
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
        
        try? FS.rm(path: githubDir)
        try FS.mkdir(path: githubDir, slience: false, withIntermediates: true)

        print("正在从 github 下载: \"\(url)\"...".info)
        
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        try FS.download(from: url, to: tarPath) { curSize, totalSize in
            let progress = Float(curSize) / Float(totalSize)
            let percentage = Int(progress * 100)

            // 进度条宽度（可以调整）
            let barWidth = 80
            let filledLength = Int(Float(barWidth) * progress)
            let bar = String(repeating: "─", count: filledLength) + String(repeating: " ", count: barWidth - filledLength)

            // 格式化文件大小
            let curStr = formatter.string(fromByteCount: Int64(curSize))
            let totalStr = formatter.string(fromByteCount: Int64(totalSize))

            // \r 会回到行首并覆盖之前的内容
            print(String(format: "\r[%@] %3d%% (%@ / %@)", bar, percentage, curStr, totalStr), terminator: "")

            // 当下载完成后换行
            if curSize == totalSize {
                print()
            }
        }
        
        print("下载完成".succ)
        
        print("正在解压 ...".info)
        
        try Sh.Github.unzip(name: bundleName, des: githubDir, env: env)
        
        let configure = "\(githubDir)/module/configure.yaml"

        print("""

        -------------------------------------------------------
        解压完成, 配置位于: 
        \(configure)
        -------------------------------------------------------

        """.succ)
        
        return configure
    }
}

extension ByteCountFormatter: @unchecked @retroactive Sendable {}
