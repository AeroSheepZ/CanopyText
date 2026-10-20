import Foundation

struct TextError: Error {
    let message: String
}

struct TransformOptions: Sendable {
    var sortKeys = true
    var urlSafe = false
    /// `component` 按查询值编码，`full` 保留网址结构字符。
    var scope = "component"
}

struct TransformOutput: Sendable {
    var text: String?
    var fields: [String: String]?
}

enum TextTransform {
    static func run(action: String, text: String, options: TransformOptions) throws -> TransformOutput {
        switch action {
        case "json.pretty":
            return TransformOutput(text: try json(text, pretty: true, sortKeys: options.sortKeys))
        case "json.compact":
            return TransformOutput(text: try json(text, pretty: false, sortKeys: options.sortKeys))
        case "base64.encode":
            return TransformOutput(text: try base64Encode(text, urlSafe: options.urlSafe))
        case "base64.decode":
            return TransformOutput(text: try base64Decode(text, urlSafe: options.urlSafe))
        case "url.encode":
            return TransformOutput(text: try urlEncode(text, scope: options.scope))
        case "url.decode":
            return TransformOutput(text: try urlDecode(text))
        case "time.parse":
            return TransformOutput(fields: try timeParse(text))
        case "time.now":
            return TransformOutput(fields: timeFields(Date()))
        default:
            throw TextError(message: "未知动作")
        }
    }

    /// 先确认是合法 JSON。排序时交给系统重排键，再统一排成两空格缩进，避免开关键序被打乱。
    private static func json(_ text: String, pretty: Bool, sortKeys: Bool) throws -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw TextError(message: "没有内容") }
        guard let data = trimmed.data(using: .utf8),
              (try? JSONSerialization.jsonObject(with: data)) != nil else {
            throw TextError(message: "不是合法的 JSON")
        }
        let source = sortKeys ? try sortedCompact(data) : trimmed
        if let formatted = formatPreservingOrder(source, pretty: pretty),
           let formattedData = formatted.data(using: .utf8),
           (try? JSONSerialization.jsonObject(with: formattedData)) != nil {
            return formatted
        }
        return try systemWrite(data, pretty: pretty, sortKeys: sortKeys)
    }

    private static func sortedCompact(_ data: Data) throws -> String {
        let object = try JSONSerialization.jsonObject(with: data)
        let written = try JSONSerialization.data(
            withJSONObject: object,
            options: [.sortedKeys, .withoutEscapingSlashes]
        )
        guard let output = String(data: written, encoding: .utf8) else {
            throw TextError(message: "不是合法的 JSON")
        }
        return output
    }

    private static func systemWrite(_ data: Data, pretty: Bool, sortKeys: Bool) throws -> String {
        let object = try JSONSerialization.jsonObject(with: data)
        var options: JSONSerialization.WritingOptions = [.withoutEscapingSlashes]
        if sortKeys {
            options.insert(.sortedKeys)
        }
        if pretty {
            options.insert(.prettyPrinted)
        }
        let written = try JSONSerialization.data(withJSONObject: object, options: options)
        guard let output = String(data: written, encoding: .utf8) else {
            throw TextError(message: "不是合法的 JSON")
        }
        return output
    }

    private enum JSONToken {
        case syntax(Character)
        case string(String)
        case number(String)
        case literal(String)
    }

    /// 丢掉空白，保留字符串原文和键的出现顺序。
    private static func tokenizeJSON(_ text: String) throws -> [JSONToken] {
        var tokens: [JSONToken] = []
        var index = text.startIndex

        while index < text.endIndex {
            let character = text[index]
            if character == " " || character == "\n" || character == "\r" || character == "\t" {
                index = text.index(after: index)
                continue
            }
            if "{}[],:".contains(character) {
                tokens.append(.syntax(character))
                index = text.index(after: index)
                continue
            }
            if character == "\"" {
                tokens.append(.string(try scanString(text, from: &index)))
                continue
            }
            if character == "-" || character.isNumber {
                tokens.append(.number(try scanNumber(text, from: &index)))
                continue
            }
            if let literal = scanLiteral(text, from: &index) {
                tokens.append(.literal(literal))
                continue
            }
            throw TextError(message: "不是合法的 JSON")
        }
        return tokens
    }

    private static func scanString(_ text: String, from index: inout String.Index) throws -> String {
        let start = index
        index = text.index(after: index)
        var closed = false
        while index < text.endIndex {
            let character = text[index]
            index = text.index(after: index)
            if character == "\\" {
                guard index < text.endIndex else { break }
                index = text.index(after: index)
                continue
            }
            if character == "\"" {
                closed = true
                break
            }
        }
        guard closed else { throw TextError(message: "不是合法的 JSON") }
        return String(text[start..<index])
    }

    private static func scanNumber(_ text: String, from index: inout String.Index) throws -> String {
        let start = index
        if text[index] == "-" {
            index = text.index(after: index)
        }
        guard index < text.endIndex, text[index].isNumber else {
            throw TextError(message: "不是合法的 JSON")
        }
        if text[index] == "0" {
            index = text.index(after: index)
        } else {
            while index < text.endIndex, text[index].isNumber {
                index = text.index(after: index)
            }
        }
        if index < text.endIndex, text[index] == "." {
            index = text.index(after: index)
            guard index < text.endIndex, text[index].isNumber else {
                throw TextError(message: "不是合法的 JSON")
            }
            while index < text.endIndex, text[index].isNumber {
                index = text.index(after: index)
            }
        }
        if index < text.endIndex, text[index] == "e" || text[index] == "E" {
            index = text.index(after: index)
            if index < text.endIndex, text[index] == "+" || text[index] == "-" {
                index = text.index(after: index)
            }
            guard index < text.endIndex, text[index].isNumber else {
                throw TextError(message: "不是合法的 JSON")
            }
            while index < text.endIndex, text[index].isNumber {
                index = text.index(after: index)
            }
        }
        return String(text[start..<index])
    }

    private static func scanLiteral(_ text: String, from index: inout String.Index) -> String? {
        for word in ["true", "false", "null"] where text[index...].hasPrefix(word) {
            let next = text.index(index, offsetBy: word.count)
            if next == text.endIndex || !"0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_".contains(text[next]) {
                index = next
                return word
            }
        }
        return nil
    }

    private static func formatPreservingOrder(_ text: String, pretty: Bool) -> String? {
        guard let tokens = try? tokenizeJSON(text), !tokens.isEmpty else { return nil }
        return pretty ? prettyTokens(tokens) : compactTokens(tokens)
    }

    private static func prettyTokens(_ tokens: [JSONToken]) -> String {
        var output = ""
        var indent = 0
        var index = 0

        func breakLine() {
            output.append("\n")
            if indent > 0 {
                output.append(String(repeating: "  ", count: indent))
            }
        }

        while index < tokens.count {
            switch tokens[index] {
            case .syntax("{"):
                if closesEmpty(tokens, index: index, close: "}") {
                    output.append("{}")
                    index += 2
                } else {
                    output.append("{")
                    indent += 1
                    breakLine()
                    index += 1
                }
            case .syntax("["):
                if closesEmpty(tokens, index: index, close: "]") {
                    output.append("[]")
                    index += 2
                } else {
                    output.append("[")
                    indent += 1
                    breakLine()
                    index += 1
                }
            case .syntax("}"):
                indent = max(0, indent - 1)
                breakLine()
                output.append("}")
                index += 1
            case .syntax("]"):
                indent = max(0, indent - 1)
                breakLine()
                output.append("]")
                index += 1
            case .syntax(","):
                output.append(",")
                breakLine()
                index += 1
            case .syntax(":"):
                output.append(": ")
                index += 1
            case .syntax:
                index += 1
            case .string(let value), .number(let value), .literal(let value):
                output.append(value)
                index += 1
            }
        }
        return output
    }

    private static func closesEmpty(_ tokens: [JSONToken], index: Int, close: Character) -> Bool {
        guard index + 1 < tokens.count else { return false }
        if case .syntax(let next) = tokens[index + 1] {
            return next == close
        }
        return false
    }

    private static func compactTokens(_ tokens: [JSONToken]) -> String {
        var output = ""
        for token in tokens {
            switch token {
            case .syntax(let character):
                output.append(character)
            case .string(let value), .number(let value), .literal(let value):
                output.append(value)
            }
        }
        return output
    }

    private static func base64Encode(_ text: String, urlSafe: Bool) throws -> String {
        guard !text.isEmpty else { throw TextError(message: "没有内容") }
        var encoded = Data(text.utf8).base64EncodedString()
        if urlSafe {
            encoded = encoded
                .replacingOccurrences(of: "+", with: "-")
                .replacingOccurrences(of: "/", with: "_")
                .replacingOccurrences(of: "=", with: "")
        }
        return encoded
    }

    private static func base64Decode(_ text: String, urlSafe: Bool) throws -> String {
        var compact = String(text.unicodeScalars.filter { !CharacterSet.whitespacesAndNewlines.contains($0) })
        guard !compact.isEmpty else { throw TextError(message: "没有内容") }
        if urlSafe {
            compact = compact.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
            if !compact.contains("=") {
                let remainder = compact.count % 4
                guard remainder != 1 else { throw TextError(message: "不是合法的 Base64") }
                if remainder > 0 {
                    compact += String(repeating: "=", count: 4 - remainder)
                }
            }
        }
        guard let data = Data(base64Encoded: compact) else {
            throw TextError(message: "不是合法的 Base64")
        }
        guard let output = String(data: data, encoding: .utf8) else {
            throw TextError(message: "Base64 解出来不是文本")
        }
        return output
    }

    /// 片段对应 encodeURIComponent，整段对应 encodeURI。
    private static func urlEncode(_ text: String, scope: String) throws -> String {
        guard !text.isEmpty else { throw TextError(message: "没有内容") }
        let allowed = scope == "full" ? fullURLAllowed : componentURLAllowed
        guard let encoded = text.addingPercentEncoding(withAllowedCharacters: allowed) else {
            throw TextError(message: "无法编码")
        }
        return encoded
    }

    private static func urlDecode(_ text: String) throws -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw TextError(message: "没有内容") }
        guard let decoded = trimmed.removingPercentEncoding else {
            throw TextError(message: "不是合法的百分号编码")
        }
        return decoded
    }

    private static let componentURLAllowed: CharacterSet = {
        var set = CharacterSet.alphanumerics
        set.insert(charactersIn: "-_.!~*'()")
        return set
    }()

    private static let fullURLAllowed: CharacterSet = {
        var set = componentURLAllowed
        set.insert(charactersIn: ";,/?:@&=+$#")
        return set
    }()

    private static func timeParse(_ text: String) throws -> [String: String] {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw TextError(message: "没有内容") }
        if trimmed.allSatisfy(\.isNumber) {
            guard trimmed.count == 10 || trimmed.count == 13, let raw = Double(trimmed) else {
                throw TextError(message: "时间戳要是 10 位的秒或 13 位的毫秒")
            }
            let seconds = trimmed.count == 13 ? raw / 1000 : raw
            return timeFields(Date(timeIntervalSince1970: seconds))
        }
        guard let date = parseDate(trimmed) else {
            throw TextError(message: "认不出这个时间，用 2026-10-17 11:14:00 这种写法")
        }
        return timeFields(date)
    }

    private static func timeFields(_ date: Date) -> [String: String] {
        let seconds = Int64(date.timeIntervalSince1970)
        let millis = Int64((date.timeIntervalSince1970 * 1000).rounded())
        return [
            "local": format(date),
            "seconds": String(seconds),
            "millis": String(millis)
        ]
    }

    private static func parseDate(_ text: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        for format in ["yyyy-MM-dd HH:mm:ss", "yyyy-MM-dd HH:mm", "yyyy-MM-dd"] {
            formatter.dateFormat = format
            if let date = formatter.date(from: text) {
                return date
            }
        }
        let iso = ISO8601DateFormatter()
        iso.timeZone = .current
        // JavaScript toISOString() 带小数秒。带上这个选项时，没有小数的字符串会认不出，所以两种都试。
        for options in [
            ISO8601DateFormatter.Options.withInternetDateTime.union(.withFractionalSeconds),
            ISO8601DateFormatter.Options.withInternetDateTime
        ] {
            iso.formatOptions = options
            if let date = iso.date(from: text) {
                return date
            }
        }
        return nil
    }

    private static func format(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: date)
    }
}
