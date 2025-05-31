import Foundation

extension Yaml.MODULE {
    func start(env: Env, filePath: String, depends: Depends) {
        for bundle in self.serviceBundles {
            bundle.start(module: name, env: env, filePath: filePath, depends: depends)
        }
        for pgService in self.pgsql {
            pgService.start(module: name, env: env, filePath: filePath, depends: depends)
        }
    }
}

extension Yaml.PGSQL {
    func start(module: String, env: Env, filePath: String, depends: Depends) {
        fireAndForget {
            try PgService.Action.start(module: module, port: port, env: env, depends: depends)
        }
    }
}

extension Yaml.SERVICE_BUNDLE {
    func start(module: String, env: Env, filePath: String, depends: Depends) {
        fireAndForget {
            try WebService.Action.start(module: module, name: name, env: env, depends: depends)
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
