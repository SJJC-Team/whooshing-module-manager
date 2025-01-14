import ArgumentParser

protocol ErrList: Error, CustomStringConvertible {
    var rawValue: String { get }
    func d(_ detail: String) -> String
}

extension String: @retroactive Error {}

extension ErrList { 
    var description: String { (String(reflecting: Self.self) + ":" + self.rawValue).err } 
    func d(_ detail: String) -> String {
        let trimmedDetail = detail.trimmingCharacters(in: .whitespacesAndNewlines)
        return (String(reflecting: Self.self) + ":" + self.rawValue + (trimmedDetail.isEmpty ? "" : "(" + trimmedDetail + ")")).err
    }
}

extension String {
    var err: String { "\u{001B}[31m\(self)\u{001B}[0m" }
    var info: String { "\u{001B}[34m\(self)\u{001B}[0m" }
    var succ: String { "\u{001B}[32m\(self)\u{001B}[0m" }
    var warn: String { "\u{001B}[33m\(self)\u{001B}[0m" }
}

protocol LCDS
where
    Self.L.Super == Self,
    Self.C.Super == Self,
    Self.D.Super == Self,
    Self.S.Super == Self
{
    static var name: String { get }
    static var shortName: String? { get }
    static var paraLabel: String { get }
    static var help: String { get }
    static var subCmds: [ParsableCommand.Type] { get }
    associatedtype L: List
    associatedtype C: Create
    associatedtype D: Delete
    associatedtype S: Stop
    
    static func begin(env: Env) throws
    static func end(env: Env) throws
}

protocol LCDCmd: ParsableCommand {
    associatedtype Super: LCDS
    associatedtype CmdRes = ()
    static var name: String { get }
    static var shortName: String? { get }
    static var help: String { get }
    mutating func cmd(env: Env) throws -> CmdRes
}

extension LCDS {
    static var shortName: String? { String(Self.name.prefix(1)) }
    static var subCmds: [ParsableCommand.Type] { [L.self, C.self, D.self, S.self] }
    static var paraLabel: String { "" }
    static var help: String { "" }
    static func begin(env: Env) throws {}
    static func end(env: Env) throws {}
}

extension LCDCmd {
    static var shortName: String? { String(Self.name.prefix(1)) }
    static var cmdName: String { Self.name + "-" + Super.name }
    static var cmdShortName: String? { (Self.shortName != nil && Super.shortName != nil) ?  Self.shortName! + "-" + Super.shortName! : nil }
    static var help: String { "" }
    static var configuration: CommandConfiguration { Self.cmdShortName != nil ? .init(commandName: Self.cmdShortName!, abstract: Self.help + Super.help, aliases: [Self.cmdName]) : .init(commandName: Self.cmdName, abstract: Self.help + Super.help) }
    
    mutating func run() throws {
        let env = try Env()
        try Self.Super.begin(env: env)
        let _ = try self.cmd(env: env)
        try Self.Super.end(env: env)
    }
}

extension LCDCmd where CmdRes == () {
    func cmd(env: Env) throws {}
}

protocol LCDExpand: LCDCmd {
    associatedtype ParaType = ()
    var paras: [ParaType] { get }
    static var paraLabel: String { get }
    mutating func one(para: ParaType, env: Env) throws -> CmdRes
}

extension LCDExpand { 
    static var paraLabel: String { Self.Super.paraLabel }

    mutating func cmd(env: Env) throws {
        for (i, para) in self.paras.enumerated() { 
            do {
                if self.paras.count > 1 { print("正在处理任务 \(i + 1): \(Self.paraLabel) \(para) ...".info) }
                let _ = try self.one(para: para, env: env)
            } catch let err {
                print(err)
            }
        }
    }

    mutating func one(para: ParaType, env: Env) throws {}
}

protocol List: LCDCmd {}
extension List { static var name: String { "list" }; static var shortName: String? { "li" }; static var help: String { "列出 " } }
protocol Delete: LCDExpand {}
extension Delete { static var name: String { "delete" }; static var shortName: String? { "del" }; static var help: String { "删除 " } }
protocol Stop: LCDExpand {}
extension Stop { static var name: String { "stop" }; static var shortName: String? { "stp" }; static var help: String { "停止 " } }
protocol Create: LCDExpand {}
extension Create { static var name: String { "create" }; static var shortName: String? { "cre" }; static var help: String { "创建 " } }