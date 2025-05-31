import NIOPosix
import NIOCore
import AsyncHTTPClient
import NIOFileSystem

extension FS {
    static func download(from urlString: String, to destinationPath: String, progress: @escaping @Sendable (Int) throws -> ()) throws {
        let semaphore = DispatchSemaphore(value: 0)
        var err: Error?
        Task {
            var fileio: WriteFileHandle? = nil
            let client = HTTPClient()
            do {
                try await Curl.isUriConnectable(urlString)
                
                let response = try await client.execute(HTTPClientRequest(url: urlString), timeout: .minutes(1))
                
                guard response.status == .ok else { throw "下载失败，状态码为 \(response.status)" }
                
                let fh = try await FileSystem.shared.openFile(
                    forWritingAt: FilePath(destinationPath),
                    options: .newFile(replaceExisting: true, permissions: [.groupReadExecute, .ownerReadWriteExecute])
                )
                
                fileio = fh
                
                var i: Int64 = 0
                for try await chunk in response.body {
                    try progress(Int(i))
                    let res = try await fh.write(contentsOf: chunk, toAbsoluteOffset: i)
                    i += res
                }
                
                try await fh.close()
                try await client.shutdown()
            } catch {
                try? await fileio?.close()
                try? await client.shutdown()
                err = error
            }
            
            semaphore.signal()
        }
        semaphore.wait()
        if let e = err { throw e }
    }
}