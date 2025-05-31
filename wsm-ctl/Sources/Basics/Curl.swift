import Foundation
import NIOHTTP1

#if os(Linux)
import FoundationNetworking
#endif

public struct Curl {
    
    #if !canImport(Darwin) || os(macOS)
    
    /// 判断 uri 是否可被正确连接
    /// 该函数会发起一个真实的 curl 请求以测试网络连接
    /// 若可以连接，则返回对方发来的状态码
    /// 若无法连接，则返回 curl 错误，见 ``Curl.Err``
    ///
    /// Unix 命令行仅在 linux 或 macOS 受支持
    @discardableResult
    static func isUriConnectable(_ uri: String) async throws -> HTTPResponseStatus {
        let task = Process()
        let pipe = Pipe()
        task.executableURL = URL(fileURLWithPath: "/bin/bash")
        task.arguments = ["-c", "curl --silent --output /dev/null --write-out '%{http_code}' \"\(uri)\" 2>&1 || exit $?"]
        task.standardOutput = pipe
        task.standardError = pipe
        do { try task.run() } catch { throw Curl.Err.unknow }
        task.waitUntilExit()
        guard task.terminationStatus == 0 else {
            let code = Int(task.terminationStatus)
            if let err = Curl.Err(rawValue: code) {
                throw err
            } else {
                throw Curl.Err.nonErrorCode
            }
        }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard
            let codeStr = String(data: data, encoding: .utf8),
            let code = Int(codeStr)
        else {
            return .custom(code: 10000, reasonPhrase: "非正常 http 响应")
        }
        return HTTPResponseStatus(statusCode: code)
    }
    
    #else
    
    /// 判断 uri 是否可被正确连接
    /// 该函数会发起一个真实的 curl 请求以测试网络连接
    /// 若可以连接，则返回对方发来的状态码
    /// 若无法连接，则返回 URLError 错误，见 ``URLError``
    ///
    /// IOS 支持
    @discardableResult
    static func isUriConnectable(_ uri: String) async throws -> HTTPResponseStatus {
        guard let url = URL(string: uri) else { throw URLError(.badURL) }
        let req = URLRequest(url: url)
        guard let res = try await URLSession.shared.data(for: req).1 as? HTTPURLResponse else {
            throw URLError(.unknown)
        }
        return .init(statusCode: res.statusCode)
    }
    
    #endif
}

public extension Curl {
    enum Err: Int, Error {
        case ok = 0
        case unsupportedProtocol = 1
        case failedInit = 2
        case urlMalformat = 3
        case notBuiltIn = 4
        case couldntResolveProxy = 5
        case couldntResolveHost = 6
        case couldntConnect = 7
        case ftpWeirdServerReply = 8
        case remoteAccessDenied = 9
        case ftpAcceptFailed = 10
        case ftpWeirdPassReply = 11
        case ftpAcceptTimeout = 12
        case ftpWeirdPasvReply = 13
        case ftpWeird227Format = 14
        case ftpCantGetHost = 15
        case http2 = 16
        case ftpCouldntSetType = 17
        case partialFile = 18
        case ftpCouldntRetrFile = 19
        case quoteError = 21
        case httpReturnedError = 22
        case writeError = 23
        case uploadFailed = 25
        case readError = 26
        case outOfMemory = 27
        case operationTimedOut = 28
        case ftpPortFailed = 30
        case ftpCouldntUseRest = 31
        case rangeError = 33
        case httpPostError = 34
        case sslConnectError = 35
        case badDownloadResume = 36
        case fileCouldntReadFile = 37
        case ldapCannotBind = 38
        case ldapSearchFailed = 39
        case functionNotFound = 41
        case abortedByCallback = 42
        case badFunctionArgument = 43
        case interfaceFailed = 45
        case tooManyRedirects = 47
        case unknownOption = 48
        case telnetOptionSyntax = 49
        case peerFailedVerification = 51
        case gotNothing = 52
        case sslEngineNotFound = 53
        case sslEngineSetFailed = 54
        case sendError = 55
        case recvError = 56
        case sslCertProblem = 58
        case sslCipher = 59
        case sslCACert = 60
        case badContentEncoding = 61
        case ldapInvalidURL = 62
        case fileSizeExceeded = 63
        case useSSLFailed = 64
        case sendFailRewind = 65
        case sslEngineInitFailed = 66
        case loginDenied = 67
        case tftpNotFound = 68
        case tftpPerm = 69
        case remoteDiskFull = 70
        case tftpIllegal = 71
        case tftpUnknownID = 72
        case remoteFileExists = 73
        case tftpNoSuchUser = 74
        case convFailed = 75
        case convReqd = 76
        case sslCACertBadFile = 77
        case remoteFileNotFound = 78
        case ssh = 79
        case sslShutdownFailed = 80
        case again = 81
        case sslCRLBadFile = 82
        case sslIssuerError = 83
        case ftpPretFailed = 84
        case rtspCSeqError = 85
        case rtspSessionError = 86
        case ftpBadFileList = 87
        case chunkFailed = 88
        case noConnectionAvailable = 89
        case sslPinnedPubKeyNotMatch = 90
        case sslInvalidCertStatus = 91
        case http2Stream = 92
        case nonErrorCode = 100
        case unknow = 101
    }
}

extension Curl.Err: LocalizedError, CustomStringConvertible {
    
    public var description: String { "curl Error \(rawValue): \(errorDescription!)" }
    
    public var errorDescription: String? {
        switch self {
        case .ok: return "成功，无错误"
        case .unsupportedProtocol: return "不支持的协议或协议拼写错误"
        case .failedInit: return "初始化失败，资源或内部问题"
        case .urlMalformat: return "URL 格式错误"
        case .notBuiltIn: return "请求的功能或协议未编译进 curl"
        case .couldntResolveProxy: return "无法解析代理地址"
        case .couldntResolveHost: return "无法解析主机名"
        case .couldntConnect: return "连接主机或代理失败"
        case .ftpWeirdServerReply: return "服务器返回了无法解析的响应"
        case .remoteAccessDenied: return "被拒绝访问资源"
        case .ftpAcceptFailed: return "FTP 主动连接时连接失败"
        case .ftpWeirdPassReply: return "FTP 登录密码响应异常"
        case .ftpAcceptTimeout: return "FTP 主动连接超时"
        case .ftpWeirdPasvReply: return "PASV 命令返回格式错误"
        case .ftpWeird227Format: return "FTP 227 响应无法解析"
        case .ftpCantGetHost: return "无法解析新连接的主机"
        case .http2: return "HTTP/2 帧结构错误"
        case .ftpCouldntSetType: return "设置 FTP 传输模式失败"
        case .partialFile: return "文件传输大小与预期不符"
        case .ftpCouldntRetrFile: return "FTP RETR 命令失败或传输为零"
        case .quoteError: return "自定义 QUOTE 命令执行失败"
        case .httpReturnedError: return "HTTP 返回 400 以上错误码"
        case .writeError: return "写入本地文件失败"
        case .uploadFailed: return "上传失败（如 STOR 被拒绝）"
        case .readError: return "读取本地文件失败"
        case .outOfMemory: return "内存分配失败"
        case .operationTimedOut: return "操作超时"
        case .ftpPortFailed: return "FTP PORT 命令失败"
        case .ftpCouldntUseRest: return "FTP REST 命令失败"
        case .rangeError: return "服务器不支持 Range 请求"
        case .httpPostError: return "HTTP POST 请求内部错误"
        case .sslConnectError: return "SSL 握手失败"
        case .badDownloadResume: return "无法恢复下载，偏移量超出"
        case .fileCouldntReadFile: return "本地文件不可读取"
        case .ldapCannotBind: return "LDAP 绑定失败"
        case .ldapSearchFailed: return "LDAP 查询失败"
        case .functionNotFound: return "函数未找到（如 zlib）"
        case .abortedByCallback: return "回调请求中止"
        case .badFunctionArgument: return "函数调用参数错误"
        case .interfaceFailed: return "指定的网络接口不可用"
        case .tooManyRedirects: return "重定向次数过多"
        case .unknownOption: return "未识别的 curl 参数选项"
        case .telnetOptionSyntax: return "Telnet 选项语法错误"
        case .peerFailedVerification: return "证书验证失败"
        case .gotNothing: return "服务器无响应"
        case .sslEngineNotFound: return "SSL 引擎未找到"
        case .sslEngineSetFailed: return "设置默认 SSL 引擎失败"
        case .sendError: return "发送数据失败"
        case .recvError: return "接收数据失败"
        case .sslCertProblem: return "客户端证书问题"
        case .sslCipher: return "无法使用指定的加密套件"
        case .sslCACert: return "CA 证书无法验证对方身份"
        case .badContentEncoding: return "未知的内容编码"
        case .ldapInvalidURL: return "LDAP URL 无效"
        case .fileSizeExceeded: return "超出文件大小限制"
        case .useSSLFailed: return "FTP SSL 请求失败"
        case .sendFailRewind: return "重发数据时无法回退"
        case .sslEngineInitFailed: return "SSL 引擎初始化失败"
        case .loginDenied: return "服务器拒绝登录"
        case .tftpNotFound: return "TFTP 服务器文件未找到"
        case .tftpPerm: return "TFTP 权限错误"
        case .remoteDiskFull: return "服务器磁盘空间不足"
        case .tftpIllegal: return "非法 TFTP 操作"
        case .tftpUnknownID: return "未知的 TFTP 传输 ID"
        case .remoteFileExists: return "远程文件已存在"
        case .tftpNoSuchUser: return "TFTP 用户不存在"
        case .convFailed: return "字符编码转换失败"
        case .convReqd: return "必须注册转换回调"
        case .sslCACertBadFile: return "读取 CA 证书文件失败"
        case .remoteFileNotFound: return "远程资源不存在"
        case .ssh: return "SSH 会话错误"
        case .sslShutdownFailed: return "SSL 关闭失败"
        case .again: return "套接字未就绪，需重试"
        case .sslCRLBadFile: return "加载 CRL 文件失败"
        case .sslIssuerError: return "证书颁发者验证失败"
        case .ftpPretFailed: return "FTP 不支持 PRET 命令"
        case .rtspCSeqError: return "RTSP CSeq 不匹配"
        case .rtspSessionError: return "RTSP 会话 ID 不匹配"
        case .ftpBadFileList: return "FTP 文件列表解析失败"
        case .chunkFailed: return "分块回调错误"
        case .noConnectionAvailable: return "无连接可用（内部）"
        case .sslPinnedPubKeyNotMatch: return "SSL 固定公钥不匹配"
        case .sslInvalidCertStatus: return "证书状态校验失败"
        case .http2Stream: return "HTTP/2 流错误"
        case .nonErrorCode: return "错误解析失败"
        case .unknow: return "运行失败"
        }
    }
}
