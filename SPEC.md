# CopyRuleFilter — specification

**Tagline:** Automatic rules that clean or transform whatever you copy, like stripping tracking links or forcing plain text.

**Category:** Clipboard

**Inspired by (paid):** Pastebot ($24.99/year)

**Frameworks:** SwiftUI, AppKit, Foundation, ServiceManagement, UserNotifications

**Donation URL (Support button):** https://ko-fi.com/leodavidai

## Spec

What the paid app does and evidence of demand. Pastebot from Tapbots is a long-running clipboard manager whose standout idea is filters, small automations that transform clipboard content as you copy or paste. The Mac App Store edition is sold as a subscription at 2.99 dollars per month or 24.99 dollars per year, and MacStories and 9to5Mac covered its release and its third major version. The filter and rule concept is the reason people pay for it over simpler history tools. Our clean-room version, CopyRuleFilter, focuses on only the rules engine and leaves the history browser to other tools.

Feature set. A rule has a name, an enabled toggle, an optional condition, and one or more ordered actions. Conditions: content is text, content is a URL, text matches a regular expression, or source app is or is not a chosen app. Built-in actions: convert to plain text, trim whitespace, collapse multiple blank lines, remove tracking query parameters such as utm and fbclid from URLs, convert to lowercase, uppercase or title case, convert smart quotes to straight quotes, strip a given prefix or suffix, find and replace with a regular expression, and wrap each line in a chosen prefix and suffix. A rule can run automatically on every copy or only on demand from a menu. A Test area lets the user paste sample text and see the before and after result live. Ship six default rules, all disabled except Plain text for chosen apps.

UI spec. The app is a MenuBarExtra. The menu shows a Pause All Rules toggle, a list of on-demand rules which, when clicked, transform the current clipboard in place and show a brief notification, a Rules item that opens the window, and Quit. The main window is a split view with the rule list on the left, including add, duplicate, delete, and drag to reorder, and an editor on the right. The editor has a name field, a run mode picker with Automatic and On demand, a condition section, an action list with add and reorder controls, and the live test area with two text panes. Empty state for the rule list: a message saying No rules yet with a button to add one from a template. A small counter in the window footer shows how many items were transformed today. Settings include Launch at login, Show notification after a transform, and an ignored apps list.

Technical approach. Poll NSPasteboard.general.changeCount on a short timer. When it changes and automatic rules exist, read the string and URL representations, run the matching rules in order, and if the result differs, write it back and record the new changeCount so the app does not process its own write. Respect concealed and transient pasteboard types by skipping them entirely. Use NSRegularExpression for patterns and URLComponents for query parameter removal. Model rules with Codable structs and persist them as JSON in Application Support, with a version field for future migration. Settings use AppStorage. Notifications use UserNotifications, with authorization requested the first time the toggle is enabled. No Accessibility or Screen Recording permission is needed because the app only reads and writes the pasteboard. Launch at login uses SMAppService.mainApp.

Edge cases and error handling. Invalid regular expressions are flagged inline in red and the rule is skipped at runtime. Guard against infinite loops by processing each changeCount at most once. If a rule produces empty output, leave the clipboard unchanged and log it in a small recent activity list. Preserve rich formatting unless an action explicitly converts to plain text. Large clipboards over 2 megabytes are skipped. Importing and exporting rules as a JSON file through open and save panels lets users share them, and malformed imports show a clear error rather than overwriting existing rules.
