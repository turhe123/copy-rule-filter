import SwiftUI

/// Split view: the rule list with add / duplicate / delete / reorder, and the editor for the selection.
struct RulesWindow: View {
    @EnvironmentObject private var model: AppModel
    @State private var selection: Rule.ID?

    var body: some View {
        NavigationSplitView {
            sidebar.navigationSplitViewColumnWidth(min: 220, ideal: 250)
        } detail: {
            if let id = selection, let binding = binding(for: id) {
                RuleEditor(rule: binding).id(id)
            } else {
                ContentUnavailableView("Select a Rule", systemImage: "line.3.horizontal.decrease.circle",
                                       description: Text("Choose a rule on the left to edit it."))
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) { footer }
        .alert("CopyRuleFilter", isPresented: Binding(get: { model.errorMessage != nil },
                                                      set: { if !$0 { model.errorMessage = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(model.errorMessage ?? "")
        }
        .onAppear { model.refreshTodayCount() }
    }

    private var sidebar: some View {
        Group {
            if model.rules.isEmpty {
                ContentUnavailableView {
                    Label("No rules yet", systemImage: "wand.and.stars")
                } actions: {
                    templateMenu(title: "Add from Template")
                }
            } else {
                List(selection: $selection) {
                    ForEach(model.rules) { rule in
                        RuleRow(rule: rule).tag(rule.id)
                            .contextMenu {
                                Button("Duplicate") { duplicate(rule.id) }
                                Button("Delete", role: .destructive) { delete(rule.id) }
                            }
                    }
                    .onMove { model.rules.move(fromOffsets: $0, toOffset: $1) }
                    .onDelete { model.rules.remove(atOffsets: $0) }
                }
            }
        }
        .toolbar {
            ToolbarItemGroup {
                templateMenu(title: "Add Rule")
                Button { if let id = selection { duplicate(id) } } label: { Label("Duplicate", systemImage: "plus.square.on.square") }
                    .disabled(selection == nil)
                Button { if let id = selection { delete(id) } } label: { Label("Delete", systemImage: "trash") }
                    .disabled(selection == nil)
            }
        }
    }

    private var footer: some View {
        HStack(spacing: 12) {
            Label("\(model.todayCount) transformed today", systemImage: "checkmark.circle")
                .foregroundStyle(.secondary)
            if let last = model.activity.first {
                Text(last.message).lineLimit(1).truncationMode(.tail).foregroundStyle(.tertiary)
                    .help(model.activity.prefix(10).map(\.message).joined(separator: "\n"))
            }
            Spacer()
            Button("Import…") { model.importRules() }
            Button("Export…") { model.exportRules() }
            Button("Support / Donate ❤️") { AppActions.openDonate() }
        }
        .font(.callout)
        .padding(.horizontal, 12).padding(.vertical, 6)
        .background(.bar)
    }

    private func templateMenu(title: String) -> some View {
        Menu {
            Button("Blank Rule") { add(Rule(name: "New Rule", enabled: true, actions: [RuleAction(kind: .trim)])) }
            Divider()
            ForEach(Rule.defaults, id: \.name) { template in
                Button(template.name) { var r = template; r.enabled = true; add(r) }
            }
        } label: {
            Label(title, systemImage: "plus")
        }
    }

    private func binding(for id: Rule.ID) -> Binding<Rule>? {
        guard let rule = model.rules.first(where: { $0.id == id }) else { return nil }
        return Binding(
            get: { model.rules.first(where: { $0.id == id }) ?? rule },
            set: { new in
                if let i = model.rules.firstIndex(where: { $0.id == id }) { model.rules[i] = new }
            })
    }

    private func add(_ rule: Rule) {
        var r = rule
        r.id = UUID()
        model.rules.append(r)
        selection = r.id
    }

    private func duplicate(_ id: Rule.ID) {
        guard let i = model.rules.firstIndex(where: { $0.id == id }) else { return }
        var copy = model.rules[i]
        copy.id = UUID()
        copy.name += " Copy"
        copy.actions = copy.actions.map { var a = $0; a.id = UUID(); return a }
        model.rules.insert(copy, at: i + 1)
        selection = copy.id
    }

    private func delete(_ id: Rule.ID) {
        model.rules.removeAll { $0.id == id }
        if selection == id { selection = nil }
    }
}

/// A single row in the rule list.
struct RuleRow: View {
    let rule: Rule

    var body: some View {
        HStack {
            Image(systemName: rule.mode == .automatic ? "bolt.fill" : "hand.tap")
                .foregroundStyle(rule.enabled ? Color.accentColor : .secondary)
                .frame(width: 18)
            VStack(alignment: .leading, spacing: 2) {
                Text(rule.name.isEmpty ? "Untitled" : rule.name)
                Text(rule.enabled ? rule.mode.title : "Disabled").font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            if RuleEngine.validationError(for: rule) != nil {
                Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.red).help("Invalid regular expression")
            }
        }
        .opacity(rule.enabled ? 1 : 0.6)
    }
}
