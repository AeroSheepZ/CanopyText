import CanopyToolWire
import Foundation

enum TextToolMain {
    static let pluginID = "com.canopydeck.plugin.text"
    static let panelID = "com.canopydeck.plugin.text.page"
    static let openCommandID = "com.canopydeck.plugin.text.open"
    /// 与页面请求体上限相同。
    private static let maxInputBytes = 1_048_576

    static func main() {
        ProcessLocalization.bootstrapFromEnvironment()
        let server: PageServer
        do {
            server = try PageServer.start()
        } catch {
            let line = TextL10n.t(
                "转换器页面没有绑上端口: %@",
                error.localizedDescription
            )
            fputs(line + "\n", stderr)
            exit(1)
        }
        let pageURL = "http://127.0.0.1:\(server.port)/"
        fputs(TextL10n.t("转换器页面 %@", pageURL) + "\n", stderr)
        let name = TextL10n.t("转换器")
        let peer = ToolPeer.stdio()
        peer.send(.hello(ToolManifest(
            id: pluginID,
            name: name,
            commands: commands(),
            panels: [
                ToolPanelSpec(
                    id: panelID,
                    title: name,
                    systemImage: "arrow.left.arrow.right",
                    pageURL: pageURL
                )
            ]
        )))
        while let message = peer.next() {
            switch message {
            case .perform(let requestID, let commandID, let paths):
                peer.send(.result(
                    requestID: requestID,
                    message: reply(commandID: commandID, paths: paths),
                    items: []
                ))
            case .shutdown:
                exit(0)
            default:
                break
            }
        }
    }

    /// showsPage 为真时甲板不另画按钮，助手仍能调用。快捷键只展开页面。
    private static func commands() -> [ToolCommandSpec] {
        let hint = TextL10n.t("paths 第一项是原文或 UTF-8 文件")
        return [
            command(openCommandID, title: TextL10n.t("打开转换器")),
            command(
                "\(pluginID).json.pretty",
                title: TextL10n.t("美化 JSON，排序键。%@", hint)
            ),
            command(
                "\(pluginID).json.pretty.unsorted",
                title: TextL10n.t("美化 JSON，保留键序。%@", hint)
            ),
            command(
                "\(pluginID).json.compact",
                title: TextL10n.t("压缩 JSON，排序键。%@", hint)
            ),
            command(
                "\(pluginID).json.compact.unsorted",
                title: TextL10n.t("压缩 JSON，保留键序。%@", hint)
            ),
            command(
                "\(pluginID).base64.encode",
                title: TextL10n.t("Base64 编码。%@", hint)
            ),
            command(
                "\(pluginID).base64.encode.urlSafe",
                title: TextL10n.t("Base64 编码，URL-safe。%@", hint)
            ),
            command(
                "\(pluginID).base64.decode",
                title: TextL10n.t("Base64 解码。%@", hint)
            ),
            command(
                "\(pluginID).base64.decode.urlSafe",
                title: TextL10n.t("Base64 解码，URL-safe。%@", hint)
            ),
            command(
                "\(pluginID).url.encode",
                title: TextL10n.t("URL 编码，按片段。%@", hint)
            ),
            command(
                "\(pluginID).url.encode.full",
                title: TextL10n.t("URL 编码，整段。%@", hint)
            ),
            command(
                "\(pluginID).url.decode",
                title: TextL10n.t("URL 解码。%@", hint)
            ),
            command(
                "\(pluginID).time.parse",
                title: TextL10n.t("解析时间。%@", hint)
            ),
            command(
                "\(pluginID).time.now",
                title: TextL10n.t("当前时间")
            )
        ]
    }

    private static func command(_ id: String, title: String) -> ToolCommandSpec {
        ToolCommandSpec(
            id: id,
            title: title,
            systemImage: "arrow.left.arrow.right",
            showsPage: true
        )
    }

    private static func reply(commandID: String, paths: [String]) -> String {
        if commandID == openCommandID {
            return TextL10n.t("请在甲板里打开转换器")
        }
        let prefix = pluginID + "."
        guard commandID.hasPrefix(prefix) else {
            return TextL10n.t("未知动作")
        }
        let suffix = String(commandID.dropFirst(prefix.count))
        guard let job = job(for: suffix) else {
            return TextL10n.t("未知动作")
        }
        do {
            let text: String
            if suffix == "time.now" {
                text = ""
            } else {
                text = try inputText(paths)
            }
            let output = try TextTransform.run(action: job.action, text: text, options: job.options)
            return render(output)
        } catch let error as TextError {
            return error.message
        } catch {
            return TextL10n.t("读不了这个文件")
        }
    }

    private static func job(for suffix: String) -> (action: String, options: TransformOptions)? {
        switch suffix {
        case "json.pretty":
            return ("json.pretty", TransformOptions(sortKeys: true))
        case "json.pretty.unsorted":
            return ("json.pretty", TransformOptions(sortKeys: false))
        case "json.compact":
            return ("json.compact", TransformOptions(sortKeys: true))
        case "json.compact.unsorted":
            return ("json.compact", TransformOptions(sortKeys: false))
        case "base64.encode":
            return ("base64.encode", TransformOptions())
        case "base64.encode.urlSafe":
            return ("base64.encode", TransformOptions(urlSafe: true))
        case "base64.decode":
            return ("base64.decode", TransformOptions())
        case "base64.decode.urlSafe":
            return ("base64.decode", TransformOptions(urlSafe: true))
        case "url.encode":
            return ("url.encode", TransformOptions())
        case "url.encode.full":
            return ("url.encode", TransformOptions(scope: "full"))
        case "url.decode":
            return ("url.decode", TransformOptions())
        case "time.parse":
            return ("time.parse", TransformOptions())
        case "time.now":
            return ("time.now", TransformOptions())
        default:
            return nil
        }
    }

    private static func inputText(_ paths: [String]) throws -> String {
        guard paths.count == 1, let raw = paths.first else {
            throw TextError(message: TextL10n.t("要一项原文或文件路径"))
        }
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: raw, isDirectory: &isDirectory) else {
            return raw
        }
        if isDirectory.boolValue {
            throw TextError(message: TextL10n.t("这是目录"))
        }
        let attributes = try FileManager.default.attributesOfItem(atPath: raw)
        let size = (attributes[.size] as? NSNumber)?.intValue ?? 0
        if size > maxInputBytes {
            throw TextError(message: TextL10n.t("内容太大"))
        }
        let data = try Data(contentsOf: URL(fileURLWithPath: raw))
        guard let text = String(data: data, encoding: .utf8) else {
            throw TextError(message: TextL10n.t("不是 UTF-8 文本"))
        }
        return text
    }

    private static func render(_ output: TransformOutput) -> String {
        if let text = output.text {
            return text
        }
        let fields = output.fields ?? [:]
        let local = TextL10n.t("本地时间")
        let seconds = TextL10n.t("秒")
        let millis = TextL10n.t("毫秒")
        return [
            "\(local)\t\(fields["local"] ?? "")",
            "\(seconds)\t\(fields["seconds"] ?? "")",
            "\(millis)\t\(fields["millis"] ?? "")"
        ].joined(separator: "\n")
    }
}

TextToolMain.main()
