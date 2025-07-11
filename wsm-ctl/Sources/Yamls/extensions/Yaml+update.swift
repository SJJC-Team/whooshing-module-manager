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
        
        try self.create(
            module: module,
            inline: inline,
            pgSqls: pgSqls,
            relativeDomain: relativeDomain,
            env: env,
            filePath: filePath,
            depends: depends
        )
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
