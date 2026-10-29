import Foundation
import CanopyToolWire

/// 单文件外部工具的文案表。不走 Bundle.module（宿主只装可执行文件）。
enum TextL10n {
    static func t(_ key: String, _ arguments: CVarArg...) -> String {
        let code = languageCode()
        let template = table[code]?[key]
            ?? table["zh-Hans"]?[key]
            ?? key
        if arguments.isEmpty { return template }
        return String(
            format: template,
            locale: Locale(identifier: code),
            arguments: arguments
        )
    }

    /// 与宿主语言环境键同规则（供网页 `lang` 与文案表共用）。
    static func languageCode() -> String {
        let raw = ProcessInfo.processInfo.environment[ProcessLocalization.environmentKey]
        if let raw, raw != ProcessLocalization.systemToken, !raw.isEmpty {
            if raw.hasPrefix("en") { return "en" }
            if raw.hasPrefix("zh") { return "zh-Hans" }
            return raw
        }
        let preferred = Locale.preferredLanguages.first ?? "zh-Hans"
        if preferred.hasPrefix("en") { return "en" }
        if preferred.hasPrefix("zh") { return "zh-Hans" }
        return "zh-Hans"
    }

    private static let table: [String: [String: String]] = [
        "zh-Hans": [
            "10 位": "10 位",
            "13 位": "13 位",
            "Base64 编码。%@": "Base64 编码。%@",
            "Base64 编码，URL-safe。%@": "Base64 编码，URL-safe。%@",
            "Base64 解出来不是文本": "Base64 解出来不是文本",
            "Base64 解码。%@": "Base64 解码。%@",
            "Base64 解码，URL-safe。%@": "Base64 解码，URL-safe。%@",
            "URL 编码，按片段。%@": "URL 编码，按片段。%@",
            "URL 编码，整段。%@": "URL 编码，整段。%@",
            "URL 解码。%@": "URL 解码。%@",
            "paths 第一项是原文或 UTF-8 文件": "paths 第一项是原文或 UTF-8 文件",
            "不是 UTF-8 文本": "不是 UTF-8 文本",
            "不是合法的 Base64": "不是合法的 Base64",
            "不是合法的 JSON": "不是合法的 JSON",
            "不是合法的百分号编码": "不是合法的百分号编码",
            "内容太大": "内容太大",
            "压缩": "压缩",
            "压缩 JSON，保留键序。%@": "压缩 JSON，保留键序。%@",
            "压缩 JSON，排序键。%@": "压缩 JSON，排序键。%@",
            "复制": "复制",
            "对调": "对调",
            "已压缩": "已压缩",
            "已复制": "已复制",
            "已美化": "已美化",
            "当前时间": "当前时间",
            "打开转换器": "打开转换器",
            "找不到": "找不到",
            "排序键": "排序键",
            "整段": "整段",
            "文本": "文本",
            "无法编码": "无法编码",
            "时间": "时间",
            "时间戳要是 10 位的秒或 13 位的毫秒": "时间戳要是 10 位的秒或 13 位的毫秒",
            "未知动作": "未知动作",
            "本地时间": "本地时间",
            "毫秒": "毫秒",
            "没有内容": "没有内容",
            "没有结果": "没有结果",
            "片段": "片段",
            "现在": "现在",
            "百分号编码": "百分号编码",
            "秒": "秒",
            "编码": "编码",
            "编码范围": "编码范围",
            "美化": "美化",
            "美化 JSON，保留键序。%@": "美化 JSON，保留键序。%@",
            "美化 JSON，排序键。%@": "美化 JSON，排序键。%@",
            "要一项原文或文件路径": "要一项原文或文件路径",
            "要编码的文本": "要编码的文本",
            "要解码的 Base64": "要解码的 Base64",
            "解析时间。%@": "解析时间。%@",
            "认不出这个时间，用 2026-10-17 11:14:00 这种写法": "认不出这个时间，用 2026-10-17 11:14:00 这种写法",
            "请在甲板里打开转换器": "请在甲板里打开转换器",
            "请求无法识别": "请求无法识别",
            "请求过大": "请求过大",
            "读不了这个文件": "读不了这个文件",
            "转换器": "转换器",
            "转换器页面 %@": "转换器页面 %@",
            "转换器页面没有绑上端口: %@": "转换器页面没有绑上端口: %@",
            "转换没有完成": "转换没有完成",
            "这是目录": "这是目录",
            "选中了结果，可以手动复制": "选中了结果，可以手动复制",
        ],
        "en": [
            "10 位": "10 digits",
            "13 位": "13 digits",
            "Base64 编码。%@": "Base64 encode. %@",
            "Base64 编码，URL-safe。%@": "Base64 encode, URL-safe. %@",
            "Base64 解出来不是文本": "Base64 decoded to non-text",
            "Base64 解码。%@": "Base64 decode. %@",
            "Base64 解码，URL-safe。%@": "Base64 decode, URL-safe. %@",
            "URL 编码，按片段。%@": "URL-encode by component. %@",
            "URL 编码，整段。%@": "URL-encode the whole string. %@",
            "URL 解码。%@": "URL decode. %@",
            "paths 第一项是原文或 UTF-8 文件": "paths[0] is raw text or a UTF-8 file",
            "不是 UTF-8 文本": "Not UTF-8 text",
            "不是合法的 Base64": "Not valid Base64",
            "不是合法的 JSON": "Not valid JSON",
            "不是合法的百分号编码": "Not valid percent-encoding",
            "内容太大": "Content is too large",
            "压缩": "Compact",
            "压缩 JSON，保留键序。%@": "Compact JSON keeping key order. %@",
            "压缩 JSON，排序键。%@": "Compact JSON with sorted keys. %@",
            "复制": "Copy",
            "对调": "Swap",
            "已压缩": "Compacted",
            "已复制": "Copied",
            "已美化": "Prettified",
            "当前时间": "Current time",
            "打开转换器": "Open Converter",
            "找不到": "Not found",
            "排序键": "Sort keys",
            "整段": "Full",
            "文本": "Text",
            "无法编码": "Couldn’t encode",
            "时间": "Time",
            "时间戳要是 10 位的秒或 13 位的毫秒": "Timestamp must be 10-digit seconds or 13-digit milliseconds",
            "未知动作": "Unknown action",
            "本地时间": "Local time",
            "毫秒": "Milliseconds",
            "没有内容": "No content",
            "没有结果": "Nothing to copy",
            "片段": "Part",
            "现在": "Now",
            "百分号编码": "Percent-encoded",
            "秒": "Seconds",
            "编码": "Encoded",
            "编码范围": "Encode scope",
            "美化": "Pretty",
            "美化 JSON，保留键序。%@": "Pretty-print JSON keeping key order. %@",
            "美化 JSON，排序键。%@": "Pretty-print JSON with sorted keys. %@",
            "要一项原文或文件路径": "Need one text value or file path",
            "要编码的文本": "Text to encode",
            "要解码的 Base64": "Base64 to decode",
            "解析时间。%@": "Parse time. %@",
            "认不出这个时间，用 2026-10-17 11:14:00 这种写法": "Unrecognized time; use something like 2026-10-17 11:14:00",
            "请在甲板里打开转换器": "Open Converter on the deck",
            "请求无法识别": "Unrecognized request",
            "请求过大": "Request too large",
            "读不了这个文件": "Couldn’t read that file",
            "转换器": "Converter",
            "转换器页面 %@": "Converter page %@",
            "转换器页面没有绑上端口: %@": "Converter page failed to bind a port: %@",
            "转换没有完成": "Conversion failed",
            "这是目录": "That’s a directory",
            "选中了结果，可以手动复制": "Selected; copy manually",
        ],
    ]
}
