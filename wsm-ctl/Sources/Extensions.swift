import ArgumentParser

protocol ErrList: Error, CustomStringConvertible {
    var rawValue: String { get }
    func d(_ detail: String) -> String
}

extension String: @retroactive Error {}

extension ErrList { 
    var description: String { (String(reflecting: Self.self) + ":" + self.rawValue).err } 
    func d(_ detail: String) -> String { (String(reflecting: Self.self) + ":" + self.rawValue + "(" + detail).err + ")" }
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
    static var name: String { get }
    mutating func cmd(env: Env) throws
}

extension LCDS {
    static var subCmds: [ParsableCommand.Type] { [L.self, C.self, D.self, S.self] }
    static func begin(env: Env) throws {}
    static func end(env: Env) throws {}
}

extension LCDCmd {
    static var cmdName: String { Self.name + "-" + Super.name }
    static var configuration: CommandConfiguration { .init(commandName: Self.cmdName) }
    
    mutating func run() throws {
        let env = try Env()
        try Self.Super.begin(env: env)
        try self.cmd(env: env)
        try Self.Super.end(env: env)
    }
    
    mutating func cmd(env: Env) throws {}
}

protocol List: LCDCmd {}
extension List { static var name: String { "list" } }
protocol Create: LCDCmd {}
extension Create { static var name: String { "create" } }
protocol Delete: LCDCmd {}
extension Delete { static var name: String { "delete" } }
protocol Stop: LCDCmd {}
extension Stop { static var name: String { "stop" } }
