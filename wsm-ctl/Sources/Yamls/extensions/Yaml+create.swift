import Foundation

extension Yaml.MODULE {
    func create(env: Env, filePath: String, depends: Depends) throws { 
        try Module.Action.create(name: name, env: env, depends: depends)
        for pgService in self.pgsql {
            try pgService.create(module: name, env: env, filePath: filePath, depends: depends)
        }
        for bundle in self.serviceBundles {
            try bundle.create(
                module: name,
                inline: self.sharedInline,
                pgSqls: self.pgsql,
                relativeDomain: self.domain,
                env: env,
                filePath: filePath,
                depends: depends
            )
        }
    }
}

extension Yaml.PGSQL {
    func create(module: String, env: Env, filePath: String, depends: Depends) throws {
        try PgService.Action.create(module: module, port: port, env: env, depends: depends)
        for db in self.databases {
            try PgDatabase.Action.create(module: module, port: port, database: db, env: env, depends: depends)
        }
    }
}

extension Yaml.SERVICE_BUNDLE {
    func create(
        module: String,
        inline: Yaml.INLINE,
        pgSqls: [Yaml.PGSQL],
        relativeDomain: String?,
        env: Env,
        filePath: String,
        depends: Depends
    ) throws {
        var serParas: [WebService.C.Paras] = []
        serParas.append(.init(
            domain: nil,
            serviceType: .inline,
            hostname: "localhost",
            port: inline.port,
            dbServices: try getDbs(for: inline.pgPorts, service: .inline)
        ))
        
        if let apiService = api {
            serParas.append(.init(
                domain: (relativeDomain != nil && apiService.domain != nil) ? "\(apiService.domain!).\(relativeDomain!).\(env.rootDomain)" : nil,
                serviceType: .api,
                hostname: apiService.hostname,
                port: apiService.port,
                dbServices: try getDbs(for: apiService.pgPorts, service: .api)
            ))
        }
        if let httpsService = https {
            serParas.append(.init(
                domain: (relativeDomain != nil && httpsService.domain != nil) ? "\(httpsService.domain!).\(relativeDomain!).\(env.rootDomain)" : nil,
                serviceType: .https,
                hostname: httpsService.hostname,
                port: httpsService.port,
                dbServices: try getDbs(for: httpsService.pgPorts, service: .https)
            ))
        }
        try WebService.Action.create(module: module, name: name, serviceParas: serParas, bundle: resolvePath(basePath: filePath, append: path), env: env, depends: depends)

        func getDbs(for ports: [Int], service: WebService.ServiceType) throws -> [WebService.C.Paras.DBService] {
            var res: [WebService.C.Paras.DBService] = []
            for p in ports {
                guard let names = (pgSqls.first { $0.port == p }?.databases) else { throw "数据库端口\(p)未找到对应的数据库名称" }
                res.append(.init(name: "\(service.rawValue.lowercased())_\(p)", port: p, dbs: names))
            }
            return res
        }
    }

    /// 拼接路径的实用函数
    private func resolvePath(basePath: String, append pathToAppend: String) -> String {
        let base = (basePath as NSString).expandingTildeInPath
        let baseURL = URL(fileURLWithPath: base)
        let appended = (pathToAppend as NSString).expandingTildeInPath
        let finalURL: URL
        if appended.hasPrefix("/") {
            finalURL = URL(fileURLWithPath: appended)
        } else {
            finalURL = baseURL.appendingPathComponent(appended)
        }
        return finalURL.standardized.path
    }
}
