# CopyRuleFilter

Automatic rules that clean or transform whatever you copy, like stripping tracking links or forcing plain text.

![macOS 14+](https://img.shields.io/badge/macOS-14%2B-blue)
![Swift 5.9](https://img.shields.io/badge/Swift-5.9-orange)
![License MIT](https://img.shields.io/badge/License-MIT-green)
![Release](https://img.shields.io/github/v/release/turhe123/copy-rule-filter)

## Why

Rule-based clipboard filters are the reason many people pay for tools in the *Clipboard* category, for example Pastebot ($24.99/year), which inspired this project. CopyRuleFilter is a free, open-source, 100% native, backend-free alternative that focuses on one thing: a rules engine for your clipboard. It has no accounts, no servers, and no analytics. Everything stays on your Mac.

## Features

- **Menu bar app.** Lives in the menu bar, with no Dock icon. The menu has a **Pause All Rules** toggle, an **Apply to Clipboard** list of your on-demand rules, and shortcuts to Rules, Settings, and Support.
- **Rules.** Each rule has a name, an enabled toggle, a run mode, an optional condition, and an ordered list of actions.
- **Automatic or on demand.** Automatic rules run on every copy (the pasteboard is polled every 0.4 s). On-demand rules transform the current clipboard when you pick them from the menu.
- **Conditions.** Always, content is text, content is a URL, text matches a regex, source app is, or source app is not.
- **Actions.**
  - Convert to plain text
  - Trim whitespace
  - Collapse blank lines
  - Remove tracking parameters (utm, fbclid, and similar) from URLs
  - Lowercase, uppercase, and Title Case
  - Smart quotes → straight quotes
  - Strip prefix and strip suffix
  - Find and replace with a regex (with `$1…` capture groups)
  - Wrap each line with a prefix and suffix
- **Rules window.** A split view with the rule list on the left (add from template, duplicate, delete, drag to reorder, import and export) and the editor on the right.
- **Live Test area.** Paste sample text and see the before and after result as you edit.
- **Six starter rules.** Plain text for chosen apps (the only one enabled), Strip tracking links, Tidy whitespace, Straight quotes, Title Case, and Quote as Markdown.
- **Import and export.** Share rules as JSON. Malformed or newer-format files show an error and never overwrite your existing rules.
- **Safety.**
  - Concealed, transient, auto-generated, and 1Password pasteboard content is skipped.
  - File copies and clipboards over 2 MB are skipped.
  - Invalid regexes are flagged and the rule is skipped.
  - A rule that would produce empty output leaves the clipboard unchanged.
  - Each change is written back once, so the app does not process its own write.
  - Rich formatting is kept unless a rule converts to plain text.
- **Activity and counter.** A recent activity list and a "transformed today" counter.
- **Settings.** Launch at login, an optional notification after each transform, and an ignored apps list.
- **Local storage.** Rules are saved as versioned JSON in `~/Library/Application Support/CopyRuleFilter/rules.json`. If that file can't be read, it is kept as `rules.corrupt.json` and the defaults are loaded.

## Screenshots

_Screenshots coming soon._

## Install

1. Download `CopyRuleFilter-macOS.zip` from the [latest release](https://github.com/turhe123/copy-rule-filter/releases/latest).
2. Unzip it and move `CopyRuleFilter.app` to `/Applications`.
3. The app is open source and not notarized, so clear the quarantine flag:

   ```bash
   xattr -cr /Applications/CopyRuleFilter.app
   ```

4. The first time, right-click the app and choose **Open**.

## Build from source

Requires macOS 14+ and Xcode with Swift 5.9 or later.

```bash
brew install xcodegen
xcodegen generate
xcodebuild -project CopyRuleFilter.xcodeproj -scheme CopyRuleFilter -configuration Release -derivedDataPath ./build build
```

The app is produced at `build/Build/Products/Release/CopyRuleFilter.app`.

## Permissions

CopyRuleFilter only reads and writes the system pasteboard, so it needs **no** Accessibility, Screen Recording, or Microphone permission.

- **Notifications (optional):** requested only when you turn on "Show notification after a transform", and when an on-demand rule reports its result.
- **Login item (optional):** used only if you enable "Launch at login" (via `SMAppService`).

## Support ❤️

CopyRuleFilter is free and open source. If it saves you time, you can support its development:

[Support Or (Leo) Davidai ❤️](https://ko-fi.com/leodavidai)

## License

MIT © Or Davidai Bachar
