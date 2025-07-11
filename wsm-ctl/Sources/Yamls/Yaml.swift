struct Yaml {
    typealias Top = MODULE
    let tops: [Top]
    
    static func parse(data: [String: [String: Any]], filePath: String) throws -> Self {
        .init(try data.map { try Top.parse(data: $0.value, name: $0.key, keyPath: "/" + $0.key) })
    }
    
    private init(_ tops: [Top]) { self.tops = tops }
    
    func create(filePath: String, env: Env, depends: Depends) throws {
        for top in tops {
            try top.create(env: env, filePath: filePath, depends: depends)
        }
        print("Yaml 配置创建成功".succ)
    }
    
    func delete(filePath: String, env: Env, depends: Depends) {
        for top in tops {
            top.delete(env: env, filePath: filePath, depends: depends)
        }
        print("Yaml 配置删除完成".succ)
    }
    
    func update(filePath: String, env: Env, depends: Depends) throws {
        for top in tops {
            try top.update(env: env, filePath: filePath, depends: depends)
        }
        print("Yaml 配置更新完成".succ)
    }
    
    func start(filePath: String, env: Env, depends: Depends) {
        for top in tops {
            top.start(env: env, filePath: filePath, depends: depends)
        }
        print("Yaml 配置启动完成".succ)
    }
    
    func stop(filePath: String, env: Env, depends: Depends) {
        for top in tops {
            top.stop(env: env, filePath: filePath, depends: depends)
        }
        print("Yaml 配置停止完成".succ)
    }
    
    func restart(filePath: String, env: Env, depends: Depends) {
        for top in tops {
            top.restart(env: env, filePath: filePath, depends: depends)
        }
        print("Yaml 配置重启完成".succ)
    }
    
}

extension Yaml {
    enum Types {
        case string
        case int
        case stringArr
        case intArr
        case dataTemplate(DataTemplate.Type)
        case dataTemplateList(DataTemplate.Type)
    }

    protocol DataTemplate {
        static var paras: [String: Types] { get }
        static func parse(data: [String: Any], name: String, keyPath: String) throws -> Self
        init(data: [String: Any], name: String)
        init()
    }

    struct MODULE: DataTemplate {
        var name: String = ""
        var domain: String? = nil
        var pgsql: [PGSQL] = []
        var sharedInline: INLINE = .init()
        var serviceBundles: [SERVICE_BUNDLE] = []
        
        static let paras: [String: Types] = [
            "#domain": .string,
            "pgsql": .dataTemplateList(PGSQL.self),
            "shared_inline_module": .dataTemplate(INLINE.self),
            "service_bundles": .dataTemplateList(SERVICE_BUNDLE.self)
        ]
        
        init() {}
        
        init(data: [String: Any], name: String) {
            self.name = name
            self.domain = data["domain"] as? String
            self.pgsql = data["pgsql"] as! [PGSQL]
            self.sharedInline = data["shared_inline_module"] as! INLINE
            self.serviceBundles = data["service_bundles"] as! [SERVICE_BUNDLE]
        }
    }

    struct PGSQL: DataTemplate {
        var name: String = ""
        var databases: [String] = []
        var port: Int = 0
        
        static let paras: [String: Types] = [
            "databases": .stringArr,
            "port": .int
        ]
        
        init() {}
        
        init(data: [String: Any], name: String) {
            self.name = name
            self.databases = data["databases"] as! [String]
            self.port = data["port"] as! Int
        }
    }
    
    struct INLINE: DataTemplate {
        var pgDatabasePorts: [Int] = []
        var port: Int = 0
        
        static let paras: [String: Types] = [
            "pg_database_ports": .intArr,
            "port": .int
        ]
        
        init() {}
        
        init(data: [String : Any], name: String) {
            self.pgDatabasePorts = data["pg_database_ports"] as! [Int]
            self.port = data["port"] as! Int
        }
    }
    
    struct SERVICE_BUNDLE: DataTemplate {
        var name: String = ""
        var api: API? = nil
        var https: HTTPS? = nil
        var path: String = ""
        
        static let paras: [String : Types] = [
            "#api": .dataTemplate(API.self),
            "#https": .dataTemplate(HTTPS.self),
            "path": .string
        
        ]
        init() {}
        
        init(data: [String : Any], name: String) {
            self.name = name
            self.api = data["api"] as? API
            self.https = data["https"] as? HTTPS
            self.path = data["path"] as! String
        }
    }

    struct API: DataTemplate {
        var pgDatabasePorts: [Int] = []
        var port: Int = 0
        var domain: String? = nil
        var hostname: String = "localhost"
        
        static let paras: [String: Types] = [
            "pg_database_ports": .intArr,
            "port": .int,
            "#domain": .string,
            "#hostname": .string
        ]
        
        init() {}
        
        init(data: [String: Any], name: String) {
            self.pgDatabasePorts = data["pg_database_ports"] as! [Int]
            self.port = data["port"] as! Int
            self.domain = data["domain"] as? String
            self.hostname = data["hostname"] as? String ?? "localhost"
        }
    }

    struct HTTPS: DataTemplate {
        var pgDatabasePorts: [Int] = []
        var port: Int = 0
        var domain: String? = nil
        var hostname: String = "localhost"
        
        static let paras: [String: Types] = [
            "pg_database_ports": .intArr,
            "port": .int,
            "#domain": .string,
            "#hostname": .string
        ]
        
        init() {}
        
        init(data: [String: Any], name: String) {
            self.pgDatabasePorts = data["pg_database_ports"] as! [Int]
            self.port = data["port"] as! Int
            self.domain = data["domain"] as? String
            self.hostname = data["hostname"] as? String ?? "localhost"
        }
    }

    enum Err: String, ErrList {
        case typeIncorrect = "Yaml 配置类型不匹配"
        case missingKey = "Yaml 配置字段缺失"
    }
}

extension Yaml.DataTemplate {
    static func parse(data: [String: Any], name: String, keyPath: String) throws -> Self {
        var values = data
        for (envKey, v) in Self.paras {
            let value: Any
            let k: String
            if envKey.hasPrefix("#") {
                k = String(envKey.dropFirst())
                guard let envValue = data[k] else { continue }
                value = envValue
            } else {
                k = envKey
                guard let envValue = data[k] else { throw Yaml.Err.missingKey.d("\(keyPath)/\(k)") }
                value = envValue
            }
            switch v {
                case .string: guard let _ = value as? String else { throw Yaml.Err.typeIncorrect.d("\(keyPath)/\(k), 预期为 String, 得到 \(type(of: value))") }
                case .int: guard let _ = value as? Int else { throw Yaml.Err.typeIncorrect.d("\(keyPath)/\(k), 预期为 Int, 得到 \(type(of: value))") }
                case .stringArr: guard let _ = value as? [String] else { throw Yaml.Err.typeIncorrect.d("\(keyPath)/\(k), 预期为 [String], 得到 \(type(of: value))") }
                case .intArr: guard let _ = value as? [Int] else { throw Yaml.Err.typeIncorrect.d("\(keyPath)/\(k), 预期为 [Int], 得到 \(type(of: value))") }
                case .dataTemplate(let template):
                    guard let d = value as? [String: Any] else { throw Yaml.Err.typeIncorrect.d("\(keyPath)/\(k), 预期为 Dictionary, 得到 \(type(of: value))") }
                    values[k] = try template.parse(data: d, name: "", keyPath: "\(keyPath)/\(k)")
                case .dataTemplateList(let template):
                    guard let d = value as? [String: [String: Any]] else { throw Yaml.Err.typeIncorrect.d("\(keyPath)/\(k), 预期为 Dictionary<Dictionary>, 得到 \(type(of: value))") }
                    values[k] = try d.map { try template.parse(data: $0.value, name: $0.key, keyPath: "\(keyPath)/\(k)/\($0.key)") }
            }
        }
        return Self(data: values, name: name)  
    }
}
