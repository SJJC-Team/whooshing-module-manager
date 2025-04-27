extension Yaml.MODULE {
    func create(env: Env, depends: Depends) throws { 
        try Module.Action.create(name: name, env: env, depends: depends)
        try self.pgsql.forEach { try $0.create(module: name, env: env, depends: depends) }
        try self.serviceBundles.forEach { try $0.create(module: name, inline: self.sharedInline, pgSqls: self.pgsql, env: env, depends: depends) }
    }
}

extension Yaml.PGSQL {
    func create(module: String, env: Env, depends: Depends) throws {
        try PgService.Action.create(module: module, port: port, env: env, depends: depends)
        try PgDatabase.Action.create(module: module, port: port, database: database, env: env, depends: depends)
    }
}

extension Yaml.SERVICE_BUNDLE {
    func create(module: String, inline: Yaml.INLINE, pgSqls: [Yaml.PGSQL], env: Env, depends: Depends) throws {
        var serParas: [WebService.C.Paras] = []
        serParas.append(WebService.C.Paras(serviceType: .inline, port: inline.port, dbPorts: inline.pgDatabasePorts, dbNames: try getDbNames(for: inline.pgDatabasePorts)))
        if let apiSer = api { serParas.append(WebService.C.Paras(serviceType: .api, port: apiSer.port, dbPorts: apiSer.pgDatabasePorts, dbNames: try getDbNames(for: apiSer.pgDatabasePorts))) }
        if let httpsSer = https { serParas.append(WebService.C.Paras(serviceType: .https, port: httpsSer.port, dbPorts: httpsSer.pgDatabasePorts, dbNames: try getDbNames(for: httpsSer.pgDatabasePorts))) }
        try WebService.Action.create(module: module, name: name, serviceParas: serParas, bundle: path, env: env, depends: depends)

        func getDbNames(for ports: [Int]) throws -> [String] {
            var res: [String] = []
            for p in ports {
                guard let name = (pgSqls.first { $0.port == p }?.database) else { throw "数据库端口\(p)未找到对应的数据库名称" }
                res.append(name)
            }
            return res
        }
    }
}
