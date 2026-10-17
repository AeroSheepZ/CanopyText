import CanopyToolWire
import Foundation

enum TextToolMain {
    static let pluginID = "com.canopydeck.plugin.text"
    static let panelID = "com.canopydeck.plugin.text.page"
    static let openCommandID = "com.canopydeck.plugin.text.open"

    static func main() {
        let server: PageServer
        do {
            server = try PageServer.start()
        } catch {
            fputs("文本页面没有绑上端口: \(error)\n", stderr)
            exit(1)
        }
        fputs("文本页面 http://127.0.0.1:\(server.port)/\n", stderr)
        let peer = ToolPeer.stdio()
        peer.send(.hello(ToolManifest(
            id: pluginID,
            name: "文本",
            commands: [
                ToolCommandSpec(
                    id: openCommandID,
                    title: "打开文本",
                    systemImage: "textformat",
                    showsPage: true
                )
            ],
            panels: [
                ToolPanelSpec(
                    id: panelID,
                    title: "文本",
                    systemImage: "textformat",
                    pageURL: "http://127.0.0.1:\(server.port)/"
                )
            ]
        )))
        while let message = peer.next() {
            if case .shutdown = message {
                exit(0)
            }
        }
    }
}

TextToolMain.main()
