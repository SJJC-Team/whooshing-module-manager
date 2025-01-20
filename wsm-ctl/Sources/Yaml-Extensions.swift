extension Yaml.MODULE {
    func create(env: Env, depends: Depends) throws { 
        try Module.Action.create(name: name, env: env, depends: depends)
        try self.pgsql.forEach { try $0.create(module: name, env: env, depends: depends) }
        try self.api.forEach { try $0.create(module: name, env: env, depends: depends) }
        try self.inline.forEach { try $0.create(module: name, env: env, depends: depends) }
        try self.https.forEach { try $0.create(module: name, env: env, depends: depends) }
    }
}

extension Yaml.PGSQL {
    func create(module: String, env: Env, depends: Depends) throws {
        try PgService.Action.create(module: module, port: port, env: env, depends: depends)
        try PgDatabase.Action.create(module: module, port: port, database: database, env: env, depends: depends)
    }
}

extension Yaml.API {
    func create(module: String, env: Env, depends: Depends) throws {
        try Service<Api>.Action.create(module: module, port: port, bundle: bundle, dbPorts: pgDatabasePorts, env: env, depends: depends)
    }
}

extension Yaml.INLINE {
    func create(module: String, env: Env, depends: Depends) throws {
        try Service<Inline>.Action.create(module: module, port: port, bundle: bundle, dbPorts: pgDatabasePorts, env: env, depends: depends)
    }
}

extension Yaml.HTTPS {
    func create(module: String, env: Env, depends: Depends) throws {
        try Service<Https>.Action.create(module: module, port: port, bundle: bundle, dbPorts: pgDatabasePorts, env: env, depends: depends)
    }
}