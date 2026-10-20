import Foundation
import Network

enum PageServerError: Error {
    case notReady
}

/// 只听本机回环。页面和转换都由这个进程提供。
final class PageServer: @unchecked Sendable {
    let port: UInt16
    private let listener: NWListener
    private let queue = DispatchQueue(label: "com.canopydeck.plugin.text.http")
    private static let maxBytes = 1_048_576

    private init(listener: NWListener, port: UInt16) {
        self.listener = listener
        self.port = port
    }

    static func start() throws -> PageServer {
        let parameters = NWParameters.tcp
        parameters.requiredLocalEndpoint = NWEndpoint.hostPort(host: "127.0.0.1", port: .any)
        let listener = try NWListener(using: parameters)
        let gate = BindGate()
        let accept = AcceptBox()
        listener.stateUpdateHandler = { state in
            switch state {
            case .ready:
                gate.succeed()
            case .failed(let error):
                gate.fail(error)
            default:
                break
            }
        }
        listener.newConnectionHandler = { connection in
            accept.server?.accept(connection)
        }
        listener.start(queue: DispatchQueue(label: "com.canopydeck.plugin.text.listen"))
        try gate.wait()
        guard let raw = listener.port?.rawValue, raw != 0 else {
            throw PageServerError.notReady
        }
        let server = PageServer(listener: listener, port: raw)
        accept.server = server
        return server
    }

    private func accept(_ connection: NWConnection) {
        connection.start(queue: queue)
        receive(connection, buffer: Data())
    }

    private func receive(_ connection: NWConnection, buffer: Data) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65_536) { [weak self] data, _, isComplete, error in
            guard let self else {
                connection.cancel()
                return
            }
            var next = buffer
            if let data {
                next.append(data)
            }
            if next.count > Self.maxBytes {
                self.finish(connection, status: 413, type: "text/plain; charset=utf-8", body: Data("请求过大".utf8))
                return
            }
            if let request = Self.parse(next) {
                self.route(connection, request: request)
                return
            }
            if isComplete || error != nil {
                connection.cancel()
                return
            }
            self.receive(connection, buffer: next)
        }
    }

    private func route(_ connection: NWConnection, request: Request) {
        if request.method == "GET", request.path == "/" {
            finish(connection, status: 200, type: "text/html; charset=utf-8", body: Data(PageHTML.source.utf8))
            return
        }
        if request.method == "POST", request.path == "/convert" {
            finish(connection, status: 200, type: "application/json; charset=utf-8", body: convert(request.body))
            return
        }
        finish(connection, status: 404, type: "text/plain; charset=utf-8", body: Data("找不到".utf8))
    }

    private func convert(_ body: Data) -> Data {
        guard let object = try? JSONSerialization.jsonObject(with: body) as? [String: Any],
              let action = object["action"] as? String else {
            return json(ok: false, text: nil, message: "请求无法识别", fields: nil)
        }
        let text = object["text"] as? String ?? ""
        let options = Self.options(from: object["options"] as? [String: Any])
        do {
            let output = try TextTransform.run(action: action, text: text, options: options)
            return json(ok: true, text: output.text, message: nil, fields: output.fields)
        } catch let error as TextError {
            return json(ok: false, text: nil, message: error.message, fields: nil)
        } catch {
            return json(ok: false, text: nil, message: "转换没有完成", fields: nil)
        }
    }

    /// 缺省与页面第一次打开一致：排序键开着，Base64 用标准字母表，URL 按片段编码。
    private static func options(from object: [String: Any]?) -> TransformOptions {
        var options = TransformOptions()
        guard let object else { return options }
        if let sortKeys = object["sortKeys"] as? Bool {
            options.sortKeys = sortKeys
        }
        if let urlSafe = object["urlSafe"] as? Bool {
            options.urlSafe = urlSafe
        }
        if let scope = object["scope"] as? String, scope == "full" || scope == "component" {
            options.scope = scope
        }
        return options
    }

    private func json(ok: Bool, text: String?, message: String?, fields: [String: String]?) -> Data {
        var object: [String: Any] = ["ok": ok]
        if let text {
            object["text"] = text
        }
        if let message {
            object["message"] = message
        }
        if let fields {
            object["fields"] = fields
        }
        return (try? JSONSerialization.data(withJSONObject: object)) ?? Data("{\"ok\":false}".utf8)
    }

    private func finish(_ connection: NWConnection, status: Int, type: String, body: Data) {
        let reason = status == 200 ? "OK" : "Error"
        let header = "HTTP/1.1 \(status) \(reason)\r\nContent-Type: \(type)\r\nContent-Length: \(body.count)\r\nConnection: close\r\nCache-Control: no-store\r\n\r\n"
        var packet = Data(header.utf8)
        packet.append(body)
        connection.send(content: packet, completion: .contentProcessed { _ in
            connection.cancel()
        })
    }

    private struct Request {
        var method: String
        var path: String
        var body: Data
    }

    private static func parse(_ data: Data) -> Request? {
        let separator = Data("\r\n\r\n".utf8)
        guard let range = data.range(of: separator) else { return nil }
        let head = data.subdata(in: 0..<range.lowerBound)
        guard let text = String(data: head, encoding: .utf8) else { return nil }
        let lines = text.components(separatedBy: "\r\n")
        guard let first = lines.first else { return nil }
        let parts = first.split(separator: " ")
        guard parts.count >= 2 else { return nil }
        var length = 0
        for line in lines.dropFirst() where line.lowercased().hasPrefix("content-length:") {
            let raw = line.split(separator: ":", maxSplits: 1).last?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard let value = Int(raw), value >= 0, value <= maxBytes else { return nil }
            length = value
        }
        let bodyStart = range.upperBound
        guard data.count >= bodyStart + length else { return nil }
        let path = String(parts[1]).split(separator: "?").first.map(String.init) ?? "/"
        return Request(method: String(parts[0]), path: path, body: data.subdata(in: bodyStart..<(bodyStart + length)))
    }
}

private final class AcceptBox: @unchecked Sendable {
    var server: PageServer?
}

private final class BindGate: @unchecked Sendable {
    private let semaphore = DispatchSemaphore(value: 0)
    private let lock = NSLock()
    private var error: Error?

    func succeed() {
        semaphore.signal()
    }

    func fail(_ error: Error) {
        lock.lock()
        self.error = error
        lock.unlock()
        semaphore.signal()
    }

    func wait() throws {
        if semaphore.wait(timeout: .now() + .seconds(2)) == .timedOut {
            throw PageServerError.notReady
        }
        lock.lock()
        let error = self.error
        lock.unlock()
        if let error {
            throw error
        }
    }
}
