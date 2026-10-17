import Foundation

struct TextError: Error {
    let message: String
}

enum TextTransform {
    static func run(action: String, text: String) throws -> String {
        switch action {
        case "json.pretty":
            return try json(text, pretty: true)
        case "json.compact":
            return try json(text, pretty: false)
        case "base64.encode":
            return try base64Encode(text)
        case "base64.decode":
            return try base64Decode(text)
        case "url.encode":
            return try urlEncode(text)
        case "url.decode":
            return try urlDecode(text)
        case "time.convert":
            return try timeConvert(text)
        case "time.now":
            return render(Date())
        default:
            throw TextError(message: "未知动作")
        }
    }

    private static func json(_ text: String, pretty: Bool) throws -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw TextError(message: "没有内容") }
        guard let data = trimmed.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data) else {
            throw TextError(message: "不是合法的 JSON")
        }
        var options: JSONSerialization.WritingOptions = [.sortedKeys]
        if pretty {
            options.insert(.prettyPrinted)
        }
        let written = try JSONSerialization.data(withJSONObject: object, options: options)
        guard let output = String(data: written, encoding: .utf8) else {
            throw TextError(message: "不是合法的 JSON")
        }
        return output
    }

    private static func base64Encode(_ text: String) throws -> String {
        guard !text.isEmpty else { throw TextError(message: "没有内容") }
        return Data(text.utf8).base64EncodedString()
    }

    private static func base64Decode(_ text: String) throws -> String {
        let compact = String(text.unicodeScalars.filter { !CharacterSet.whitespacesAndNewlines.contains($0) })
        guard !compact.isEmpty else { throw TextError(message: "没有内容") }
        guard let data = Data(base64Encoded: compact) else {
            throw TextError(message: "不是合法的 Base64")
        }
        guard let output = String(data: data, encoding: .utf8) else {
            throw TextError(message: "Base64 解出来不是文本")
        }
        return output
    }

    private static func urlEncode(_ text: String) throws -> String {
        guard !text.isEmpty else { throw TextError(message: "没有内容") }
        guard let encoded = text.addingPercentEncoding(withAllowedCharacters: .alphanumerics) else {
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

    private static func timeConvert(_ text: String) throws -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw TextError(message: "没有内容") }
        if trimmed.allSatisfy(\.isNumber) {
            guard trimmed.count == 10 || trimmed.count == 13, let raw = Double(trimmed) else {
                throw TextError(message: "时间戳要是 10 位的秒或 13 位的毫秒")
            }
            let seconds = trimmed.count == 13 ? raw / 1000 : raw
            return render(Date(timeIntervalSince1970: seconds))
        }
        guard let date = parseDate(trimmed) else {
            throw TextError(message: "认不出这个时间，用 2026-10-17 11:14:00 这种写法")
        }
        return render(date)
    }

    private static func render(_ date: Date) -> String {
        let seconds = Int64(date.timeIntervalSince1970)
        let millis = Int64((date.timeIntervalSince1970 * 1000).rounded())
        return "本地 \(format(date))\n秒 \(seconds)\n毫秒 \(millis)"
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
        return iso.date(from: text)
    }

    private static func format(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: date)
    }
}
