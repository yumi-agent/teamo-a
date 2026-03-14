import SwiftUI

struct SidebarView: View {
    @EnvironmentObject var store: ProjectStore
    @Binding var selectedItem: NavigationItem?
    @State private var showCreateAgent = false

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

                Section("WORK") {
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

    var onCreated: ((UUID) -> Void)?

    init(onCreated: ((UUID) -> Void)? = nil) {
        self.onCreated = onCreated
    }

    var body: some View {
        VStack(spacing: 24) {
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

                // Role
                TextField("Role (e.g. Frontend Engineer)", text: $role)
                    .textFieldStyle(.roundedBorder)

                // Engine
                Picker("Engine", selection: $engine) {
                    ForEach(AgentEngine.allCases) { eng in
                        HStack {
                            Image(systemName: eng.iconName)
                            Text(eng.displayName)
                        }
                        .tag(eng)
                    }
                }
                .pickerStyle(.segmented)

                // Optional Goal
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Goal")
                            .font(.system(size: 13, weight: .medium))
                        Text("(optional)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    TextField("What should this agent work towards?", text: $goalDescription)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 13))
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
        .frame(width: 460, height: 420)
    }

    private func createAgent() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        let agentRole = role.trimmingCharacters(in: .whitespaces).isEmpty
            ? "\(engine.displayName) Agent"
            : role.trimmingCharacters(in: .whitespaces)

        let goalDesc = goalDescription.trimmingCharacters(in: .whitespaces)

        store.createAgent(
            name: trimmedName,
            role: agentRole,
            engine: engine,
            goalDescription: goalDesc.isEmpty ? nil : goalDesc
        )

        // Find the created agent to navigate to it
        if let created = store.currentAgents.last(where: { $0.name == trimmedName }) {
            onCreated?(created.id)
        }

        dismiss()
    }
}
