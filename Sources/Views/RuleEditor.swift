import SwiftUI
import AppKit

/// Editor for one rule: name, run mode, condition, ordered actions and a live before/after test area.
struct RuleEditor: View {
    @Binding var rule: Rule
    @State private var sample = "Check this out: https://example.com/article?id=42&utm_source=news&fbclid=abc\n\n\n“Smart quotes”   "
    @State private var sampleApp = ""

    var body: some View {
        Form {
            Section {
                TextField("Name", text: $rule.name)
                Toggle("Enabled", isOn: $rule.enabled)
                Picker("Run", selection: $rule.mode) {
                    ForEach(RunMode.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
            }
            Section("Condition") { conditionEditor }
            Section {
                if rule.actions.isEmpty {
                    Text("Add at least one action.").foregroundStyle(.secondary)
                }
                ForEach($rule.actions) { $action in
                    ActionRow(action: $action,
                              canMoveUp: rule.actions.first?.id != action.id,
                              canMoveDown: rule.actions.last?.id != action.id,
                              move: { move(action.id, by: $0) },
                              remove: { rule.actions.removeAll { $0.id == action.id } })
                }
            } header: {
                HStack {
                    Text("Actions (run top to bottom)")
                    Spacer()
                    Menu {
                        ForEach(RuleAction.Kind.allCases) { kind in
                            Button(kind.title) { rule.actions.append(RuleAction(kind: kind)) }
                        }
                    } label: { Label("Add Action", systemImage: "plus") }
                        .menuStyle(.borderlessButton).fixedSize()
                }
            }
            Section("Test") { testArea }
        }
        .formStyle(.grouped)
    }

    @ViewBuilder private var conditionEditor: some View {
        Picker("Only when", selection: $rule.condition.kind) {
            ForEach(Condition.Kind.allCases) { Text($0.title).tag($0) }
        }
        switch rule.condition.kind {
        case .matchesRegex:
            TextField("Pattern", text: $rule.condition.value).font(.body.monospaced())
            if let error = RuleEngine.regexError(rule.condition.value) {
                Text(error + " — this rule is skipped until fixed.").font(.caption).foregroundStyle(.red)
            }
        case .sourceAppIs, .sourceAppIsNot:
            AppPickerField(bundleID: $rule.condition.value)
        default:
            EmptyView()
        }
    }

    private var testArea: some View {
        let isAppCondition = rule.condition.kind == .sourceAppIs || rule.condition.kind == .sourceAppIsNot
        let content = ClipContent(text: sample, sourceBundleID: isAppCondition ? sampleApp : nil)
        var probe = rule
        probe.enabled = true
        let invalid = RuleEngine.validationError(for: rule)
        let matched = RuleEngine.matches(rule.condition, content)
        let output = RuleEngine.run([probe], on: content).text
        return VStack(alignment: .leading, spacing: 8) {
            if isAppCondition {
                TextField("Pretend source app (bundle ID)", text: $sampleApp)
            }
            HStack(spacing: 10) {
                pane(title: "Before") { TextEditor(text: $sample) }
                pane(title: "After") {
                    ScrollView { Text(output).frame(maxWidth: .infinity, alignment: .leading).textSelection(.enabled).padding(4) }
                }
            }
            .frame(height: 170)
            if let invalid {
                Label(invalid, systemImage: "exclamationmark.triangle.fill").foregroundStyle(.red).font(.caption)
            } else if !matched {
                Label("Condition not met — text passes through unchanged.", systemImage: "info.circle").font(.caption).foregroundStyle(.secondary)
            } else if output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Label("Empty output — the clipboard would be left unchanged.", systemImage: "info.circle").font(.caption).foregroundStyle(.orange)
            }
        }
    }

    private func pane<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            content()
                .font(.body.monospaced())
                .scrollContentBackground(.hidden)
                .background(Color(nsColor: .textBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(.quaternary))
        }
    }

    private func move(_ id: RuleAction.ID, by offset: Int) {
        guard let i = rule.actions.firstIndex(where: { $0.id == id }) else { return }
        let j = i + offset
        guard rule.actions.indices.contains(j) else { return }
        rule.actions.swapAt(i, j)
    }
}

/// One editable action with its parameters and reorder / delete buttons.
struct ActionRow: View {
    @Binding var action: RuleAction
    let canMoveUp: Bool
    let canMoveDown: Bool
    let move: (Int) -> Void
    let remove: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Picker("", selection: $action.kind) {
                    ForEach(RuleAction.Kind.allCases) { Text($0.title).tag($0) }
                }
                .labelsHidden()
                Spacer()
                Button { move(-1) } label: { Image(systemName: "arrow.up") }.disabled(!canMoveUp).help("Move up")
                Button { move(1) } label: { Image(systemName: "arrow.down") }.disabled(!canMoveDown).help("Move down")
                Button(role: .destructive, action: remove) { Image(systemName: "minus.circle") }.help("Remove action")
            }
            .buttonStyle(.borderless)
            let labels = action.kind.parameterLabels
            if labels.count > 0 { TextField(labels[0], text: $action.first).font(.body.monospaced()) }
            if labels.count > 1 { TextField(labels[1], text: $action.second).font(.body.monospaced()) }
            if action.kind == .regexReplace, let error = RuleEngine.regexError(action.first) {
                Text(error + " — this rule is skipped until fixed.").font(.caption).foregroundStyle(.red)
            }
        }
        .padding(.vertical, 2)
    }
}

/// A bundle-ID text field with a menu of currently running apps to pick from.
struct AppPickerField: View {
    @Binding var bundleID: String

    var body: some View {
        HStack {
            TextField("App bundle ID", text: $bundleID, prompt: Text("com.apple.Safari"))
            Menu("Running Apps") {
                ForEach(runningApps, id: \.0) { id, name in
                    Button(name) { bundleID = id }
                }
            }
            .fixedSize()
        }
    }

    private var runningApps: [(String, String)] {
        NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular }
            .compactMap { app in app.bundleIdentifier.map { ($0, app.localizedName ?? $0) } }
            .sorted { $0.1.localizedCaseInsensitiveCompare($1.1) == .orderedAscending }
    }
}
