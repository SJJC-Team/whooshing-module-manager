import Foundation

extension Yaml.MODULE {
    func stop(env: Env, filePath: String, depends: Depends) {
        for bundle in self.serviceBundles {
            bundle.stop(module: name, env: env, filePath: filePath, depends: depends)
        }
        for pgService in self.pgsql {
            pgService.stop(module: name, env: env, filePath: filePath, depends: depends)
        }
    }
}

extension Yaml.PGSQL {
    func stop(module: String, env: Env, filePath: String, depends: Depends) {
        fireAndForget {
            try PgService.Action.stop(module: module, port: port, env: env, depends: depends)
        }
    }
}

extension Yaml.SERVICE_BUNDLE {
    func stop(module: String, env: Env, filePath: String, depends: Depends) {
        fireAndForget {
            try WebService.Action.stop(module: module, name: name, env: env, depends: depends)
        }
    }
}

fileprivate func fireAndForget(action: () throws -> ()) {
    do {
        try action()
    } catch {
        print("\(error)".info)
    }
}
