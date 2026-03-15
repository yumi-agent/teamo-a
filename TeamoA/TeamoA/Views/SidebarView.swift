import SwiftUI

struct SidebarView: View {
    @EnvironmentObject var store: ProjectStore
    @EnvironmentObject var sessionManager: TerminalSessionManager
    @Binding var selectedItem: NavigationItem?
    @State private var showCreateAgent = false
    @State private var agentToDelete: Agent?

    var body: some View {
        VStack(spacing: 0) {
            // Workspace header
            workspaceHeader
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

            Divider()

            List(selection: $selectedItem) {
                // Dashboard
                NavigationLink(value: NavigationItem.dashboard) {
                    HStack {
                        Label("Dashboard", systemImage: "square.grid.2x2")
                        Spacer()
                        if store.runningAgentsCount > 0 {
                            HStack(spacing: 4) {
                                Circle().fill(.blue).frame(width: 6, height: 6)
                                Text("\(store.runningAgentsCount) live")
                                    .font(.caption2)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }

                NavigationLink(value: NavigationItem.workbench) {
                    HStack {
                        Label("Workbench", systemImage: "rectangle.split.2x2")
                        Spacer()
                        if store.runningAgentsCount > 0 {
                            Text("\(store.runningAgentsCount)")
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(.green.opacity(0.2)))
                                .foregroundColor(.green)
                        }
                    }
                }

                NavigationLink(value: NavigationItem.issues) {
                    Label {
                        HStack {
                            Text("Issues")
                            Spacer()
                            if store.openIssuesCount > 0 {
                                Text("\(store.openIssuesCount)")
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Capsule().fill(.secondary.opacity(0.2)))
                            }
                        }
                    } icon: {
                        Image(systemName: "circle.dotted")
                    }
                }

                NavigationLink(value: NavigationItem.goals) {
                    Label {
                        HStack {
                            Text("Goals")
                            Spacer()
                            if store.goalsTotalCount > 0 {
                                Text("\(store.goalsCompletedCount)/\(store.goalsTotalCount)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    } icon: {
                        Image(systemName: "target")
                    }
                }

                NavigationLink(value: NavigationItem.settings) {
                    Label("Settings", systemImage: "gearshape")
                }

                Section("AGENTS") {
                    if store.currentAgents.isEmpty {
                        Button(action: { showCreateAgent = true }) {
                            HStack(spacing: 8) {
                                Image(systemName: "plus.circle.dashed")
                                    .foregroundColor(.blue)
                                Text("Create first agent...")
                                    .font(.system(size: 13))
                                    .foregroundColor(.blue)
                            }
                        }
                        .buttonStyle(.plain)
                    } else {
                        ForEach(store.currentAgents) { agent in
                            NavigationLink(value: NavigationItem.agent(agent.id)) {
                                AgentSidebarRow(agent: agent)
                            }
                            .contextMenu {
                                Button(role: .destructive, action: {
                                    agentToDelete = agent
                                }) {
                                    Label("Delete Agent", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(.sidebar)
        }
        .toolbar {
            ToolbarItem {
                Button(action: { showCreateAgent = true }) {
                    Image(systemName: "plus")
                }
                .help("New Agent")
            }
        }
        .sheet(isPresented: $showCreateAgent) {
            CreateAgentView { agentId in
                selectedItem = .agent(agentId)
            }
        }
        .alert("Delete Agent", isPresented: Binding(
            get: { agentToDelete != nil },
            set: { if !$0 { agentToDelete = nil } }
        )) {
            Button("Cancel", role: .cancel) { agentToDelete = nil }
            Button("Delete", role: .destructive) {
                if let agent = agentToDelete {
                    sessionManager.destroySession(for: agent.id)
                    store.deleteAgent(agent)
                    if selectedItem == .agent(agent.id) {
                        selectedItem = .dashboard
                    }
                    agentToDelete = nil
                }
            }
        } message: {
            if let agent = agentToDelete {
                Text("Are you sure you want to delete \"\(agent.name)\"? This will terminate any running process and cannot be undone.")
            }
        }
    }

    private var workspaceHeader: some View {
        HStack(spacing: 8) {
            if let ws = store.currentWorkspace {
                Image(systemName: ws.workspaceType.iconName)
                    .font(.system(size: 14))
                    .foregroundColor(.blue)
                VStack(alignment: .leading, spacing: 1) {
                    Text(ws.name)
                        .font(.system(size: 14, weight: .semibold))
                    Text(ws.workspaceType.displayName)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct AgentSidebarRow: View {
    @ObservedObject var agent: Agent

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: agent.iconName)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .frame(width: 20)

            Text(agent.name)
                .lineLimit(1)

            Spacer()

            if agent.state == .running {
                HStack(spacing: 4) {
                    Circle().fill(.green).frame(width: 6, height: 6)
                    Text("live")
                        .font(.caption2)
                        .foregroundColor(.green)
                }
            } else {
                Circle()
                    .fill(agent.state.color)
                    .frame(width: 8, height: 8)
            }
        }
    }
}

// MARK: - Create Agent

struct CreateAgentView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: ProjectStore
    @State private var name = ""
    @State private var role = ""
    @State private var engine: AgentEngine = .claudeCode
    @State private var goalDescription = ""
    @State private var workingDirectory = NSHomeDirectory()

    var onCreated: ((UUID) -> Void)?

    init(onCreated: ((UUID) -> Void)? = nil) {
        self.onCreated = onCreated
    }

    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 6) {
                Image(systemName: "person.badge.plus")
                    .font(.system(size: 32))
                    .foregroundColor(.blue)
                Text("New Agent")
                    .font(.title2.bold())
                Text("Create an agent to start working on tasks")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Form {
                // Name
                TextField("Agent Name", text: $name)
                    .textFieldStyle(.roundedBorder)

                // Role (optional)
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Text("Role")
                            .font(.system(size: 13, weight: .medium))
                        Text("(optional)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    TextField("e.g. Frontend Engineer", text: $role)
                        .textFieldStyle(.roundedBorder)
                }

                // Engine — only Claude Code and Codex
                Picker("Engine", selection: $engine) {
                    Text("Claude Code").tag(AgentEngine.claudeCode)
                    Text("Codex").tag(AgentEngine.codex)
                }
                .pickerStyle(.segmented)

                // Working Directory
                VStack(alignment: .leading, spacing: 4) {
                    Text("Working Directory")
                        .font(.system(size: 13, weight: .medium))
                    HStack {
                        Text(workingDirectory)
                            .font(.system(size: 12, design: .monospaced))
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(RoundedRectangle(cornerRadius: 6).fill(Color(.textBackgroundColor)))
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(.separatorColor)))

                        Button("Choose...") {
                            chooseDirectory()
                        }
                    }
                }

                // Goal (optional) — multi-line
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Text("Goal")
                            .font(.system(size: 13, weight: .medium))
                        Text("(optional)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    TextEditor(text: $goalDescription)
                        .font(.system(size: 13))
                        .frame(height: 80)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color(.separatorColor))
                        )
                        .overlay(alignment: .topLeading) {
                            if goalDescription.isEmpty {
                                Text("Describe what this agent should work on...")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary.opacity(0.5))
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 8)
                                    .allowsHitTesting(false)
                            }
                        }
                }
            }
            .formStyle(.grouped)

            // Actions
            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)

                Spacer()

                Button(action: createAgent) {
                    Text("Create Agent")
                        .frame(width: 120)
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(20)
        .frame(width: 500, height: 540)
    }

    private func chooseDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.directoryURL = URL(fileURLWithPath: workingDirectory)
        panel.prompt = "Select"
        if panel.runModal() == .OK, let url = panel.url {
            workingDirectory = url.path
        }
    }

    private func createAgent() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        let trimmedRole = role.trimmingCharacters(in: .whitespaces)

        let goalDesc = goalDescription.trimmingCharacters(in: .whitespaces)

        store.createAgent(
            name: trimmedName,
            role: trimmedRole.isEmpty ? "" : trimmedRole,
            engine: engine,
            goalDescription: goalDesc.isEmpty ? nil : goalDesc,
            workingDirectory: workingDirectory
        )

        // Find the created agent to navigate to it
        if let created = store.currentAgents.last(where: { $0.name == trimmedName }) {
            onCreated?(created.id)
        }

        dismiss()
    }
}
