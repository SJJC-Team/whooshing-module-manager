import ArgumentParser

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
    
    static func begin() throws
    static func end() throws
}

protocol LCDCmd: ParsableCommand {
    associatedtype Super: LCDS
    static var name: String { get }
    mutating func cmd(env: Env) throws
}

extension LCDS {
    static var subCmds: [ParsableCommand.Type] { [L.self, C.self, D.self, S.self] }
    static func begin() throws {}
    static func end() throws {}
}

extension LCDCmd {
    static var cmdName: String { Super.name + "-" + Self.name }
    static var configuration: CommandConfiguration { .init(commandName: Self.cmdName) }
    
    mutating func run() throws {
        try Self.Super.begin()
        try self.cmd(env: WSM.getEnv())
        try Self.Super.end()
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
