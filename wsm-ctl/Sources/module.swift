import ArgumentParser
import Foundation

struct Module: LCDS {
    
    static let name = "module"
    
    static func begin() throws {
        
    }
    
    struct L: List {
        typealias Super = Module
    }
    
    struct C: Create {
        typealias Super = Module
        
        @Argument var name: String
        
        func cmd() throws {
            print("Hello")
        }
    }
    
    struct D: Delete {
        typealias Super = Module
    }
    
    struct S: Stop {
        typealias Super = Module
    }
    
    
}
