import SwiftUI
import ServiceManagement

/// Settings: launch at login, notifications, ignored apps and support link.
struct SettingsView: View {
    @EnvironmentObject private var model: AppModel
    @AppStorage("showNotifications") private var showNotifications = false
    @AppStorage("ignoredApps") private var ignoredApps = ""
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var loginError: String?
    @State private var notificationsDenied = false
    @State private var newIgnored = ""

    var body: some View {
        Form {
            Section("General") {
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, enabled in setLaunchAtLogin(enabled) }
                if let loginError {
                    Text(loginError).font(.caption).foregroundStyle(.red)
                }
                Toggle("Show notification after a transform", isOn: $showNotifications)
                    .onChange(of: showNotifications) { _, enabled in
                        guard enabled else { return }
                        AppModel.requestNotificationAuthorization { granted in notificationsDenied = !granted }
                    }
                if notificationsDenied {
                    Text("Notifications are turned off for CopyRuleFilter. Enable them in System Settings → Notifications.")
                        .font(.caption).foregroundStyle(.orange)
                }
            }
            Section {
                ForEach(ignoredList, id: \.self) { id in
                    HStack {
                        Text(id).font(.body.monospaced())
                        Spacer()
                        Button { setIgnored(ignoredList.filter { $0 != id }) } label: { Image(systemName: "minus.circle") }
                            .buttonStyle(.borderless)
                    }
                }
                HStack {
                    AppPickerField(bundleID: $newIgnored)
                    Button("Add") {
                        let id = newIgnored.trimmingCharacters(in: .whitespaces)
                        if !id.isEmpty, !ignoredList.contains(id) { setIgnored(ignoredList + [id]) }
                        newIgnored = ""
                    }
                }
            } header: {
                Text("Ignored Apps")
            } footer: {
                Text("Automatic rules never run on content copied while these apps are frontmost. Password-manager content marked as concealed is always skipped.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section {
                HStack {
                    Text("CopyRuleFilter is free and open source. Only the pasteboard is read — no special permissions needed.")
                        .font(.caption).foregroundStyle(.secondary)
                    Spacer()
                    Button("Support / Donate ❤️") { AppActions.openDonate() }
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 520, height: 480)
        .onAppear { launchAtLogin = SMAppService.mainApp.status == .enabled }
    }

    private var ignoredList: [String] {
        ignoredApps.split(whereSeparator: { $0 == "\n" || $0 == "," })
            .map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
    }

    private func setIgnored(_ list: [String]) { ignoredApps = list.joined(separator: "\n") }

    private func setLaunchAtLogin(_ enabled: Bool) {
        let service = SMAppService.mainApp
        guard enabled != (service.status == .enabled) else { return }
        do {
            if enabled { try service.register() } else { try service.unregister() }
            loginError = nil
        } catch {
            loginError = "Could not update login item: \(error.localizedDescription)"
            launchAtLogin = service.status == .enabled
        }
    }
}
