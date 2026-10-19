import Foundation

/// When a rule runs: on every copy, or only when picked from the menu.
enum RunMode: String, Codable, CaseIterable, Identifiable {
    case automatic, onDemand
    var id: String { rawValue }
    var title: String { self == .automatic ? "Automatic" : "On demand" }
}

/// An optional gate that decides whether a rule applies to the current clipboard.
struct Condition: Codable, Hashable {
    /// The kind of test performed by a condition.
    enum Kind: String, Codable, CaseIterable, Identifiable {
        case always, isText, isURL, matchesRegex, sourceAppIs, sourceAppIsNot
        var id: String { rawValue }
        var title: String {
            switch self {
            case .always: return "Always (no condition)"
            case .isText: return "Content is text"
            case .isURL: return "Content is a URL"
            case .matchesRegex: return "Text matches regex"
            case .sourceAppIs: return "Source app is"
            case .sourceAppIsNot: return "Source app is not"
            }
        }
    }
    var kind: Kind = .always
    var value: String = ""
}

/// A single ordered transformation step inside a rule.
struct RuleAction: Codable, Hashable, Identifiable {
    /// The built-in transformation performed by an action.
    enum Kind: String, Codable, CaseIterable, Identifiable {
        case plainText, trim, collapseBlankLines, removeTracking, lowercase, uppercase, titleCase
        case straightQuotes, stripPrefix, stripSuffix, regexReplace, wrapLines
        var id: String { rawValue }
        var title: String {
            switch self {
            case .plainText: return "Convert to plain text"
            case .trim: return "Trim whitespace"
            case .collapseBlankLines: return "Collapse blank lines"
            case .removeTracking: return "Remove tracking parameters"
            case .lowercase: return "Lowercase"
            case .uppercase: return "Uppercase"
            case .titleCase: return "Title Case"
            case .straightQuotes: return "Smart quotes → straight"
            case .stripPrefix: return "Strip prefix"
            case .stripSuffix: return "Strip suffix"
            case .regexReplace: return "Find & replace (regex)"
            case .wrapLines: return "Wrap each line"
            }
        }
        /// Labels for the parameters this action uses (empty when none).
        var parameterLabels: [String] {
            switch self {
            case .stripPrefix: return ["Prefix"]
            case .stripSuffix: return ["Suffix"]
            case .regexReplace: return ["Pattern", "Replacement ($1…)"]
            case .wrapLines: return ["Line prefix", "Line suffix"]
            default: return []
            }
        }
    }
    var id = UUID()
    var kind: Kind
    var first: String = ""
    var second: String = ""
}

/// A named, ordered list of actions with an optional condition.
struct Rule: Codable, Hashable, Identifiable {
    var id = UUID()
    var name: String
    var enabled: Bool = false
    var mode: RunMode = .automatic
    var condition = Condition()
    var actions: [RuleAction] = []
}

/// The on-disk / import-export envelope, versioned for future migrations.
struct RuleFile: Codable {
    static let currentVersion = 1
    var version: Int = RuleFile.currentVersion
    var rules: [Rule]
}

extension Rule {
    /// The six rules shipped on first launch; only "Plain text for chosen apps" is enabled.
    static var defaults: [Rule] {
        [
            Rule(name: "Plain text for chosen apps", enabled: true, mode: .automatic,
                 condition: Condition(kind: .sourceAppIs, value: "com.apple.Safari"),
                 actions: [RuleAction(kind: .plainText)]),
            Rule(name: "Strip tracking links", mode: .automatic,
                 condition: Condition(kind: .isText),
                 actions: [RuleAction(kind: .removeTracking)]),
            Rule(name: "Tidy whitespace", mode: .automatic,
                 condition: Condition(kind: .isText),
                 actions: [RuleAction(kind: .trim), RuleAction(kind: .collapseBlankLines)]),
            Rule(name: "Straight quotes", mode: .onDemand,
                 actions: [RuleAction(kind: .straightQuotes)]),
            Rule(name: "Title Case", mode: .onDemand,
                 actions: [RuleAction(kind: .titleCase)]),
            Rule(name: "Quote as Markdown", mode: .onDemand,
                 actions: [RuleAction(kind: .wrapLines, first: "> ")]),
        ]
    }
}
