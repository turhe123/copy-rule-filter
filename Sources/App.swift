import SwiftUI
import AppKit

/// App entry point: a menu bar extra, the Rules window and the Settings scene.
@main
struct CopyRuleFilterApp: App {
    @StateObject private var model = AppModel()

    var body: some Scene {
        MenuBarExtra("CopyRuleFilter", systemImage: model.isPaused ? "pause.circle" : "line.3.horizontal.decrease.circle") {
            MenuContent().environmentObject(model)
        }
        Window("CopyRuleFilter Rules", id: "rules") {
            RulesWindow().environmentObject(model)
        }
        .defaultSize(width: 920, height: 640)
        Settings {
            SettingsView().environmentObject(model)
        }
    }
}

/// Shared helpers for links and window activation.
enum AppActions {
    static func openDonate() {
        NSWorkspace.shared.open(URL(string: "https://ko-fi.com/leodavidai")!)
    }

    static func openSettings() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }
}

/// The menu shown from the menu bar icon.
struct MenuContent: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Toggle("Pause All Rules", isOn: $model.isPaused)
        Divider()
        let onDemand = model.rules.filter { $0.enabled && $0.mode == .onDemand }
        if onDemand.isEmpty {
            Text("No on-demand rules enabled")
        } else {
            Section("Apply to Clipboard") {
                ForEach(onDemand) { rule in
                    Button(rule.name) { model.runOnDemand(rule) }
                }
            }
        }
        Divider()
        Button("Rules…") {
            openWindow(id: "rules")
            NSApp.activate(ignoringOtherApps: true)
        }
        .keyboardShortcut("r")
        Button("Settings…") { AppActions.openSettings() }
            .keyboardShortcut(",")
        Button("Support / Donate ❤️") { AppActions.openDonate() }
        Divider()
        Button("Quit CopyRuleFilter") { NSApp.terminate(nil) }
            .keyboardShortcut("q")
    }
}
