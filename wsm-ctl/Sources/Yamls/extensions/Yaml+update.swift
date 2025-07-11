import Foundation

extension Yaml.MODULE {
    func update(env: Env, filePath: String, depends: Depends) throws {
        for pgService in self.pgsql {
            try pgService.update(module: name, env: env, filePath: filePath, depends: depends)
        }
        for bundle in self.serviceBundles {
            try bundle.update(
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
    func update(module: String, env: Env, filePath: String, depends: Depends) throws {
        fireAndForget {
            try PgService.Action.start(module: module, port: port, env: env, depends: depends)
        }
    }
}

extension Yaml.SERVICE_BUNDLE {
    func update(
        module: String,
        inline: Yaml.INLINE,
        pgSqls: [Yaml.PGSQL],
        relativeDomain: String?,
        env: Env,
        filePath: String,
        depends: Depends
    ) throws {
        
        print("正在删除旧的模块配置...".info)
        
        fireAndForget {
            try WebService.Action.stop(module: module, name: name, env: env, depends: depends)
        }
        fireAndForget {
            try WebService.Action.delete(module: module, name: name, env: env, depends: depends)
        }
        
        print("正在创建新的模块配置...".info)
        
        var serParas: [WebService.C.Paras] = []
        serParas.append(.init(
            domain: nil,
            serviceType: .inline,
            hostname: "localhost",
            port: inline.port,
            dbServices: try getDbs(for: inline.pgDatabasePorts, service: .inline)
        ))
        
        if let apiService = api {
            serParas.append(.init(
                domain: (relativeDomain != nil && apiService.domain != nil) ? "\(apiService.domain!).\(relativeDomain!).\(env.rootDomain)" : nil,
                serviceType: .api,
                hostname: apiService.hostname,
                port: apiService.port,
                dbServices: try getDbs(for: apiService.pgDatabasePorts, service: .api)
            ))
        }
        if let httpsService = https {
            serParas.append(.init(
                domain: (relativeDomain != nil && httpsService.domain != nil) ? "\(httpsService.domain!).\(relativeDomain!).\(env.rootDomain)" : nil,
                serviceType: .https,
                hostname: httpsService.hostname,
                port: httpsService.port,
                dbServices: try getDbs(for: httpsService.pgDatabasePorts, service: .https)
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
        let baseURL = URL(fileURLWithPath: base).deletingLastPathComponent()
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

fileprivate func fireAndForget(action: () throws -> ()) {
    do {
        try action()
    } catch {
        print("\(error)".info)
    }
}
