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
        serParas.append(WebService.C.Paras(domain: nil, serviceType: .inline, port: inline.port, dbPorts: inline.pgDatabasePorts, dbNames: try getDbNames(for: inline.pgDatabasePorts)))
        if let apiSer = api {
            serParas.append(
                WebService.C.Paras(
                    domain: (relativeDomain != nil && apiSer.domain != nil) ? "\(apiSer.domain!).\(relativeDomain!).\(env.rootDomain)" : nil,
                    serviceType: .api,
                    port: apiSer.port,
                    dbPorts: apiSer.pgDatabasePorts,
                    dbNames: try getDbNames(for: apiSer.pgDatabasePorts)
                )
            )
        }
        if let httpsSer = https {
            serParas.append(
                WebService.C.Paras(
                    domain: (relativeDomain != nil && httpsSer.domain != nil) ? "\(httpsSer.domain!).\(relativeDomain!).\(env.rootDomain)" : nil,
                    serviceType: .https,
                    port: httpsSer.port,
                    dbPorts: httpsSer.pgDatabasePorts,
                    dbNames: try getDbNames(for: httpsSer.pgDatabasePorts)
                )
            )
        }
        try WebService.Action.create(module: module, name: name, serviceParas: serParas, bundle: resolvePath(basePath: filePath, append: path), env: env, depends: depends)

        func getDbNames(for ports: [Int]) throws -> [String] {
            var res: [String] = []
            for p in ports {
                guard let name = (pgSqls.first { $0.port == p }?.database) else { throw "数据库端口\(p)未找到对应的数据库名称" }
                res.append(name)
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
