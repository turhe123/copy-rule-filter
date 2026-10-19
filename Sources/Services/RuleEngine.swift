import Foundation

/// Snapshot of the clipboard (or test input) that rules are evaluated against.
struct ClipContent {
    var text: String
    var hasURLType = false
    var sourceBundleID: String?
}

/// Result of running one or more rules over a piece of text.
struct EngineResult {
    var text: String
    var forcePlain = false
    var appliedRules: [String] = []
}

/// Pure, side-effect-free evaluation of conditions and actions.
enum RuleEngine {
    static let trackingKeys: Set<String> = [
        "fbclid", "gclid", "dclid", "gbraid", "wbraid", "msclkid", "mc_cid", "mc_eid", "igshid",
        "yclid", "twclid", "ttclid", "_hsenc", "_hsmi", "mkt_tok", "oly_anon_id", "oly_enc_id",
        "vero_id", "ref_src", "s_cid", "spm",
    ]

    /// Returns a compile error message for a pattern, or nil when it is valid.
    static func regexError(_ pattern: String) -> String? {
        do { _ = try NSRegularExpression(pattern: pattern); return nil } catch {
            return "Invalid regular expression"
        }
    }

    /// Returns the first invalid regex in a rule, so the rule can be flagged and skipped.
    static func validationError(for rule: Rule) -> String? {
        if rule.condition.kind == .matchesRegex, let e = regexError(rule.condition.value) { return "Condition: \(e)" }
        for action in rule.actions where action.kind == .regexReplace {
            if let e = regexError(action.first) { return "\(action.kind.title): \(e)" }
        }
        return nil
    }

    static func matches(_ condition: Condition, _ content: ClipContent) -> Bool {
        let app = condition.value.trimmingCharacters(in: .whitespaces)
        switch condition.kind {
        case .always: return true
        case .isText: return !content.text.isEmpty && !isURL(content)
        case .isURL: return isURL(content)
        case .matchesRegex:
            guard let re = try? NSRegularExpression(pattern: condition.value) else { return false }
            return re.firstMatch(in: content.text, range: NSRange(content.text.startIndex..., in: content.text)) != nil
        case .sourceAppIs: return content.sourceBundleID?.caseInsensitiveCompare(app) == .orderedSame
        case .sourceAppIsNot: return content.sourceBundleID?.caseInsensitiveCompare(app) != .orderedSame
        }
    }

    static func isURL(_ content: ClipContent) -> Bool {
        if content.hasURLType { return true }
        let t = content.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.contains(where: \.isWhitespace), let url = URL(string: t), let scheme = url.scheme else { return false }
        return url.host != nil || scheme == "mailto"
    }

    /// Runs the given rules in order; rules with invalid regexes or unmet conditions are skipped.
    static func run(_ rules: [Rule], on content: ClipContent) -> EngineResult {
        var result = EngineResult(text: content.text)
        for rule in rules {
            guard validationError(for: rule) == nil else { continue }
            var current = content
            current.text = result.text
            guard matches(rule.condition, current) else { continue }
            let before = result
            for action in rule.actions {
                if action.kind == .plainText { result.forcePlain = true }
                result.text = apply(action, to: result.text)
            }
            if result.text != before.text || result.forcePlain != before.forcePlain {
                result.appliedRules.append(rule.name)
            }
        }
        return result
    }

    static func apply(_ action: RuleAction, to text: String) -> String {
        switch action.kind {
        case .plainText: return text
        case .trim: return text.trimmingCharacters(in: .whitespacesAndNewlines)
        case .collapseBlankLines: return replace(#"(\r?\n[ \t]*){3,}"#, in: text, with: "\n\n")
        case .removeTracking: return removeTracking(in: text)
        case .lowercase: return text.lowercased()
        case .uppercase: return text.uppercased()
        case .titleCase: return text.capitalized
        case .straightQuotes:
            var out = text
            for c in ["\u{201C}", "\u{201D}", "\u{201E}", "\u{201F}", "\u{2033}"] { out = out.replacingOccurrences(of: c, with: "\"") }
            for c in ["\u{2018}", "\u{2019}", "\u{201A}", "\u{201B}", "\u{2032}"] { out = out.replacingOccurrences(of: c, with: "'") }
            return out
        case .stripPrefix:
            guard !action.first.isEmpty, text.hasPrefix(action.first) else { return text }
            return String(text.dropFirst(action.first.count))
        case .stripSuffix:
            guard !action.first.isEmpty, text.hasSuffix(action.first) else { return text }
            return String(text.dropLast(action.first.count))
        case .regexReplace: return replace(action.first, in: text, with: action.second)
        case .wrapLines:
            return text.components(separatedBy: "\n").map { action.first + $0 + action.second }.joined(separator: "\n")
        }
    }

    private static func replace(_ pattern: String, in text: String, with template: String) -> String {
        guard let re = try? NSRegularExpression(pattern: pattern) else { return text }
        return re.stringByReplacingMatches(in: text, range: NSRange(text.startIndex..., in: text), withTemplate: template)
    }

    /// Removes utm_* and known click-ID parameters from every URL found in the text.
    static func removeTracking(in text: String) -> String {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else { return text }
        let ns = text as NSString
        var out = text
        let matches = detector.matches(in: text, range: NSRange(location: 0, length: ns.length))
        for match in matches.reversed() {
            let original = ns.substring(with: match.range)
            guard let cleaned = cleanURL(original), cleaned != original,
                  let range = Range(match.range, in: out) else { continue }
            out.replaceSubrange(range, with: cleaned)
        }
        return out
    }

    static func cleanURL(_ string: String) -> String? {
        guard var comps = URLComponents(string: string), let items = comps.queryItems else { return nil }
        let kept = items.filter { item in
            let key = item.name.lowercased()
            return !key.hasPrefix("utm_") && !trackingKeys.contains(key)
        }
        guard kept.count != items.count else { return nil }
        comps.queryItems = kept.isEmpty ? nil : kept
        return comps.string
    }
}
