import Foundation

extension Yaml.MODULE {
    func delete(env: Env, filePath: String, depends: Depends) {
        for bundle in self.serviceBundles {
            bundle.delete(module: name, env: env, filePath: filePath, depends: depends)
        }
        for pgService in self.pgsql {
            pgService.delete(module: name, env: env, filePath: filePath, depends: depends)
        }
        fireAndForget {
            try Module.Action.delete(name: name, env: env, depends: depends)
        }
    }
}

extension Yaml.PGSQL {
    func delete(module: String, env: Env, filePath: String, depends: Depends) {
        fireAndForget {
            try PgService.Action.stop(module: module, port: port, env: env, depends: depends)
        }
        fireAndForget {
            try PgService.Action.delete(module: module, port: port, env: env, depends: depends)
        }
    }
}

extension Yaml.SERVICE_BUNDLE {
    func delete(module: String, env: Env, filePath: String, depends: Depends) {
        fireAndForget {
            try WebService.Action.stop(module: module, name: name, env: env, depends: depends)
        }
        fireAndForget {
            try WebService.Action.delete(module: module, name: name, env: env, depends: depends)
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
