import Foundation

extension Yaml.MODULE {
    func restart(env: Env, filePath: String, depends: Depends) {
        for bundle in self.serviceBundles {
            bundle.restart(module: name, env: env, filePath: filePath, depends: depends)
        }
        for pgService in self.pgsql {
            pgService.restart(module: name, env: env, filePath: filePath, depends: depends)
        }
    }
}

extension Yaml.PGSQL {
    func restart(module: String, env: Env, filePath: String, depends: Depends) {
        fireAndForget {
            try PgService.Action.restart(module: module, port: port, env: env, depends: depends)
        }
    }
}

extension Yaml.SERVICE_BUNDLE {
    func restart(module: String, env: Env, filePath: String, depends: Depends) {
        fireAndForget {
            try WebService.Action.restart(module: module, name: name, env: env, depends: depends)
        }
    }
}

fileprivate func fireAndForget(action: () throws -> ()) {
    do {
        try action()
    } catch {
        print("\(error)".err)
    }
}
