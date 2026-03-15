import SwiftUI

struct SettingsDetailView: View {
    @AppStorage("default_engine") private var defaultEngine: String = AgentEngine.claudeCode.rawValue
    @AppStorage("default_working_directory") private var defaultWorkingDir: String = NSHomeDirectory()
    @AppStorage("notifications_enabled") private var notificationsEnabled: Bool = true
    @AppStorage("workbench_columns") private var workbenchColumns: Int = 2
    @AppStorage("workbench_heightPercent") private var workbenchHeight: Int = 50

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Settings")
                    .font(.title2.bold())
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // General
                    settingsSection("General") {
                        settingsRow("Default Engine") {
                            Picker("", selection: Binding(
                                get: { AgentEngine(rawValue: defaultEngine) ?? .claudeCode },
                                set: { defaultEngine = $0.rawValue }
                            )) {
                                Text("Claude Code").tag(AgentEngine.claudeCode)
                                Text("Codex").tag(AgentEngine.codex)
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 240)
                        }

                        settingsRow("Default Working Directory") {
                            HStack {
                                Text(defaultWorkingDir)
                                    .font(.system(size: 12, design: .monospaced))
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                    .frame(maxWidth: 300, alignment: .leading)

                                Button("Choose...") {
                                    let panel = NSOpenPanel()
                                    panel.canChooseFiles = false
                                    panel.canChooseDirectories = true
                                    panel.directoryURL = URL(fileURLWithPath: defaultWorkingDir)
                                    if panel.runModal() == .OK, let url = panel.url {
                                        defaultWorkingDir = url.path
                                    }
                                }
                                .controlSize(.small)
                            }
                        }
                    }

                    // Notifications
                    settingsSection("Notifications") {
                        settingsRow("Enable Notifications") {
                            Toggle("", isOn: $notificationsEnabled)
                                .toggleStyle(.switch)
                        }
                    }

                    // Workbench
                    settingsSection("Workbench Defaults") {
                        settingsRow("Columns per Row") {
                            Picker("", selection: $workbenchColumns) {
                                Text("1").tag(1)
                                Text("2").tag(2)
                                Text("3").tag(3)
                                Text("4").tag(4)
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 200)
                        }

                        settingsRow("Terminal Height") {
                            Picker("", selection: $workbenchHeight) {
                                Text("25%").tag(25)
                                Text("50%").tag(50)
                                Text("75%").tag(75)
                                Text("100%").tag(100)
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 240)
                        }
                    }

                    // About
                    settingsSection("About") {
                        HStack {
                            Text("Teamo A")
                                .font(.system(size: 13, weight: .medium))
                            Text("v0.2.0")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(24)
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private func settingsSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            VStack(spacing: 0) {
                content()
            }
            .background(RoundedRectangle(cornerRadius: 8).fill(Color(nsColor: .controlBackgroundColor)))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.15)))
        }
    }

    private func settingsRow<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
            Spacer()
            content()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}
