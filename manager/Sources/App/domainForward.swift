import NIOCore
import NIO
import Logging
import ErrorHandle
import WhooshingClient
import Vapor
import NIOConcurrencyHelpers
import Fluent
import FluentPostgresDriver
import NIOExtras
import NIOHTTP1

enum DomainForwardErr: String, ErrList {
    var domain: String { "woo.sys.manager.domain.forward.err" }
    case unknowError = "域名转发时发生未知错误"
    case clientChannelError = "客户端与该中转的连线出现错误"
    case forwardChannelError = "该中转与目标服务模块的连线出现错误"
    case clientChannelNotExist = "客户端连线不存在"
    case protocolError = "客户端的传输机制不正确"
    case domainNotExist = "客户端所请求的域名不存在"
}

class DomainForward: @unchecked Sendable {

    // key: 客户端与该中转的连线 channel
    // value: 该中转与目标服务的连线 channel
    let connectionPool: SendableDictionary<ObjectIdentifier, Channel> = .init()
    let verifingPool: SendableDictionary<ObjectIdentifier, Bool> = .init()

    func domainForwardExecute(app: Application) async throws {
        let bootstrap = ServerBootstrap(group: app.eventLoopGroup.next())
            .childChannelInitializer { channel in
                channel.pipeline.addHandlers([
                    LengthFieldPrepender(lengthFieldLength: .eight, lengthFieldEndianness: .big),
                    ByteToMessageHandler(LengthFieldBasedFrameDecoder(lengthFieldLength: .eight, lengthFieldEndianness: .big)),
                    ServerChannelHandler(
                        connectionPool: self.connectionPool,
                        verifingPool: self.verifingPool,
                        logger: app.logger,
                        db: app.db
                    ),
                    NIOCloseOnErrorHandler()
                ])
            }
            .serverChannelOption(.socketOption(.tcp_nodelay), value: 1)
            .serverChannelOption(.socketOption(.so_reuseaddr), value: 1)
            .serverChannelOption(.maxMessagesPerRead, value: 1)

        do {
            let channel = try await bootstrap.bind(host: "0.0.0.0", port: 20002).get()
            app.logger.notice("域名转发服务开始监听 \(channel.localAddrInfo)")
        } catch {
            app.logger.report(error: DomainForwardErr.unknowError.d(13053, #file, #line).subErr(error))
            throw error
        }
    }
}

final class Queue<DataType>: @unchecked Sendable {

    var handler: (DataType) async throws -> Void = { _ in }

    private let lock = NIOLock()
    private var datas: [DataType] = []
    private var busy = false
    private var stop = false

    func append(_ data: DataType) {
        lock.withLock {
            datas.append(data)
        }
    }

    func run() async throws {
        guard busy == false else { return }
        lock.withLock { busy = true }
        while datas.count > 0 {
            let data = lock.withLock { datas.removeFirst() }
            if stop { stop = false; break }
            try await self.handler(data)
            if stop { stop = false; break }
        }
        lock.withLock { busy = false }
    }

    func pause() {
        stop = true
    }
}

final class ServerChannelHandler: ChannelInboundHandler, @unchecked Sendable {
    typealias InboundIn = ByteBuffer
    typealias InboundOut = ByteBuffer

    let connectionPool: SendableDictionary<ObjectIdentifier, Channel>
    let verifingPool: SendableDictionary<ObjectIdentifier, Bool>
    let logger: Logger
    let db: Database
    let queue = Queue<(ByteBuffer, ChannelHandlerContext)>()

    init(
        connectionPool: SendableDictionary<ObjectIdentifier, Channel>, 
        verifingPool: SendableDictionary<ObjectIdentifier, Bool>,
        logger: Logger, 
        db: Database
    ) {
        self.connectionPool = connectionPool
        self.verifingPool = verifingPool
        self.logger = logger
        self.db = db
        self.queue.handler = dataHandler
    }

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let data = unwrapInboundIn(data)
        
        queue.append((data, context))

        context.eventLoop.makeFutureWithTask {
            try await self.queue.run()
        }.whenFailure { err in
            self.errorHappend(channel: context.channel, error: err, status: .internalServerError, clientErr: true)
        }
    }

    func dataHandler(_ d: (ByteBuffer, ChannelHandlerContext)) async throws {
        let (data, context) = d
        let id = ObjectIdentifier(context.channel)
        if self.connectionPool[id] == nil {
            print("// 该请求是第一次发送来的")
            let request = String(buffer: data)
            print("-------------------------")
            print(request)
            print("-----------End--------------")
            guard let hostStr = request.split(separator: "\r\n").first(where: { $0.lowercased().hasPrefix("host") })?.lowercased() else {
                let err = DomainForwardErr.protocolError.d("未能找到 Host", 13061, (#file, #line))
                self.errorHappend(channel: context.channel, error: err, status: .badRequest, clientErr: true)
                return
            }

            let hostArr = hostStr.split(separator: ": ")
            
            guard hostArr.count == 2 else {
                let err = DomainForwardErr.protocolError.d("Host 字段不符合 HTTP 规范", 13062, (#file, #line))
                self.errorHappend(channel: context.channel, error: err, status: .badRequest, clientErr: true)
                return
            }

            let domain = String(hostArr[1])

            print("// 检查域名")
            let clientDomain = try await Domain.query(on: self.db).filter(\.$domain == domain).first().get()
            guard let dom = clientDomain else {
                throw DomainForwardErr.domainNotExist.d("客户端所请求的域名: \(domain)", 13060, (#file, #line))
            }

            let channel = try await self.forwardToService(port: dom.port, clientChannel: context.channel)
            self.connectionPool[id] = channel
        }

        let targetChannel = self.connectionPool[id]!
        print("// 将客户端请求发送给服务模块")
        try await targetChannel.writeAndFlush(data)
    }

    // 与服务模块建立连线
    func forwardToService(port: Int, clientChannel: Channel) async throws -> Channel {
        let handler = ForwardChannelHandler(clientChannel: clientChannel, serverChannelHandler: self, logger: self.logger)

        let bootstrap = ClientBootstrap(group: clientChannel.eventLoop)
            .channelInitializer { channel in
                channel.pipeline.addHandlers([
                    LengthFieldPrepender(lengthFieldLength: .eight, lengthFieldEndianness: .big),
                    ByteToMessageHandler(LengthFieldBasedFrameDecoder(lengthFieldLength: .eight, lengthFieldEndianness: .big)),
                    handler,
                    NIOCloseOnErrorHandler()
                ])
            }
            .channelOption(.socketOption(.tcp_nodelay), value: 1)
            .channelOption(.socketOption(.so_reuseaddr), value: 1)
            .channelOption(.maxMessagesPerRead, value: 1)
        
        let channel = try await bootstrap.connect(host: "127.0.0.1", port: port).get()
        return channel
    }

    func errorHappend(channel: Channel, error: Error, status: HTTPStatus, clientErr: Bool) {

        self.queue.pause()

        let id = ObjectIdentifier(channel)
        if let targetChannel = connectionPool[id] {
            targetChannel.close(promise: nil)
            connectionPool[id] = nil
        }
        
        let err: Error

        if clientErr {
            err = DomainForwardErr.clientChannelError.d(13055, #file, #line).subErr(error)
        } else {
            err = DomainForwardErr.forwardChannelError.d(13065, #file, #line).subErr(error)
        }

        logger.report(error: err)

        struct BodyReply: Content {
            let error: Bool
            let reason: String
        }

        if channel.isActive {
            var headers = HTTPHeaders()
            let body = try! ByteBuffer(data: JSONEncoder().encode(BodyReply(error: true, reason: "\(err)")))
            headers.add(name: "Content-Type", value: "application/json")
            headers.add(name: "Content-Length", value: "\(body.readableBytes)")
            headers.add(name: "Connection", value: "close")

            let head = HTTPResponseHead(
                version: .http1_1,
                status: status,
                headers: headers
            )

            channel.writeAndFlush(ByteBuffer(string: httpResponseHeadToString(head))).flatMap {
                var buffer = ChunkTool.eof
                var body = body
                buffer.writeBuffer(&body)
                return channel.writeAndFlush(buffer)
            }.whenComplete { _ in
                channel.close(promise: nil)
            }
        } else {
            channel.close(promise: nil)
        }

        func httpResponseHeadToString(_ head: HTTPResponseHead) -> String {
            var lines: [String] = []
            let statusLine = "HTTP/\(head.version.major).\(head.version.minor) \(head.status.code) \(head.status.reasonPhrase)"
            lines.append(statusLine)
            for (name, value) in head.headers {
                lines.append("\(name): \(value)")
            }
            lines.append("")
            return lines.joined(separator: "\r\n") + "\r\n"
        }
    }
}

final class ForwardChannelHandler: ChannelInboundHandler, @unchecked Sendable {
    typealias InboundIn = ByteBuffer
    typealias InboundOut = ByteBuffer

    let logger: Logger

    weak var clientChannel: Channel?
    weak var serverChannelHandler: ServerChannelHandler?

    init(clientChannel: Channel, serverChannelHandler: ServerChannelHandler, logger: Logger) {
        self.clientChannel = clientChannel
        self.serverChannelHandler = serverChannelHandler
        self.logger = logger
    }

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        if let clientChannel = self.clientChannel, let serverChannelHandler = serverChannelHandler {
            let data = unwrapInboundIn(data)
            clientChannel.writeAndFlush(data).whenFailure { err in 
                serverChannelHandler.errorHappend(channel: clientChannel, error: err, status: .internalServerError, clientErr: false)
            }
        } else {
            let err = DomainForwardErr.clientChannelNotExist.d(13057, #file, #line)
            logger.report(error: err)
        }
    }
}