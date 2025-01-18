extension Yaml.MODULE {
    func create(env: Env, depends: Depends) throws { 
        try Module.Action.create(name: name, env: env, depends: depends)
        try self.pgsql.forEach { try $0.create(module: name, env: env) }
        try self.api.forEach { try $0.create(module: name, env: env) }
        try self.inline.forEach { try $0.create(module: name, env: env) }
        try self.https.forEach { try $0.create(module: name, env: env) }
    }
}

extension Yaml.PGSQL {
    func create(module: String, env: Env) throws {
        try PgService.Action.create(module: module, port: port, env: env)
        try PgDatabase.Action.create(module: module, port: port, database: database, env: env)
    }
}

extension Yaml.API {
    func create(module: String, env: Env) throws {
        
    }
}

extension Yaml.INLINE {
    func create(module: String, env: Env) throws {
        
    }
}

extension Yaml.HTTPS {
    func create(module: String, env: Env) throws {
        
    }
}